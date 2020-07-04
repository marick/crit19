defmodule CritBiz.ViewModels.Reservation.CalendarEntry do
  use Ecto.Schema
  alias Crit.Reservations.Schemas.Reservation
  alias Crit.Reservations.ReservationApi
  alias CritWeb.Reservations.ReservationView

  def to_map(%Reservation{} = r, institution) do
    {animal_names, procedure_names} =
      ReservationApi.all_names(r.id, institution)
    %{
      id: to_string(r.id),
      calendarId: to_string(r.id),
      title: r.responsible_person,
      category: "time",
      start: r.span.first,
      end: r.span.last,
      isReadOnly: true,
      body: ReservationView.popup_body(r.id, animal_names, procedure_names)
    }
  end
end
