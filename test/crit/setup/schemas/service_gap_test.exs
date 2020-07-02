defmodule Crit.Setup.Schemas.ServiceGapTest do
  use Crit.DataCase
  alias Crit.Setup.Schemas.ServiceGap
  alias Crit.Exemplars, as: Ex

  describe "changeset for insertion" do
    defp handle(attrs), do: ServiceGap.changeset(%ServiceGap{}, attrs)
    
    test "accepted" do
      span = Ex.Datespan.named(:widest_finite)
      
      handle(%{span: span, reason: "reason"})
      |> assert_valid
      |> assert_changes(span: span, reason: "reason")
    end
    
    test "required fields are must be present" do
      handle(%{})
      |> assert_errors([:span, :reason])
    end
  end
end
