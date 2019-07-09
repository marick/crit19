defmodule Crit.Users do
  import Ecto.Query, warn: false
  alias Crit.Repo
  import Ecto.Changeset

  alias Crit.Users.User
  alias Crit.Users.PasswordToken
  alias Crit.Users.Password


  def user_needing_activation(params) do
    User.create_changeset(params)
    |> put_change(:password_token, PasswordToken.unused())
    |> Repo.insert()
  end

  def user_id_from_token(token_text) do
    case Repo.get_by(PasswordToken, text: token_text) do
      %PasswordToken{user_id: user_id} ->
        {:ok, user_id}
      nil ->
        :error
    end
  end

  def fresh_password_changeset(),
    do: change(%Password{})
      
  def set_password(auth_id, params) do
    result =
      %Password{auth_id: auth_id}
      |> Password.changeset(params)
      |> Repo.insert(on_conflict: :replace_all, conflict_target: :auth_id)
    case result do
      {:ok, _} -> :ok
    end
  end

  def check_password(auth_id, proposed_password) do
    password = Repo.get_by(Password, auth_id: auth_id)
    if password && Pbkdf2.verify_pass(proposed_password, password.hash) do
      :ok
    else
      Pbkdf2.no_user_verify()
      :error
    end
  end
end
