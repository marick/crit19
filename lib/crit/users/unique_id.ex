defmodule Crit.Users.UniqueId do
  @moduledoc """
  Any given `conn` represents a request for a particular user. The same
  `User.id` may appear in more than one institution, so uniqueness requires
  that the institution's shortname accompany the user_id wherever it goes.
  """

  defstruct user_id: nil, institution: nil


  def new(user_id, institution),
    do: %__MODULE__{user_id: user_id, institution: institution}
end
