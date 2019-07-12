defmodule Crit.Users.Internal.PasswordTest do
  use Crit.DataCase
  alias Crit.Users.Password
  alias Pile.Changeset

  # Most tests are in ../password_test.exs

  test "a blank changeset" do
    assert changeset = Password.fresh_password_changeset()
    refute Changeset.represents_form_errors?(changeset)
    assert Changeset.empty_text_field?(changeset, :new_password)
    assert Changeset.empty_text_field?(changeset, :new_password_confirmation)
    # Be very sure confidential data doesn't leak
    assert Changeset.hidden?(changeset, :hash)
    assert Changeset.hidden?(changeset, :auth_id)
  end
  

end
