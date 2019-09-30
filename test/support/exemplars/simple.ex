defmodule Crit.Exemplars.Simple do 

  defmacro __using__(_) do 
    quote do
      @iso_date "2025-09-05"
      @date Date.from_iso8601!(@iso_date)
      
      @later_iso_date "2026-09-05"
      @later_date Date.from_iso8601!(@later_iso_date)
    end
  end
  
end
