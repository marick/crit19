# Derived from https://github.com/aliou/radch

defmodule Ecto.Span do
  defmacro __using__(db_type: db_type,
                     type: elixir_type) do

    db_overlap_string = "?::#{db_type} && ?::#{db_type}"
    db_contain_string = "?::#{db_type} @> ?::#{db_type}"
    
    quote do

      # We have to duplicate Postgrex.Range because of how behaviors work.
      defstruct [:first, :last, :lower_inclusive, :upper_inclusive]

      defp convert_to_endpoint_type(:unbound = value), do: value

      def new(first, last, lower_inclusive, upper_inclusive) do 
        %__MODULE__{
          first: convert_to_endpoint_type(first),
          last: convert_to_endpoint_type(last),
          lower_inclusive: lower_inclusive,
          upper_inclusive: upper_inclusive
        }
      end

      # extends to negative infinity
      def infinite_down(last, :inclusive), do: new(:unbound, last, false, true)
      def infinite_down(last, :exclusive), do: new(:unbound, last, false, false)

      def infinite_down?(%{first: :unbound, last: last}) when is_map(last), do: true
      def infinite_down?(_), do: false

      
      # extends to positive infinity
      def infinite_up(first, :inclusive), do: new(first, :unbound, true, false)
      def infinite_up(first, :exclusive), do: new(first, :unbound, false, false)

      def infinite_up?(%{first: first, last: :unbound}) when is_map(first), do: true
      def infinite_up?(_), do: false
      
      def customary(first, last), do: new(first, last, true, false)

      @impl Ecto.Type
      def type, do: unquote(db_type)

      @impl Ecto.Type
      def cast(%__MODULE__{} = range), do: {:ok, range}
      def cast(_), do: :error

      @impl Ecto.Type
      def load(%Postgrex.Range{} = range) do
        {:ok,
         new(range.lower, range.upper, range.lower_inclusive, range.upper_inclusive)
        }
      end
      def load(_), do: :error

      @impl Ecto.Type
      def dump(%__MODULE__{} = range) do
        {:ok,
         %Postgrex.Range{
           lower: range.first || :unbound,
           upper: range.last || :unbound,
           lower_inclusive: range.lower_inclusive,
           upper_inclusive: range.upper_inclusive
         }}
      end

      def dump(_), do: :error

      def dump!(x) do
        {:ok, result} = dump(x)
        result
      end

      # This is a ridiculous amount of code just to avoid using `==` on `Date`.
      @impl Ecto.Type
      def equal?(nil, _), do: false
      def equal?(_, nil), do: false
      def equal?(one, two) do
        # Too lazy to implement Access
        get = fn span, key -> Map.get(span, key) end

        equal_in? = fn key ->
          left = get.(one, key)
          right = get.(two, key)
          case {left, right} do
            {:unbound, :unbound} -> true
            {:unbound, _} -> false
            {_, :unbound} -> false
            _ -> 
              (unquote(elixir_type).compare(right, left) == :eq)
          end
        end

        # Strictly for an :unbound value, whether it's lower or upper
        # inclusive shouldn't matter. Since we always follow the same
        # convention, that doesn't matter.
           get.(one, :lower_inclusive) == get.(two, :lower_inclusive)
        && get.(one, :upper_inclusive) == get.(two, :upper_inclusive)
        && equal_in?.(:first)
        && equal_in?.(:last)
      end

      # Implement these iff they're ever used
      @impl Ecto.Type
      def embed_as(_format), do: raise "embed_as not implemented"

      defmacro overlaps(span1, span2) do
        postgres_expr = unquote(db_overlap_string)
        quote do
          fragment(unquote(postgres_expr), unquote(span1), unquote(span2))
        end
      end

      defmacro contains(container, contained) do
        postgres_expr = unquote(db_contain_string)
        quote do
          fragment(unquote(postgres_expr), unquote(container), unquote(contained))
        end
      end
    end
  end
end
