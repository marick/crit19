defmodule CritWeb.Usables.AnimalControllerTest do
  use CritWeb.ConnCase

  # alias Crit.Usables

  # @create_attrs %{lock_version: 42, name: "some name", species: "some species"}
  # @update_attrs %{lock_version: 43, name: "some updated name", species: "some updated species"}
  # @invalid_attrs %{lock_version: nil, name: nil, species: nil}

  # def fixture(:animal) do
  #   {:ok, animal} = Usables.create_animal(@create_attrs)
  #   animal
  # end

  # describe "index" do
  #   test "lists all animals", %{conn: conn} do
  #     conn = get(conn, Routes.usables_animal_path(conn, :index))
  #     assert html_response(conn, 200) =~ "Listing Animals"
  #   end
  # end

  # describe "new animal" do
  #   test "renders form", %{conn: conn} do
  #     conn = get(conn, Routes.usables_animal_path(conn, :new))
  #     assert html_response(conn, 200) =~ "New Animal"
  #   end
  # end

  # describe "create animal" do
  #   test "redirects to show when data is valid", %{conn: conn} do
  #     conn = post(conn, Routes.usables_animal_path(conn, :create), animal: @create_attrs)

  #     assert %{id: id} = redirected_params(conn)
  #     assert redirected_to(conn) == Routes.usables_animal_path(conn, :show, id)

  #     conn = get(conn, Routes.usables_animal_path(conn, :show, id))
  #     assert html_response(conn, 200) =~ "Show Animal"
  #   end

  #   test "renders errors when data is invalid", %{conn: conn} do
  #     conn = post(conn, Routes.usables_animal_path(conn, :create), animal: @invalid_attrs)
  #     assert html_response(conn, 200) =~ "New Animal"
  #   end
  # end

  # describe "edit animal" do
  #   setup [:create_animal]

  #   test "renders form for editing chosen animal", %{conn: conn, animal: animal} do
  #     conn = get(conn, Routes.usables_animal_path(conn, :edit, animal))
  #     assert html_response(conn, 200) =~ "Edit Animal"
  #   end
  # end

  # describe "update animal" do
  #   setup [:create_animal]

  #   test "redirects when data is valid", %{conn: conn, animal: animal} do
  #     conn = put(conn, Routes.usables_animal_path(conn, :update, animal), animal: @update_attrs)
  #     assert redirected_to(conn) == Routes.usables_animal_path(conn, :show, animal)

  #     conn = get(conn, Routes.usables_animal_path(conn, :show, animal))
  #     assert html_response(conn, 200) =~ "some updated name"
  #   end

  #   test "renders errors when data is invalid", %{conn: conn, animal: animal} do
  #     conn = put(conn, Routes.usables_animal_path(conn, :update, animal), animal: @invalid_attrs)
  #     assert html_response(conn, 200) =~ "Edit Animal"
  #   end
  # end

  # describe "delete animal" do
  #   setup [:create_animal]

  #   test "deletes chosen animal", %{conn: conn, animal: animal} do
  #     conn = delete(conn, Routes.usables_animal_path(conn, :delete, animal))
  #     assert redirected_to(conn) == Routes.usables_animal_path(conn, :index)
  #     assert_error_sent 404, fn ->
  #       get(conn, Routes.usables_animal_path(conn, :show, animal))
  #     end
  #   end
  # end

  # defp create_animal(_) do
  #   animal = fixture(:animal)
  #   {:ok, animal: animal}
  # end
end
