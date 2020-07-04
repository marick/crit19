defmodule CritBiz.ViewModels.DateOrDates do
  use Ecto.Schema
  use Crit.Global.Constants
  alias Crit.Setup.InstitutionApi
  import Ecto.Changeset

  @last_day_radio_value "just one day"  


  embedded_schema do
    field :first_datestring, :string, default: @today
    field :last_datestring, :string, default: @last_day_radio_value
  end

  @required [:first_datestring, :last_datestring]

  def changeset(struct, attrs) do
    struct
    |> cast(attrs, @required)
    |> validate_required(@required)
  end

  def starting_changeset(), do: changeset(%__MODULE__{}, %{})

  def to_dates(attrs, institution) do
    changeset = changeset(%__MODULE__{}, attrs)
    {:ok, first_date} =
      synthesize(changeset,
        :first_datestring,
        {@today, InstitutionApi.today!(institution)})
    {:ok, last_date} =
      synthesize(changeset,
        :last_datestring,
        {@last_day_radio_value, first_date})
    
    {:ok, first_date, last_date}
  end

  def synthesize(changeset, field, {default_signal, default_value}) do
    case get_field(changeset, field) do
      ^default_signal ->
        {:ok, default_value} 
      iso_string -> 
        Date.from_iso8601(iso_string)
    end
  end    
end
