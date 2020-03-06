defmodule CritWeb.Fomantic.Informative do
  use Phoenix.HTML
  import Phoenix.Controller, only: [get_flash: 2]
  # import CritWeb.Fomantic.Helpers
  alias CritWeb.ErrorHelpers


  @doc """
  Generates tag for inlined form input errors.
  """
  def error_tag(form, field) do
    Enum.map(Keyword.get_values(form.errors, field), fn error ->
      ~E"""
         <span class="ui pointing red basic label">
           <%= ErrorHelpers.translate_error(error) %>
         </span>
      """
    end)
  end

  def error_flash_attached_above(conn),
    do: error_flash_above(conn, "ui negative attached message")

  def error_flash_above(conn),
    do: error_flash_above(conn, "ui negative message")

  def error_flash_above(conn, class) do
    if get_flash(conn, :error) do
      ~E"""
      <div class="<%=class%>">
        <%= get_flash(conn, :error) %>
      </div>
      """
    end
  end

  def success_flash_above(conn) do
    if get_flash(conn, :info) do
      ~E"""
      <div class="ui positive attached message">
        <%= get_flash(conn, :info) %>
      </div>
      """
    end
  end

  def note_changeset_errors(changeset) do
    if changeset.action do
      ~E"""
      <div class="ui negative attached message">
        Please fix the errors shown below.
      </div>
      """
    end
  end

  def dropdown_error_notification(has_errors) do
    if has_errors do 
      ~E"""
      <div class="ui negative attached message">
      <span>
        There were errors.
        (You may need to click the <i class="caret right icon"></i> arrows to see them.)
      </span>
      </div>
      """
    else
      []
    end
  end
end
