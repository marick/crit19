defmodule CritWeb.Fomantic.Labeled do
  use Phoenix.HTML
  import CritWeb.Fomantic.Helpers
  import CritWeb.Fomantic.Informative

  def labeled_text_field(f, label, field, input_opts \\ []) do
    ~E"""
      <div class="field">
          <%= label f, field, label %>
          <%= text_input f, field, input_opts %>
          <%= error_tag f, field %>
      </div>
    """
  end

  def labeled_number_field(f, label, field, input_opts \\ []) do
    ~E"""
      <div class="field">
          <%= label f, field, label %>
          <%= number_input f, field, input_opts %>
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

  def self_labeled_checkbox(f, field, opts \\ []) do
    labeled_checkbox(f, humanize(field), field, opts)
  end
  
end
