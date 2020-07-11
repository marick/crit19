defmodule CritBiz.ViewModels.Setup.ProcedureVM.ValidationTest do
  use Crit.DataCase, async: true
  alias CritBiz.ViewModels.Setup, as: VM

  @valid_entry %{
    "name" => "haltering",
    "species_ids" => [to_string(@bovine_id)],
    "frequency_id" => "32"
  }

  @blank_entry %{
    "name" => "",
    # no value for this parameter will be sent by the browser.
    "frequency_id" => "32"
  }

  defp make_params(entries) do
    entries
    |> Enum.with_index
    |> Enum.map(fn {entry, index} ->
         key = to_string(index)
         value = Map.put(entry, "index", to_string(index))
         {key, value}
       end)
   |> Map.new
  end

  # ----------------------------------------------------------------------------
  describe "successful form validation" do
    test "validation of one procedure" do
      params = make_params([@valid_entry])

      [only] = VM.BulkProcedure.accept_form(params) |> ok_payload

      only
      |> assert_valid
      |> assert_change(name: "haltering",
                       species_ids: [@bovine_id],
                       frequency_id: 32)
    end

    test "an empty procedure doesn't turn into a changeset" do
      params = make_params([@blank_entry])

      assert [] = VM.BulkProcedure.accept_form(params) |> ok_payload
    end

    test "the empty procedure doesn't have to be at the end" do
      params = make_params([@blank_entry, @valid_entry])

      assert [only] = VM.BulkProcedure.accept_form(params) |> ok_payload
      only
      |> assert_valid
      |> assert_change(name: "haltering",
                       species_ids: [@bovine_id],
                       frequency_id: 32)
    end

    test "procedure names are trimmed" do
      params = [Map.put(@valid_entry, "name", " proc  ")] |> make_params
      assert [only] = VM.BulkProcedure.accept_form(params) |> ok_payload

      only
      |> assert_valid
      |> assert_change(name: "proc")
    end
    
  end

  describe "errors" do
    test "name must be present" do
      params = [Map.put(@valid_entry, "name", "   ")] |> make_params
      assert [only] = VM.BulkProcedure.accept_form(params) |> error2_payload(:form)

      only
      |> assert_invalid
      |> assert_change(species_ids: [@bovine_id],
                       frequency_id: 32,
                       index: 0)
      |> assert_error(name: @blank_message)

    end
    
    test "species_ids must be present" do
      params = [Map.delete(@valid_entry, "species_ids")] |> make_params
      assert [only] = VM.BulkProcedure.accept_form(params) |> error2_payload(:form)

      only
      |> assert_invalid
      |> assert_change(name: "haltering",
                       frequency_id: 32,
                       index: 0)
      |> assert_error(species_ids: @at_least_one_species)
    end

    test "blank fields are retained when there are errors" do
      params = make_params([
        @blank_entry,
        Map.put(@valid_entry, "name", ""),
        @blank_entry
      ])

      assert [blank1, only, blank2] =
        VM.BulkProcedure.accept_form(params)
        |> error2_payload(:form)

      only
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
end
