defmodule CritWeb.Reservations.ReservationView do
  use CritWeb, :view
  import Pile.TimeHelper
  

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

end
