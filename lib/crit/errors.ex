defmodule Crit.Errors do
  import Ecto.Changeset

  @doc """
  Input that should be impossible. For example, because animals are never
  deleted - only put out of service - a form should never provide an ID 
  that doesn't match a database record. 

  Strictly, a user in control of the browser could provide such an ID. But
  just crashing serves her right.
  """
  
  def impossible_input(message, _data \\ []) do 
    # Will eventually add logging.
    raise "Impossible input: #{message}"
  end


  def program_error(message, _data \\ []) do
    raise "Program error: #{message}"
  end

  def date_misorder_message, do: "should not be before the start date"
end
