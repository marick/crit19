defmodule Crit.Exemplars.Params do
  use ExContract

  def put_nested(top_params, field, nary) when is_list(nary) do
    check is_binary(field)
    param_map = 
      nary
      |> Enum.with_index
      |> Enum.map(fn {lower_params, index} -> {to_string(index), lower_params} end)
      |> Map.new
    %{ top_params | field => param_map}
  end
end
