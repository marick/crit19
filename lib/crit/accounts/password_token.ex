defmodule Crit.Accounts.PasswordToken do
  use Ecto.Schema
  import Ecto.Query
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
end
