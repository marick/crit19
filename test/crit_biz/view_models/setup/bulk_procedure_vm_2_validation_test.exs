defmodule CritBiz.ViewModels.Setup.ProcedureVM.ValidationTest do
  use Crit.DataCase, async: true
  alias CritBiz.ViewModels.Setup, as: VM
  alias Crit.Exemplars.Params.BulkProcedures, as: Params


  # ----------------------------------------------------------------------------
  test "the representative kinds of forms" do
    Params.check_form_validation(categories: [:invalid])
    Params.check_form_validation(categories: [:valid, :filled])
    Params.check_form_validation(categories: [:valid, :blank],
      result: Params.discarded)
  end
  
  describe "successful form validation" do
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
    test "blank fields are retained when there are errors" do
      actual =
        Params.that_are([
          :all_blank,
          :blank_with_species,
          :valid,
          :name_but_no_species
        ])
        |> become_incorrect
      
      assert [all_blank, blank_with_species, valid, invalid] = actual

      :form_checking
      |> Params.validate(:all_blank, all_blank)
      |> Params.validate(:blank_with_species, blank_with_species)
      |> Params.validate(:valid, valid)
      |> Params.validate(:name_but_no_species, invalid)
    end
  end

  describe "numbering" do 
    # Empty changesets are numbered to make processing a little easier.
    # This numbering is retained (as are blank forms) when there's an
    # error.

    test "numbering is retained when there are errors" do
      actual =
        Params.that_are([:valid, :all_blank, :name_but_no_species])
        |> become_incorrect
      
      assert [0, 1, 2] == Enum.map(actual, &(ChangesetX.new!(&1, :index)))
    end
  end

  # ----------------------------------------------------------------------------

  defp become_correct(params) do 
    changesets = VM.BulkProcedure.accept_form(params) |> ok_content
    for c <- changesets, do: assert_valid(c)
    changesets
  end

  defp become_correct_singleton(params),
    do: become_correct(params) |> singleton_content

  defp become_incorrect(params) do
    VM.BulkProcedure.accept_form(params) |> error2_content(:form)
  end
end
