defmodule CritWeb.Setup.ProcedureView do
  use CritWeb, :view
  alias Ecto.Changeset

  def procedure_input(f, changeset) do
    [text_input(f, :name,
        value: Changeset.fetch_field!(changeset, :name),
        placeholder: "Procedure name"),
     error_tag(changeset, :name)
    ]
  end

  def species_chooser(f, species_pairs, changeset) do 
    [multiple_checkbox_row(f, species_pairs, :species_ids,
        checked: Changeset.fetch_field!(changeset, :species_ids),
        data_target: "procedure-creation.checkboxes"),
     error_tag(changeset, :species_ids)
    ]
  end

  def frequency_chooser(f, frequencies) do
    ~E"""
        <%= select f, :frequency, EnumX.names(frequencies), id: "3838",
            class: "ui dropdown" %>
    """
  end

  def frequency_help(frequency) do
    ~E"""
       <dt><%= frequency.name %></dt>
       <dd><%= frequency.description %></dd>
    """
  end

end
