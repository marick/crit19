defmodule Crit.Assertions.ChangesetTest do
  use ExUnit.Case, async: true
  import Crit.Assertions.Changeset
  use Ecto.Schema
  import Ecto.Changeset

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
      exception = assert_raise ExUnit.AssertionError, fn -> 
        changeset(valid, %{name: valid.name})
        |> assert_changes(name: valid.name)
      end
      
      assert_raise ExUnit.AssertionError, fn -> 
        changeset(valid, %{name: "wrong new name"})
        |> assert_changes(name: "right new name")
      end
      
      assert_raise ExUnit.AssertionError, fn -> 
        changeset(valid, %{name: valid.name})
        |> assert_change(:name)
      end
    end
  end

  describe "lack of changes" do
    test "assert no anywhere changes", %{valid: valid} do
      changeset(valid, %{tags: "wrong"})
      |> assert_invalid
      |> assert_unchanged

      assert_raise ExUnit.AssertionError, fn -> 
        changeset(valid, %{tags: ["tag"]})
        |> assert_unchanged
      end
    end

    test "assert particular values are unchanged", %{valid: valid} do
      changeset(valid, %{name: "new name"})
      |> assert_valid
      |> assert_unchanged([:tags])
      |> assert_unchanged(:tags)

      assert_raise ExUnit.AssertionError, fn -> 
        changeset(valid, %{name: "new name"})
        |> assert_unchanged(:name)
      end
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
      assert_raise ExUnit.AssertionError, fn -> 
        changeset(valid, %{name: "new name"})
        |> assert_error(:name)
      end
    end

    test "that field doesn't have an error", %{valid: valid} do 
      assert_raise ExUnit.AssertionError, fn -> 
        changeset(valid, %{tags: "wrong"})
        |> assert_error(:name)
      end
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
      assert_raise ExUnit.AssertionError, fn -> 
        changeset(valid, %{name: "new name"})
        |> assert_error(tags: "is invalid")
      end
    end

    test "that field doesn't have an error", %{valid: valid} do 
      assert_raise ExUnit.AssertionError, fn -> 
        changeset(valid, %{tags: "wrong"})
        |> assert_error(name: "can't be blank")
      end
    end

    test "that field has a different error", %{valid: valid} do 
      assert_raise ExUnit.AssertionError, fn -> 
        changeset(valid, %{tags: "wrong"})
        |> assert_error(tags: "this is not the actual error message")
      end
    end

    test "you can ask for all of a list of errors", %{valid: valid} do 
      cs =
        changeset(valid, %{tags: "wrong"})
        |> add_error(:tags, "added error 1")
        |> add_error(:tags, "not checked")

      cs 
      |> assert_error(tags: "added error 1")
      |> assert_error(tags: ["is invalid", "added error 1"])

      assert_raise ExUnit.AssertionError, fn ->
        cs
        |> assert_error(tags: ["is invalid", "not present"])
      end
    end
  end
end

        
