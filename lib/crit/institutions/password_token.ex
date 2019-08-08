defmodule Crit.Institutions.PasswordToken do
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

  # def suitable_text(), do: EmailToken.generate()
  # def unused(), do: %__MODULE__{text: suitable_text()}


  # @expiration_in_seconds (7 * 24 * 60 * 60)

  # def expiration_threshold(now \\ NaiveDateTime.utc_now) do
  #   NaiveDateTime.add(now, -1 * @expiration_in_seconds)
  # end

  # def force_update(token, datetime, institution) do
  #   for_postgres = NaiveDateTime.truncate(datetime, :second)

  #   change(token, updated_at: for_postgres) |> Sql.update(institution)
  #   :ok
  # end

  # defmodule Query do
  #   import Ecto.Query
  #   alias Crit.Institutions.PasswordToken

  #   def matching_user(token_text) do
  #     from u in User,
  #       join: pt in assoc(u, :password_token),
  #       where: pt.text == ^token_text
  #   end

  #   # Note that userids are *not* unique
  #   def by_user_id(user_id),
  #     do: from PasswordToken, where: [user_id: ^user_id]
  
  #   def expired_tokens do
  #     from r in PasswordToken,
  #       where: r.updated_at < ^PasswordToken.expiration_threshold()
  #   end
  # end
4end
