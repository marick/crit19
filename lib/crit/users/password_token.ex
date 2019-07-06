defmodule Crit.Users.PasswordToken do
  use Ecto.Schema
  import Ecto.Query
  alias Crit.Repo
  alias Crit.Users.User

  schema "password_tokens" do
    field :text, :string
    belongs_to :user, User

    timestamps()
  end

  def suitable_text(), do: Crit.Puid.generate()
  def unused(), do: %__MODULE__{text: suitable_text()}


  # @expiration_in_seconds (7 * 24 * 60 * 60)

  # def expiration_threshold(now \\ NaiveDateTime.utc_now) do
  #   NaiveDateTime.add(now, -1 * @expiration_in_seconds)
  # end

  # def expired do
  #   from r in __MODULE__,
  #     where: r.inserted_at < ^expiration_threshold()
  # end

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
end
