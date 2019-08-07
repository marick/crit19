defmodule CritWeb.CurrentUser.SessionController do
  use CritWeb, :controller
  alias Crit.Users
  import CritWeb.Plugs.Authorize
  alias Crit.Institutions

  plug :must_be_logged_in when action in [:logout]
  plug :must_be_logged_out when action not in [:logout]

  def path(action), do: Routes.current_user_session_path(Endpoint, action)
  def path(action, param), do: Routes.current_user_session_path(Endpoint, action, param)

  @default_institution_selection "critter4us"

  def get_login_form(conn, _params) do
    render_login(conn, %{}, institution_options(@default_institution_selection))
  end

  def try_login(conn, %{"login" => params}) do
    auth_id = params["auth_id"]
    password = params["password"]
    institution = params["institution"]
    case Users.check_password(auth_id, password, institution) do
      {:ok, user_id} ->
        conn
        |> put_session(:user_id, user_id)
        |> redirect(to: Routes.public_path(conn, :index))
      :error ->
        conn
        |> Common.form_error_flash
        |> render_login(params, institution_options(institution))
    end
  end

  def logout(conn, _params) do
    conn
    |> configure_session(drop: true)
    |> redirect(to: Routes.public_path(conn, :index))
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

  def institution_options(selected, institutions \\ Institutions.all()) do
    winnow = fn institution ->
      {institution.display_name, institution.short_name}
    end

    is_default? = fn { _, short_name} ->
      short_name == Institutions.default_institution.short_name
    end

    { default, remainder } =
      institutions
      |> Enum.map(winnow)
      |> Pile.Enum.extract(is_default?)

    sorted_remainder = List.keysort(remainder, 0)

    { [ default | sorted_remainder ] , selected }
  end
end
