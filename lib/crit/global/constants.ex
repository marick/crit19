
defmodule Crit.Global.Constants do
  alias Crit.Global.Constants
  alias Crit.Setup.Schemas.Institution
  
  # The rather curious duplication of this and below is because `@attributes`
  # can only be used in modules, which seed scripts are not.
  def default_institution, do: %Institution{
    display_name: "Critter4Us Demo",
    short_name: "critter4us",
    prefix: "demo",
    timezone: "America/Los_Angeles"
  }

  def default_prefix, do: Constants.default_institution.prefix

  defmacro __using__(_) do
    quote do
      @today "today"
      @never "never"

      @institution Constants.default_institution.short_name
      @default_prefix Constants.default_prefix
    end
  end
end
