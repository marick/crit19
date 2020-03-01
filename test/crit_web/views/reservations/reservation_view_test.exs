defmodule CritWeb.Setup.ReservationViewTest do
  use CritWeb.ConnCase, async: true
  import Phoenix.HTML
  alias CritWeb.Reservations.ReservationView

  describe "date_or_dates_header" do
    test "two dates" do
      actual = ReservationView.date_or_dates_header(~D[2020-02-03], ~D[2020-02-24])
      expected = "Reservations from February  3, 2020 through February 24, 2020"
      assert safe_to_string(actual) =~ expected
    end

    test "one date" do
      actual = ReservationView.date_or_dates_header(~D[2020-02-24], ~D[2020-02-24])
      expected = "Reservations on February 24, 2020"
      assert safe_to_string(actual) =~ expected
    end

    test "count_header" do
      assert ReservationView.count_header(0) == "Zero Reservations"
      assert ReservationView.count_header(1) == "One Reservation"
      assert ReservationView.count_header(100) == "One Hundred Reservations"
      assert ReservationView.count_header(101) == "101 Reservations"
    end
  end
end
