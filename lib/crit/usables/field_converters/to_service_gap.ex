

defmodule Crit.Usables.FieldConverters.ToServiceGap do
  use Ecto.Schema
  import Ecto.Changeset
  alias Crit.Usables.Schemas.ServiceGap
  import Pile.ChangesetFlow

  # Assumes this partial schema
  #   field :computed_in_service_date, :date, virtual: true
  #   field :computed_out_of_service_date, :date, virtual: true
  #   field :computed_service_gaps, {:array, Datespan}, virtual: true

  def expand_start_and_end(changeset) do
    given_prerequisite_values_exist(changeset,
      [:computed_in_service_date, :computed_out_of_service_date],
      fn [computed_in_service_date, computed_out_of_service_date] ->
        spans = 
          if computed_out_of_service_date == :missing do
            [ServiceGap.in_service_gap(computed_in_service_date)
            ]
          else
            [ServiceGap.in_service_gap(computed_in_service_date), 
             ServiceGap.out_of_service_gap(computed_out_of_service_date)
            ]
          end

        put_change(changeset, :computed_service_gaps, spans)
      end)
  end
end  
