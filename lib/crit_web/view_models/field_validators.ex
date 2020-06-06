defmodule CritWeb.ViewModels.FieldValidators do
  import Ecto.Changeset
  alias Ecto.ChangesetX
  use Crit.Errors

  def date_order(changeset) do
    [in_service, out_of_service] =
      changeset
      |> ChangesetX.values([:in_service_datestring, :out_of_service_datestring])
        
    case in_service < out_of_service do  # Works: ISO8601
      true ->
        changeset
      false ->
        add_error(changeset, :out_of_service_datestring, @date_misorder_message)
    end
  end
end
