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

  def labeled_text_field(f, tag, label, opts \\ [])

  def labeled_text_field(f, tag, label_text, opts) when is_map(opts) do

    wrapper_attrs =
      opts |> Map.get(:wrapper_extras, []) |> Keyword.put_new(:class, "field")
    wrapper_start =
      tag :div, wrapper_attrs

    input_attrs =
      opts |> Map.get(:input_extras, []) |> Keyword.put_new(:class, "input")
    input = text_input f, tag, input_attrs

    label_elt = label f, tag, label_text, class: "label"
    error = error_tag f, tag

    advice = Map.get(opts, :advice, "")
    
    ~E"""
    <%= wrapper_start %>
      <%= label_elt %>
      <%= advice %>
      <div class="control">
         <%= input %>
         <%= error %>
      </div>
    </div>
    """
  end

  # Shorthand for the common case where you only want to decorate the text field.
  def labeled_text_field(f, tag, label_text, input_extras) when is_list(input_extras) do
    labeled_text_field(f, tag, label_text, %{input_extras: input_extras})
  end

  

  def labeled_select(f, tag, label, options, opts \\ []) do
    info = label f, tag, label, class: "label"
    dropdown = select f, tag, options, opts
    ~E"""
    <div class="field">
      <%= info %>
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



