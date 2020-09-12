defmodule CritWeb.Reservations.AfterTheFactView do
  use CritWeb, :view
  alias Pile.TimeHelper

  def context_header(showable_date, timeslot_name) do
    ~E"""
    <h2 class="ui center aligned header">
      Step 2: Choose animals for
      <%= showable_date %>, 
      <%= timeslot_name %>
    </h2>
    """
  end

  def animals_header(animals) do
    names = Conjunction.join(EnumX.names(animals), "and")
    ~E"""
    <h2 class="ui center aligned header">
      <%= names %>
    </h2>
    """
  end

  def describe_creation(conflicts) do
    if EnumX.all_empty?(Map.values(conflicts)) do
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
           <%= li_was_where(:rest_period, conflicts.rest_period) %>
        </ul>
      </div>
      """
    end
  end

  def li_was_where(_, []), do: []

  IO.puts("Better names than :service_gap and :use")
  
  def li_was_where(:service_gap, animal_list) do
    was_where(animal_list, "supposed to be out of service on the reservation date.")
    |> li
  end

  def li_was_where(:use, animal_list) do
    was_where(animal_list, "already reserved at the same time.")
    |> li
  end

  def li_was_where(:rest_period, conflict_list) do
    one = fn %{animal_name: a, procedure_name: p, dates: dates} ->
      datestring =
        dates 
        |> Enum.map(&TimeHelper.date_string_without_year/1)
        |> Conjunction.join
      li "This use of #{a} for #{p} is too close to #{datestring}."
    end
    
    Enum.map(conflict_list, one)
  end

  def was_where(animal_list, suffix) do
    was_where =
      case length(animal_list) do
        1 -> "was"
        _ -> "were"
      end

    "#{Conjunction.join(EnumX.names(animal_list))} #{was_where} #{suffix}"
  end
end
