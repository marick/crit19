defmodule CritBiz.ViewModels.Setup.AnimalVM.UpdateTest do
  use Crit.DataCase, async: true
  alias CritBiz.ViewModels.Setup, as: VM
  alias Crit.Schemas
  alias Crit.Exemplars, as: Ex
  import Crit.RepoState
  alias Ecto.Changeset

  setup do
    repo =
      Ex.Bossie.create
      |> animal("Not_bossie")
      |> shorthand

    [repo: repo]
  end

  # Note: any service gap errors should be impossible at this point, 
  # so we don't bother with service gaps. Changes to service gaps
  # are tested in more end-to-end tests.

  test "simple change: returns Animal ready to display", %{repo: repo} do
    changeset_with_change(repo.bossie.id, :name, "ossie")
    |> VM.Animal.update(@institution)
    |> ok_content
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
    change_first = changeset_with_change(repo.bossie.id, :name, "first change")
    change_second = changeset_with_change(repo.bossie.id, :name, "blocked")

    assert {:ok, _} = VM.Animal.update(change_first, @institution)
    
    assert {:error, :optimistic_lock, id} = 
      VM.Animal.update(change_second, @institution)

    assert id == repo.bossie.id
  end

  # ----------------------------------------------------------------------------

  defp changeset_with_change(id, field, value) do
    Schemas.Animal.Get.one_by_id(id, @institution, preloads: [:service_gaps])
    |> Schemas.Animal.changeset(%{})
    |> Changeset.put_change(field, value)
  end
end
