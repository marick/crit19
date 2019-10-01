defmodule Crit.Users.Internal.PasswordTest do
  use Crit.DataCase, async: true
  alias Crit.Users.Password
  alias Ecto.ChangesetX
  alias Faker.String
  alias Crit.Exemplars.PasswordFocused

  # Most tests are in ../password_test.exs

  test "a blank changeset" do
    assert changeset = Password.default_changeset()
    refute ChangesetX.represents_form_errors?(changeset)
    assert ChangesetX.empty_text_field?(changeset, :new_password)
    assert ChangesetX.empty_text_field?(changeset, :new_password_confirmation)
    # Be very sure confidential data doesn't leak
    assert ChangesetX.hidden?(changeset, :hash)
    assert ChangesetX.hidden?(changeset, :auth_id)
  end

  describe "kinds of errors" do
    test "missing values" do
      refute attempt_to_set("PASSWORD", nil).valid?
      refute attempt_to_set(nil, "PASSWORD").valid?
    end
    
    test "lower bound" do
      too_short = String.base64(7)
      just_right = String.base64(8)

      
      refute attempt_to_set(too_short, too_short).valid?
      assert attempt_to_set(just_right, just_right).valid?
    end

    test "upper bound" do
      just_right = String.base64(128)
      too_long = String.base64(129)
      
      refute attempt_to_set(too_long, too_long).valid?
      assert attempt_to_set(just_right, just_right).valid?
    end

    test "confirmation mismatch" do
      result = attempt_to_set("new password", "confirmation")

      assert %{new_password_confirmation: ["should be the same as the new password"]}
      == errors_on(result)
    end
  end

  def attempt_to_set(new_password, confirmation) do
    Password.create_changeset(
      Password.default_changeset(), PasswordFocused.params(new_password, confirmation)
    )
  end          
end
