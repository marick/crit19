defmodule Crit.Usables.Write.DateComputersTest do
  use Ecto.Schema
  use Crit.DataCase
  alias Crit.Usables.Write.DateComputers
  alias Pile.TimeHelper
  alias Ecto.Changeset

  embedded_schema do
    field :start_date, :string
    field :end_date, :string
    field :timezone, :string

    field :computed_start_date, :date, virtual: true
    field :computed_end_date, :date, virtual: true
    field :computed_names, {:array, :string}, virtual: true
  end
  

  @iso_date "2001-09-05"
  @date Date.from_iso8601!(@iso_date)

  @later_iso_date "2200-09-05"
  @later_date Date.from_iso8601!(@later_iso_date)

  def so_far(opts \\ []) do
    default = %{timezone: "America/Chicago"}
    Changeset.change(%__MODULE__{}, Enum.into(opts, default))
  end
  
  test "explicit dates" do
      changeset = 
        so_far(start_date: @iso_date, end_date: @later_iso_date)
        |> DateComputers.start_and_end

      assert changeset.valid?
      assert changeset.changes.computed_start_date == @date
      assert changeset.changes.computed_end_date == @later_date
  end

  test "starting date is today" do
    changeset = 
      so_far(start_date: "today", end_date: @later_iso_date)
      |> DateComputers.start_and_end


    today = TimeHelper.today_date(changeset.changes.timezone)
    
    # Yes, this test will fail if it runs across a date boundary. So sue me.
    assert changeset.valid?
    assert changeset.changes.computed_start_date == today
    assert changeset.changes.computed_end_date == @later_date
  end

  test "ending day is 'never', which marks the end date specially" do
    changeset = 
      so_far(start_date: @iso_date, end_date: "never")
      |> DateComputers.start_and_end

    assert changeset.valid?
    assert changeset.changes.computed_start_date == @date
    assert changeset.changes.computed_end_date == :missing
  end

  test "are in the wrong order" do
    errors = 
      so_far(start_date: @later_iso_date, end_date: @iso_date)
      |> DateComputers.start_and_end
      |> errors_on

    assert errors.end_date == [DateComputers.misorder_error_message]
  end

  test "for completeness, a supposedly impossible ill-formed date" do
    errors = 
      so_far(start_date: "todays", end_date: "Nev")
      |> DateComputers.start_and_end
      |> errors_on
    
      assert errors.start_date == [DateComputers.parse_error_message]
      assert errors.end_date == [DateComputers.parse_error_message]
    end
  
end  
