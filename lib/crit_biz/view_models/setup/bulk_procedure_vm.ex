defmodule CritBiz.ViewModels.Setup.BulkProcedure do
  use CritBiz, :view_model
  use ExContract
  alias CritBiz.ViewModels.Setup, as: VM
  alias CritBiz.ViewModels.Common
  alias Crit.Schemas
  alias Crit.Ecto.TrimmedString
  
  alias Crit.Ecto.BulkInsert
  alias Ecto.Changeset
  alias Ecto.ChangesetX
  alias Crit.Servers.Institution
  

  # The index is used to give each element of the array its own unique id.
  # That may not be necessary, but it doesn't hurt and is arguably clearer.
  @primary_key false
  embedded_schema do
    field :index, :integer
    field :name, TrimmedString, default: ""
    field :species_ids, {:array, :id}, default: []
    field :frequency_id, :integer
    
    field :blank?, :boolean, default: false, virtual: true
  end

  def fields(), do: __schema__(:fields)
  # `:name` and `:species_id` may be absent, if absent together.
  def required(), do: fields() |> ListX.delete([:name, :species_ids])

  def fresh_form_changesets() do
    for i <- 0..9 do 
      %__MODULE__{index: i} |> change
    end
  end

  # ----------------------------------------------------------------------------

  @spec accept_form(params()) :: nary_error([Changeset.t(VM.BulkProcedure)])
  def accept_form(params) do
    params = Common.flatten_to_list(params)
    changesets = Enum.map(params, &fresh_individual_changeset/1)

    for_blank_form? = fn changeset ->
      ChangesetX.newest!(changeset, :blank?)
    end
    
    case Enum.all?(changesets, &(&1.valid?)) do
      true ->
        {:ok, Enum.reject(changesets, for_blank_form?) }
      false ->
        {:error, :form, changesets}
    end
  end

  defp fresh_individual_changeset(attrs) do
    cast(%__MODULE__{}, attrs, fields())
    |> validate_name_and_species
    |> validate_required(required())
  end


  defp validate_name_and_species(original) do
    case {classify_name(original), classify_species(original)}  do
      {:filled, :filled} ->
        original
      {:filled, :blank} -> 
        add_error(original, :species_ids, @at_least_one_species)
      {:blank, _} ->
        put_change(original, :blank?, true)
    end
  end

  defp classify_name(changeset) do
    changeset
    |> validate_required([:name])
    |> ChangesetX.has_error?(:name)
    |> boolean_to_atom
  end

  defp classify_species(changeset) do
    (ChangesetX.newest!(changeset, :species_ids) == [])
    |> boolean_to_atom
  end

  defp boolean_to_atom(false), do: :filled
  defp boolean_to_atom(true), do: :blank

  # ----------------------------------------------------------------------------

  @spec lower_changesets([Changeset.t(VM.BulkProcedure)]) :: [Schemas.Procedure]
  def lower_changesets(changesets),
    do: Enum.flat_map(changesets, &lower_changeset/1)
  
  @spec lower_changeset(Changeset.t(VM.BulkProcedure)) :: Schemas.Procedure
  def lower_changeset(vm_changeset) do
    view_model = apply_changes(vm_changeset)
    for species_id <- view_model.species_ids do
      %Schemas.Procedure{
        name: view_model.name,
        frequency_id: view_model.frequency_id,
        species_id: species_id
      }
    end
  end

  # ----------------------------------------------------------------------------

  @spec insert_all([Schemas.Procedure], short_name()) :: [VM.Procedure]
  def insert_all(procedures, institution) do
    insertion_result = 
      (for p <- procedures, do: Schemas.Procedure.constrained(p))
      |> BulkInsert.insertion_script(institution, schema: Schemas.Procedure)
      |> Sql.transaction(institution)
      |> Sql.Transaction.simplify_result(:return_inserted_values)
    
    case insertion_result do
      {:ok, procedures} -> 
        {:ok, VM.Procedure.lift(procedures, institution)}
      {:error, index, changeset} ->
        check Keyword.has_key?(changeset.errors, :name)
        message = duplicate_name_message(changeset, institution)
        {:error, :constraint, %{duplicate_name: index, message: message}}
    end
  end

  defp duplicate_name_message(changeset, institution) do
    data = Changeset.apply_changes(changeset)
    "A procedure named \"" <> data.name <> "\" already exists for species " <>
      Institution.species_name(data.species_id, institution)
  end
end
