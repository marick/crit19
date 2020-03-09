defmodule CritWeb.Setup.ProcedureView do
  use CritWeb, :view
  alias Ecto.Changeset
  alias CritWeb.ViewModels.Procedure.Creation  


  def creation_error_tag(%Changeset{} = changeset, field) do
    changeset.errors
    |> Keyword.get_values(field)
    |> Enum.flat_map(&expand_error/1)
  end

  defp expand_error({message, _}) do
    case message in Map.values(Creation.legit_error_messages) do
      true ->
        [~E"""
         <span class="ui pointing red basic label">
           <%= message %>
         </span>
        """]
      false ->
        []
    end
  end

  def animal_entry(f, changeset) do
    [text_input(f, :name, value: Changeset.fetch_field!(changeset, :name)),
     creation_error_tag(changeset, :name)
    ]
  end

  def species_chooser(f, species_pairs, changeset) do 
    [multiple_checkbox_row(f, species_pairs, :species_ids,
        checked: Changeset.fetch_field!(changeset, :species_ids)),
     creation_error_tag(changeset, :species_ids)
    ]
  end
end
