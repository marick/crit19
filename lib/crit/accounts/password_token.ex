defmodule Crit.Accounts.PasswordToken do
  use Ecto.Schema
  import Ecto.Query
  alias Crit.Repo
  alias Crit.Accounts.User

  schema "password_tokens" do
    field :token, :string
    belongs_to :user, User

    timestamps()
  end

  @expiration_in_seconds (7 * 24 * 60 * 60)

  def expiration_threshold(now \\ NaiveDateTime.utc_now) do
    NaiveDateTime.add(now, -1 * @expiration_in_seconds)
  end

  def expired do
    from r in __MODULE__,
      where: r.inserted_at < ^expiration_threshold()
  end


  def user_from_unexpired_token(token) do
    Repo.delete_all(expired())
    query =
      from __MODULE__,
      where: [token: ^token],
      preload: [:user]

    row = Repo.one(query)
    if row do
      Repo.delete(row)    # tokens are single-use
      {:ok, row.user}
    else
      :error
    end
  end
end
