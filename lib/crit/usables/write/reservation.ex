defmodule Crit.Usables.Write.Reservation do
  use Ecto.Schema
  import Ecto.Changeset
  alias Ecto.Timespan
  alias Crit.Sql
  alias Crit.Usables.Write
  alias Ecto.Multi
  alias Crit.Ecto.BulkInsert

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

    script =
      Multi.new
      |> Multi.insert(:reservation, changeset, Sql.multi_opts(institution))
    
    case Sql.transaction(script, institution) do
      {:error, :reservation, changeset, _so_far} ->
        {:error, changeset} 
      {:ok, %{reservation: inserted}} -> 
        {:ok, inserted}
    end

    # results = 
    # for animal_id <- animal_ids, procedure_id <- procedure_ids do
    #   Write.Use.changeset(%Write.Use{animal_id: animal_id, procedure_id: procedure_id, reservation_id: inserted.id}, %{})
    #   |> Sql.insert(institution)
    #   |> IO.inspect 
    # end
  end


  def populate_timespan(%{valid?: false} = changeset), do: changeset
  def populate_timespan(%{changes: changes} = changeset) do
    timespan = Timespan.from_date_time_and_duration(
      changes.start_date, changes.start_time, changes.minutes)
    put_change(changeset, :timespan, timespan)
  end
end
