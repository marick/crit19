defmodule CritWeb.Usables.AnimalView do
  use CritWeb, :view
  alias CritWeb.Usables.AnimalController
  alias Crit.Usables.Schemas.ServiceGap
  alias Phoenix.HTML.Form
  alias Ecto.Changeset

  def animal_form_id(animal) do
    "animal_#{animal.id}"
  end
end
