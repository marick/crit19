defmodule CritWeb.Bulma.Elements do
  use Phoenix.HTML
  import CritWeb.ErrorHelpers

  def compact_checkbox(form, field, opts \\ []) do
    content_tag(:div, 
      [ checkbox(form, field, opts),
        raw("&nbsp;"),
        humanize(field),
      ])
  end

  def form_button(text) do
   ~E"""
   <div class="field">
     <div class="control">
       <%= submit "#{text}", class: "button is-success" %>
     </div>
   </div>
   """
  end

  def labeled_text_field(f, tag, label, text_input_extras \\ []) do
    wrapper = label f, tag, label, class: "label"
    error = error_tag f, tag
    input = text_input f, tag, Keyword.put_new(text_input_extras, :class, "input")
    
    ~E"""
    <div class="field">
      <%= wrapper %>
      <div class="control">
         <%= input %>
         <%= error %>
      </div>
    </div>
    """
  end

  def labeled_select(f, tag, label, options, opts \\ []) do
    wrapper = label f, tag, label, class: "label"
    dropdown = select f, tag, options, opts
    ~E"""
    <div class="field">
      <%= wrapper %>
      <div class="control">
         <div class="select">
           <%= dropdown %>
         </div>
      </div>
    </div>
    """
  end

  def unlabelled(control) do
    ~E"""
    <div class="field">
      <div class="control">
         <%= control %>
      </div>
    </div>
    """
  end


  def start_centered_form do
    ~E"""
    <div class="container">
    <div class="columns is-centered">
    <div class="column is-5-tablet is-5-desktop is-5-widescreen">
    """
  end

  def end_centered_form do
    ~E"""
    </div>
    </div>
    </div>
    """
  end

  def note_existence_of_any_form_errors(changeset) do
    if changeset.action do
      ~E"""
      <div class="has-text-danger has-text-weight-bold has-text-centered">
        Please fix the errors shown below.
      </div>
      """
    end
  end

    
end



