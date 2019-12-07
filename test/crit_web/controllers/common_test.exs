defmodule CritWeb.Controller.CommonTest do 
  use Crit.DataCase, async: true
  alias CritWeb.Controller.Common

  test "standard processing for nested forms" do
    filled_in = %{"subfield" => "some value"}
    blank = %{"subfield" => " "}

    enclosing_form = %{
      "subforms" => %{"0" => filled_in,
                      "1" => blank}
    }

    result = Common.process_upsert_subforms(enclosing_form, "subforms", ["subfield"])

    assert result == %{"subforms" => [filled_in]}
  end
end
