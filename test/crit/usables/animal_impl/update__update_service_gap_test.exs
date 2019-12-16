defmodule Crit.Usables.AnimalImpl.UpdateUpdateServiceGapTest do
  use Crit.DataCase
  alias Crit.Usables.AnimalApi
  alias Crit.Exemplars
  alias Crit.FieldConverters.ToSpan
  alias Crit.Extras.AnimalT

  describe "updating service dates" do
    setup do
      [dates: Exemplars.Date.service_dates()]
    end
    
    test "update in-service date", %{dates: dates} do
      original_animal = dated_animal(
        in_service_datestring: dates.iso_in_service,
        out_of_service_datestring: "never"
      )
        
      params = %{"in_service_datestring" => dates.iso_next_in_service,
                 "out_of_service_datestring" => "never"}
      new_animal = AnimalT.update_for_success(original_animal.id, params)
      assert new_animal == %{original_animal | 
                             in_service_datestring: dates.iso_next_in_service,
                             in_service_date: dates.next_in_service,
                             lock_version: 2
                           }
    end

    test "update out-of-service date", %{dates: dates} do
      animal = dated_animal(
        in_service_datestring: dates.iso_in_service,
        out_of_service_datestring: dates.iso_out_of_service
      )
      params = %{"in_service_datestring" => dates.iso_in_service,
                 "out_of_service_datestring" => dates.iso_next_out_of_service}
      new_animal = AnimalT.update_for_success(animal.id, params)

      assert new_animal == %{animal | 
                             out_of_service_datestring: dates.iso_next_out_of_service,
                             out_of_service_date: dates.next_out_of_service,
                             lock_version: 2
                           }
    end

    test "update both dates", %{dates: dates} do
      original_animal = dated_animal(
        in_service_datestring: dates.iso_in_service,
        out_of_service_datestring: dates.iso_out_of_service
      )
      params = %{"in_service_datestring" => dates.iso_next_in_service,
                 "out_of_service_datestring" => dates.iso_next_out_of_service}
      new_animal = AnimalT.update_for_success(original_animal.id, params)

      assert new_animal == %{original_animal | 
                             in_service_datestring: dates.iso_next_in_service,
                             in_service_date: dates.next_in_service,
                             out_of_service_datestring: dates.iso_next_out_of_service,
                             out_of_service_date: dates.next_out_of_service,
                             lock_version: 2
                           }
    end
    
    test "delete out-of-service date", %{dates: dates} do 
      original_animal = dated_animal(
        in_service_datestring: dates.iso_in_service,
        out_of_service_datestring: dates.iso_out_of_service
      )
      params = %{"in_service_datestring" => dates.iso_in_service,
                 "out_of_service_datestring" => @never}
      new_animal = AnimalT.update_for_success(original_animal.id, params)

      assert new_animal == %{original_animal | 
                             in_service_datestring: dates.iso_in_service,
                             in_service_date: dates.in_service,
                             out_of_service_datestring: @never,
                             lock_version: 2
                           }
    end
    
    test "add new out-of-service date", %{dates: dates} do 
      original_animal = dated_animal(
        in_service_datestring: dates.iso_in_service,
        out_of_service_datestring: @never
      )
      params = %{"in_service_datestring" => dates.iso_in_service,
                 "out_of_service_datestring" => dates.iso_next_out_of_service}
      new_animal = AnimalT.update_for_success(original_animal.id, params)

      assert new_animal == %{original_animal | 
                             in_service_datestring: dates.iso_in_service,
                             in_service_date: dates.in_service,
                             out_of_service_datestring: dates.iso_next_out_of_service,
                             out_of_service_date: dates.next_out_of_service,
                             lock_version: 2
                            }
    end

    test "reject out-of-order-dates", %{dates: dates} do
      original_animal = dated_animal(
        in_service_datestring: dates.iso_in_service,
        out_of_service_datestring: dates.iso_out_of_service
      )
      #           vv                                       vvvvvv
      params = %{"in_service_datestring" => dates.iso_next_out_of_service,
                 "out_of_service_datestring" => dates.iso_next_in_service}
      #           ^^^^^^                                       ^^
      assert {:error, changeset} = AnimalApi.update(original_animal.id, params, @institution)
      assert ToSpan.misorder_error_message in errors_on(changeset).out_of_service_datestring
    end
  end

  defp dated_animal(opts) do
    with_in_service =
      Keyword.put(opts, :in_service,
        Date.from_iso8601!(Keyword.get(opts, :in_service_datestring)))

    with_out_of_service =
      case outstring = Keyword.get(opts, :out_of_service_datestring) do 
        @never -> with_in_service
        _ -> Keyword.put(with_in_service, :out_of_service,
               Date.from_iso8601!(outstring))
      end
    
    id = Exemplars.Available.animal_id(with_out_of_service)
    AnimalApi.updatable!(id, @institution)
  end
end
