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
                 "institution" => @institution,
                 "reason" => "reason"}
      
      ViewModels.ServiceGap.form_changeset(params)
      |> assert_valid
      |> assert_changes(id: 1,
                        in_service_datestring: @iso_date_1,
                        out_of_service_datestring: @iso_date_2,
                        reason: "reason")
    end

    # Error checking

    test "required fields are must be present" do
      ViewModels.ServiceGap.form_changeset(%{"id" => "1"})
      |> assert_errors([:in_service_datestring, :out_of_service_datestring, :reason])
    end

    test "dates must be in the right order" do
      params = %{"id" => "1",
                 "in_service_datestring" => @iso_date_1,
                 "out_of_service_datestring" => @iso_date_1,
                 "institution" => @institution,
                 "reason" => "reason"}
      ViewModels.ServiceGap.form_changeset(params)
      |> assert_error(out_of_service_datestring: @date_misorder_message)

      # Other fields are available to fill form fields
      |> assert_changes(in_service_datestring: @iso_date_1,
                        out_of_service_datestring: @iso_date_1,
                        reason: "reason")
    end
  end

  # ----------------------------------------------------------------------------

  describe "from_web" do
    test "valid are converted" do
      view_model = %{id: 1,
                     in_service_datestring: @iso_date_1,
                     out_of_service_datestring: @iso_date_2,
                     institution: @institution,
                     reason: "reason"}

      expected = %Schemas.ServiceGap{
        id: 1,
        animal_id: "some animal id",
        reason: "reason",
        span: Datespan.customary(@date_1, @date_2)
      }

      actual =
        [ViewModels.ServiceGap.form_changeset(view_model)]
        |> ViewModels.ServiceGap.from_web("some animal id")
        |> singleton_payload
        |> assert_shape(%Schemas.ServiceGap{})

      assert actual == expected
    end
  end
end
