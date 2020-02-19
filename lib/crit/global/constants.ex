defmodule Crit.Global.Constants do
  alias Crit.Global.Constants
  alias Crit.Setup.Schemas.Institution
  
  # The rather curious duplication of this and below is because `@attributes`
  # can only be used in modules, which seed scripts are not.
  def bovine_id, do: 1
  def bovine, do: "bovine"
  def equine_id, do: 2
  def equine, do: "equine"
  def default_prefix, do: Constants.default_institution.prefix

  def default_institution, do: %Institution{
    display_name: "Critter4Us Demo",
    short_name: "critter4us",
    prefix: "demo",
    timezone: "America/Los_Angeles"
 }

  # Suitable for insert_all.
  def default_timeslots, do: [ %{name: "morning (8-noon)",
                                 start: ~T[08:00:00],
                                 duration: 4 * 60},
                               %{name: "afternoon (1-5)",
                                 start: ~T[13:00:00],
                                 duration: 4 * 60},
                               %{name: "evening (6-midnight)",
                                 start: ~T[18:00:00],
                                 duration: 5 * 60},
                               %{name: "all day (8-5)",
                                 start: ~T[08:00:00],
                                 duration: 9 * 60},
  ]
  

  defmacro __using__(_) do
    quote do
      @today "today"
      @never "never"

      # There are always at least these two species.
      # Note that the correctness of the ids are checked
      # when the values are seeded.
      @bovine_id Constants.bovine_id()
      @bovine Constants.bovine()
      
      @equine_id Constants.equine_id()
      @equine Constants.equine()

      @institution Constants.default_institution.short_name
      @default_timezone Constants.default_institution.timezone
      @default_prefix Constants.default_prefix
    end
  end
end
