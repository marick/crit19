defmodule Integration.Setup.ProcedureCreationTest do
  use CritWeb.IntegrationCase
  alias CritWeb.Setup.ProcedureController, as: UnderTest
  use CritWeb.ConnMacros, controller: UnderTest
  alias Crit.Schemas

  setup :logged_in_as_setup_manager

  test "procedure creation workflow",
    %{conn: conn} do 
    # ----------------------------------------------------------------------------
    get_via_action(conn, :bulk_creation_form)              
    # ----------------------------------------------------------------------------
    |> follow_form(%{procedures:
                    %{0 => %{name: "procedure #1",
                             species_ids: [@bovine_id],
                             frequency_id: @once_per_week_frequency_id},
                      1 => %{name: "procedure #2",
                             species_ids: [@bovine_id, @equine_id]}
                             # default frequency
                            }})
    # ----------------------------------------------------------------------------
    |> assert_purpose(displaying_procedure_summaries())

    assert [p1, p2] = Schemas.Procedure.Get.all_by_species(@bovine_id, @institution)
    assert_fields(p1,
      name: "procedure #1",
      frequency_id: @once_per_week_frequency_id
    )
    assert_fields(p2,
      name: "procedure #2",
      frequency_id: @unlimited_frequency_id
    )

    assert [ep2] = Schemas.Procedure.Get.all_by_species(@equine_id, @institution)
    assert_fields(ep2,
      name: "procedure #2",
      frequency_id: @unlimited_frequency_id
    )
  end
end
