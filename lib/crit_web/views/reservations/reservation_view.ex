defmodule CritWeb.Reservations.ReservationView do
  use CritWeb, :view
  import Pile.TimeHelper
  alias CritWeb.Reservations.ReservationController
  alias CritBiz.ViewModels.Reservation.CalendarEntry
  alias Pile.Extras.IntegerX
  

  def date_or_dates_header(first_date, last_date) do
    header =
      if Date.compare(first_date, last_date) == :eq do
        "Reservations on #{date_string(first_date)}"
      else
        "Reservations from #{date_string(first_date)} through #{date_string(last_date)}"
      end
    ~E"""
    <h2 class="ui header"><%=header%></h2>
    """
  end

  def count_header(count) do
    "#{IntegerX.to_words(count)} #{Inflex.inflect("reservation", count)}"
    |> Recase.to_title
  end

  def popup_body(reservation_id, animal_names, procedure_names) do
    link =
      Phoenix.HTML.Link.link(
        "Click to edit or delete",
        to: ReservationController.path(:show, reservation_id))

    
    ~E"""
    <%= Enum.join(animal_names, ", ") %><br/>
    <%= Enum.join(procedure_names, ", ") %>
    <p> <%= link %></p>
    """ |> Phoenix.HTML.safe_to_string
  end

  def render("week.json", %{reservations: reservations,
                            institution: institution}) do
    one = fn reservation ->
      CalendarEntry.to_map(reservation, institution)
    end
    %{data: Enum.map(reservations, one)}
  end
end
