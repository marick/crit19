defmodule CritWeb.Fomantic.Helpers do
  use Phoenix.HTML

  def input_list_name(f, field), do: input_name(f, field) <> "[]"

  def unique_ref(within_form_field, role, unique_form_id),
   do: "#{to_string(within_form_field)}_#{unique_form_id}_#{role}"
end
