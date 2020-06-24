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
    first: %{
      named: Datespan.customary(@date_2, @date_3),
      strings: {@iso_date_2, @iso_date_3}
      
    }
  }

  def named(description) do
    check Map.has_key?(@spans, description)
    @spans[description].named
  end
 
  def in_service(description) do
    check Map.has_key?(@spans, description)
    named(description).first
  end
  
  def out_of_service(description) do
    check Map.has_key?(@spans, description)
    named(description).last
  end


  # ----------------------------------------------------------------------------

  def assert_datestrings(container, description) do
    check Map.has_key?(@spans, description) 
   
    {in_string, out_string} = @spans[description].strings
    assert container.in_service_datestring == in_string
    assert container.out_of_service_datestring == out_string
  end
    
end
