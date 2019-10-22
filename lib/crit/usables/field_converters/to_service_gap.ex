defmodule Crit.Usables.FieldConverters.ToServiceGap do
  use Ecto.Schema
  import Ecto.Changeset
  alias Crit.Usables.Schemas.ServiceGap
  import Pile.ChangesetFlow
  alias Ecto.Datespan

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
            [pre_service(computed_in_service_date)
            ]
          else
            [pre_service(computed_in_service_date), 
             post_service(computed_out_of_service_date)
            ]
          end

        put_change(changeset, :computed_service_gaps, spans)
      end)
  end

  defp pre_service(first_day_in_service),
    do: %ServiceGap{
          gap: Datespan.strictly_before(first_day_in_service),
          reason: before_service_reason()
    }

  defp post_service(first_day_out_of_service),
    do: %ServiceGap{
          gap: Datespan.date_and_after(first_day_out_of_service),
          reason: after_service_reason()
    }
  

  def before_service_reason(), do: "before animal was put in service"
  def after_service_reason(), do: "animal taken out of service"
end  
