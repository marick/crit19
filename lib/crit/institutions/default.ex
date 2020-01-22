defmodule Crit.Global.Default do
  alias Crit.Setup.Schemas.{Institution,TimeSlot}


  defmacro __using__(_) do
    quote do 
      @institution Crit.Setup.InstitutionApi.default.short_name
    end
  end
end
