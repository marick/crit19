defmodule CritBiz.ViewModels.FieldFillers.ToWebTest do
  use Ecto.Schema
  use Crit.DataCase
  alias CritBiz.ViewModels.FieldFillers.ToWeb
  alias Ecto.Datespan

  embedded_schema do
    field :in_service_datestring, :string
    field :out_of_service_datestring, :string
  end

  test "customary" do
    span = Datespan.customary(@date_1, @date_2)

    ToWeb.service_datestrings(%__MODULE__{}, span)
    |> assert_fields(in_service_datestring: @iso_date_1,
                     out_of_service_datestring: @iso_date_2)
  end

  test "infinite up" do
    span = Datespan.inclusive_up(@date_1)
    ToWeb.service_datestrings(%__MODULE__{}, span)
    |> assert_fields(in_service_datestring: @iso_date_1,
                     out_of_service_datestring: @never)
  end
end
