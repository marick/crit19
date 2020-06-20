defmodule CritWeb do
  @moduledoc """
  The entrypoint for defining your web interface, such
  as controllers, views, channels and so on.

  This can be used in your application as:

      use CritWeb, :controller
      use CritWeb, :view

  The definitions below will be executed for every view,
  controller, etc, so keep them short and clean, focused
  on imports, uses and aliases.

  Do NOT define functions inside the quoted expressions
  below. Instead, define any helper function in modules
  and import those modules here.
  """

  def controller do
    quote do
      use Phoenix.Controller, namespace: CritWeb
      use Crit.Global.Constants

      import Plug.Conn
      import CritWeb.Gettext
      alias CritWeb.Router.Helpers, as: Routes
      alias CritWeb.Controller.Common
      alias CritWeb.Endpoint
      import CritWeb.Plugs.Accessors
    end
  end

  def view do
    quote do
      use Phoenix.View,
        root: "lib/crit_web/templates",
        namespace: CritWeb

      # Import convenience functions from controllers
      import Phoenix.Controller, only: [get_flash: 1, get_flash: 2, view_module: 1]

      # Use all HTML functionality (forms, tags, etc)
      use Phoenix.HTML

      import CritWeb.ErrorHelpers
      import CritWeb.Gettext
      alias CritWeb.Router.Helpers, as: Routes
      alias CritWeb.Templates.Purpose
      import CritWeb.Fomantic.Tags
      import CritWeb.Fomantic.Helpers
      import CritWeb.Fomantic.Elements
      import CritWeb.Fomantic.ListProducing
      import CritWeb.Fomantic.Informative
      import CritWeb.Fomantic.Labeled
      import CritWeb.Fomantic.Page
      import CritWeb.Fomantic.Calendars
      import CritWeb.Plugs.Accessors
      alias Ecto.ChangesetX
      import CritWeb.TaskHelpers
    end
  end

  def router do
    quote do
      use Phoenix.Router
      import Plug.Conn
      import Phoenix.Controller
    end
  end

  def channel do
    quote do
      use Phoenix.Channel
      import CritWeb.Gettext
    end
  end

  def view_model do
    quote do
      use Ecto.Schema
      use Crit.Types
      import Ecto.Changeset
      alias Ecto.ChangesetX
      alias Crit.Sql
      alias CritWeb.ViewModels.Common
    end
  end

  @doc """
  When used, dispatch to the appropriate controller/view/etc.
  """
  defmacro __using__(which) when is_atom(which) do
    apply(__MODULE__, which, [])
  end
end
