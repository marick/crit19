defmodule Crit.DataCase do
  @moduledoc """
  This module defines the setup for tests requiring
  access to the application's data layer.

  You may define functions here to be used as helpers in
  your tests.

  Finally, if the test case interacts with the database,
  it cannot be async. For this reason, every test runs
  inside a transaction which is reset at the beginning
  of the test unless the test case is marked as async.
  """

  use ExUnit.CaseTemplate

  using do
    quote do
      alias Crit.Repo

      import Ecto
      import Ecto.Changeset
      alias Ecto.ChangesetX
      import Ecto.Query
      import Crit.DataCase
      alias Crit.Factory
      use Crit.TestConstants
      alias Crit.Extras.SqlT
      use FlowAssertions
      use FlowAssertions.Ecto
      import Assertions
      use Crit.Mock
      import Crit.Extras.ChangesetT, only: [errors_on: 1]
      use Crit.Errors
    end
  end

  setup tags do
    :ok = Ecto.Adapters.SQL.Sandbox.checkout(Crit.Repo)

    unless tags[:async] do
      Ecto.Adapters.SQL.Sandbox.mode(Crit.Repo, {:shared, self()})
    end

    :ok
  end
end
