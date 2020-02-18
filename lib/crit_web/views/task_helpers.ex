defmodule CritWeb.TaskHelpers do
  @moduledoc """
  Help with user tasks
  """
  use Phoenix.HTML

  def task_header(state), do: MapX.just!(state, :task_header)

  def hidden_task_id(form, state), 
    do: hidden_input form, :task_id, value: MapX.just!(state, :task_id)
end
