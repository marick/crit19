defmodule CritBiz.ViewModels.Setup.ProcedureVM.ValidationTest do
  use Crit.DataCase, async: true
  alias CritBiz.ViewModels.Setup, as: VM
  alias Crit.Exemplars.Params.BulkProcedures, as: Params

  # ----------------------------------------------------------------------------
  describe "successful form validation" do
    test "validation of one procedure" do
      Params.that_are(:valid)
      |> become_correct_singleton
      |> assert_changes(Params.as_cast(:valid))
    end

    test "an empty subform doesn't turn into a changeset" do
      params = Params.that_are(:all_blank)
      assert VM.BulkProcedure.accept_form(params) == {:ok, []}
    end

    test "the empty procedure doesn't have to be at the end" do
      params = Params.that_are([:all_blank, :valid])

      assert [only] = become_correct(params)
      assert_change(only, Params.as_cast(:valid))
    end

    test "procedure names are trimmed" do
      params = Params.that_are(:valid,  except: %{"name" => " proc  "})
      as_cast = Params.as_cast(:valid, except: %{name:      "proc"})

      params
      |> become_correct_singleton
      |> assert_change(as_cast)
    end
  end

  describe "errors" do     # name ^ not species
    test "species_ids must be present if the name is" do
      Params.that_are(:valid, deleting: ["species_ids"])
      |> become_incorrect_singleton
      |> assert_error(species_ids: @at_least_one_species)

      |> assert_change(Params.as_cast(:valid, without: [:species_ids]))
    end

    test "the name can be missing if the species id is present" do  #
      # ... so that a single button can select a species for N procedures"
      Params.that_are(:blank_with_species)
      |> become_correct
      |> assert_equal([])  # Blank forms are filtered out.
    end

    test "blank fields are retained when there are errors" do
      actual =
        Params.that_are([
          :all_blank,
          :blank_with_species,
          :valid,
          [:valid, deleting: ["species_ids"]],
        ])
        |> become_incorrect
      

      assert [all_blank, blank_with_species, valid, invalid_only_name] = actual

      all_blank
      |> assert_valid
      |> assert_unchanged([:name, :species_ids])
      |> assert_change(index: 0)

      blank_with_species
      |> assert_valid
      |> assert_unchanged(:name)
      |> assert_changes(Params.as_cast(:blank_with_species, without: [:name]))
      |> assert_change(index: 1)
      
      valid
      |> assert_valid
      |> assert_changes(Params.as_cast(:valid))
      |> assert_change(index: 2)

      invalid_only_name
      |> assert_invalid
      |> assert_unchanged(:species_ids)
      |> assert_change(name: "haltering")
      |> assert_change(index: 3)
    end
  end

  # ----------------------------------------------------------------------------

  defp become_correct(params) do 
    changesets = VM.BulkProcedure.accept_form(params) |> ok_payload
    for c <- changesets, do: assert_valid(c)
    changesets
  end

  defp become_correct_singleton(params),
    do: become_correct(params) |> singleton_payload

  def become_incorrect(params) do
    VM.BulkProcedure.accept_form(params) |> error2_payload(:form)
  end

  def become_incorrect_singleton(params) do
    become_incorrect(params)
    |> singleton_payload
    |> assert_invalid
  end
end
