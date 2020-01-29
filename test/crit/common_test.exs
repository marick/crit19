defmodule Crit.CommonTest do 
  use Crit.DataCase, async: true
  alias Crit.Common

  test "standard processing for nested forms" do
    filled_in = %{"subfield" => "some value"}
    blank = %{"subfield" => " "}

    enclosing_form = %{
      "subforms" => %{"0" => filled_in,
                      "1" => blank}
    }

    result = Common.filter_out_unstarted_subforms(enclosing_form, "subforms", ["subfield"])

    assert result == %{"subforms" => [filled_in]}
  end

  test "standard processing for arrays of ids" do
    input = %{"animal_ids" => %{"0" => "true", "5" => "true"},
              "other" => "5"}
    actual = Common.make_id_array(input, "animal_ids")

    assert actual["other"] == "5"
    assert_lists_equal(["0", "5"], actual["animal_ids"])
  end
end
