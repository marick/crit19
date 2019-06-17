defmodule Spikes.Factory do
  use ExMachina.Ecto, repo: Spikes.Repo
  alias Spikes.{ReservationBundle, Animal}

  def reservation_bundle_factory() do
    start = Faker.NaiveDateTime.backward(4)
    %ReservationBundle{
      name: sequence(:bundle_name, &"bundle#{&1}"),
      relevant_during: Ecto2.Timespan.infinite_up(start, :exclusive),
    }
  end

  def animal_factory() do
    %Animal{
      name: sequence(:animal_name, &"animal#{&1}"),
      species: sequence(:species, &"species#{&1}"),
    }
  end
      
end
