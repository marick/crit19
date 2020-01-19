defmodule CritWeb.Setup.AnimalController.ReadTest do
  use CritWeb.ConnCase
  alias CritWeb.Setup.AnimalController, as: UnderTest
  use CritWeb.ConnMacros, controller: UnderTest

  setup :logged_in_as_setup_manager

  test "fetching a set of animals", %{conn: conn} do
    name1 = "Bossie"
    name2 = "Hank"
    Factory.sql_insert!(:animal, [name: name1], @institution)
    Factory.sql_insert!(:animal, [name: name2], @institution)
    
    get_via_action(conn, :index)
    |> assert_purpose(displaying_animal_summaries())
    |> assert_user_sees(name1)
    |> assert_user_sees(name2)
  end

  test "fetching a partial of animals", %{conn: conn} do
    animal = Factory.sql_insert!(:animal, @institution)
    
    get_via_action(conn, :_show, to_string(animal.id))
    |> assert_purpose(snippet_to_display_animal())
    |> assert_user_sees(animal.name)
  end
end
