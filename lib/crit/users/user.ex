defmodule Crit.Users.User do
  use Ecto.Schema
  import Ecto.Changeset
  alias Crit.Users.PermissionList
  alias Crit.Users.PasswordToken

  schema "users" do
    field :auth_id, :string
    field :display_name, :string
    field :email, :string
    field :active, :boolean, default: true
    has_one :permission_list, PermissionList
    has_one :password_token, PasswordToken

    timestamps()
  end

  @creation_required_attrs [:display_name, :auth_id, :email]
  @creation_optional_attrs []

  defp check_attr(:email = field, changeset) do
    changeset
    |> validate_length(field, min: 5, max: 100, count: :codepoints)
  end

  defp check_attr(:auth_id = field, changeset) do
    changeset
    |> validate_length(field, min: 5, max: 100, count: :codepoints)
    |> unique_constraint(field, name: :unique_auth_id)
  end

  defp check_attr(:display_name = field, changeset) do 
    changeset
    |> validate_length(field, min: 2, max: 100, count: :codepoints)
  end

  defp check_attr(_, changeset), do: changeset

  # Util
  defp check_attrs(user, required_attrs, optional_attrs, attrs) do
    all_fields = required_attrs ++ optional_attrs
    changeset =
      user
      |> cast(attrs, all_fields)
      |> validate_required(required_attrs)
    Enum.reduce(Map.keys(changeset.changes), changeset, &check_attr/2)
  end

  def changeset(struct, attrs \\ %{}) do
    struct
    |> cast(attrs, [:display_name, :auth_id, :email])
    |> cast_assoc(:permission_list)
  end

  def create_changeset(attrs \\ %{}) do
    %__MODULE__{}
    |> cast(attrs, [:display_name, :auth_id, :email])
    |> check_attrs(@creation_required_attrs, @creation_optional_attrs, attrs)
    |> cast_assoc(:permission_list, required: true)
  end
end
