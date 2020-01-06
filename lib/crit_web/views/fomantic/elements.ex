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


  def start_centered_form__2 do
    ~E"""
    <div class="ui middle aligned center aligned grid">
      <div class="left aligned column">
    """
  end

  def end_centered_form__2 do
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

  def small_calendar(f, label, field, input_opts \\ []) do
    ~E"""
      <div class="field">
          <%= label f, field, label %>
          <%= text_input f, field, input_opts %>
          <%= error_tag f, field %>
      </div>
    """
  end

  def small_calendar__2(f, label, field, input_opts \\ []) do
    opts = Enum.into(input_opts, %{})
    ~E"""
      <div class="field" id="<%=opts.id%>">
          <%= label f, field, label %>
          <%= text_input f, field %>
          <%= error_tag f, field %>
      </div>
    """
  end

  def labeled_field(f, label, field, input_opts \\ []) do
    ~E"""
      <div class="field">
          <%= label f, field, label %>
          <%= text_input f, field, input_opts %>
          <%= error_tag f, field %>
      </div>
    """
  end

  def labeled_field_with_advice(f, label, field, advice, input_opts \\ []) do
    ~E"""
      <div class="field">
          <%= label f, field, label %>
          <%= advice %>
          <%= text_input f, field, input_opts %>
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
