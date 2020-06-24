defmodule CritWeb.ViewModels.Setup.AnimalVM.UpdateTest do
  use Crit.DataCase, async: true
  alias CritWeb.ViewModels.Setup, as: VM
  alias Crit.Setup.Schemas
  import Crit.Exemplars.Bossie
  import Crit.RepoState
  alias Ecto.Changeset
  alias Crit.Setup.AnimalApi2, as: AnimalApi

  setup do
    repo =
      empty_repo(@bovine_id)
      |> animal("Bossie", available: maximum_customary_span())
      |> animal("Not_bossie", available: maximum_customary_span())
      |> shorthand
    [repo: repo]
  end

  # Note: any service gap errors should be impossible at this point, 
  # so we don't bother with service gaps. Changes to service gaps
  # are tested in more end-to-end tests.

  test "simple change: returns Animal ready to display", %{repo: repo} do
    changeset_with_change(repo.bossie.id, :name, "ossie")
    |> VM.Animal.update(@institution)
    |> ok_payload
    |> assert_shape(%VM.Animal{})
    |> assert_field(name: "ossie")
  end

  test "trying to rename an animal to an existing animal", %{repo: repo} do
    assert {:error, :constraint, changeset} = 
      changeset_with_change(repo.not_bossie.id, :name, "Bossie")
      |> VM.Animal.update(@institution)

    assert_error(changeset, name: @already_taken)
  end


  test "conflicting updates", %{repo: repo} do
    first = changeset_with_change(repo.bossie.id, :name, "first")
    second = changeset_with_change(repo.bossie.id, :name, "second")

    {:ok, _} = VM.Animal.update(first, @institution)
    
    assert {:error, :constraint, changeset} = 
      VM.Animal.update(second, @institution)

    assert_error(changeset, :optimistic_lock_error)
    
  end

  # ----------------------------------------------------------------------------

  defp changeset_with_change(id, field, value) do
    AnimalApi.one_by_id(id, @institution, preloads: [:service_gaps])
    |> Schemas.Animal.changeset(%{})
    |> Changeset.put_change(field, value)
  end
end
