defmodule CritWeb.Reservations.AfterTheFactController do
  use CritWeb, :controller
  use CritWeb.Controller.Path, :after_the_fact_path
  import CritWeb.Plugs.Authorize
  alias Crit.Setup.{InstitutionApi,AnimalApi} #,ProcedureApi}
  # alias Ecto.Changeset
  alias Ecto.ChangesetX
  alias Crit.MultiStepCache, as: Cache
  alias CritWeb.Reservations.AfterTheFactData, as: Data
  alias CritWeb.Reservations.AfterTheFactView, as: View

  plug :must_be_able_to, :make_reservations

  def start(conn, _params) do
    render(conn, "species_and_time_form.html",
      changeset: Data.SpeciesAndTime.empty,
      path: path(:put_species_and_time),
      species_options: InstitutionApi.available_species(institution(conn)),
      time_slot_options: InstitutionApi.time_slot_tuples(institution(conn)))
  end

  def put_species_and_time(conn, %{"species_and_time" => delivered_params}) do
    params = Map.put(delivered_params, "institution", institution(conn))

    case ChangesetX.realize_struct(params, Data.SpeciesAndTime) do
      {:ok, new_data} ->
        header =
          View.species_and_time_header(
            new_data.date_showable_date,
            InstitutionApi.time_slot_name(new_data.time_slot_id, institution(conn)))
        
        workflow_state =
          Map.merge(%Data.Workflow{animal_choice_header: header}, new_data)
        key = Cache.put_first(workflow_state)
        animals =
          AnimalApi.available_after_the_fact(new_data, @institution)

        render(conn, "animals_form.html",
          transaction_key: key,
          header: header,
          path: path(:put_animals),
          animals: animals)
    end
  end

  def put_animals(_conn, %{"animals" => _params}) do
    # changeset = AnimalData.changeset(params)

    # case changeset.valid? do
    #   true -> 
    #     {:ok, struct} = Changeset.apply_action(changeset, :insert)
    #     IO.inspect struct
    #     reminders = Cache.get(struct.transaction_key)
    #     # IO.inspect reminders
    #     animal_names = Enum.map(struct.chosen_animal_ids, &(reminders.animal_names[&1]))
    #     IO.inspect animal_names

    #     Cache.add(reminders.transaction_key, %{chosen_animal_ids: struct.chosen_animal_ids})

    #     procedures =
    #       ProcedureApi.all_by_species(reminders.species_id, @institution)

    #     # IO.inspect procedures
        
        
    #     render(conn, "procedures_form.html",
    #       transaction_key: struct.transaction_key,
    #       animal_names: Enum.join(animal_names, ", "),
    #       procedures: procedures,
    #       reminders: reminders,
    #       path: path(:put_procedures))
    # end
  end
  
  def put_procedures(_conn, %{"after_the_fact_form" => _params}) do
    # render(conn, "done.html")
  end
  
end
