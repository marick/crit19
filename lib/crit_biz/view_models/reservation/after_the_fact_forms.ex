defmodule CritBiz.ViewModels.Reservation.AfterTheFact.Forms do
  defmodule Context do
    use Ecto.Schema
    import Ecto.Changeset
    alias Crit.Servers.Institution
    alias Ecto.Timespan
    alias CritBiz.ViewModels.Step
    alias Crit.Reservations.ReservationApi
    alias CritWeb.Reservations.AfterTheFactView, as: View
    
    embedded_schema do
      field :species_id, :integer
      field :date, :date
      field :date_showable_date, :string
      field :timeslot_id, :integer
      field :responsible_person, :string
      field :task_id, :string
    end
    
    @required [:responsible_person, :species_id, :date,
               :date_showable_date, :timeslot_id, :task_id]
    
    @transfers [:species_id, :responsible_person, :date, :timeslot_id]

    def empty do
      change(%__MODULE__{})
    end
    
    def changeset(attrs) do
      empty()
      |> cast(attrs, @required)
      |> validate_required(@required)
    end

    def next_task_memory(task_memory, struct) do
      span =
        Institution.timespan(
          struct.date, struct.timeslot_id, task_memory.institution)

      header =
        View.context_header(
          struct.date_showable_date,
          Institution.timeslot_name(struct.timeslot_id, task_memory.institution))
      
      
      task_memory
      |> Step.initialize_by_transfer(struct, @transfers)
      |> Step.initialize_by_setting(span: span, task_header: header)
    end

    def next_form_data(task_memory, _struct) do 
      ReservationApi.after_the_fact_animals(task_memory, task_memory.institution)
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
