defmodule CritWeb.ViewModels.FieldFillers.FromWeb do
  use Ecto.Schema
  alias Ecto.Datespan

  def span(data) do
    Datespan.customary(
      Date.from_iso8601!(data.in_service_datestring),
      Date.from_iso8601!(data.out_of_service_datestring))
    
  end
end
