defmodule CritWeb.Usables.AnimalView do
  use CritWeb, :view
  alias CritWeb.Usables.AnimalController
  alias Crit.Usables.Schemas.ServiceGap
  alias Phoenix.HTML.Form
  alias Ecto.Changeset

  def animal_form_id(animal) do
    "animal_#{animal.id}"
  end

  def animal_calendar_id(%Changeset{} = changeset, field),
    do: animal_calendar_id(changeset.data, field)

  def animal_calendar_id(animal, field),
    do: "calendar_for_animal_#{animal.id}_#{to_string field}"

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

  def bulk_creation_calendar(f, large_label, target, opts) do

    advice = Keyword.get(opts, :advice, "")
    radio_label = Keyword.fetch!(opts, :alternative)
    radio_value = String.downcase(radio_label)

    calendar = to_string(target) <> "_calendar"
    date = to_string(target) <> "_date"
    radio = to_string(target) <> "_radio"
    
    ~E"""
    <div data-controller="bulk-creation-calendar"
         data-bulk-creation-calendar-calendar-id="#<%=calendar%>"
         data-bulk-creation-calendar-radio-value="<%=radio_value%>"
         >

      <div class="field">
        <%= label f, target, large_label %>
        <%= advice %>
      </div>
      
      <%= hidden_input f, target,
            data_target: "bulk-creation-calendar.hidden" %>
    
      <div class="inline fields">
        <div class="field">
          <div class="ui calendar" id="<%=calendar%>">
            <div class="ui input left icon">
              <i class="calendar icon"></i>
              <input type="text" name="<%=date%>" id="<%=date%>"
                     readonly="true"
                     value=""
                     placeholder="Click for a calendar"
                     data-target="bulk-creation-calendar.date"/>
            </div>
          </div>
        </div>
        <div class="field">
          <div class="ui radio checkbox">
            <input type="radio" name="<%=radio%>" id="<%=radio%>"
                   checked="checked"
                   data-action="click->bulk-creation-calendar#propagate_from_radio_button",
                   data-target="bulk-creation-calendar.radio">
            <label for="<%=radio%>"><%=radio_label%></label>
          </div>
        </div>
      </div>
      <%= error_tag f, target %>
    </div>
    """
  end
end
