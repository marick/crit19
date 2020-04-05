defmodule Crit.Assertions.ChangesetTest do
  use Crit.DataCase, async: true
  use Ecto.Schema
  import Crit.Assertions.{Changeset, Assertion}
  alias Crit.Users.Schemas.{PermissionList,User}
  alias Crit.Users.UserApi

  embedded_schema do
    field :name, :string
    field :tags, {:array, :string}
  end

  def changeset(thing, attrs) do
    thing
    |> cast(attrs, [:name, :tags])
    |> validate_required([:name])
  end

  setup do
    [valid: %__MODULE__{name: "Bossie", tags: ["cow"]}]
  end

  test "pure booleans" do
    changeset(%__MODULE__{}, %{})
    |> assert_invalid

    changeset(%__MODULE__{}, %{name: "Bossie"})
    |> assert_valid
  end

  describe "changes" do
    test "successful checking for change existence", %{valid: valid} do
      changeset(valid, %{name: "new", tags: []})
      |> assert_changes(name: "new", tags: [])
      # don't have to give a value
      |> assert_changes([:name, :tags])
      # fields don't have to be mentioned
      |> assert_changes(name: "new")
      |> assert_changes([:name])
      # assert_change variant
      |> assert_change(:name)
    end

    test "failure cases", %{valid: valid} do 
      assertion_fails_with_diagnostic(
        "Field `:name` is missing",
        fn -> 
          changeset(valid, %{name: valid.name})
          |> assert_changes(name: valid.name)
        end)
      
      assertion_fails_with_diagnostic(
        ["`:name` has the wrong value",
         "wrong new name",
         "right new name"],
        fn -> 
          changeset(valid, %{name: "wrong new name"})
          |> assert_changes(name: "right new name")
        end)

      assertion_fails_with_diagnostic(
        ["Field `:name` is missing"],
        fn -> 
          changeset(valid, %{name: valid.name})
          |> assert_change(:name)
        end)
    end
  end

  describe "lack of changes" do
    test "assert no changes anywhere", %{valid: valid} do
      changeset(valid, %{tags: "wrong"})
      |> assert_invalid
      |> assert_no_changes

      assertion_fails_with_diagnostic(
        "Fields have changed: `[:tags]`",
        fn -> 
          changeset(valid, %{tags: ["tag"]})
          |> assert_no_changes
        end)
    end

    test "assert particular values are unchanged", %{valid: valid} do
      changeset(valid, %{name: "new name"})
      |> assert_valid
      |> assert_unchanged([:tags])
      |> assert_unchanged(:tags)

      assertion_fails_with_diagnostic(
        "Field `:name` has changed",
        fn -> 
          changeset(valid, %{name: "new name"})
          |> assert_unchanged([:name])
        end)
    end

    test "will object to an impossible field", %{valid: valid} do
      assertion_fails_with_diagnostic(
        ["Test error: there is no key `:gorp` in Crit.Assertions.ChangesetTest"],
        fn -> 
          changeset(valid, %{})
          |> assert_unchanged([:gorp, :foop])
        end)
    end
    
  end
  
  describe "the existence of errors" do
    test "yes, the error is there", %{valid: valid} do
      changeset(valid, %{tags: "wrong", name: ""})
      |> assert_errors([:tags, :name])
      # You don't have to speak to all errors
      |> assert_errors([:tags])
      |> assert_errors([:name])

      # assert_error variant
      |> assert_error(:tags)
      |> assert_error([:tags])
    end
      
    test "there is no error at all", %{valid: valid} do
      assertion_fails_with_diagnostic(
        "There are no errors for field `:name`", 
        fn -> 
          changeset(valid, %{name: "new name"})
          |> assert_error(:name)
        end)
    end

    test "that field doesn't have an error", %{valid: valid} do 
      assertion_fails_with_diagnostic(
        "There are no errors for field `:name`", 
        fn -> 
          changeset(valid, %{tags: "wrong"})
          |> assert_error(:name)
        end)
    end
  end    
    
  describe "specific error messages" do
    test "yes, the error is there", %{valid: valid} do
      changeset(valid, %{tags: "wrong", name: ""})
      |> assert_error(tags: "is invalid")
      |> assert_error(name: "can't be blank")
      |> assert_error(
           tags: "is invalid",
           name: "can't be blank")
    end
      
    test "there is no error at all", %{valid: valid} do
      assertion_fails_with_diagnostic(
        "There are no errors for field `:tags`", 
        fn -> 
          changeset(valid, %{name: "new name"})
          |> assert_error(tags: "is invalid")
        end)
    end

    test "that field doesn't have an error", %{valid: valid} do
      assertion_fails_with_diagnostic(
        "There are no errors for field `:name`",
        fn -> 
          changeset(valid, %{tags: "wrong"})
          |> assert_error(name: "can't be blank")
        end)
    end

    test "that field has a different error", %{valid: valid} do
      assertion_fails_with_diagnostic(
        ["`:tags` is missing an error message",
         "this is not the actual error message",
         "is invalid"],
        fn -> 
          changeset(valid, %{tags: "wrong"})
          |> assert_error(tags: "this is not the actual error message")
        end)
    end

    test "you can ask for all of a list of errors", %{valid: valid} do 
      cs =
        changeset(valid, %{tags: "wrong"})
        |> add_error(:tags, "added error 1")
        |> add_error(:tags, "not checked")

      cs 
      |> assert_error(tags: "added error 1")
      |> assert_error(tags: ["is invalid", "added error 1"])

      assertion_fails_with_diagnostic(
        ["`:tags` is missing an error message",
         "not present",
         ~r[not checked.*added error 1.*is invalid"]
        ],
        fn ->
          cs
          |> assert_error(tags: ["is invalid", "not present"])
        end)
    end
  end

  describe "asserting there is no error" do
    test "success case", %{valid: valid} do
      changeset(valid, %{})
      |> assert_valid
      |> assert_error_free([:tags, :name])
      |> assert_error_free( :tags)
    end

    test "field does have an error", %{valid: valid} do
      assertion_fails_with_diagnostic(
        ["There is an error for field `:tags`"],
        fn -> 
          changeset(valid, %{tags: "bogus"})
          |> assert_invalid
          |> assert_error_free(:tags)
        end)
    end

    test "will object to an impossible field", %{valid: valid} do
      assertion_fails_with_diagnostic(
        ["Test error: there is no key `:gorp` in Crit.Assertions.ChangesetTest"],
        fn -> 
          changeset(valid, %{tags: "bogus"})
          |> assert_error_free(:gorp)
        end)
    end
  end

  describe "testing the data part" do
    test "equality comparison", %{valid: valid} do
      changeset(valid, %{})
      |> assert_data(name: valid.name)
      |> assert_data(tags: valid.tags)
      |> assert_data(name: valid.name, tags: valid.tags)
    end

    test "shape comparison" do
      assert %PermissionList{}.view_reservations == true # default

      (fresh = UserApi.fresh_user_changeset)
      |> assert_data_shape(:permission_list, %{})
      |> assert_data_shape(:permission_list, %PermissionList{})
      |> assert_data_shape(:permission_list,
                           %PermissionList{view_reservations: true})

      assertion_fails_with_diagnostic(
        ["The value doesn't match the given pattern"],
        fn -> 
          assert_data_shape(fresh, :permission_list, %User{})
        end)
      
      assertion_fails_with_diagnostic(
        ["The value doesn't match the given pattern"],
        fn -> 
          assert_data_shape(fresh, :permission_list,
            %PermissionList{view_reservations: false})
        end)
    end
  end
end
