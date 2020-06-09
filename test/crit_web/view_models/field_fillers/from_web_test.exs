defmodule CritWeb.ViewModels.FieldFillers.FromWebTest do
  use Ecto.Schema
  use Crit.DataCase
  alias CritWeb.ViewModels.FieldFillers.FromWeb
  alias Pile.TimeHelper
  alias Ecto.Datespan
  alias Crit.Setup.InstitutionApi

  # Assumes this partial schema. 
  # Various constants are reasonably stable, given the domain.
  
  embedded_schema do
    field :in_service_datestring, :string
    field :out_of_service_datestring, :string
    field :institution, :string
  end

  @timezone "America/Los_Angeles"

  describe "cases where there's no upper bound" do
    @tag :skip
    test "a valid in-service date" do
      input = %__MODULE__{
        in_service_datestring: @iso_date_1,
        out_of_service_datestring: @never,
        institution: "--irrelevant--"
      }

      actual = FromWeb.span(input)
      expected = Datespan.inclusive_up(@date_1)

      assert actual == expected
    end

    @tag :skip
    test "the special value `today`" do
      # Make sure that timezone is as expected
      assert InstitutionApi.timezone(@institution) == @timezone
      
      input = %__MODULE__{
        in_service_datestring: @today,
        out_of_service_datestring: @never,
        institution: @institution
      }

      actual = FromWeb.span(input)
      expected = Datespan.inclusive_up(TimeHelper.today_date(@timezone))

      assert actual == expected
    end
  end

  describe "cases where there is an upper bound" do
    test "a valid in-service date" do
      input = %__MODULE__{
        in_service_datestring: @iso_date_1,
        out_of_service_datestring: @iso_date_2,
        institution: "--irrelevant--"
      }

      actual = FromWeb.span(input)
      expected = Datespan.customary(@date_1, @date_2)

      assert actual == expected
      
    end

    @tag :skip
    test "the special value `today`" do
      # Make sure that timezone is as expected
      assert InstitutionApi.timezone(@institution) == @timezone
      
      input = %__MODULE__{
        in_service_datestring: @today,
        out_of_service_datestring: @iso_date_2,
        institution: @institution
      }

      actual = FromWeb.span(input)
      expected = Datespan.customary(TimeHelper.today_date(@timezone), @date_2)

      assert actual == expected
    end
  end
end
