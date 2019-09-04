defmodule CritWeb.Usables.AnimalControllerTest do
  use CritWeb.ConnCase
  alias CritWeb.Usables.AnimalController, as: UnderTest
  use CritWeb.ConnMacros, controller: UnderTest
  alias Crit.Usables

  setup :logged_in_as_usables_manager

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

  describe "new animal" do
    test "renders form", %{conn: conn} do
      conn
      |> get_via_action(:new)
      |> assert_purpose(form_for_creating_new_animal())
    end
  end

  describe "create animal" do
    setup do
      [act: fn conn, params ->
        post_to_action(conn, :create, under(:animal, params))
      end]
    end
    
    test "redirects to :new when data is valid", %{conn: conn, act: act} do
      conn = act.(conn, Factory.string_params_for(:animal))
      
      assert redirected_to(conn) == Routes.usables_animal_path(conn, :new)
    end

      

    # test "renders errors when data is invalid", %{conn: conn} do
    #   conn = post(conn, Routes.usables_animal_path(conn, :create), animal: @invalid_attrs)
    #   assert html_response(conn, 200) =~ "New Animal"
    # end
  end

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

  def redirected_to_new_animal_form?(conn),
    do: redirected_to(conn) == UnderTest.path(:new)
end
