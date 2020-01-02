defmodule CritWeb.Usables.AnimalView do
  use CritWeb, :view
  alias Crit.Usables.AnimalApi
  alias CritWeb.Usables.AnimalController
  alias Crit.Usables.Schemas.ServiceGap
  alias Phoenix.HTML.Form
  alias Ecto.Changeset

  def animal_id_attribute(animal) do
    "editing_animal#{animal.id}"
  end

  def big_calendar_widget(f, opts) do
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
    <div data-controller="calendar"
       style="max-width: 540px">

    <%= field %>
    <div data-target="calendar.div" display="none"> </div>
    </div>
    """
  end


  def small_calendar_widget(f, label, tag) do
    ~E"""
    <div data-controller="calendar">
       <div data-target="calendar.wrapper">
         <%= label %>
         <%= text_input(f, tag,
                        data_target: "calendar.input",
                        data_action: "click->calendar#reveal") %>
         <div><%= error_tag(f, tag) %></div>
       </div>
       <div data-target="calendar.div" display="none"> </div>
    </div>
    """
  end


  def delete_if_exists(f) do
    if Form.input_value(f, :id) do
      labeled_checkbox f, "Delete", :delete
    end
  end

end
