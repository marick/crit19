defmodule Crit.Exemplars.Simple do 

  defmacro __using__(_) do 
    quote do
      @iso_date "2035-09-05"
      @date Date.from_iso8601!(@iso_date)

      @bumped_date Date.add(@date, 1)
      @iso_bumped_date Date.to_iso8601(@bumped_date)
  
      @later_iso_date "2046-09-05"
      @later_date Date.from_iso8601!(@later_iso_date)

      @later_bumped_date Date.add(@later_date, 1)
      @later_iso_bumped_date Date.to_iso8601(@later_bumped_date)
    end
  end
  
end
