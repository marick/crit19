defmodule Crit.Common do

  # This handles the case of a form for updating a top level structure (such as
  # `Animal`) that allows the simultaneous updating *or* insertion of nested
  # ("has_many") structures (like `ServiceGap`s). Insertion means filling in
  # an initially blank subform. This function is used to remove subforms that
  # were ignored by the user (nothing put in any of the fields).
  #
  # The example in the test probably makes this more clear.
  #
  # Note: when there's a list of subforms in the display, the POST params
  # come as a map from (string) index to a map of subform name/entry pairs.
  # The function flattens the result to just the values of the input map,
  # just because it's easier. Changeset (`cast_assoc`) processing works with
  # either form. 

  def filter_out_unstarted_subforms(params, subform_field, blank_indicators) do
    trimmed = fn string ->
      string |> String.trim_leading |> String.trim_trailing
    end

    empty_subform? = fn one_subform ->
      Enum.all?(blank_indicators, &(trimmed.(one_subform[&1]) == ""))
    end

    simplified = 
      params
      |> Map.get(subform_field)
      |> Map.values
      |> Enum.reject(empty_subform?)

    Map.put(params, subform_field, simplified)
  end
end
