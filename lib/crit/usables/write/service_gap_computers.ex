defmodule Crit.Usables.Write.ServiceGapComputers do
  use Ecto.Schema
  import Ecto.Changeset
  alias Crit.Usables.ServiceGap
  import Crit.Usables.Write.ChangesetFlow
  alias Ecto.Datespan

  def expand_start_and_end(changeset) do
    given_prerequisite_values_exist(changeset,
      [:computed_start_date, :computed_end_date],
      fn [computed_start_date, computed_end_date] ->
        spans = 
          if computed_end_date == :missing do
            [pre_service(computed_start_date)
            ]
          else
            [pre_service(computed_start_date), 
             post_service(computed_end_date)
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
