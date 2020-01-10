defmodule CritWeb.Fomantic.Elements do
  use Phoenix.HTML
  import Phoenix.Controller, only: [get_flash: 2]
  import CritWeb.ErrorHelpers, only: [error_tag: 2]

  def error_flash_above(conn) do
    if get_flash(conn, :error) do
      ~E"""
      <div class="ui negative attached message">
        <%= get_flash(conn, :error) %>
      </div>
      """
    end
  end

  def success_flash_above(conn) do
    if get_flash(conn, :info) do
      ~E"""
      <div class="ui positive attached message">
        <%= get_flash(conn, :info) %>
      </div>
      """
    end
  end

  def note_changeset_errors(changeset) do
    if changeset.action do
      ~E"""
      <div class="ui negative attached message">
        Please fix the errors shown below.
      </div>
      """
    end
  end

  def centered_image(src) do
    classes = "ui center aligned container main" 
    
    ~E"""
    <div class="<%=classes%>">
      <img src=<%=src%>>
    </div>
    """
  end


  def start_centered_form do
    ~E"""
    <div class="ui middle aligned center aligned grid">
      <div class="left aligned column">
    """
  end

  def end_centered_form do
    ~E"""
    </div>
    </div>
    """
  end


  def list_link(text, module, action) do
    ~E"""
    <div class="item">
      <%= link text, to: apply(module, :path, [action]) %>
    </div>
    """
  end

  def dashboard_card(header, items) do
    ~E"""
    <div class="card">
      <div class="content">
        <div class="header">
          <%= header %>
        </div>
        <div class="ui left aligned list">
          <%= items %>
        </div>
      </div>
    </div>
    """
  end


  def login_form_style do
    ~E"""
    <style type="text/css">
        body {
          background-color: #DADADA;
        }
        .column {
          max-width: 350px;
        }
    </style>
    """
  end

  def small_calendar(f, label, target, opts) do
    unique_in_this_form = Keyword.fetch!(opts, :unique)
    # Used with JQuery to control the calendar.
    calendar = unique_ref(target, "calendar", unique_in_this_form)
    # id and name of the text field that shows the date.
    date = unique_ref(target, "date", unique_in_this_form)
    
    ~E"""
      <div class="ui calendar" id="<%=calendar%>"
           data-controller="small-calendar"
           data-small-calendar-jquery-arg="#<%=calendar%>">

        <%= hidden_input f, target, data_target: "small-calendar.hidden" %>
        <div class="field">
          <%= label f, target, label %>
          <div class="ui input left icon">
            <i class="calendar icon"></i>
            <input type="text" name="<%=date%>" id="<%=date%>"
                   readonly="true"
                   required="true"
                   value=""
                   placeholder="Click for a calendar"
                   data-target="small-calendar.date"/>
            <%= error_tag f, target %>
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


  defp unique_ref(within_form_field, role, unique_form_id),
   do: "#{to_string(within_form_field)}_#{unique_form_id}_#{role}"
    
  

  def labeled_text_field(f, label, field, input_opts \\ []) do
    ~E"""
      <div class="field">
          <%= label f, field, label %>
          <%= text_input f, field, input_opts %>
          <%= error_tag f, field %>
      </div>
    """
  end

  def labeled_text_field_with_advice(f, label, field, advice, input_opts \\ []) do
    ~E"""
      <div class="field">
          <%= label f, field, label %>
          <%= advice %>
          <%= text_input f, field, input_opts %>
          <%= error_tag f, field %>
      </div>
    """
  end

  def labeled_textarea_with_advice(f, label, field, advice, input_opts \\ []) do
    ~E"""
      <div class="field">
          <%= label f, field, label %>
          <%= advice %>
          <%= textarea f, field, input_opts %>
          <%= error_tag f, field %>
      </div>
    """
  end

  def labeled_icon_field(f, label, field, icon, input_opts \\ []) do
    ~E"""
      <%= label f, field, label %>
      <div class="field">
          <div class="ui left icon input">
            <i class="<%=icon%>"></i>
            <%= text_input f, field, input_opts %>
          </div>
          <%= error_tag f, field %>
      </div>
    """
  end

  def labeled_checkbox(f, label, field, input_opts \\ []) do
    ~E"""
    <div class="field">
    <div class="ui checkbox">
        <%= checkbox(f, field, input_opts) %>
        <label><%=label%></label>
    </div>
    </div>
    """
  end

  def self_labeled_checkbox(f, field, input_opts \\ []) do
    labeled_checkbox(f, humanize(field), field, input_opts)
  end

  def big_submit_button(label) do
    submit label, class: "ui fluid large teal submit button"
  end

end
