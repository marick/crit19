defmodule Crit.MultiStepCache do
  @moduledoc """
  Cache used user activities that occur in multiple steps.
  """

  alias Ecto.Changeset

  def new_key, do: UUID.uuid4()

  def add_transaction_key(%Changeset{} = changeset),
    do: Changeset.put_change(changeset, :transaction_key, new_key())

  def put(data) do 
    :ok = ConCache.insert_new(Crit.Cache, data.transaction_key, data)
  end
  
end
