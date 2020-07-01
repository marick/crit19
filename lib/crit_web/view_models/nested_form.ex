defmodule CritWeb.ViewModels.NestedForm do 
  use CritWeb, :view
  alias Ecto.Changeset


  def inputs_for(containing_form, field, builder) do
    %Changeset{} = form_changeset = containing_form.source

    nested_form_changesets = 
      Changeset.fetch_field!(form_changeset, field)
      |> Enum.map(&Changeset.change/1)
    
    for {nested, index} <- Enum.with_index(nested_form_changesets) do
      builder.(inputs_for_one(containing_form, field, index, nested))
    end
  end    
  
  defp inputs_for_one(containing_form, field, index, %Changeset{} = changeset) do
    # I can't see a way to orchestrate things so that an ID appears in
    # the form without manually setting it as hidden.
    hidden_list =
      case Changeset.fetch_field!(changeset, :id) do
        nil -> []
        x -> [id: x]
      end

    form_for(changeset, "no route for embedded form")
    |> Map.put(:hidden, hidden_list)
    |> Map.put(:id, "#{containing_form.id}_#{to_string field}_#{index}")
    |> Map.put(:name, "#{containing_form.name}[#{to_string field}][#{index}]")
    |> Map.put(:index, index)
  end
end  

