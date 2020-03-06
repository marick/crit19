defmodule CritWeb.Fomantic.Elements do
  use Phoenix.HTML
  import CritWeb.Fomantic.Helpers
  import CritWeb.Fomantic.Informative

  def centered_image(src) do
    classes = "ui center aligned container main" 
    
    ~E"""
    <div class="<%=classes%>">
      <img src=<%=src%>>
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

  def unordered(list) do
    ~E"""
    <ul>
    <%= for elt <- list do %>
      <li><%=elt%></li>
    <% end %>
    </ul>
    """
  end

  def big_submit_button(label) do
    submit label, class: "ui fluid large teal submit button"
  end

  @doc """
  This is a button that is *not* a Submit button (that is, it is
  not selected by Return/Enter, no matter where it is in the form). 
  It operates by calling a Javascript action
  """
  # The `type="button"` prevents it from becoming a `submit` button inside
  # a form.
  def negative_action_button(content, action) do
    ~E"""
      <button class="ui negative button"
              data-action="<%=action%>"
              type="button">
        <%= content %>
      </button>
    """
  end

  def dropdown(f, label, form_field, opts) do
    dropdown_id = Keyword.fetch!(opts, :dropdown_id)
    options = Keyword.fetch!(opts, :options)
    
    ~E"""
    <div class="field">
      <%= label f, form_field, label %>
      <%= select f, form_field, options, id: dropdown_id,
          class: "ui fluid dropdown" %>
    </div>
    """
  end
end
