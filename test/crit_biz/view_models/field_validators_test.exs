defmodule CritBiz.ViewModels.FieldValidatorsTest do
  use Ecto.Schema
  use Crit.DataCase
  alias CritBiz.ViewModels.FieldValidators
  alias Pile.TimeHelper
  import Ecto.Changeset

  embedded_schema do
    field :in_service_datestring, :string
    field :out_of_service_datestring, :string
    field :institution, :string
    field :names, :string
  end

  @timezone "America/Los_Angeles"

  defp date_order(input), do: FieldValidators.date_order(change(input))

  describe "cases where there's no upper bound are always valid" do
    test "a valid in-service date" do
      input = %__MODULE__{
        in_service_datestring: @iso_date_1,
        out_of_service_datestring: @never,
        institution: "--irrelevant--"
      }

      date_order(input)
      |> assert_valid
    end

    test "the special value `today`" do
      input = %__MODULE__{
        in_service_datestring: @today,
        out_of_service_datestring: @never,
        institution: "--irrelevant--"
      }

      date_order(input)
      |> assert_valid
    end
  end

  describe "cases using specific dates" do
    test "a valid specific in-service date" do
      input = %__MODULE__{
        in_service_datestring: @iso_date_1,
        out_of_service_datestring: @iso_date_2,
        institution: "--irrelevant--"
      }

      date_order(input)
      |> assert_valid
    end

    test "an invalid specific in-service date" do
      input = %__MODULE__{
        in_service_datestring: @iso_date_1,
        out_of_service_datestring: @iso_date_1,
        institution: "--irrelevant--"
      }

      date_order(input)
      |> assert_invalid
      |> assert_error(out_of_service_datestring: @date_misorder_message)
    end
  end    
    

  describe "cases using today with a specific end date" do
    test "a valid today" do
      input = %__MODULE__{
        in_service_datestring: @today,
        out_of_service_datestring: @iso_date_8,  # This date is way in the future.
        institution: @institution
      }

      date_order(input)
      |> assert_valid
    end

    test "an invalid today" do
      today_value = TimeHelper.today_date(@timezone)
      input = %__MODULE__{
        in_service_datestring: @today,
        out_of_service_datestring: today_value,
        institution: @institution
      }

      date_order(input)
      |> assert_invalid
      |> assert_error(out_of_service_datestring: @date_misorder_message)
    end
  end

  describe "namelists" do
    defp namelist(value), do: cast(%__MODULE__{}, %{names: value}, [:names])

    test "success case" do
      namelist("a, b")
      |> FieldValidators.namelist(:names)
      |> assert_valid
    end
    
    test "an empty string is invalid" do
      namelist("")
      |> FieldValidators.namelist(:names)
      |> assert_invalid
      |> assert_error(names: @no_valid_names_message)
    end

    test "not fooled by a bunch of blanks" do
      namelist("     \t   ")
      |> FieldValidators.namelist(:names)
      |> assert_invalid
      |> assert_error(names: @no_valid_names_message)
    end
    
    test "not fooled by comma-separated nothingness" do
      namelist("    , \t   ")
      |> FieldValidators.namelist(:names)
      |> assert_invalid
      |> assert_error(names: @no_valid_names_message)
    end
    
    test "does not like duplicate names" do
      namelist("a, b, a")
      |> FieldValidators.namelist(:names)
      |> assert_invalid
      |> assert_error(names: @duplicate_name)
    end
    
  end
end
