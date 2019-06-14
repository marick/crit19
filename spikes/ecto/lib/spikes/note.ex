defmodule Spikes.Note do
  use Ecto.Schema

  schema "all_notes" do
    field :text, :string
    belongs_to(:animal, Spikes.Animal)
    
    timestamps()
  end
end
