defmodule CritWeb.Reservations.AfterTheFactView do
  use CritWeb, :view

  def non_use_values_header(showable_date, timeslot_name) do
    ~E"""
    <h2 class="ui center aligned header">
      Step 2: Choose animals for
      <%= showable_date %>, 
      <%= timeslot_name %>
    </h2>
    """
  end

  defp names(animals), do: Enum.map(animals, &(&1.name))  

  def animals_header(animals) do
    names = Conjunction.join(names(animals), "and")
    ~E"""
    <h2 class="ui center aligned header">
      <%= names %>
    </h2>
    """
  end

  def describe_creation(conflicts) do
    if Enum.all?(Map.values(conflicts), &Enum.empty?/1) do
      ~E"""
      <div class="ui positive attached message"> 
        The reservation was created.
      </div>
      """
    else
      ~E"""
      <div class="ui warning attached message"> 
        The reservation was created despite these oddities:
        <ul> 
           <%= li_was_where(:service_gap, conflicts.service_gap) %>
           <%= li_was_where(:use, conflicts.use) %>
        </ul>
      </div>
      """
    end
  end

  def li_was_where(_, []), do: []

  def li_was_where(:service_gap, animal_list) do
    was_where(animal_list, "supposed to be out of service on the reservation date.")
    |> li
  end

  def li_was_where(:use, animal_list) do
    was_where(animal_list, "already reserved at the same time.")
    |> li
  end

  def was_where(animal_list, suffix) do
    was_where =
      case length(animal_list) do
        1 -> "was"
        2 -> "were"
      end

    "#{Conjunction.join(names(animal_list))} #{was_where} #{suffix}"
  end
end
