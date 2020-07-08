Think of the modules in this directory as adding on *testing-specific*
public functions to modules. So a test involving animals might find it
useful to have this in the module header:

```elixir
defmodule Crit.Something.SomethingTest do
  alias Crit.Schemas.Animal
  alias Crit.Extras.AnimalT
```

(It's sad that Elixir doesn't have Elm's ability to merge modules via multiple
alias statements.)

Note that assertions can be found separately in `../assertions/`
