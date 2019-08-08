defmodule Crit.Institutions.PasswordToken2 do
  use Ecto.Schema
  alias Crit.EmailToken
  import Ecto.Changeset
  import Ecto.Query
  alias Crit.Sql
  alias Crit.Institutions.Institution

  @schema_prefix "clients"
  
  schema "all_password_tokens" do
    field :text, :string
    field :user_id, :id
    belongs_to :institution, Institution

    timestamps(inserted_at: false)
  end

end
