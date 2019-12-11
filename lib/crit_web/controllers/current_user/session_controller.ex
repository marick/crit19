defmodule CritWeb.CurrentUser.SessionController do
  use CritWeb, :controller
  use CritWeb.Controller.Path, :current_user_session_path
  import CritWeb.Plugs.Authorize
  alias Crit.Users
  alias Crit.Users.UniqueId
  alias Crit.Global
  alias CritWeb.PublicController
  use Crit.Global.Default
  

  plug :must_be_logged_in when action in [:logout]
  plug :must_be_logged_out when action not in [:logout]

  def get_login_form(conn, _params) do
    starting_institution = @institution
    render_login(conn, %{}, institution_options(starting_institution))
  end

  # This is a little unusual in that it doesn't use the changeset to
  # populate the fields and show errors. That's because we don't want
  # to specify which field is wrong. Also, we want the password field to
  # be cleared, but not the auth field.

  def try_login(conn, %{"login" => params}) do
    auth_id = params["auth_id"]
    password = params["password"]
    institution = params["institution"]
    case Users.attempt_login(auth_id, password, institution) do
      {:ok, %UniqueId{} = unique_id} ->
        successful_login(conn, unique_id)
      :error ->
        conn
        |> Common.form_error_flash
        |> render_login(params, institution_options(institution))
    end
  end

  def successful_login(conn, %UniqueId{} = unique_id) do
    conn
    |> put_flash(:info, "You have been logged in.")
    |> put_unique_id(unique_id)
    |> redirect(to: PublicController.path(:index))
  end 

  # Note: the `clear_session` isn't actually needed. It's enough to
  # drop the session. However, A test can't (legitimately) tell if the session
  # has been dropped.
  def logout(conn, _params) do
    conn
    |> clear_session()
    |> configure_session(drop: true)
    |> redirect(to: PublicController.path(:index))
  end

  defp render_login(conn, params, {options, selected}) do
    conn
    |> render("login_form.html",
         auth_id: params["auth_id"],
         path: path(:try_login),
         options: options,
         selected: selected
    )
  end

  def institution_options(selected, institutions \\ Global.all_institutions()) do
    winnow = fn institution ->
      {institution.display_name, institution.short_name}
    end

    is_default? = fn { _, short_name} ->
      short_name == @institution
    end

    { default, remainder } =
      institutions
      |> Enum.map(winnow)
      |> EnumX.extract(is_default?)

    sorted_remainder = List.keysort(remainder, 0)

    { [ default | sorted_remainder ] , selected }
  end
end
