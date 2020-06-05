defmodule CritWeb.ViewModels.FieldFillers.ToWeb do
  use Ecto.Schema
  alias Ecto.Datespan
  alias Ecto.Association.NotLoaded

  def service_datestrings(current, %Datespan{} = span) do
    %{current |
       in_service_datestring: Datespan.first_to_string(span), 
       out_of_service_datestring: Datespan.last_to_string(span)
    }
  end

  def when_loaded(current, field, source, converter) do
    old_value = Map.get(source, field)
    new_value = 
      case old_value do
        %NotLoaded{} -> old_value
        old_value -> converter.(old_value)
      end

    Map.put(current, field, new_value)
  end
end  
