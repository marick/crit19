defmodule CritWeb.ViewModels.NestedForm do 
  use CritWeb, :view
  alias Ecto.Changeset


  def inputs_for(form, field, builder) do
    indexed =
      form.data
      |> Map.get(field)
      |> Enum.with_index

    for {nested, index} <- indexed do
      builder.(inputs_for_one(form, field, index, nested))
    end
  end    

    
  
  defp inputs_for_one(form, field, index, %Changeset{} = changeset) do
    form_for(changeset, "no route for embedded form")
    |> Map.put(:id, "#{form.id}_#{to_string field}_#{index}")
    |> Map.put(:name, "#{form.name}[#{to_string field}][#{index}]")
  end

  defp inputs_for_one(form, field, index, struct),
    do: inputs_for_one(form, field, index, Changeset.change(struct))
end  

