defmodule CritWeb.ViewModels.Setup.ServiceGap do
  use Ecto.Schema
  alias CritWeb.ViewModels.Setup, as: VM
  alias Crit.Setup.Schemas
  alias CritWeb.ViewModels.FieldFillers.{FromWeb,ToWeb}
  alias CritWeb.ViewModels.FieldValidators
  import Ecto.Changeset
  
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

  def lift(sources, institution) when is_list(sources),
    do: (for s <- sources, do: lift(s, institution))

  def lift(%Schemas.ServiceGap{} = source, institution) do
    %{EnumX.pour_into(source, VM.ServiceGap) |
      institution: institution
    }
    |> ToWeb.service_datestrings(source.span)
  end

  # ----------------------------------------------------------------------------
  def changeset(%VM.ServiceGap{} = struct, params) do
    struct
    |> cast(params, fields())
    |> validate_required(required())
    |> FieldValidators.date_order
  end
  
  def accept_form(params, institution) do
    %VM.ServiceGap{institution: institution}
    |> changeset(params)
  end
 


  # ----------------------------------------------------------------------------

  def from_empty_form?(%{} = params) do
    trimmed = fn string ->
      string |> String.trim_leading |> String.trim_trailing
    end

    empty? = fn one ->
      Enum.all?(@unstarted_indicators, &(trimmed.(one[&1]) == ""))
    end

    empty?.(params)
  end
  
  # ----------------------------------------------------------------------------

  def lower_to_attrs(changesets) when is_list(changesets) do 
    for c <- changesets do
      {:ok, data} = apply_action(c, :insert)
      %{id: data.id,
        reason: data.reason,
        span: FromWeb.span(data)
      }
    end
  end

  # ----------------------------------------------------------------------------
end
