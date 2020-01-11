defmodule CritWeb.View.Support.Id do
  alias Phoenix.HTML.Form
  alias Ecto.Changeset
  import CritWeb.Fomantic.Elements

  def unique_snippet(%Phoenix.HTML.Form{} = form), do: unique_snippet(form.data)
  def unique_snippet(%Changeset{} = changeset), do: unique_snippet(changeset.data)
  def unique_snippet(%{id: nil}), do: "_and_new"
  def unique_snippet(%{id: id}), do: "_#{id}"

  def unique_snippet(id_holder1, id_holder_2),
    do: unique_snippet(id_holder1) <> unique_snippet(id_holder_2)

  def delete_if_exists(f) do
    if Form.input_value(f, :id) do
      labeled_checkbox f, "Delete", :delete
    else
      []
    end
  end

  def accordion_div_id(%Changeset{} = changeset),
    do: accordion_div_id(changeset.data)
  def accordion_div_id(id_holder), 
    do: "accordion" <> unique_snippet(id_holder)
end
