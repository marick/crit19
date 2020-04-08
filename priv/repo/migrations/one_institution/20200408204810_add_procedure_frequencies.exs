defmodule Crit.Repo.Migrations.AddProcedureFrequencies do
  use Ecto.Migration

  def change do
    create table(:procedure_frequencies) do
      add :name, :citext, null: false
      add :calculation_name, :string, null: false
      add :description, :text, null: false, default: ""
    end

    alter table(:procedures) do
      add :frequency_id, references(:procedure_frequencies, on_delete: :restrict),
        null: true
    end
  end
end
