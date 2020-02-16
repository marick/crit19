defmodule CritWeb.Reservations.AfterTheFactData do

  defmodule Workflow do
    defstruct species_and_time_header: nil,
      animals_header: nil,
      institution: nil,

      species_id: nil,
      date: nil,
      time_slot_id: nil,
      span: nil,

      chosen_animal_ids: nil,
      chosen_procedure_ids: nil
  end

  defmodule SpeciesAndTime do
    use Ecto.Schema
    import Ecto.Changeset
    alias Crit.Setup.InstitutionApi
    alias Ecto.Timespan

    embedded_schema do
      field :species_id, :integer
      field :date, :date
      field :date_showable_date, :string
      field :time_slot_id, :integer
      field :institution, :string
      field :span, Timespan
    end

    @required [:species_id, :date, :date_showable_date, :time_slot_id, :institution]

    def empty do
      change(%__MODULE__{})
    end

    def changeset(attrs) do
      empty()
      |> cast(attrs, @required)
      |> validate_required(@required)
      |> add_span
    end

    defp add_span(changeset) do
      args =
        [:date, :time_slot_id, :institution]
        |> Enum.map(&(get_change changeset, &1))
      
      result = apply(InstitutionApi, :timespan, args)
      put_change(changeset, :span, result)
    end
  end

  defmodule Animals do
    use Ecto.Schema
    import Ecto.Changeset
    alias Crit.Common

    embedded_schema do
      field :chosen_animal_ids, {:array, :integer}
      field :transaction_key, :string
      field :institution, :string
    end

    @required [:chosen_animal_ids, :transaction_key, :institution]

    def changeset(attrs) do
    
      %__MODULE__{}
      |> cast(attrs, @required)
      |> validate_required(@required)
    end
  end

  defmodule Procedures do
    use Ecto.Schema
    import Ecto.Changeset
    alias Crit.Common

    embedded_schema do
      field :chosen_procedure_ids, {:array, :integer}
      field :transaction_key, :string
      field :institution, :string
    end

    @required [:chosen_procedure_ids, :transaction_key, :institution]

    def changeset(attrs) do
    
      %__MODULE__{}
      |> cast(attrs, @required)
      |> validate_required(@required)
    end
  end
  
end

