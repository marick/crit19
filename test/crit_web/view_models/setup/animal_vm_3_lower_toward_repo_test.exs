defmodule CritWeb.ViewModels.Setup.AnimalVM.LowerTowardRepoTest do
  use Crit.DataCase, async: true
  alias CritWeb.ViewModels.Setup, as: VM
  alias Crit.Setup.Schemas
#  alias Crit.Setup.AnimalApi2, as: AnimalApi
  import Crit.Exemplars.RepoState
  import Crit.RepoState
  alias Ecto.Changeset

  setup :repo_has_bossie

  setup %{repo: repo} do
    repo =
      repo
      |> service_gap_for("Bossie", name: "only_sg", starting: @date_2, ending: @date_3)
      |> shorthand
    no_changes =
      VM.Animal.fetch(:one_for_edit, repo.bossie.id, @institution)
      |> recursive_change

    [repo: repo, no_changes: no_changes]
  end

  describe "converting to a lowered changeset" do
    test "a changeset with no changes", %{repo: repo, no_changes: start} do

      actual = 
        VM.Animal.lower_changeset(repo.bossie.id, start, @institution)

      # The main result is a changeset for the lowered type with no changes at all
      # to the top-level fields.
      actual 
      |> assert_unchanged([:name, :lock_version, :span, :service_gaps])
      |> assert_data(id: repo.bossie.id,
                     name: repo.bossie.name,
                     lock_version: repo.bossie.lock_version)

      # We have the right type.
      Changeset.apply_changes(actual)      
      |> assert_shape(%Schemas.Animal{})
      
      # There's no service-gap changesets. But the data has been converted
      # to the lower type.
      
      underlying_sg = 
        actual |> Changeset.fetch_field!(:service_gaps) |> singleton_payload

      underlying_sg
      |> assert_shape(%Schemas.ServiceGap{})
      |> assert_field(id: repo.only_sg.id,
                     reason: repo.only_sg.reason,
                     span: repo.only_sg.span)
    end

    # test "top level changes are used", %{repo: repo, no_changes: start} do
    # end
    
    # test "service gap changes are used", %{repo: repo, no_changes: start} do
    # end
    
    # test "deletion of service gaps", %{repo: repo, no_changes: start} do
    # end
    
  end

  # It's an assumed precondition that both the top-level AnimalVM *and* the
  # lower-level service gaps are changesets. `accept_form` guarantees that
  # in the code; this guarantees it here.
  defp recursive_change(%VM.Animal{} = animal) do
    top = change(animal)
    lower = Enum.map(animal.service_gaps, &Changeset.change/1)

    Changeset.put_change(top, :service_gaps, lower)
  end
end
