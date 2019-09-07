defmodule Crit.ScheduledUnavailabilityTest do
  use Crit.DataCase
#  alias Crit.Usables
#  alias Crit.Usables.{Animal, ScheduledUnavailability}
  alias Crit.Sql

  setup do
    [animal_id: Sql.insert!(Factory.build(:animal), @default_short_name).id]
  end

  describe "fetching an animal" do
    test "success produces a preloaded animal", %{animal_id: _animal_id} do
    end
  end
end
