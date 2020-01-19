defmodule Crit.Setup.AnimalImpl.ReadTest do
  use Crit.DataCase
  alias Crit.Setup.Schemas.{Animal, ServiceGap}
  alias Crit.Setup.HiddenSchemas.{Species}
  alias Crit.Setup.AnimalImpl.Read
  alias Ecto.Datespan

  describe "put_updatable_fields" do
    setup do
      [as_fetched: %Animal{
          species: %Species{name: @bovine},
          span: Datespan.customary(@date, @later_date),
          service_gaps: [%ServiceGap{
                            span: Datespan.customary(@bumped_date, @later_bumped_date),
                            reason: "reason"}
                        ]
       },
       
       new_animal_fields: %{
         species_name: @bovine,
         in_service_datestring: @iso_date,
         out_of_service_datestring: @later_iso_date,
         institution: @institution
       },

       # Note: it's valid for fields to be Date structures rather than
       # strings because EEX knows how to render them.
       new_service_gap_fields: %{
         in_service_datestring: @iso_bumped_date,
         out_of_service_datestring: @later_iso_bumped_date,
       },
      ]
    end

    test "basic conversions",
      %{as_fetched: fetched, new_service_gap_fields: new_service_gap_fields,
        new_animal_fields: new_animal_fields}  do
      %Animal{service_gaps: [updatable_gap]} = updatable =
        Read.put_updatable_fields(fetched, @institution)

      assert_fields(updatable, new_animal_fields)
      assert_fields(updatable_gap, new_service_gap_fields)
    end

    test "with an infinite-up span", %{as_fetched: fetched} do
      fetched
      |> Map.put(:span, Datespan.inclusive_up(@date))
      |> Read.put_updatable_fields(@institution)
      |> assert_field(in_service_datestring: @iso_date,
                      out_of_service_datestring: @never)
    end
    
    test "put_updatable_fields can take a list argument", %{as_fetched: fetched} do
      [updatable] = Read.put_updatable_fields([fetched], @institution)
      # It's enough to confirm a single conversion.
      assert_field(updatable, species_name: @bovine)
    end
  end

  describe "properties common to queries" do
    setup do
      animal = Factory.sql_insert!(:animal, @institution)

      [from_all] = Read.all(@institution)
      from_one = Read.one([name: animal.name], @institution)
      [from_ids] = Read.ids_to_animals([animal.id], @institution)

      assert from_all == from_one
      assert from_one == from_ids

      [fetched: from_all]
    end
  
    test "the species and service gaps are loaded", %{fetched: fetched} do
      assert Ecto.assoc_loaded?(fetched.species)
      assert Ecto.assoc_loaded?(fetched.service_gaps)
    end
  end


  describe "bulk queries order by name" do
    test "... not by id order when fetching by ids" do 
      %{id: id1} = Factory.sql_insert!(:animal, [name: "ZZZ"], @institution)
      %{id: id3} = Factory.sql_insert!(:animal, [name: "m"], @institution)
      %{id: id2} = Factory.sql_insert!(:animal, [name: "aaaaa"], @institution)

      ordering = 
        Read.ids_to_animals([id1, id2, id3], @institution)
        |> Enum.map(&(&1.name))

      assert ordering == ["aaaaa", "m", "ZZZ"]
    end

    test "when using `all`" do
      # This might not fail on a bug, since the animals could happen to be generated
      # in sorted order. But note that the names are different for each run of
      # the test.

      for name <- Factory.unique_names() do
        Factory.sql_insert!(:animal, [name: name], @institution)
      end

      as_read = Read.all(@institution) |> Enum.map(&(&1.name))
      sorted = Enum.sort(as_read)

      assert as_read == sorted
    end
  end

  test "fetching animal by name is case independent" do
    %{name: name} = Factory.sql_insert!(:animal, @institution)

    upname = String.upcase(name)
    downname = String.downcase(name)

    assert upname != downname

    up_fetched = Read.one([name: upname], @institution) 
    down_fetched = Read.one([name: downname], @institution)

    assert up_fetched == down_fetched
  end

  test "when fetching ids, missing ids are silently ignored" do
    %{id: id} = Factory.sql_insert!(:animal, @institution)

    [%{id: ^id}] = Read.ids_to_animals([id * 2000, id * 4000, id], @institution)
  end
end
