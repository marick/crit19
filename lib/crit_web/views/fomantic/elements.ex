defmodule CritWeb.Fomantic.Elements do
  use Phoenix.HTML
  import Phoenix.Controller, only: [get_flash: 2]

  def form_error_flash(conn) do
    if get_flash(conn, :error) do
      ~E"""
      <div class="ui negative bottom attached message">
        <%= get_flash(conn, :error) %>
      </div>
      """
    end
  end


  def start_centered_form__2 do
    ~E"""
    <div class="ui middle aligned center aligned grid">
      <div class="left aligned column">
    """
  end

  def end_centered_form__2 do
    ~E"""
    </div>
    </div>
    """
  end
end



