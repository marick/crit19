defmodule CritWeb.Reservations.ReservationControllerTest do
  use CritWeb.ConnCase
  alias CritWeb.Reservations.ReservationController, as: UnderTest
  use CritWeb.ConnMacros, controller: UnderTest

  setup :logged_in_as_reservation_manager

  # Currently, everything about the controller is tested via integration
  # tests.

end
