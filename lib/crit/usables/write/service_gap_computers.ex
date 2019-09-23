defmodule Crit.Usables.Write.ServiceGapComputers do
  use Ecto.Schema
  import Ecto.Changeset
  alias Crit.Usables.ServiceGap
  alias Ecto.Datespan

  def expand_start_and_end(%{valid?: false} = changeset), do: changeset
  def expand_start_and_end(%{changes: changes} = changeset) do
    computed_start_date = changes[:computed_start_date]
    computed_end_date = changes[:computed_end_date]

    pre_service = %ServiceGap{gap: Datespan.strictly_before(computed_start_date),
                              reason: before_service_reason()
                             }
    spans = 
      if computed_end_date == :missing do
        [pre_service]
      else
        [ pre_service,
          %{gap: Datespan.date_and_after(computed_end_date),
            reason: after_service_reason()
          }
        ]        
      end

    put_change(changeset, :computed_service_gaps, spans)
  end

  def before_service_reason(), do: "before animal was put in service"
  def after_service_reason(), do: "animal taken out of service"
end  
