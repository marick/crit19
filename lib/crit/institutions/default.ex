defmodule Crit.Global.Default do
  alias Crit.Global.Institution


  @doc """
  This institution must be in the database(s) for all environments: dev, prod, test. 
  It is also "default" in the sense that a dropdown list of institutions should
  show/select this one by default.
  """
  def institution do
    %Institution{
      display_name: "Critter4Us Demo",
      short_name: "critter4us",
      prefix: "demo",
      timezone: "America/Los_Angeles"
    }
  end

  defmacro __using__(_) do
    quote do 
      @institution Crit.Global.Default.institution.short_name
    end
  end
end
