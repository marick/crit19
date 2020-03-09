defmodule CritWeb.Setup.ProcedureView do
  use CritWeb, :view
  alias Ecto.Changeset
  alias CritWeb.ViewModels.Procedure.Creation  


  def creation_error_tag(%Changeset{} = changeset) do
    changeset.errors
    |> Keyword.get_values(:name)
    |> Enum.flat_map(&expand_error/1)
    |> IO.inspect
  end

  defp expand_error({message, _}) do
    IO.inspect message
    case message in Map.values(Creation.legit_error_messages) do
      true ->
        [~E"""
         <span class="ui pointing red basic label">
           <%= message %>
         </span>
        """] |> IO.inspect
      false ->
        []
    end
  end
end
