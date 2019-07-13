defmodule Crit.Users.PasswordToken do
  use Ecto.Schema
  alias Crit.Users.User
  alias Crit.EmailToken
  alias Crit.Repo
  import Ecto.Changeset
  import Ecto.Query

  schema "password_tokens" do
    field :text, :string
    belongs_to :user, User

    timestamps()
  end

  def suitable_text(), do: EmailToken.generate()
  def unused(), do: %__MODULE__{text: suitable_text()}


  @expiration_in_seconds (7 * 24 * 60 * 60)

  def expiration_threshold(now \\ NaiveDateTime.utc_now) do
    NaiveDateTime.add(now, -1 * @expiration_in_seconds)
  end

  def delete_expired_tokens do
    query = 
      from r in __MODULE__,
      where: r.updated_at < ^expiration_threshold()
    Repo.delete_all(query)
  end

  def force_update(token, datetime) do
    for_postgres = NaiveDateTime.truncate(datetime, :second)

    change(token, updated_at: for_postgres) |> Repo.update
    :ok
  end




  # def user_from_unexpired_token(token_text) do
  #   Repo.delete_all(expired())
  #   query =
  #     from __MODULE__,
  #     where: [text: ^token_text],
  #     preload: [:user]

  #   row = Repo.one(query)
  #   if row do
  #     {:ok, row.user}
  #   else
  #     :error
  #   end
  # end

  defmodule Query do
    import Ecto.Query
    alias Crit.Users.PasswordToken

    def matching_user(token_text) do
      from u in User,
        join: pt in assoc(u, :password_token),
        where: pt.text == ^token_text
    end

    def by_user_id(user_id),
      do: from PasswordToken, where: [user_id: ^user_id]
  end


  
end
