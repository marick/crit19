alias Spikes.Repo


alias Spikes.Repo
alias Spikes.{Animal, Procedure, ReservationBundle, ScheduledUnavailability}
alias Ecto2.InclusiveDateRange

added_interval = fn (date) ->
    %ScheduledUnavailability{
      interval: InclusiveDateRange.ending_at(date),
      reason: "Added to herd"
    }
end

# This lets me repopulate the database without deleting the tables,
# which is a pain because I've always got Postico open to the database.
Repo.delete_all(Animal)
Repo.delete_all(Procedure)
Repo.delete_all(ReservationBundle)
Repo.delete_all(ScheduledUnavailability)

bovine_bundle = Repo.insert!(%ReservationBundle{ name: "horses" })
equine_bundle = Repo.insert!(%ReservationBundle{ name: "equine" })
vm334 = Repo.insert!(%ReservationBundle{ name: "vm334" })


Repo.insert! %Animal{
  name: "bossie",
  species: "bovine",
  reservation_bundles: [bovine_bundle, vm334],
  scheduled_unavailabilities: [ added_interval.(~D[2001-01-01]) ] 
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


