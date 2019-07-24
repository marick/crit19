defmodule Crit.Audit.LogApi do
  @callback put(any, %Crit.Audit{}) :: any
end
