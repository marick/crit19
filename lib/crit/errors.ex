defmodule Crit.Errors do

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

  defmacro __using__(_) do
    quote do 
      @date_misorder_message "should not be before the start date"
      @no_valid_names_message "must have at least one valid name"
      @login_failed "Login failed"
      @blank_message "can't be blank"
      @blank_message_in_html "can&#39;t be blank"
    end
  end
end
