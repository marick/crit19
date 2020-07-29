defmodule Crit.Params.Validation do
  use Crit.TestConstants
  alias Crit.Params.Get

  # ----------------------------------------------------------------------------


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

