defmodule CritBiz.ViewModels.Reservation.InitialFormTest do
  use Crit.DataCase
  alias CritBiz.ViewModels.Reservation.AfterTheFact, as: VM
  alias Ecto.Changeset

  @tag :skip
  test "the starting changeset" do
    VM.Forms.Context.empty
    |> assert_shape(%Changeset{})
    |> assert_data(species_id: @bovine_id)
    |> IO.inspect
  end
end
  
