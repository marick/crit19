defmodule Crit.Users.Password do
  use Ecto.Schema
  alias Crit.Users.User
  import Ecto.Changeset
  import Ecto.Query
  alias Crit.Repo
  alias Crit.Sql
  import Pile.Changeset

  schema "passwords" do
    field :hash, :string
    belongs_to :user, User, foreign_key: :auth_id, type: :string
    field :new_password, :string, virtual: true
    field :new_password_confirmation, :string, virtual: true

    timestamps()
  end

  @default_institution "critter4us"

  # A changeset with only default or empty fields. For `new` actions.
  def default_changeset(),
    do: change(%__MODULE__{}) |> hide([:hash, :auth_id])

  def create_changeset(password, attrs \\ %{}) do
    password
    |> cast(attrs, [:new_password, :new_password_confirmation])
    |> validate_required([:new_password, :new_password_confirmation])
    |> validate_password_length(:new_password)
    |> validate_password_confirmation()
    |> put_password_hash()
  end


  # Util
  
  defp validate_password_length(changeset, field),
    do: validate_length(changeset, field, min: 8, max: 128)

  defp validate_password_confirmation(changeset) do
    password = changeset.changes[:new_password]
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
  def count_for(auth_id, institution) do
    query =
      from p in __MODULE__,
      where: p.auth_id == ^auth_id,
      select: count(p.id)
    Sql.one(query, institution)
  end


  defmodule Query do
    import Ecto.Query
    alias Crit.Users.Password

    def by_auth_id(auth_id) do
      from p in Password,
        where: p.auth_id == ^auth_id
    end
      
    # This seems ridiculously overcomplicated, but I can't make 
    # a plain preload work without the join.
    def preloading_user(query) do
      query
      |> join(:inner, [p], u in User, on: p.auth_id == u.auth_id)
      |> preload([p, u], [user: u])
    end

  end
  

end
