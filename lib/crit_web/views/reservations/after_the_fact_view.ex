defmodule CritWeb.Reservations.AfterTheFactView do
  use CritWeb, :view

  def species_and_time_header(showable_date, time_slot_name) do
    ~E"""
    <h2 class="ui center aligned header">
      Step 2: Choose animals for
      <%= showable_date %>, 
      <%= time_slot_name %>
    </h2>
    """
  end
end
