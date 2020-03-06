defmodule CritWeb.Fomantic.Calendars do
  use Phoenix.HTML
  import CritWeb.Fomantic.Helpers
  import CritWeb.Fomantic.Informative

  def small_calendar(f, label, target, opts) do
    unique_in_this_form = Keyword.fetch!(opts, :unique)
    # Used with JQuery to control the calendar.
    calendar = unique_ref(target, "calendar", unique_in_this_form)
    # id and name of the text field that shows the date.
    date = unique_ref(target, "date", unique_in_this_form)
    
    ~E"""
      <div data-controller="small-calendar"
           data-small-calendar-jquery-arg="#<%=calendar%>">
        <%= hidden_input f, target, data_target: "small-calendar.hidden" %>
        
        <div class="ui calendar" id="<%=calendar%>">
          <div class="field">
            <%= label f, target, label %>
            <div class="ui input left icon">
              <i class="calendar icon"></i>
              <%= text_input f, String.to_atom(date), 
                     readonly: true,
                     required: true,
                     value: "",
                     placeholder: "Click for a calendar",
                     data_target: "small-calendar.date" %>
              <%= error_tag f, target %>
            </div>
          </div>
        </div>
      </div>
    """
  end

  def calendar_with_alternatives(f, large_label, target, opts) do
    advice = Keyword.get(opts, :advice, "")
    radio_label = Keyword.fetch!(opts, :alternative)
    radio_value = String.downcase(radio_label)
    unique_in_this_form = Keyword.get(opts, :unique, "")

    # Used with JQuery to control the calendar.
    calendar = unique_ref(target, "calendar", unique_in_this_form)
    # id and name of the text field that shows the date.
    date = unique_ref(target, "date", unique_in_this_form)
    # id and name of the radio button
    radio = unique_ref(target, "radio", unique_in_this_form)
    
    ~E"""
    <div data-controller="calendar-with-alternatives"
         data-calendar-with-alternatives-jquery-arg="#<%=calendar%>"
         data-calendar-with-alternatives-radio-value="<%=radio_value%>"
         >

      <div class="field">
        <%= label f, target, large_label %>
        <%= advice %>
      </div>
      
      <%= hidden_input f, target,
            data_target: "calendar-with-alternatives.hidden" %>
    
      <div class="inline fields">
        <div class="field">
          <div class="ui calendar" id="<%=calendar%>">
            <div class="ui input left icon">
              <i class="calendar icon"></i>
              <input type="text" name="<%=date%>" id="<%=date%>"
                     readonly="true"
                     value=""
                     placeholder="Click for a calendar"
                     data-target="calendar-with-alternatives.date"/>
            </div>
          </div>
        </div>
        <div class="field">
          <div class="ui radio checkbox">
            <input type="radio" name="<%=radio%>" id="<%=radio%>"
                   checked="checked"
                   data-action="click->calendar-with-alternatives#propagate_from_radio_button"
                   data-target="calendar-with-alternatives.radio"/>
            <label for="<%=radio%>"><%=radio_label%></label>
          </div>
        </div>
      </div>
      <%= error_tag f, target %>
    </div>
    """
  end

  
end
