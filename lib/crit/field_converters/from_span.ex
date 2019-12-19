defmodule Crit.FieldConverters.FromSpan do
  use Ecto.Schema
  alias Ecto.Datespan

  # Assumes this partial schema. Fields are constant because they come from
  # the domain.
  
  # field :span, Datespan       # from

  # field :in_service_datestring, :string         # to 
  # field :out_of_service_datestring, :string     # to
  

  def expand(struct) do
    %{struct |
       in_service_datestring: Datespan.first_to_string(struct.span), 
       out_of_service_datestring: Datespan.last_to_string(struct.span)
    }
  end
end  



