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
end

