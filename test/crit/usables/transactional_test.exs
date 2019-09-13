defmodule Crit.Usables.TransactionalTest do
  use Crit.DataCase
  alias Crit.Usables.Transactional

  @iso_date "2001-09-05"
  @date Date.from_iso8601!(@iso_date)
  
  describe "initial service gaps" do
    test "without an out-of-service date" do
      params = %{
        "start_date" => @iso_date,
        "end_date" => "never"
      }

      postgres_result =
        Transactional.initial_service_gaps(params, @default_short_name)
        |> Repo.transaction

      case postgres_result do
        {:ok, %{gap_ids: gap_ids}} ->
          IO.inspect gap_ids, label: "ids"
      end
    end
  end
  
end
