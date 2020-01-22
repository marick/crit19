defmodule Crit.Global.Constants do

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
      @bovine_id Crit.Global.Constants.bovine_id()
      @bovine Crit.Global.Constants.bovine()
      
      @equine_id Crit.Global.Constants.equine_id()
      @equine Crit.Global.Constants.equine()

      @institution Crit.Setup.InstitutionApi.default.short_name
    end
  end
end
