defmodule Crit.Users.Schemas.User do
  use Ecto.Schema
  import Ecto.Changeset
  alias Crit.Users.Schemas.PermissionList
  alias Crit.Ecto.TrimmedString

  schema "users" do
    field :auth_id, TrimmedString
    field :display_name, TrimmedString
    field :email, TrimmedString
    field :active, :boolean, default: true
    has_one :permission_list, PermissionList

    timestamps()
  end

  # These are up here to make it more likely they'll be changed when the schema is.
  @creation_required_attrs [:display_name, :auth_id, :email]
  @creation_optional_attrs []


  def fresh_user_changeset(),
    do: changeset(%__MODULE__{permission_list: %PermissionList{}}, %{})

  def creation_changeset(attrs) do
    changeset(%__MODULE__{}, attrs)
  end

  def changeset(%__MODULE__{} = struct, attrs) do 
    struct
    |> check_attrs(@creation_required_attrs, @creation_optional_attrs, attrs)
    |> cast_assoc(:permission_list, required: true)
  end

  # Util


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
end
