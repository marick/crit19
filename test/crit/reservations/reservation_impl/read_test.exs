defmodule Crit.Reservations.ReservationImpl.ReadTest do
  use Crit.DataCase
  alias Crit.Setup.Schemas.{Animal}
  alias Crit.Reservations.ReservationImpl.Read
  alias Ecto.Datespan
  alias Crit.Exemplars.{Available}
  # alias Ecto.Timespan
  
  describe "animals that can be reserved" do
    setup do
      Available.bovine("NEVER RETURNED: not in service yet", @date_7)
      Available.bovine("NEVER RETURNED: past out of service date",
        Datespan.customary(@date_1, @date_2))
      hard_unavailable_plus_service_gap_unavailability =
        Factory.sql_insert!(:animal,
          [name: "NEVER RETURNED: marked 'hard' unavailable (has conflicting sg)",
           species_id: @bovine_id,
           span: Datespan.inclusive_up(@date_1),
           available: false],
          @institution)
      Factory.sql_insert!(:service_gap,
        [animal_id: hard_unavailable_plus_service_gap_unavailability.id,
         span: Datespan.customary(@date_3, @date_4)],
        @institution)
        
      Factory.sql_insert!(:animal,
        [name: "NEVER RETURNED: marked 'hard' unavailable",
         species_id: @bovine_id,
         span: Datespan.inclusive_up(@date_1),
         available: false],
        @institution)

      wrong_species = Available.equine("NEVER RETURNED: wrong species", @date_3)
      Factory.sql_insert!(:service_gap,
        [animal_id: wrong_species.id, span: Datespan.customary(@date_3, @date_4)],
        @institution)
      :ok
    end

    @desired %{date: @date_3, species_id: @bovine_id}

    test "fetch animals with/without an overlapping service gap" do
      rejected = Available.bovine("RETURNED by rejected_at", @date_3)
      Factory.sql_insert!(:service_gap,
        [animal_id: rejected.id, span: Datespan.customary(@date_3, @date_4)],
        @institution)
        
      available = Available.bovine("RETURNED by available", @date_3)

      rejected_id = rejected.id
      actual = Read.rejected_at(:service_gap, @desired, @institution)
      assert [%Animal{id: ^rejected_id}] = actual

      available_id = available.id
      actual = Read.available(@desired, @institution)
      assert [%Animal{id: ^available_id}] = actual
    end


    # test "fetch animals with/without an overlapping use" do
    #   rejected = Available.bovine("RETURNED by rejected_at", @date_3)
    #   Factory.sql_insert!(:service_gap,
    #     [animal_id: rejected.id, span: Datespan.customary(@date_3, @date_4)],
    #     @institution)
        
    #   available = Available.bovine("RETURNED by available", @date_3)

    #   rejected_id = rejected.id
    #   actual = Read.rejected_at(:service_gap, @date_3, @bovine_id, @institution)
    #   assert [%Animal{id: ^rejected_id}] = actual

    #   available_id = available.id
    #   actual = Read.available(@date_3, @bovine_id, @institution)
    #   assert [%Animal{id: ^available_id}] = actual
    # end
    
  end
end
