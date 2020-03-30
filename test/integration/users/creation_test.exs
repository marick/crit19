defmodule Integration.Users.CreationTest do
  use CritWeb.IntegrationCase
  alias CritWeb.UserManagement.UserController
  alias CritWeb.CurrentUser.{SettingsController, SessionController}
  alias Crit.Sql
  alias Crit.Repo
  alias Crit.Users.User
  alias Crit.Users.Schemas.PasswordToken

  @auth_id "dmarick"
  @display_name "Dawn Marick"
  @email "dmarick@marick.com"
  @permission_list Factory.build(:permission_list)
  @password "password"

  test "user creation workflow", context do
    as_manager = Keyword.get(logged_in_as_user_manager(context), :conn)
    %{conn: as_anonymous} = context

    # ------------------------------------------------------------------------
    get(as_manager, UserController.path(:new))           # New user form
    |> assert_purpose(form_for_creating_new_user())
    # ------------------------------------------------------------------------
    |> follow_form(%{user:                               # Create user
                    %{auth_id: @auth_id,
                      display_name: @display_name,
                      email: @email,
                      permission_list: @permission_list}})
    |> assert_purpose(form_for_creating_new_user())
    # ------------------------------------------------------------------------
                                                        # A user and token exists
    assert %{id: user_id} =
      Sql.get_by(User, [auth_id: @auth_id], @institution)

    assert %{text: token_text} = 
      Repo.get_by(PasswordToken,
        [user_id: user_id, institution_short_name: @institution])
    # ------------------------------------------------------------------------
                                                        # Redeem token
    get(as_anonymous, SettingsController.path(:fresh_password_form, token_text))
    |> assert_purpose(create_a_password_without_needing_an_existing_one())

    # ------------------------------------------------------------------------
    |> follow_form(%{password:                          # Create password
                    %{new_password: @password,
                      new_password_confirmation: @password}})
    |> assert_purpose(home_page_for_logged_in_user())   # Logged in
    |> assert_logged_in(user_id, @institution)
    # ------------------------------------------------------------------------
    |> delete(SessionController.path(:logout))          # Log out
    |> follow_redirect
    |> assert_purpose(public_facing_page())
    |> refute_logged_in
    # ------------------------------------------------------------------------
    |> get(SessionController.path(:get_login_form))     # Log back in
    |> follow_form(%{login:
                    %{auth_id: @auth_id,
                      password: @password}})
    |> assert_purpose(home_page_for_logged_in_user())
    |> assert_logged_in(user_id, @institution)
  end
end
