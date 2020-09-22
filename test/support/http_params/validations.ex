defmodule Crit.Params.Validations do
  import ExUnit.Assertions
  use FlowAssertions
  use FlowAssertions.Ecto
  alias Crit.Params.Get
  use FlowAssertions.Define
  use FlowAssertions.Ecto
  import Mockery.Assertions
  alias Crit.Params.Validate


  def check_form_validation(test_data, accept_form, opts) do
    opts = Enum.into(opts, %{verbose: false})
    
    check =
      case Map.get(opts, :result) do
        nil ->
          fn result, name ->
            check_validation_result(test_data, result, name)
          end
        f -> f
      end
    
    names = 
      Crit.Params.Get.names_in_categories(test_data, opts.categories, opts.verbose)
    
    for name <- names do
      Validate.note_name(name, opts.verbose)
      accept_form.(name) |> check.(name)
    end
  end


  defchain check_form_lowering(test_data, name, accept_and_lower),
    do: Validate.Lowering.check(test_data, name, accept_and_lower.(name))
  

  def check_exampler_changeset(test_data, pairs) do
    for {exemplar_name, changeset} <- pairs do 
      Validate.FormChecking.check(test_data, changeset, exemplar_name)
    end
  end

  def check_validation_result(test_data, {:error, :form, [changeset]}, name),
    do: check_validation_result(test_data, {:error, :form, changeset}, name)

  def check_validation_result(test_data, {:ok, [changeset]}, name),
    do: check_validation_result(test_data, {:ok, changeset}, name)

  def check_validation_result(test_data, {:error, :form, changeset}, name) do 
    assert_invalid(changeset)
    assert_error_expected(test_data, name)
    check(test_data, changeset, name)
  end

  def check_validation_result(test_data, {:ok, changeset}, name) do 
    assert_valid(changeset)
    refute_error_expected(test_data, name)
    check(test_data, changeset, name)
  end
  

  def assert_error_expected(test_data, name) do
    exemplar = Get.exemplar(test_data, name)
    assert Map.has_key?(exemplar, :errors)
  end
  
  def refute_error_expected(test_data, name) do
    exemplar = Get.exemplar(test_data, name)
    refute Map.has_key?(exemplar, :errors)
  end

  # ----------------------------------------------------------------------------
  
  defp check(test_data, changeset, descriptor) do
    item = Get.exemplar(test_data, descriptor)
    
    try do 
      assert changeset.valid? == Enum.member?(item.categories, :valid)
      
      unchanged_fields = Map.get(item, :unchanged, [])
      errors = Map.get(item, :errors, [])
      
      changeset
      |> assert_change(Get.as_cast(test_data, descriptor, without: unchanged_fields))
      |> assert_no_changes(unchanged_fields)
      |> assert_errors(errors)
      check_spies(item[:because_of])
    rescue
      exception in [ExUnit.AssertionError] ->
        IO.puts "\nBackground for following test failure:"
      IO.inspect(item.params, label: to_string(descriptor))
      IO.inspect(changeset, label: "changeset")
      IO.inspect(changeset.data, label: "underlying data")
      reraise exception, __STACKTRACE__
    end
  end
  
  defp check_spies(dependencies) when is_list(dependencies) do
    for {module, name} <- dependencies do
      assert_called(module, name)
    end
  end
  
  defp check_spies(tuple) when is_tuple(tuple), do: check_spies([tuple])
  defp check_spies(_), do: "nothing"
end
