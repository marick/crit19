defmodule CritWeb.Controller.Common do
  use Phoenix.Controller, namespace: CritWeb
  import Plug.Conn

  def form_error_flash(conn) do 
    put_flash(conn, :error, "Unfortunately, that didn't work.")
  end
end

