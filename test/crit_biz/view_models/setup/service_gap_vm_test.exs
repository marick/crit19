defmodule CritBiz.ViewModels.Setup.ServiceGapTest do
  use Crit.DataCase, async: true
  alias CritBiz.ViewModels.Setup, as: VM
  alias Crit.Schemas
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
      |> VM.ServiceGap.lift(@institution)
      |> assert_fields(id: @id,
                       reason: @reason,
                       institution: @institution,
                       delete: false)
    end

    test "datespan" do
       create(Datespan.customary(@date_2, @date_3))
       |> VM.ServiceGap.lift(@institution)
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
      
      VM.ServiceGap.accept_form(params, @institution)
      |> assert_valid
      |> assert_changes(id: 1,
                        in_service_datestring: @iso_date_1,
                        out_of_service_datestring: @iso_date_2,
                        reason: "reason")
      |> refute_form_will_display_errors
    end

    test "an empty service gap is OK" do
      params = %{
        "in_service_datestring" =>     "",
        "out_of_service_datestring" => "",
        "reason" => "        "  # Note this will be shown as a change
      }
      VM.ServiceGap.accept_form(params, @institution)
      |> assert_data(reason: "",
                     in_service_datestring: "",
                     out_of_service_datestring: "")
      |> assert_change(reason: "        ")
      |> refute_form_will_display_errors
    end

    # Error checking

    test "dates must be in the right order" do
      params = %{"id" => "1",
                 "in_service_datestring" => @iso_date_1,
                 "out_of_service_datestring" => @iso_date_1,
                 "reason" => "reason"}
      VM.ServiceGap.accept_form(params, @institution)
      |> assert_error(out_of_service_datestring: @date_misorder_message)
      |> assert_form_will_display_errors

      # Other fields are available to fill form fields
      |> assert_changes(in_service_datestring: @iso_date_1,
                        out_of_service_datestring: @iso_date_1,
                        reason: "reason")
    end
  end

  describe "empty forms and their results can be detected" do
    test "empty params can be detected" do
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
      
      actual = Enum.map(list, &VM.ServiceGap.from_empty_form?/1)
    
      assert [true, false, false, false] == actual
    end
    
    test "empty service gaps can be detected" do
      list = [%VM.ServiceGap{
                 in_service_datestring: "",
                 out_of_service_datestring: "",
                 reason: ""},
              # these stay but they are error cases
              %VM.ServiceGap{id: 1,
                in_service_datestring: "",
                out_of_service_datestring: @iso_date_2,
                reason: "reason"},              
              %VM.ServiceGap{id: 2,
                in_service_datestring: @iso_date_1,
                out_of_service_datestring: "",
                reason: "reason"},
              %VM.ServiceGap{id: 3,
                in_service_datestring: @iso_date_1,
                out_of_service_datestring: @iso_date_2,
                reason: ""}
             ]
      
      actual = Enum.map(list, &VM.ServiceGap.from_empty_form?/1)
    
      assert [true, false, false, false] == actual
    end
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
        [VM.ServiceGap.accept_form(params, @institution)]
        |> VM.ServiceGap.lower_to_attrs
        |> singleton_payload

      assert actual == expected
    end

    test "empty insertions are not included" do
      params = %{"in_service_datestring" => "",
                 "out_of_service_datestring" => "",
                 "reason" => ""}

      actual =
        [VM.ServiceGap.unchecked_empty_changeset(params)]
        |> VM.ServiceGap.lower_to_attrs

      assert actual == []
    end
  end
end
