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

  def error_flash(conn) do
    if get_flash(conn, :error) do
      ~E"""
      <div class="ui negative bottom attached message">
        <%= get_flash(conn, :error) %>
      </div>
      """
    end
  end

  def centered_image(src) do
    classes = "ui center aligned container main" 
    
    ~E"""
    <div class="<%=classes%>">
      <img src=<%=src%>>
    </div>
    """
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


  def list_link(text, module, action) do
    ~E"""
    <div class="item">
      <%= link text, to: apply(module, :path, [action]) %>
    </div>
    """
  end

  def dashboard_card(header, items) do
    ~E"""
    <div class="card">
      <div class="content">
        <div class="header">
          <%= header %>
        </div>
        <div class="ui left aligned list">
          <%= items %>
        </div>
      </div>
    </div>
    """
  end

end
