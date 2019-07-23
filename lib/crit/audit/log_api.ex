defmodule Crit.Audit.LogApi do
  @callback put(%Crit.Audit{}) :: any
end
