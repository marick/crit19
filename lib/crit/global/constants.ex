defmodule Crit.Global.Constants do
  alias Crit.Global.Constants
  alias Crit.Setup.InstitutionApi
  
  # The rather curious duplication of this and below is because `@attributes`
  # can only be used in modules, which seed scripts are not.
  def bovine_id, do: 1
  def bovine, do: "bovine"
  def equine_id, do: 2
  def equine, do: "equine"

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

      @institution InstitutionApi.default.short_name
      @institution_first_timeslot List.first(InstitutionApi.default.timeslots)
    end
  end
end
