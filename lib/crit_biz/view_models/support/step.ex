defmodule CritBiz.ViewModels.Step do
  alias Crit.Servers.UserTask
  alias Ecto.Changeset

  def attempt(params, form_module) do 
    UserTask.supplying_task_memory(params, fn task_memory ->
      changeset = form_module.changeset(params)
      case changeset.valid? do
        false ->
          {:error, :form, task_memory, changeset}
        true ->
          {:ok, struct} = Changeset.apply_action(changeset, :insert)
          next_task_memory = form_module.next_task_memory(task_memory, struct)
          UserTask.replace(task_memory.task_id, next_task_memory)
          next_form_data = form_module.next_form_data(next_task_memory, struct)
          
          {:ok, next_task_memory, next_form_data}
      end
    end)
  end


  def check_not_already_initialized(task_memory, field) do 
    case Map.get(task_memory, field) do
      :nothing ->
        :ok
      value ->
        raise "Task memory already has value `#{inspect value}` for field `#{inspect field}`"
    end
  end


  def initialize_by_transfer(task_memory, source, fields) do
    Enum.reduce(fields, task_memory, fn field, acc ->
      check_not_already_initialized(task_memory, field)
      Map.put(acc, field, Map.get(source, field))
    end)
  end

  def initialize_by_setting(task_memory, kvs) do
    Enum.reduce(kvs, task_memory, fn {field, value}, acc ->
      check_not_already_initialized(task_memory, field)
      Map.put(acc, field, value)
    end)
  end
  
end
