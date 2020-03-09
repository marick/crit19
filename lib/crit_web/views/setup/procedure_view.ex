defmodule CritWeb.Setup.ProcedureView do
  use CritWeb, :view
  alias Ecto.Changeset
  alias CritWeb.ViewModels.Procedure.Creation  


  def animal_entry(f, changeset) do
    [text_input(f, :name, value: Changeset.fetch_field!(changeset, :name)),
     error_tag(changeset, :name)
    ]
  end

  def species_chooser(f, species_pairs, changeset) do 
    [multiple_checkbox_row(f, species_pairs, :species_ids,
        checked: Changeset.fetch_field!(changeset, :species_ids)),
     error_tag(changeset, :species_ids)
    ]
  end
end
