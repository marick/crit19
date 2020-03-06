defmodule CritWeb.Fomantic.Helpers do
  use Phoenix.HTML
  alias Ecto.Changeset

  def input_list_name(f, field), do: input_name(f, field) <> "[]"

  def unique_ref(within_form_field, role, unique_form_id),
    do: "#{to_string(within_form_field)}_#{unique_form_id}_#{role}"

  def unique_snippet(%Phoenix.HTML.Form{} = form), do: unique_snippet(form.data)
  def unique_snippet(%Changeset{} = changeset), do: unique_snippet(changeset.data)
  def unique_snippet(%{id: nil}), do: "_and_new"
  def unique_snippet(%{id: id}), do: "_#{id}"

  def unique_snippet(id_holder1, id_holder_2),
    do: unique_snippet(id_holder1) <> unique_snippet(id_holder_2)

  def accordion_div_id(%Changeset{} = changeset),
    do: accordion_div_id(changeset.data)
  def accordion_div_id(id_holder), 
    do: "accordion" <> unique_snippet(id_holder)

end
