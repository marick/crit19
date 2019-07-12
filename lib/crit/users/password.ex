defmodule Crit.Users.Password do
  use Ecto.Schema
  alias Crit.Users.User
  import Ecto.Changeset
  import Ecto.Query
  alias Crit.Repo

  schema "passwords" do
    field :hash, :string
    belongs_to :user, User, foreign_key: :auth_id, type: :string
    field :new_password, :string, virtual: true
    field :new_password_confirmation, :string, virtual: true
  end

  def changeset(password, attrs \\ %{}) do
    password
    |> cast(attrs, [:new_password, :new_password_confirmation])
    |> validate_password_length(:new_password)
    |> validate_password_confirmation()
    |> put_password_hash()
  end

  defp validate_password_length(changeset, field),
    do: validate_length(changeset, field, min: 8, max: 128)

  defp validate_password_confirmation(changeset) do
    password = changeset.changes.new_password

    # It's possible the confirmation field could be missing, so
    # we fail softly in that case.
    confirmation = changeset.changes[:new_password_confirmation]

    if password == confirmation do
      changeset
    else
      add_error(changeset, :new_password_confirmation,
        "should be the same as the new password")
    end
  end

  defp put_password_hash(changeset) do
    case changeset do
      %Ecto.Changeset{valid?: true, changes: %{new_password: pass}} ->
        put_change(changeset, :hash, Pbkdf2.hash_pwd_salt(pass))
      _ ->
        changeset
    end
  end

  # Utilities
  def count_for(auth_id) do
    query =
      from p in __MODULE__,
      where: p.auth_id == ^auth_id,
      select: count(p.id)
    Repo.one(query)
  end




end
