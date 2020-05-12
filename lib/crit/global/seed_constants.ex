defmodule Crit.Global.SeedConstants do
  alias Crit.Global.Constants
  alias Crit.Global.SeedConstants

  @moduledoc """
  These are constants that are, strictly, for testing. However, they're
  also used when seeding the database, so they're included in the `/lib`
  code.
  """

  # The rather curious duplication of this and below is because `@attributes`
  # can only be used in modules, which seed scripts are not.

  def bovine_id, do: 1
  def bovine, do: "bovine"
  def equine_id, do: 2
  def equine, do: "equine"

  def unlimited_frequency_id, do: 1
  def once_per_week_frequency_id, do: 2
  def once_per_day_frequency_id, do: 3
  def twice_per_week_frequency_id, do: 4

  # Suitable for insert_all.
  def default_timeslots, do: [ %{name: "morning (8-noon)",
                                 start: ~T[08:00:00],
                                 duration: 4 * 60},
                               %{name: "afternoon (1-5)",
                                 start: ~T[13:00:00],
                                 duration: 4 * 60},
                               %{name: "evening (6-midnight)",
                                 start: ~T[18:00:00],
                                 duration: 6 * 60},
                               %{name: "all day (8-5)",
                                 start: ~T[08:00:00],
                                 duration: 9 * 60},
                             ]
  
  defmacro __using__(_) do
    quote do
      # There are always at least these two species.
      # Note that the correctness of the ids are checked
      # when the values are seeded.
      @bovine_id SeedConstants.bovine_id()
      @bovine SeedConstants.bovine()
      
      @equine_id SeedConstants.equine_id()
      @equine SeedConstants.equine()

      @unlimited_frequency_id SeedConstants.unlimited_frequency_id
      @once_per_week_frequency_id SeedConstants.once_per_week_frequency_id
      @default_timezone Constants.default_institution.timezone
    end
  end
end  
