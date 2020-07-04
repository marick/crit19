defmodule CritBiz.ViewModels.Setup.ServiceGap do
  use Ecto.Schema
  alias Crit.Setup.Schemas
  alias CritBiz.ViewModels.FieldFillers.{FromWeb,ToWeb}
  alias CritBiz.ViewModels.FieldValidators
  import Ecto.Changeset
  import Pile.Deftestable
  import CritBiz.ViewModels.Common, only: [summarize_validation: 1]
  
  @primary_key false   # I do this to emphasize `id` is just another field
  embedded_schema do
    field :id, :id
    field :reason, :string,                    default: ""

    field :institution, :string
    field :in_service_datestring, :string,     default: ""
    field :out_of_service_datestring, :string, default: ""
    field :delete, :boolean,                   default: false
  end

  def fields(), do: __schema__(:fields)
  def required(), do: List.delete(__schema__(:fields), :id)
      
  @unstarted_atom_keys [:in_service_datestring, :out_of_service_datestring,
                        :reason]
  @unstarted_string_keys Enum.map(@unstarted_atom_keys, &to_string/1)

 # ----------------------------------------------------------------------------

  def lift(sources, institution) when is_list(sources),
    do: (for s <- sources, do: lift(s, institution))

  def lift(%Schemas.ServiceGap{} = source, institution) do
    %{EnumX.pour_into(source, __MODULE__) |
      institution: institution
    }
    |> ToWeb.service_datestrings(source.span)
  end

  # ----------------------------------------------------------------------------

  # Note: you probably want `accept_form`, not this.
  def changeset(%__MODULE__{} = struct, params) do
    struct
    |> cast(params, fields())
    |> validate_required(required())
    |> FieldValidators.date_order
  end
  
  def accept_form(params, institution) do 
    case {from_empty_form?(params),
          describe_insertion?(params)} do
      {true, true} ->
        # Display, error free, if other forms have errors.
        unchecked_empty_changeset(params)
      _ ->
        # Look for errors.
        changeset(%__MODULE__{institution: institution}, params)
        |> summarize_validation
    end
  end

  deftestable unchecked_empty_changeset(params),
    do: cast(%__MODULE__{}, params, fields())

  defp describe_insertion?(params), do: not Map.has_key?(params, "id")

  # ----------------------------------------------------------------------------

  deftestable from_empty_form?(%__MODULE__{} = struct),
    do: from_empty_form?(struct, @unstarted_atom_keys)

  deftestable from_empty_form?(%{} = params),
    do: from_empty_form?(params, @unstarted_string_keys)
  
  def from_empty_form?(map, keys) do
    trimmed = fn string ->
      string |> String.trim_leading |> String.trim_trailing
    end

    empty? = fn one ->
      Enum.all?(keys, fn key ->
        value = Map.get(one, key) |> trimmed.()
        value == ""
      end)
    end

    empty?.(map)
  end

  # ----------------------------------------------------------------------------

  def lower_to_attrs(changesets) when is_list(changesets) do
    make_vm = fn changeset -> 
      {:ok, data} = apply_action(changeset, :insert)
      data
    end

    make_attrs = &(%{id: &1.id, reason: &1.reason, span: FromWeb.span(&1)})

    changesets
    |> Enum.map(make_vm)
    |> Enum.reject(&from_empty_form?/1)
    |> Enum.map(make_attrs)
  end

  # ----------------------------------------------------------------------------

  @spec ensure_changesets(Changeset.t(any)) :: [Changeset.t(%__MODULE__{})]
  def ensure_changesets(containing_changeset) do
    case fetch_change(containing_changeset, :service_gaps) do
      {:ok, sg_changesets} -> 
        sg_changesets
      :error ->
        containing_changeset
        |> fetch_field!(:service_gaps)
        |> Enum.map(&(change &1, %{}))
    end
  end

  def mark_deletions(containing_changeset, ids_to_delete) do
    nested_changesets =
      containing_changeset
      |> ensure_changesets
      |> Enum.map(&(mark_deletion &1, ids_to_delete))
    
    put_change(containing_changeset, :service_gaps, nested_changesets)
  end

  def mark_deletion(changeset, ids_to_delete) do 
    if MapSet.member?(ids_to_delete, fetch_field!(changeset, :id)) do
      %{changeset | action: :delete}
    else
      changeset
    end
  end
end
