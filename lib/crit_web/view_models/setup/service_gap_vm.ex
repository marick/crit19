defmodule CritWeb.ViewModels.Setup.ServiceGap do
  use Ecto.Schema
  alias CritWeb.ViewModels.FieldFillers.{FromWeb,ToWeb}
  alias CritWeb.ViewModels.FieldValidators
  import Ecto.Changeset
  alias Crit.Common
  
  @primary_key false   # I do this to emphasize `id` is just another field
  embedded_schema do
    field :id, :id
    field :reason, :string

    field :institution, :string
    field :in_service_datestring, :string
    field :out_of_service_datestring, :string
    field :delete, :boolean, default: false
  end

  def fields(), do: __schema__(:fields)
  def required(), do: List.delete(__schema__(:fields), :id)

  @unstarted_indicators ["in_service_datestring", "out_of_service_datestring",
                         "reason"]
  
  # ----------------------------------------------------------------------------

  def to_web(sources, institution) when is_list(sources),
    do: (for s <- sources, do: to_web(s, institution))

  def to_web(source, institution) do
    %{EnumX.pour_into(source, __MODULE__) |
      institution: institution
    }
    |> ToWeb.service_datestrings(source.span)
  end

  # ----------------------------------------------------------------------------
  
  def form_changeset(params, institution) do
    %__MODULE__{institution: institution}
    |> cast(params, fields())
    |> validate_required(required())
    |> FieldValidators.date_order
  end

  def form_changesets(list, institution) do
    list
    |> Common.filter_out_unstarted_forms(@unstarted_indicators)
    |> Enum.map(&form_changeset(&1, institution))
  end    

  def separate_deletions(changesets) do
    %{true => deletable, false => updateable } =
      changesets
      |> Enum.group_by(&get_field(&1, :delete))

    {updateable, Enum.map(deletable, &(get_field(&1, :id)))}
  end

  # ----------------------------------------------------------------------------

  def update_params(changesets) when is_list(changesets) do 
    for c <- changesets do
      {:ok, data} = apply_action(c, :insert)
      %{id: data.id,
        reason: data.reason,
        span: FromWeb.span(data)
      }
    end
  end
end
