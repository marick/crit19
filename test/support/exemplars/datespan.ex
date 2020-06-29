defmodule Crit.Exemplars.Datespan do
  use Crit.TestConstants
  use ExContract
  alias Ecto.Datespan
  import ExUnit.Assertions

  @spans %{
    widest_finite: %{
      named: Datespan.customary(@earliest_date, @latest_date),
      strings: {@earliest_iso_date, @latest_iso_date}
      
    },

    widest_infinite: %{
      named: Datespan.inclusive_up(@earliest_date),
      strings: {@earliest_iso_date, @never}
    },
    
    first: %{
      named: Datespan.customary(@date_2, @date_3),
      strings: {@iso_date_2, @iso_date_3}
      
    }
  }

  defp get_top(description, key) do
    check Map.has_key?(@spans, description)
    @spans[description] |> Map.get(key)
  end

  def named(description), do: get_top(description, :named)
  def strings(description), do: get_top(description, :strings)
 
  def in_service(description), do: named(description).first
  def out_of_service(description), do: named(description).last

  def in_service_datestring(description), do: strings(description) |> elem(0)
  def out_of_service_datestring(description), do: strings(description) |> elem(1)

  def put_datestrings(map, description) do
    Map.merge(map, %{
          "in_service_datestring" => in_service_datestring(description),
          "out_of_service_datestring" => out_of_service_datestring(description)
          })
  end 

  # ----------------------------------------------------------------------------

  def assert_datestrings(container, description) do
    check Map.has_key?(@spans, description) 
   
    {in_string, out_string} = @spans[description].strings
    assert container.in_service_datestring == in_string
    assert container.out_of_service_datestring == out_string
  end
    
end
