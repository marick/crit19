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

  describe "lift" do 
    test "common fields" do
      create(Datespan.customary(@date_2, @date_3))
      |> ViewModels.ServiceGap.lift(@institution)
      |> assert_fields(id: @id,
                       reason: @reason,
                       institution: @institution,
                       delete: false)
    end

    test "datespan" do
       create(Datespan.customary(@date_2, @date_3))
       |> ViewModels.ServiceGap.lift(@institution)
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
      
      ViewModels.ServiceGap.accept_form(params, @institution)
      |> assert_valid
      |> assert_changes(id: 1,
                        in_service_datestring: @iso_date_1,
                        out_of_service_datestring: @iso_date_2,
                        reason: "reason")
    end

    test "an empty service gap is OK" do
      params = %{
        "in_service_datestring" =>     "",
        "out_of_service_datestring" => "",
        "reason" => "        "  # Note this will be shown as a change
      }
      ViewModels.ServiceGap.accept_form(params, @institution)
      |> assert_data(reason: "",
                     in_service_datestring: "",
                     out_of_service_datestring: "")
      |> assert_change(reason: "        ")
    end

    # Error checking

    test "dates must be in the right order" do
      params = %{"id" => "1",
                 "in_service_datestring" => @iso_date_1,
                 "out_of_service_datestring" => @iso_date_1,
                 "reason" => "reason"}
      ViewModels.ServiceGap.accept_form(params, @institution)
      |> assert_error(out_of_service_datestring: @date_misorder_message)

      # Other fields are available to fill form fields
      |> assert_changes(in_service_datestring: @iso_date_1,
                        out_of_service_datestring: @iso_date_1,
                        reason: "reason")
    end
  end

  test "empty changesets can be detected" do
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

    actual = Enum.map(list, &ViewModels.ServiceGap.from_empty_form?/1)
    
    assert [true, false, false, false] == actual
  end

  # ----------------------------------------------------------------------------
  
  describe "lower_to_attrs" do
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
        [ViewModels.ServiceGap.accept_form(params, @institution)]
        |> ViewModels.ServiceGap.lower_to_attrs
        |> singleton_payload

      assert actual == expected
    end
  end
end
