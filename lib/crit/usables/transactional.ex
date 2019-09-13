defmodule Crit.Usables.Transactional do
  alias Ecto.Multi
  alias Crit.Usables.ServiceGap

  defp gap_key(index), do: {:gap, index}
  defp is_gap_key?({:gap, _count}), do: true
  defp is_gap_key?(_), do: false

  defp gap_ids(_repo, map_with_gaps) do
    reducer = fn {key, value}, acc ->
      case is_gap_key?(key) do
        true ->
          [value.id | acc]
        false ->
          acc
      end
    end

    result = 
      map_with_gaps
      |> Enum.reduce([], reducer)
      |> Enum.reverse

    {:ok, result}
  end

  def initial_service_gaps(params, _institution) do
    add_insertion = fn {changeset, index}, acc ->
      Multi.insert(acc, gap_key(index), changeset, prefix: "demo")
    end

    params
    |> ServiceGap.initial_changesets
    |> Enum.with_index
    |> Enum.reduce(Multi.new, add_insertion)
    |> Multi.run(:gap_ids, &gap_ids/2)
  end
end
