defmodule CritWeb.Controller.Common do
  use Phoenix.Controller, namespace: CritWeb

  def form_error_message(), do: "Unfortunately, that did not work."

  def form_error_flash(conn) do 
    put_flash(conn, :error, form_error_message())
  end

  def render_for_replacement(conn, renderable, opts) do
    conn
    |> put_layout(false)
    |> render(renderable, opts)
  end


  def process_upsert_subforms(params, subform_field, blank_indicators) do
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

