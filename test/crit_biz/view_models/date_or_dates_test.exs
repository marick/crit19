defmodule CritBiz.ViewModels.DateOrDatesTest do
  use Crit.DataCase
  alias CritBiz.ViewModels.DateOrDates
  alias Crit.Servers.Institution
  alias Ecto.Changeset

  @end_date_same_as_first "just one day"

  test "starting values" do
    start = DateOrDates.starting_changeset
    assert Changeset.get_field(start, :first_datestring) == @today
    assert Changeset.get_field(start, :last_datestring) == @end_date_same_as_first
  end

  describe "creating a structure from two dates" do
    defp today, do: Institution.today!(@institution)
    
    test "two real dates" do
      input = %{"first_datestring" => @iso_date_1,
                "last_datestring" => @iso_date_2}
      actual = DateOrDates.to_dates(input, @institution)
      assert actual == {:ok, @date_1, @date_2}
    end

    test "today and a real date" do
      input = %{"first_datestring" => @today,
                "last_datestring" => @iso_date_2}
      actual = DateOrDates.to_dates(input, @institution)
      assert actual == {:ok, today(), @date_2}
    end
    
    test "a real date and no separate ending date" do
      input = %{"first_datestring" => @iso_date_1,
                "last_datestring" => @end_date_same_as_first}
      actual = DateOrDates.to_dates(input, @institution)
      assert actual == {:ok, @date_1, @date_1}
    end
    
    test "today and no separate ending date" do
      input = %{"first_datestring" => @today,
                "last_datestring" => @end_date_same_as_first}
      actual = DateOrDates.to_dates(input, @institution)
      assert actual == {:ok, today(), today()}
    end
  end
end
