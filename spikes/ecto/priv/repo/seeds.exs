alias Spikes.Repo


alias Spikes.Repo
alias Spikes.{Animal, Procedure, ReservationBundle, ScheduledUnavailability}

added_interval = fn (date) ->
    %ScheduledUnavailability{
      interval: Ecto2.Interval.infinite_down(date, :exclusive),
      reason: "Added to herd"
    }
end

removed_interval = fn (date) ->
    %ScheduledUnavailability{
      interval: Ecto2.Interval.infinite_up(date, :inclusive),
      reason: "Removed from herd"
    }
end

# This lets me repopulate the database without deleting the tables,
# which is a pain because I've always got Postico open to the database.
Repo.delete_all(Animal)
Repo.delete_all(Procedure)
Repo.delete_all(ReservationBundle)
Repo.delete_all(ScheduledUnavailability)

bovine_bundle = Repo.insert!(%ReservationBundle{
      name: "bovine",
      relevant_during: Ecto2.Interval.infinite_up(~D[2001-01-01], :exclusive)
   })
equine_bundle = Repo.insert!(%ReservationBundle{
      name: "equine", 
      relevant_during: Ecto2.Interval.infinite_up(~D[2001-01-01], :exclusive)
   })
vm334 = Repo.insert!(%ReservationBundle{
      name: "vm334", 
      relevant_during: Ecto2.Interval.infinite_up(~D[2001-01-01], :exclusive)
   })


Repo.insert! %Animal{
  name: "bossie",
  species: "bovine",
  reservation_bundles: [bovine_bundle, vm334],
  scheduled_unavailabilities: [ added_interval.(~D[2001-01-01]),
                                removed_interval.(~D[2019-01-01])
                              ]
}

Repo.insert! %Animal{
  name: "lassy",
  species: "bovine",
  reservation_bundles: [bovine_bundle],
  scheduled_unavailabilities: [ added_interval.(~D[2002-02-02]) ] 
}

Repo.insert! %Animal{
  name: "jake",
  species: "equine",
  reservation_bundles: [equine_bundle],
  scheduled_unavailabilities: [ added_interval.(~D[2003-03-03]) ] 
}


Repo.insert! %Procedure{
  name: "cow procedure",
  reservation_bundles: [bovine_bundle, vm334]
}

Repo.insert! %Procedure{
  name: "vm334 procedure",
  reservation_bundles: [vm334]
}

Repo.insert! %Procedure{
  name: "horse procedure",
  reservation_bundles: [equine_bundle]
}


