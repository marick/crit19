defmodule Crit.Assertions.Form do
  use Crit.TestConstants
  import Crit.Assertions.Defchain
  import ExUnit.Assertions
  use PhoenixIntegration

  def form_inputs(conn, description), do: fetch_form(conn).inputs[description]

  defchain assert_form_matches(inputs, [view_model: old_vm, in: keys]) do
    expected = Map.from_struct(old_vm)
    
    for key <- keys do
      assert assert_field_equal(inputs[key], expected[key])
    end
  end

  defp assert_field_equal(left, right),
    do: assert to_string(left) == to_string(right)
    

  def subform(inputs, field, index), do: inputs[field][symbolize_index(index)]
  defp symbolize_index(index), do: to_string(index) |> String.to_atom


  def numbered_subforms(inputs, field), do: Map.values(inputs[field])
end  

