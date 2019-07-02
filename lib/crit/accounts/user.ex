defmodule Crit.Accounts.User do
  use Ecto.Schema
  import Ecto.Changeset
  alias Crit.Repo
  alias Crit.Accounts.PasswordToken

  @no_password_hash "never set"
  def no_password_hash, do: @no_password_hash
  def has_password_hash?(user), do: user.password_hash != @no_password_hash
  

  schema "users" do
    field :display_name, :string
    field :auth_id, :string
    field :email, :string
    # Note: for some organizations, the auth_id and display email may be the same.
    field :password, :string, virtual: true
    field :new_password, :string, virtual: true
    field :new_password_confirmation, :string, virtual: true
    field :password_hash, :string, default: @no_password_hash
    field :active, :boolean, default: true
    has_one :password_token, PasswordToken

    timestamps()
  end

  @creation_required_attrs [:display_name, :auth_id, :email]
  @creation_optional_attrs [:active]

  @update_required_attrs [:display_name, :email, :active]
  @update_optional_attrs [:password, :new_password, :new_password_confirmation]

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

  defp check_attr(:password = field, changeset) do 
    changeset
    |> validate_password_length(field)
  end

  defp check_attr(:new_password = field, changeset) do
    changeset
    |> validate_password_length(field)
    |> validate_password_confirmation
    |> put_password_hash
  end

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

  defp put_password_hash(changeset) do
    case changeset do
      %Ecto.Changeset{valid?: true, changes: %{new_password: pass}} ->
        put_change(changeset, :password_hash, Pbkdf2.hash_pwd_salt(pass))
      _ ->
        changeset
    end
  end

  defp put_password_token(changeset), do:
    put_change(changeset, :password_token, %{text: PasswordToken.suitable_text()})

  def authenticate_user(auth_id, proposed_password) do
    user = Repo.get_by(__MODULE__, auth_id: auth_id)

    if user && Pbkdf2.verify_pass(proposed_password, user.password_hash) do
      {:ok, user}
    else
      Pbkdf2.no_user_verify()
      :error
    end
  end

  # Util
  defp check_attrs(user, required_attrs, optional_attrs, attrs) do
    all_fields = required_attrs ++ optional_attrs
    changeset =
      user
      |> cast(attrs, all_fields)
      |> validate_required(required_attrs)
    Enum.reduce(Map.keys(changeset.changes), changeset, &check_attr/2)
  end

  def create_changeset(attrs) do
    %__MODULE__{}
    |> check_attrs(@creation_required_attrs, @creation_optional_attrs, attrs)
    |> put_password_token
  end
    
  def update_changeset(user, attrs) do
    user
    |> check_attrs(@update_required_attrs, @update_optional_attrs, attrs)
  end

  def edit_changeset(user) do
    check_attrs(user, @creation_required_attrs, @creation_optional_attrs, %{})
  end
end
