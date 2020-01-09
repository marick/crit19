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


  def unique_snippet(%Changeset{} = changeset), do: unique_snippet(changeset.data)
  def unique_snippet(%{id: id}), do: "_#{id}"

  def delete_if_exists(f) do
    if Form.input_value(f, :id) do
      labeled_checkbox f, "Delete", :delete
    end
  end

  def bulk_creation_calendar(f, large_label, target, opts) do
    advice = Keyword.get(opts, :advice, "")
    radio_label = Keyword.fetch!(opts, :alternative)
    radio_value = String.downcase(radio_label)
    unique=Keyword.get(opts, :unique, "")

    # Used with JQuery to control the calendar.
    calendar = to_string(target) <> "_calendar_" <> unique

    # id and name of the text field that shows the date.
    date = to_string(target) <> "_date" <> unique
    # id and name of the radio button
    radio = to_string(target) <> "_radio" <> unique
    
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
                   data-action="click->bulk-creation-calendar#propagate_from_radio_button"
                   data-target="bulk-creation-calendar.radio"/>
            <label for="<%=radio%>"><%=radio_label%></label>
          </div>
        </div>
      </div>
      <%= error_tag f, target %>
    </div>
    """
  end
end
