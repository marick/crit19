defmodule CritWeb.ViewModels.Setup.ServiceGapTest do
  use Crit.DataCase, async: true
  alias CritWeb.ViewModels.Setup, as: ViewModels
  alias Crit.Setup.Schemas
  alias Ecto.Datespan

  @id "any old id"
  @reason "some reason"

  def create(%Datespan{} = span) do
    %Schemas.ServiceGap{
      id: @id,
      animal_id: [:irrelevant],
      span: span,
      reason: @reason
    }
  end

  describe "to_web" do 
    test "common fields" do
      create(Datespan.customary(@date_2, @date_3))
      |> ViewModels.ServiceGap.to_web(@institution)
      |> assert_fields(id: @id,
                       reason: @reason,
                       institution: @institution,
                       delete: false)
    end

    test "datespan" do
       create(Datespan.customary(@date_2, @date_3))
       |> ViewModels.ServiceGap.to_web(@institution)
       |> assert_fields(in_service_datestring: @iso_date_2,
                        out_of_service_datestring: @iso_date_3)
    end
  end

  # ----------------------------------------------------------------------------

  describe "changesettery" do
    test "all values are valid" do
      params = %{"id" => "1",
                "in_service_datestring" => @iso_date_1,
                 "out_of_service_datestring" => @iso_date_2,
                 "reason" => "reason"}
      
      ViewModels.ServiceGap.form_changeset(params, @institution)
      |> assert_valid
      |> assert_changes(id: 1,
                        in_service_datestring: @iso_date_1,
                        out_of_service_datestring: @iso_date_2,
                        reason: "reason")
    end

    test "when given a list, empty changesets are filtered out" do
      list = [%{"id" => "",
                "in_service_datestring" => "",
                "out_of_service_datestring" => "",
                "reason" => ""},
              # these stay but they are error cases
              %{"id" => "1",
                "in_service_datestring" => "",
                "out_of_service_datestring" => @iso_date_2,
                "reason" => "reason"},              
              %{"id" => "2",
                "in_service_datestring" => @iso_date_1,
                "out_of_service_datestring" => "",
                "reason" => "reason"},
              %{"id" => "3",
                "in_service_datestring" => @iso_date_1,
                "out_of_service_datestring" => @iso_date_2,
                "reason" => ""}
             ]

      [one, two, three] = ViewModels.ServiceGap.form_changesets(list, @institution)
      assert_error(one, :in_service_datestring)
      assert_error(two, :out_of_service_datestring)
      assert_error(three, :reason)
    end

    # Error checking

    test "required fields are must be present" do
      ViewModels.ServiceGap.form_changeset(%{"id" => "1"}, @institution)
      |> assert_errors([:in_service_datestring, :out_of_service_datestring, :reason])
    end

    test "dates must be in the right order" do
      params = %{"id" => "1",
                 "in_service_datestring" => @iso_date_1,
                 "out_of_service_datestring" => @iso_date_1,
                 "reason" => "reason"}
      ViewModels.ServiceGap.form_changeset(params, @institution)
      |> assert_error(out_of_service_datestring: @date_misorder_message)

      # Other fields are available to fill form fields
      |> assert_changes(in_service_datestring: @iso_date_1,
                        out_of_service_datestring: @iso_date_1,
                        reason: "reason")
    end
  end

  describe "separating requests for deletion from requests for update" do
    no_deletion = %{"id" => "1",
                    "in_service_datestring" => @iso_date_1,
                    "out_of_service_datestring" => @iso_date_2,
                    "reason" => "reason",
                    "delete" => "false"
                   }
    deletion = %{"id" => "2",
                 "in_service_datestring" => @iso_date_1,
                 "out_of_service_datestring" => @iso_date_2,
                 "reason" => "different reason reason",
                 "delete" => "true"
                }

    assert {[only_changeset], [only_id]} = 
      [no_deletion, deletion]
      |> Enum.map(&(ViewModels.ServiceGap.form_changeset &1, @institution))
      |> ViewModels.ServiceGap.separate_deletions

    assert get_change(only_changeset, :id) == 1
    assert only_id == 2
  end

  # ----------------------------------------------------------------------------

  describe "update_params" do
    test "valid are converted" do
      params = %{"id" => 1,
                 "in_service_datestring" => @iso_date_1,
                 "out_of_service_datestring" => @iso_date_2,
                 "reason" => "reason"}

      expected = %{
        id: 1,
        reason: "reason",
        span: Datespan.customary(@date_1, @date_2)
      }

      actual =
        [ViewModels.ServiceGap.form_changeset(params, @institution)]
        |> ViewModels.ServiceGap.update_params
        |> singleton_payload

      assert actual == expected
    end
  end
end
