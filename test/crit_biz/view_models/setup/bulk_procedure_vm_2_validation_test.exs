defmodule CritBiz.ViewModels.Setup.ProcedureVM.ValidationTest do
  use Crit.DataCase, async: true
  alias CritBiz.ViewModels.Setup, as: VM
  alias Crit.Exemplars.Params.BulkProcedures, as: Params

  # ----------------------------------------------------------------------------
  describe "successful form validation" do
    test "validation of one procedure" do
      Params.bulk(:valid)
      |> becomes_correct_singleton
      |> assert_changes(Params.as_cast(:valid))
    end

    test "an empty subform doesn't turn into a changeset" do
      params = Params.bulk(:blank)
      assert VM.BulkProcedure.accept_form(params) == {:ok, []}
    end

    test "the empty procedure doesn't have to be at the end" do
      params = Params.bulk([:blank, :valid])

      assert [only] = becomes_correct(params)
      assert_change(only, Params.as_cast(:valid))
    end

    test "procedure names are trimmed" do
      params = Params.bulk(:valid,      except: %{"name" => " proc  "})
      expected = Params.as_cast(:valid, except: %{name:      "proc"})

      params
      |> becomes_correct_singleton
      |> assert_change(expected)
    end
  end

  describe "errors" do
    test "name must be present" do
      Params.bulk(:valid, except: %{"name" => "   "})
      |> becomes_incorrect_singleton
      |> assert_unchanged(:name)  # the string is trimmed to its original "" value
      |> assert_error(name: @blank_message)

      |> assert_change(Params.as_cast(:valid, without: [:name]))
    end
    
    test "species_ids must be present" do
      Params.bulk(:valid, deleting: ["species_ids"])
      |> becomes_incorrect_singleton
      |> assert_error(species_ids: @at_least_one_species)

      |> assert_change(Params.as_cast(:valid, without: [:species_ids]))
    end

    @tag :skip
    test "blank fields are retained when there are errors" do
      params = Params.bulk([
        :blank,
        [:valid, except: [name: ""]],
         :blank
        ])

      assert [blank1, wrong, blank2] = becomes_incorrect(params)

      wrong
      |> assert_invalid
      |> assert_error(name: @blank_message)
      |> assert_change(species_ids: [@bovine_id], index: 1)

      blank1
      |> assert_valid
      |> assert_change(index: 0)
      |> assert_unchanged(:name)
      
      blank2
      |> assert_valid
      |> assert_change(index: 2)
      |> assert_unchanged(:name)
    end
  end

  # ----------------------------------------------------------------------------

  defp becomes_correct(params) do 
    changesets = VM.BulkProcedure.accept_form(params) |> ok_payload
    for c <- changesets, do: assert_valid(c)
    changesets
  end

  defp becomes_correct_singleton(params),
    do: becomes_correct(params) |> singleton_payload

  def becomes_incorrect(params) do
    VM.BulkProcedure.accept_form(params) |> error2_payload(:form)
  end

  def becomes_incorrect_singleton(params) do
    becomes_incorrect(params)
    |> singleton_payload
    |> assert_invalid
  end
end
