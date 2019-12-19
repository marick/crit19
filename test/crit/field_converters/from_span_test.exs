defmodule Crit.FieldConverters.FromSpanTest do
  use Ecto.Schema
  use Crit.DataCase
  alias Crit.FieldConverters.FromSpan
  alias Ecto.Datespan

  # Assumes this partial schema. 
  # Various constants are reasonably stable, given the domain.
  
  embedded_schema do
    field :span, Datespan

    field :in_service_datestring, :string
    field :out_of_service_datestring, :string
  end

  test "customary" do
    %__MODULE__{span: Datespan.customary(@date, @later_date)}
    |> FromSpan.expand
    |> assert_fields(in_service_datestring: @iso_date,
                     out_of_service_datestring: @later_iso_date)
  end

  test "infinite up" do
    %__MODULE__{span: Datespan.inclusive_up(@date)}
    |> FromSpan.expand
    |> assert_fields(in_service_datestring: @iso_date,
                     out_of_service_datestring: @never)
  end
end
