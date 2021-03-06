defmodule CritBiz.ViewModels.Common do
  alias Ecto.ChangesetX
  alias Ecto.Changeset
  
  def flatten_numbered_sublist(top, name),
    do: Map.put(top, name, Map.values(top[name]))

  def flatten_to_list(map), do: Map.values(map)

  # Because view models don't pass changesets through the Repo
  # functions like `update`, they don't automatically get their
  # `action` set. That matters because Phoenix.Form's `error_tag`
  # won't do anything unless the (spooky) action (at a distance) is
  # set.
  
  def summarize_validation(%Changeset{valid?: true} = changeset), do: changeset

  def summarize_validation(%Changeset{valid?: false} = changeset),
    do: ChangesetX.ensure_forms_display_errors(changeset)
  

  def summarize_validation(%Changeset{} = changeset, true = _valid?, _),
    do: {:ok, force_valid(changeset) }

  def summarize_validation(%Changeset{} = changeset, false = _valid?,
    [error_subtype: error_tag]) do

    {:error,
     error_tag,
     changeset |> force_invalid |> ChangesetX.ensure_forms_display_errors
    }
  end

  # ----------------------------------------------------------------------------
  defp force_valid(changeset),   do: %{changeset | valid?: true}
  defp force_invalid(changeset), do: %{changeset | valid?: false}
end
