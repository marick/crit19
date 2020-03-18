defmodule CritWeb.Fomantic.Tags do
  use Phoenix.HTML
  import CritWeb.Fomantic.Helpers

  def div_class(classes, interior) do
    [ safe("<div class='#{classes}'>"),
        interior,
      safe("</div>")
    ]
  end

  def just_tag(tag_name, contents) do
    [ safe("<#{tag_name}>"),
      contents,
      safe("</#{tag_name}>")
    ]
  end

  def field(contents), do: div_class("field", contents)
  def fields(contents), do: div_class("fields", contents)
  def td(contents), do: just_tag("td", contents)
  def li(contents), do: just_tag("li", contents)
end
