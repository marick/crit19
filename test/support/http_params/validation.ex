defmodule Crit.Params.Validation do
  use Crit.TestConstants
  import ExUnit.Assertions
  import Crit.Assertions.Changeset
  import Crit.Assertions.{Ecto,Map}
  alias Pile.Namelist
  alias Crit.Params.Get
  alias Crit.Params.Validate

  # ----------------------------------------------------------------------------

  def check_actual(config, actual, exemplar_name) do
    case actual do
      %Ecto.Changeset{} = changeset ->
        Validate.FormChecking.check(config, changeset, exemplar_name)
      [] -> 
        :no_op
      x ->
        IO.puts "Expected either a changeset or emptiness, not:"
        IO.inspect x
        flunk "Most likely, the function given should end with []"
    end
  end

  # ----------------------------------------------------------------------------

  def note_name(name, verbose) do
    if verbose, do: IO.puts("+ #{inspect name}")
  end

  def filter_by_categories(config, names, [category | remainder]) do
    filtered = 
      Enum.filter(names, &Enum.member?(Get.exemplar(config, &1).categories, category))
    filter_by_categories(config, filtered, remainder)
  end
  
  def filter_by_categories(_config, names, []), do: names

  def filter_by_categories(config, categories, verbose) do
    if verbose, do: IO.puts(">> Partition #{inspect categories}")
    all_names = Map.keys(config.exemplars)
    filter_by_categories(config, all_names, categories)
  end


  

end

