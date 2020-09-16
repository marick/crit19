defmodule CritBiz.ViewModels.Reservation.AfterTheFact do
  alias Crit.Servers.UserTask
  alias CritBiz.ViewModels.Reservation.AfterTheFact.Forms

  defstruct task_id: :nothing,
    # Values needed for creation
    
    species_id:           :nothing,
    date:                 :nothing,
    timeslot_id:          :nothing,
    span:                 :nothing,
    responsible_person:   :nothing,
    
    chosen_animal_ids:    :nothing,
    chosen_procedure_ids: :nothing,


  # For the non-field parts of the display.
  ## Values needed after step 1 (Start)
  
  ## Values needed after step 2 (put context)
    task_header:          :nothing
  
  ## Values needed after step 3 (put animals)
  
  ## Values needed after step 3 (put procedures)


  
  def start do
    task_memory = UserTask.start(__MODULE__)
    changeset = Forms.Context.empty
    {task_memory, changeset}
  end


end
