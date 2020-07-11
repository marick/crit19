defmodule CritBiz do
  @moduledoc """
  The module for the business, currently conceptualized as everything
  that stands between humans and the permanent record.
  """

  def view_model do
    quote do
      use Ecto.Schema
      use Crit.Types
      use Crit.Errors
      use Crit.Global.Constants
      import Ecto.Changeset
      alias Ecto.ChangesetX
      alias Crit.Sql
      alias CritBiz.ViewModels.Common
      import CritBiz.ViewModels.Common, only: [summarize_validation: 3]
    end
  end

  @doc """
  When used, dispatch to the appropriate controller/view/etc.
  """
  defmacro __using__(which) when is_atom(which) do
    apply(__MODULE__, which, [])
  end
end
