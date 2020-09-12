defmodule CritBiz.ViewModels.Reservation.AfterTheFact do
  alias Crit.Servers.UserTask

  defstruct task_id: :nothing,
    task_header:          :nothing,
    
    species_id:           :nothing,
    date:                 :nothing,
    timeslot_id:          :nothing,
    span:                 :nothing,
    responsible_person:   :nothing,
    
    chosen_animal_ids:    :nothing,
    chosen_procedure_ids: :nothing
  
end
