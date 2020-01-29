defmodule CritWeb.Reservations.AfterTheFactController do
  use CritWeb, :controller
  use CritWeb.Controller.Path, :after_the_fact_path
  import CritWeb.Plugs.Authorize
  alias CritWeb.Reservations.AfterTheFact.{StartData,AnimalData}
  alias Crit.Setup.{InstitutionApi,AnimalApi}
  alias Ecto.Changeset
  alias Crit.MultiStepCache, as: Cache

  plug :must_be_able_to, :make_reservations

  def start(conn, _params) do
    render(conn, "species_and_time_form.html",
      changeset: StartData.empty,
      path: path(:put_species_and_time),
      species_options: InstitutionApi.available_species(institution(conn)),
      time_slot_options: InstitutionApi.time_slot_tuples(institution(conn)))
  end

  def put_species_and_time(conn, %{"start_data" => params}) do
    changeset = 
      params
      |> Map.put("institution", institution(conn))
      |> StartData.changeset

    case changeset.valid? do
      true -> 
        {:ok, struct} = Changeset.apply_action(changeset, :insert)
        key = Cache.put_first(struct)

        animals =
          AnimalApi.available_after_the_fact(changeset.changes, @institution)
        Cache.add(key, %{animal_names: EnumX.to_id_map(animals, :name)})
        

        render(conn, "animals_form.html",
          transaction_key: key,
          reminders: struct,
          path: path(:put_animals),
          animals: animals)
    end
  end

  def put_animals(conn, %{"animals" => params}) do
    changeset = AnimalData.changeset(params)

    case changeset.valid? do
      true -> 
        {:ok, struct} = Changeset.apply_action(changeset, :insert)
        IO.inspect struct
        reminders = Cache.get(struct.transaction_key)
        IO.inspect reminders
        animal_names = Enum.map(struct.chosen_animal_ids, &(reminders.animal_names[&1]))
        IO.inspect animal_names
        
        render(conn, "procedures_form.html",
          transaction_key: struct.transaction_key,
          animal_names: Enum.join(animal_names, ", "),
          reminders: reminders,
          path: path(:put_procedures))
    end
  end
  
  def put_procedures(conn, %{"after_the_fact_form" => _params}) do
    render(conn, "done.html")
  end
  
end
