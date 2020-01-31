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

  def animals_header(animals) do
    names = Enum.map_join(animals, ", ", &(&1.name))
    ~E"""
    <h2 class="ui center aligned header">
      <%= names %>
    </h2>
    """
  end
  
end
