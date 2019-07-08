defmodule CritWeb.UserManagement.UserView do
  use CritWeb, :view

  def compact_checkbox(form, field) do
    content_tag(:div, 
      [ checkbox(form, field),
        raw("&nbsp;"),
        humanize(field),
      ])
  end
end
