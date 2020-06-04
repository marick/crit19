defmodule CritWeb.ViewModels.FieldFillers.ToWeb do
  use Ecto.Schema
  alias Ecto.Datespan

  def service_datestrings(current, %Datespan{} = span) do
    %{current |
       in_service_datestring: Datespan.first_to_string(span), 
       out_of_service_datestring: Datespan.last_to_string(span)
    }
  end
end  
