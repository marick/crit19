defmodule Crit.Sql.Transaction do
  use Crit.Errors
  alias Crit.Errors
  alias Ecto.Changeset
  alias Ecto.ChangesetX
  use ExContract


  defmodule State do 
    defstruct attrs: nil, institution: nil, # Must be supplied
      current_struct: nil,      # Must be supplied on update
      original_changeset: nil   # There is always a validation of the form
  end

  def run_creation(attrs, institution, steps) do
    state = %State{attrs: attrs, institution: institution}
    run_steps(state, steps)
  end

  def run_update(struct, attrs, institution, steps) do
    state = %State{attrs: attrs,
                   institution: institution,
                   current_struct: struct
                  }
    run_steps(state, steps)
  end

  def run_steps(final_result, []),
    do: {:ok, final_result}
  
  def run_steps(state, [next | rest]) do
    case next.(state) do
      {:ok, state} ->
        run_steps(state, rest)
      error ->
        error
    end
  end


  defp record_validation_results(state, changeset) do 
    if changeset.valid? do
      {:ok, Map.put(state, :original_changeset, changeset)}
    else
      {:error, changeset}
    end
  end

  def make_creation_validation_step(validator) do
    fn state ->
      changeset = validator.(state.attrs)
      record_validation_results(state, changeset)
    end
  end

  def make_update_validation_step(validator) do
    fn state ->
      changeset = validator.(state.current_struct, state.attrs)
      record_validation_results(state, changeset)
    end
  end

  # Handle return value from an Sql.transaction.
  def on_ok({:error, _, _, _} = fall_through, _), do: fall_through
  def on_ok({:ok, tx_result}, [extract: key]),
    do: {:ok, tx_result[key]}
  def on_ok({:ok, tx_result}, :return_inserted_values),
    do: {:ok, Map.values(tx_result)}


  def on_error({:ok, _} = fall_through, _, _), do: fall_through
  def on_error({:error, _step, failing_changeset, _so_far},
    changeset_for_errors, handlers) do
    
    handler_map = Enum.into(handlers, %{})
    reducer = fn {failing_field, _}, acc ->
      case handler_map[failing_field] do
        nil ->
          Errors.program_error("Unhandled error for field #{failing_field}.")
        handler -> 
          handler.(failing_changeset, acc)
      end
    end

    {:error, 
     Enum.reduce(failing_changeset.errors, changeset_for_errors, reducer)
    }
  end

  def on_error({:ok, _} = fall_through, _), do: fall_through
  def on_error({:error, _step, failing_changeset, _so_far},
               [failing_changeset: field]) do
    check Keyword.has_key?(failing_changeset.errors, field)
    {:error, field, Changeset.fetch_field!(failing_changeset, field)}
  end
  

  @doc """
  Used when the original changeset had no errors but a derived changeset suffered
  a constraint error. The problem is associated with one of the original fields.

  Phoenix templates do not, by default, display changeset errors
  unless they come from an attempt to access the database. (That's so errors due
  to initial form values do not display error messages even though they're not
  valid.) So we fake an access.
  """

  def transfer_constraint_error(changeset_for_errors, field, message) do
    changeset_for_errors
    |> Changeset.add_error(field, message)
    |> ChangesetX.ensure_forms_display_errors
  end    

end  
