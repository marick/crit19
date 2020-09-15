defmodule CritBiz.ViewModels.Reservation.AfterTheFact do
  alias Crit.Servers.UserTask
  alias CritBiz.ViewModels.Reservation.AfterTheFact.Forms

  defstruct task_id: :nothing,
    task_header:          :nothing,
    
    species_id:           :nothing,
    date:                 :nothing,
    timeslot_id:          :nothing,
    span:                 :nothing,
    responsible_person:   :nothing,
    
    chosen_animal_ids:    :nothing,
    chosen_procedure_ids: :nothing

  
  def start do
    task_memory = UserTask.start(__MODULE__)
    changeset = Forms.Context.empty
    {task_memory, changeset}
  end


end
