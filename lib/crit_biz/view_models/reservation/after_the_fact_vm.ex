defmodule CritBiz.ViewModels.Reservation.AfterTheFact do
  alias Crit.Servers.UserTask
  alias CritBiz.ViewModels.Reservation.AfterTheFact.Forms
  alias CritBiz.ViewModels.Step

  defstruct task_id: :nothing,
    # Values needed for creation
    
    species_id:           :nothing,   # context form
    date:                 :nothing,   # context form
    timeslot_id:          :nothing,   # context form
    span:                 :nothing,   # context form
    responsible_person:   :nothing,   # context form
    
    chosen_animal_ids:    :nothing,   # animals form
    chosen_procedure_ids: :nothing,   # procedures form


  # For the non-field parts of the display.
    ## Values needed after step 1 (Start)
    institution:          :nothing,
  
  ## Values needed after step 2 (put context)
    task_header:          :nothing
  
  ## Values needed after step 3 (put animals)
  
  ## Values needed after step 3 (put procedures)


  
  def start(institution) do
    task_memory = UserTask.start(__MODULE__, institution: institution)
    changeset = Forms.Context.empty
    {:ok, task_memory, changeset}
  end

  def accept_context_form(params) do
    Step.attempt(params, Forms.Context)
  end
end
