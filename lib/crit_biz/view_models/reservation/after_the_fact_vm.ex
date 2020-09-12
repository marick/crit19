defmodule CritBiz.ViewModels.Reservation.AfterTheFact do
  alias Crit.State.UserTask

  defstruct task_id: :nothing,
    task_header:          :nothing,
    
    species_id:           :nothing,
    date:                 :nothing,
    timeslot_id:          :nothing,
    span:                 :nothing,
    responsible_person:   :nothing,
    
    chosen_animal_ids:    :nothing,
    chosen_procedure_ids: :nothing
  
  defmodule Form do 

    defmodule Context do
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
        field :responsible_person, :string
        field :task_id, :string
      end
      
      @required [:responsible_person, :species_id, :date, :date_showable_date, :timeslot_id, :institution, :task_id]
      
      def empty do
        change(%__MODULE__{})
      end
      
      def changeset(attrs) do
        empty()
        |> cast(attrs, @required)
        |> validate_required(@required)
        |> add_span
      end
      
      defp add_span(%{valid?: false} = changeset), do: changeset
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
        |> UserTask.validate_task_id
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
        |> UserTask.validate_task_id
      end
    end
  end
end
