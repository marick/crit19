defmodule CritWeb.UserManagement.UserControllerTest do
  use CritWeb.ConnCase

  alias Crit.Users

  # @create_attrs %{}
  # @update_attrs %{}
  # @invalid_attrs %{}

  # def fixture(:user) do
  #   {:ok, user} = Users.create_user(@create_attrs)
  #   user
  # end

  # describe "index" do
  #   test "lists all users", %{conn: conn} do
  #     conn = get(conn, Routes.user_management_user_path(conn, :index))
  #     assert html_response(conn, 200) =~ "Listing Users"
  #   end
  # end

  defp path(conn, tag),
    do: Routes.user_management_user_path(conn, tag)

  defp get_via_action(conn, tag),
    do: get(conn, path(conn, tag))

  defp post_to_action(conn, tag, attrs \\ %{}),
    do: post(conn, path(conn, tag), attrs)


  defp template_file(file),
    do: "user_management/user/" <> file

  defp assert_rendered(conn, file),
    do: assert html_response(conn, 200) =~ template_file(file)

  describe "new user" do
    test "renders form", %{conn: conn} do
      conn = get_via_action(conn, :new)
      assert html_response(conn, 200) =~ "New User"
    end
  end

  describe "create user" do
    test "redirects to provide another new-user form when data is valid",
      %{conn: conn} do
      attrs = user_creation_params()
      conn = post_to_action(conn, :create, user: attrs)
      assert redirected_to(conn) == path(conn, :new)
    end

    test "renders errors when data is invalid", %{conn: conn} do
      attrs = user_creation_params(display_name: "")
      conn = post_to_action(conn, :create, user: attrs)
      assert_rendered conn, "new.html"
      assert html_response(conn, 200) =~ standard_blank_error()
    end
  end


  # describe "edit user" do
  #   setup [:create_user]

  #   test "renders form for editing chosen user", %{conn: conn, user: user} do
  #     conn = get(conn, Routes.user_management_user_path(conn, :edit, user))
  #     assert html_response(conn, 200) =~ "Edit User"
  #   end
  # end

  # describe "update user" do
  #   setup [:create_user]

  #   test "redirects when data is valid", %{conn: conn, user: user} do
  #     conn = put(conn, Routes.user_management_user_path(conn, :update, user), user: @update_attrs)
  #     assert redirected_to(conn) == Routes.user_management_user_path(conn, :show, user)

  #     conn = get(conn, Routes.user_management_user_path(conn, :show, user))
  #     assert html_response(conn, 200)
  #   end

  #   test "renders errors when data is invalid", %{conn: conn, user: user} do
  #     conn = put(conn, Routes.user_management_user_path(conn, :update, user), user: @invalid_attrs)
  #     assert html_response(conn, 200) =~ "Edit User"
  #   end
  # end

  # describe "delete user" do
  #   setup [:create_user]

  #   test "deletes chosen user", %{conn: conn, user: user} do
  #     conn = delete(conn, Routes.user_management_user_path(conn, :delete, user))
  #     assert redirected_to(conn) == Routes.user_management_user_path(conn, :index)
  #     assert_error_sent 404, fn ->
  #       get(conn, Routes.user_management_user_path(conn, :show, user))
  #     end
  #   end
  # end

  # defp create_user(_) do
  #   user = fixture(:user)
  #   {:ok, user: user}
  # end
end
