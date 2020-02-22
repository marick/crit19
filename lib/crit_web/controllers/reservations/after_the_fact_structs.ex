defmodule CritWeb.Reservations.AfterTheFactStructs do

  defmodule State do
    defstruct task_id: :nothing,
      task_header:          :nothing,

      species_id:           :nothing,
      date:                 :nothing,
      timeslot_id:          :nothing,
      span:                 :nothing,

      chosen_animal_ids:    :nothing,
      chosen_procedure_ids: :nothing
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
      field :timeslot_id, :integer
      field :institution, :string
      field :span, Timespan
    end

    @required [:species_id, :date, :date_showable_date, :timeslot_id, :institution]

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
        [:date, :timeslot_id, :institution]
        |> Enum.map(&(get_change changeset, &1))
      
      result = apply(InstitutionApi, :timespan, args)
      put_change(changeset, :span, result)
    end
  end

  defmodule Animals do
    use Ecto.Schema
    import Ecto.Changeset

    embedded_schema do
      field :chosen_animal_ids, {:array, :integer}
      field :task_id, :string
    end

    @required [:chosen_animal_ids, :task_id]

    def changeset(attrs) do
    
      %__MODULE__{}
      |> cast(attrs, @required)
      |> validate_required(@required)
    end
  end

  defmodule Procedures do
    use Ecto.Schema
    import Ecto.Changeset

    embedded_schema do
      field :chosen_procedure_ids, {:array, :integer}
      field :task_id, :string
    end

    @required [:chosen_procedure_ids, :task_id]

    def changeset(attrs) do
    
      %__MODULE__{}
      |> cast(attrs, @required)
      |> validate_required(@required)
    end
  end
  
end

