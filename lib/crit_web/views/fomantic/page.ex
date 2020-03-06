defmodule CritWeb.Fomantic.Page do
  use Phoenix.HTML
  import CritWeb.Fomantic.Helpers
  import CritWeb.Fomantic.Informative


  def start_centered_form do
    ~E"""
    <div class="ui middle aligned center aligned grid">
      <div class="left aligned column">
    """
  end

  def end_centered_form do
    ~E"""
    </div>
    </div>
    """
  end

  def login_form_style do
    ~E"""
    <style type="text/css">
        body {
          background-color: #DADADA;
        }
        .column {
          max-width: 350px;
        }
    </style>
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
