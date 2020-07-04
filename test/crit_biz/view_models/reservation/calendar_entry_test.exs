defmodule CritBiz.ViewModels.Reservation.CalendarEntryTest do
  use Crit.DataCase
  alias CritBiz.ViewModels.Reservation.CalendarEntry
  alias Crit.Reservations.ReservationApi
  alias Crit.Exemplars.ReservationFocused

  test "conversion" do
    reservation = ReservationFocused.reserved!(@bovine_id,
      ["jeff", "bossie"], ["procedure 1", "proc"],
      date: @date_1)
    
    [result] =
      ReservationApi.on_date(@date_1, @institution)
      |> Enum.map(&(CalendarEntry.to_map(&1, @institution)))
    
    result
    |> assert_fields(id: to_string(reservation.id),
                     calendarId: to_string(reservation.id),
                     start: reservation.span.first,
                     end: reservation.span.last,
                     category: "time",
                     isReadOnly: true)

    assert result.body =~ "bossie, jeff"
    assert result.body =~ "proc, procedure 1"
    assert result.body =~ "/reservation/#{reservation.id}"
  end
end
