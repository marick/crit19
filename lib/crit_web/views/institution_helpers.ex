defmodule CritWeb.InstitutionHelpers do
  @moduledoc """
  Formatting per-institution information
  """
  alias Crit.Servers.Institution
  import CritWeb.Plugs.Accessors
  import CritWeb.Fomantic.Elements

  def species_dropdown(form, conn) do
    options = Institution.species(institution(conn)) |> EnumX.id_pairs(:name)
    dropdown(form, "Species", :species_id,
      options: options,
      dropdown_id: "species_select")
  end

  def timeslot_dropdown(form, conn) do
    options = Institution.timeslots(institution(conn)) |> EnumX.id_pairs(:name)
    dropdown(form, "Time", :timeslot_id,
      options: options,
      dropdown_id: "timeslot_select")
  end
end
