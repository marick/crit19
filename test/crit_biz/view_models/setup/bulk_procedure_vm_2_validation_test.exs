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
      params = Params.that_are(:blank)
      assert VM.BulkProcedure.accept_form(params) == {:ok, []}
    end

    test "the empty procedure doesn't have to be at the end" do
      params = Params.that_are([:blank, :valid])

      assert [only] = become_correct(params)
      assert_change(only, Params.as_cast(:valid))
    end

    test "procedure names are trimmed" do
      params = Params.that_are(:valid,  except: %{"name" => " proc  "})
      expected = Params.as_cast(:valid, except: %{name:      "proc"})

      params
      |> become_correct_singleton
      |> assert_change(expected)
    end
  end

  describe "errors" do     # name ^ not species
    test "species_ids must be present if the name is" do
      Params.that_are(:valid, deleting: ["species_ids"])
      |> become_incorrect_singleton
      |> assert_error(species_ids: @at_least_one_species)

      |> assert_change(Params.as_cast(:valid, without: [:species_ids]))
    end

    @tag :skip
    test "the name can be missing if the species id is present" do  #
      # ... so that a single button can select a species for N procedures"
      Params.that_are(:valid, except: %{"name" => ""})
      |> become_correct_singleton
      |> assert_change(Params.as_cast(:valid, without: [:name]))
    end

    @tag :skip
    test "blank fields are retained when there are errors" do
      params = Params.that_are([
        :blank,
        [:valid,  except: %{"name" => "different name"}],
        [:valid, except: %{"name" => ""}],
        [:valid, deleting: ["species_ids"]],
        :blank
      ])

      assert [blank1, valid, wrong, partly_blank, blank2] = become_incorrect(params)

      blank1
      |> assert_valid
      |> assert_unchanged(:name)
      |> assert_change(index: 0)

      valid
      |> assert_valid
      |> assert_change(species_id: [@bovine_id], name: "different name")
      |> assert_change(index: 1)
      
      wrong
      |> assert_invalid
      |> assert_error(name: @blank_message)
      |> assert_change(species_ids: [@bovine_id])
      |> assert_change(index: 2)

      partly_blank
      |> assert_valid
      |> assert_change(species_id: [@bovine_id])
      |> assert_unchanged(:name)
      |> assert_change(index: 3)

      blank2
      |> assert_valid
      |> assert_unchanged(:name)
      |> assert_change(index: 4)
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
