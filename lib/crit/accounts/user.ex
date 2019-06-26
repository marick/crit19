defmodule Crit.Accounts.User do
  use Ecto.Schema
  import Ecto.Changeset

  schema "users" do
    field :active, :boolean, default: true
    field :email, :string
    field :name, :string
    field :password, :string, virtual: true
    field :password_hash, :string

    timestamps()
  end

  @creation_required_fields [:name, :email, :password]
  @creation_optional_fields [:active]


  defp change_field(changeset, :password = field) do
    changeset
    |> validate_length(field, min: 6, max: 100)
    |> put_password_hash
  end

  defp change_field(changeset, :email = field) do
    changeset
    |> validate_length(field, min: 5, max: 100, count: :codepoints)
    |> unique_constraint(field, name: :unique_active_email)
  end

  defp change_field(changeset, :name = field) do 
    changeset
    |> validate_length(field, min: 2, max: 100, count: :codepoints)
  end

  defp change_field(changeset, _), do: changeset

  
  defp put_password_hash(changeset) do
    case changeset do
      %Ecto.Changeset{valid?: true, changes: %{password: pass}} ->
        put_change(changeset, :password_hash, Pbkdf2.hash_pwd_salt(pass))
        
      _ ->
        changeset
    end
  end

  defp change_required_fields(user, required_fields, optional_fields, attrs) do
    all_fields = required_fields ++ optional_fields
    changeset =
      user
      |> cast(attrs, all_fields)
      |> validate_required(required_fields)
    Enum.reduce(all_fields, changeset, &(change_field &2, &1))
  end

  def create_changeset(attrs) do
    change_required_fields(
      %__MODULE__{},
      @creation_required_fields, @creation_optional_fields,
      attrs)
  end
    

  def changeset(user, attrs) do
    user
    |> cast(attrs, [:name, :email, :password_hash, :active])
    |> validate_required([:name, :email, :password, :active])
  end
end
