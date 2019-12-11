defmodule CritWeb.Workflows.NewUserTest do
  # use CritWeb.ConnCase
  # alias Crit.Users
  # alias Crit.Exemplars.{PasswordFocused}
  # alias Crit.Users.{UserHavingToken, Password}
  # alias CritWeb.{UserManagement.UserController}

  # setup :logged_in_as_user_manager


  # defp audit_data(conn, event) do
  #   {:ok, audit} = Crit.Audit.ToMemory.Server.latest(conn.assigns.audit_pid)
  #   assert audit.event == event
  #   audit.data
  # end

  # def start_adding_user(conn) do
  #   get(conn, UserController.path(:new))
  # end

  # def create_user(params) do
  #   ... |> post(UserController.path(:create, under(:user, params)))

  #   assert_something_that_would_be_useful_for_a_reader
  #   {token: token, user_id: user_id} = audit_data(conn, "created user")
  # end

  # # def present_password_token(token_text) do
  # #   # assert {:ok, _} = Users.one_token(token_text)
  # # end

  # # def user_has_no_password(auth_id) do
  # #   # refute Sql.exists?(Password, [auth_id: auth_id], @institution)
  # # end

  # # def supply_new_password(user_id, new_password) do
  # #   # params = PasswordFocused.params(new_password, new_password)
  # #   # assert :ok = Users.set_password(user_id, params, @institution)
  # # end

  # # def user_has_valid_password(auth_id, password) do
  # #   # assert {:ok, _} =
  # #   #   Users.attempt_login(auth_id, password, @institution)
  # # end

  # test "successful creation through activation", %{conn: conn} do
  #   as_logged_in_user_manager fn -> do
  #     visit_add_user_page()
  #     create_user(Factory.string_params_for(:user))
  #     assert_token_email_sent(last().token.text, last().user.id)
  #   end

  #   without_login fn -> do
  #     present_password_token(last().token.text)
  #     new_password = "something horse something something"
  #     supply_new_password(last().user.auth_id, new_password)
  #   end            

    # assert_user_is_logged_in(last().user.id)
end
