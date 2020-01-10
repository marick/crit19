defmodule CritWeb.LayoutView do
  use CritWeb, :view
  alias CritWeb.CurrentUser.SessionController

  def start_page(conn) do
    ~E"""
      <!DOCTYPE html>
      <html lang="en">
        <head>
          <meta charset="utf-8"/>
          <meta http-equiv="X-UA-Compatible" content="IE=edge,chrome=1"/>
          <meta name="viewport" content="width=device-width, initial-scale=1.0"/>
          <title>Critter4Us</title>
          <script src="https://cdn.jsdelivr.net/npm/jquery@3.3.1/dist/jquery.min.js"></script>
          <link rel="stylesheet" type="text/css" href="https://cdn.jsdelivr.net/npm/fomantic-ui@2.8.3/dist/semantic.min.css">
          <script src="https://cdn.jsdelivr.net/npm/fomantic-ui@2.8.3/dist/semantic.min.js"></script>
          <link rel="stylesheet" href="<%= Routes.static_path(conn, "/css/app.css") %>"/>
        </head>
        <body>
     """
  end

  def end_page(conn) do
    ~E"""
          <script type="text/javascript"
                  src="<%= Routes.static_path(conn, "/js/app.js") %>">
          </script>
        </body>
      </html>
    """
  end

  def link_as_header_button(name, controller, action, extras \\ []) do
    opts = [to: apply(controller, :path, [action]),
            class: "ui button"
           ] ++ extras
    ~E"""
      <div class="item">
         <%= link name, opts %>
      </div>
    """
  end


  def header(kws) do
    right_items = Keyword.fetch!(kws, :right)

    ~E"""    
      <header>
        <div class="ui fixed inverted menu">
          <div class="ui container">
            <a href="/" class="header item">
              Critter4Us
            </a>
            <div class="right menu">
              <%= right_items %>
            </div>
          </div>
        </div>
      </header>
    """
  end
end
