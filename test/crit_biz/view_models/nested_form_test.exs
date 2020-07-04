defmodule CritBiz.ViewModels.NestedFormTest do
  use Crit.DataCase
  alias CritBiz.ViewModels.NestedForm
  # Note: the following two can't be aliased with `as:` 
  alias Phoenix.HTML.Form
  alias Phoenix.HTML.FormData
  alias Ecto.Changeset

  # Behavior of NestedForm is to be like that of corresponding
  # functions in PhoenixHtml.{Form,FormData} except that it doesn't
  # barf when given a plain array rather than an assoc - because view
  # model fields can't be defined with `has_many` fields. (Other
  # things break if you try.)

  # ----------------------------------------------------------------------------

  defmodule Std do
    defmodule Assoc do
      use Ecto.Schema
      embedded_schema do
        field :reason, :string, default: "reason"
      end
      
      def changeset(%__MODULE__{} = struct, attrs),
        do: struct |> cast(attrs, [:reason]) |> validate_required([:reason])
    end
    
    defmodule Container do
      use Ecto.Schema
      embedded_schema do
        field :name, :string, default: "name"
        has_many :nesteds, Std.Assoc
      end
      
      def changeset(%__MODULE__{} = struct, attrs) do
        struct
        |> cast(attrs, [:name, :id])
        |> cast_assoc(:nesteds)
        |> validate_required([:name])
      end
    end

    def forms(params, struct \\ %Container{nesteds: []}) do
      struct
      |> Container.changeset(params)
      |> Form.form_for("action")
      |> Form.inputs_for(:nesteds)
    end
  end

  defmodule New do 
    defmodule Assoc do
      use Ecto.Schema
      @primary_key false   # I do this to emphasize `id` is just another field
      embedded_schema do
        field :id, :id
        field :reason, :string, default: "reason"
      end
      
      def accept_form(attrs),
        do: %__MODULE__{} |> cast(attrs, [:reason]) |> validate_required([:reason])
    end
    
    defmodule Container do
      use Ecto.Schema
      @primary_key false   # I do this to emphasize `id` is just another field
      embedded_schema do
        field :id, :id
        field :name, :string, default: "name"
        field :nesteds, {:array, :map}, default: []
      end
      
      # This mimics the way `VM.Animal` does it, which is perhaps the
      # wrong way.
      def accept_form(attrs) do
        top = 
          %__MODULE__{}
          |> cast(attrs, [:name, :id, :nesteds])
          |> validate_required([:name])
        
        nesteds =
        for attrs <- fetch_change!(top, :nesteds) do 
          New.Assoc.accept_form(attrs)
        end
        
        top
        |> put_change(:nesteds, nesteds)
      end
    end

    def forms(params) do
      params
      |> New.Container.accept_form
      |> Form.form_for("action")
      |> NestedForm.inputs_for(:nesteds, &(&1))
    end
    
  end

    
  # ----------------------------------------------------------------------------

  describe "inputs_for handling of nested `has_many` fields: Form validation" do
    test "when given a simple changeset" do
      params = %{"name" => "new name",
                 "nesteds" => [ %{"reason" => "reason"} ]}

      
      [phoenix] = Std.forms(params)
      [crit] = New.forms(params)
      assert_equivalent(phoenix, crit)
    end
    
    test "when given a changeset with top-level error" do 
      params = %{"name" => "",
                 "nesteds" => [ %{"reason" => "reason"} ]}
    
      [phoenix] = Std.forms(params)
      [crit] = New.forms(params)
      assert_equivalent(phoenix, crit)
    end
  end


  # ----------------------------------------------------------------------------

  describe "inputs_for handling of nested `has_many` fields: Initial form creation" do
    test "when given a simple changeset" do

      top_form = fn top_module, nested_module ->
        empty_nested = struct(nested_module, %{reason: ""})
        existing_nested = struct(nested_module, %{id: 333, reason: "reason"})
        
        struct(top_module, %{id: 1, name: "name"})
        |> Map.put(:nesteds, [empty_nested, existing_nested])
        |> Changeset.change
        |> Form.form_for("action")
      end
        
      [phoenix_empty, phoenix_existing] =
        top_form.(Std.Container, Std.Assoc)
        |> Form.inputs_for(:nesteds)

      [crit_empty, crit_existing] =
        top_form.(New.Container, New.Assoc)
        |> NestedForm.inputs_for(:nesteds, &(&1))

      assert_equivalent(phoenix_empty, crit_empty)
      assert_equivalent(phoenix_existing, crit_existing)
    end
  end
  
    
  # ----------------------------------------------------------------------------


  def assert_equivalent(phoenix, crit) do 
    assert phoenix.data.reason == crit.data.reason
    # ... or, more api-ish:
    assert_same_value(phoenix, crit, :reason)  
    assert_same_relevant_metadata(phoenix, crit)
  end
  
  def assert_same_value(phoenix, crit, field) do
    phoenix_value = FormData.input_value(:atom, phoenix, field)
    crit_value =    FormData.input_value(:atom, crit,    field)
    assert phoenix_value == crit_value
  end

  defp assert_same_relevant_metadata(phoenix, crit) do
    assert phoenix.errors == crit.errors
    assert phoenix.hidden == crit.hidden
    assert phoenix.id == crit.id
    assert phoenix.name == crit.name
    assert phoenix.index == crit.index
    assert phoenix.params == crit.params
  end
end
