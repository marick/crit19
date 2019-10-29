defmodule CritWeb.Usables.AnimalView do
  use CritWeb, :view
  alias Crit.Usables.AnimalApi
  alias CritWeb.Usables.AnimalController

  def animal_id_attribute(animal) do
    "editing_animal#{animal.id}"
  end

  def calendar_widget(f, opts) do
    special_defaults = [advice: ""]
    arg = Keyword.merge(special_defaults, opts) |> Enum.into(%{})
    
    field =
      labeled_text_field f, arg.tag, arg.label, %{
        wrapper_extras:
          [data_target: "calendar.wrapper"],
        advice: arg.advice,
        input_extras: [
          readonly: true,
          data_target: "calendar.input",
          data_action: "click->calendar#reveal",
          required: true
        ]
      }
  
    ~E"""
    <div data-controller="calendar" data-calendar-which="<%=arg.which%>"
       style="max-width: 540px">

    <%= field %>
    <div id="<%= arg.which %>" display="none"> </div>
    </div>
    """
  end
end
