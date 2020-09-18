defmodule CritBiz.ViewModels.Reservation.AfterTheFact.Forms do
  defmodule Context do
    use Ecto.Schema
    alias Ecto.Timespan
    alias CritBiz.ViewModels.Step
    
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
    
    @required [:responsible_person, :species_id, :date,
               :date_showable_date, :timeslot_id, :institution, :task_id]
    
    @transfers [:species_id, :responsible_person, :date, :timeslot_id]

    def empty do
      change(%__MODULE__{})
    end
    
    def changeset(attrs) do
      empty()
      |> cast(attrs, @required)
      |> validate_required(@required)
      |> add_span
    end

    def next_task_memory(task_memory, struct) do 
      span =
        Institution.timespan(
          struct.date, struct.timeslot_id, task_memory.institution)
      
      task_memory
      |> Step.initialize_by_transfer(struct, @transfers)
      |> Step.initialize_by_setting(span: span)
    end

    def next_form_data(task_memory, _struct) do 
      ReservationApi.after_the_fact_animals(task_memory, task_memory.institution)
    end
    
    
    defp add_span(%{valid?: false} = changeset), do: changeset
    defp add_span(changeset) do
      args =
        [:date, :timeslot_id, :institution]
        |> Enum.map(&(get_change changeset, &1))
      
      result = apply(Institution, :timespan, args)
      put_change(changeset, :span, result)
    end
  end
  
  defmodule Animals do
    use Ecto.Schema
    import Ecto.Changeset
    alias Crit.Servers.UserTask
    
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
    alias Crit.Servers.UserTask
    
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
