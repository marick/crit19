defmodule Crit.Sql.Router do
  alias Crit.Setup.Schemas.Institution

  @type arg :: any

  @callback forward(atom, [arg], keyword, Institution.t) :: any
  @callback multi_opts(keyword, Institution.T) :: keyword
end

