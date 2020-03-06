defmodule CritWeb.Fomantic.MapProducing do
  use Phoenix.HTML
  import CritWeb.Fomantic.Helpers

  def indexed_text_input(form, field_label, index) do
    id = input_id(form, field_label, index)
    name = "#{input_name(form, to_string(index))}[#{field_label}]"
    text_input(form, :_ignore_, id: id, name: name)
  end

  def indexed_multiple_checkbox_row(form, [{_,_}|_]=tuples, field_label, index) do
    id = input_id(form, field_label, index) |> IO.inspect
    name = "#{input_name(form, to_string(index))}[#{field_label}][]"
    ~E"""
    <div class="field">
      <%= for tuple <- tuples, do: one_checkbox(form, tuple, id, name) %>
     </div>
    """
  end

  defp one_checkbox(f, {label_value, sent_value}, id, name) do 
    checkbox_tag = tag(:input,
      name: name,
      id: id,
      type: "checkbox",
      value: sent_value)

    label_tag = content_tag(:label, label_value, for: id)
    
    ~E"""
    <div class="ui checkbox">
      <%= checkbox_tag %>
      <%= label_tag %>
    </div>
    """
  end
end
