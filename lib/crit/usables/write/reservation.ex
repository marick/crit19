defmodule Crit.Usables.Write.Reservation do
  use Ecto.Schema
  import Ecto.Changeset
  alias Ecto.Timespan
  alias Crit.Sql
  alias Crit.Usables.Write
  alias Ecto.Multi
#  alias Crit.Ecto.BulkInsert

  schema "reservations" do
    field :timespan, Timespan
    field :species_id, :id


    field :animal_ids, {:array, :id}, virtual: true
    field :procedure_ids, {:array, :id}, virtual: true
    field :start_date, :date, virtual: true
    field :start_time, :time, virtual: true
    field :minutes, :integer, virtual: true
    timestamps()
  end

  @required [:start_date, :start_time, :minutes, :species_id, 
            :animal_ids, :procedure_ids]

  def changeset(reservation, attrs) do
    reservation
    |> cast(attrs, @required)
    |> validate_required(@required)
    |> populate_timespan
  end

  def create(attrs, institution) do
    changeset = changeset(%__MODULE__{}, attrs)
    %{animal_ids: animal_ids, procedure_ids: procedure_ids} = changeset.changes

    use_insertion_script_maker =
      make_use_insertion_script_maker(animal_ids, procedure_ids, institution)
    
    Multi.new
    |> Multi.insert(:reservation, changeset, Sql.multi_opts(institution))
    |> Multi.merge(use_insertion_script_maker)
    |> Sql.transaction(institution)
    |> produce_one_result(:reservation)
  end

  defp make_use_insertion_script_maker(animal_ids, procedure_ids, institution) do 
    fn tx_result ->

      reducer = fn use, multi_so_far ->
        Multi.insert(multi_so_far,
          use,  # We have to give a unique name for the result.
          Write.Use.changeset_with_constraints(use),
          Sql.multi_opts(institution))
      end
      
      tx_result.reservation.id
      |> Write.Use.reservation_uses(animal_ids, procedure_ids)
      |> Enum.reduce(Multi.new, reducer)
    end
  end
  

  defp produce_one_result({:error, _failing_step, changeset, _so_far}, _) do
    {:error, changeset}
  end
  
  defp produce_one_result({:ok, tx_result}, key) do
    {:ok, Map.get(tx_result, key)}
  end

  defp populate_timespan(%{valid?: false} = changeset), do: changeset
  defp populate_timespan(%{changes: changes} = changeset) do
    timespan = Timespan.from_date_time_and_duration(
      changes.start_date, changes.start_time, changes.minutes)
    put_change(changeset, :timespan, timespan)
  end
end
