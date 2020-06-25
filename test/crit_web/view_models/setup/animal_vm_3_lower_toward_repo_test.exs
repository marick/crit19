defmodule CritWeb.ViewModels.Setup.AnimalVM.LowerTowardRepoTest do
  use Crit.DataCase, async: true
  alias CritWeb.ViewModels.Setup, as: VM
  alias Crit.Setup.Schemas
  alias Crit.Exemplars.Bossie
  alias Ecto.Changeset
  alias Ecto.Datespan


  setup do
    repo =
      Bossie.create
      |> Bossie.put_service_gap(span: :first, name: "only_sg")
    no_changes =
      VM.Animal.fetch(:one_for_edit, repo.bossie.id, @institution)
      |> recursive_change

    [repo: repo, no_changes: no_changes]
  end

  describe "converting to a lowered changeset" do
    test "a changeset with no changes", %{repo: repo, no_changes: no_changes} do

      actual =
        no_changes
        |> VM.Animal.lower_changeset(repo.bossie.id, @institution)
        # The main result is a changeset for the lowered type with no
        # changes at all to the top-level fields.
        |> assert_unchanged([:name, :lock_version, :span, :service_gaps])
        |> assert_data(id: repo.bossie.id,
                       name: repo.bossie.name,
                       lock_version: repo.bossie.lock_version)

      # We have the right type.
      Changeset.apply_changes(actual)      
      |> assert_shape(%Schemas.Animal{})
      
      # There are no service-gap changesets. But the data has been converted
      # to the lower type.
      with_singleton(actual, :fetch_field!, :service_gaps)
         |> assert_shape(%Schemas.ServiceGap{})
         |> assert_field(id: repo.only_sg.id,
                         reason: repo.only_sg.reason,
                         span: repo.only_sg.span)
    end

    test "top level changes are used", %{repo: repo, no_changes: no_changes} do
      actual =
        no_changes
        |> Changeset.put_change(:out_of_service_datestring, @never)
        |> VM.Animal.lower_changeset(repo.bossie.id, @institution)

      expected_span =
        repo.bossie.span.first
        |> Datespan.inclusive_up

      actual
      |> assert_change(span: expected_span)
      |> assert_unchanged([:name, :lock_version, :service_gaps])
    end
    
    test "service gap changes are used", %{repo: repo, no_changes: no_changes} do
      no_changes
      |> only_service_gap_change(:reason, "!!!!")
      |> VM.Animal.lower_changeset(repo.bossie.id, @institution)

      |> assert_change(:service_gaps)
      |> assert_unchanged([:name, :lock_version, :span])

      # Unlike earlier tests, there is a changeset for the service gap
      |> with_singleton(:fetch_change!, :service_gaps)
         |> assert_shape(%Changeset{})
         |> assert_change(reason: "!!!!")
         |> assert_unchanged([:id, :span])
    end
    
    test "deletion of service gaps", %{repo: repo, no_changes: no_changes} do
      no_changes
      |> only_service_gap_change(:delete, true)
      |> VM.Animal.lower_changeset(repo.bossie.id, @institution)

      |> with_singleton(:fetch_change!, :service_gaps)
         |> assert_unchanged([:id, :span, :reason])
         |> assert_field(action: :delete)
    end
  end

  # ----------------------------------------------------------------------------

  # It's an assumed precondition that both the top-level AnimalVM *and* the
  # lower-level service gaps are changesets. `accept_form` guarantees that
  # in the code; this guarantees it here.
  defp recursive_change(%VM.Animal{} = animal) do
    top = change(animal)
    lower = Enum.map(animal.service_gaps, &Changeset.change/1)

    Changeset.put_change(top, :service_gaps, lower)
  end

  def only_service_gap_change(animal_changeset, field, value) do
    new_service_gap =
      animal_changeset
      |> Changeset.fetch_field!(:service_gaps)
      |> singleton_payload
      |> Changeset.put_change(field, value)
    
    Changeset.put_change(animal_changeset, :service_gaps, [new_service_gap])
  end
end
