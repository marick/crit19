defmodule CritWeb.Reservations.ReservationController.AfterTheFactFormTest do
  use Crit.DataCase, async: true
  alias CritWeb.Reservations.AfterTheFactForm

  describe "form_1_changeset" do
    test "success" do
      params = %{species_id: to_string(@bovine_id),
                 date: "2019-01-01",
                 date_showable_date: "January 1, 2019",
                 part_of_day_id: "1",
                 institution: @institution}

      AfterTheFactForm.form_1_changeset(params)
      |> assert_changes(
           species_id: @bovine_id,
           species_name: @bovine,
           date: ~D[2019-01-01],
           date_showable_date: "January 1, 2019"
         )
    end
  end
end
