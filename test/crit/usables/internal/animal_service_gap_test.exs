defmodule Crit.Usables.Internal.AnimalServiceGapTest do
  use Crit.DataCase, async: true
  alias Crit.Usables.AnimalServiceGap

  # Most tests are through the API

  test "cross product of ids" do 
    assert AnimalServiceGap.cross_product([1, 2], [11, 22])
    == [
    %AnimalServiceGap{animal_id: 1, service_gap_id: 11}, 
    %AnimalServiceGap{animal_id: 1, service_gap_id: 22}, 
    %AnimalServiceGap{animal_id: 2, service_gap_id: 11}, 
    %AnimalServiceGap{animal_id: 2, service_gap_id: 22}
    ]
  end
end
