defmodule Want.List do
  @moduledoc """
  Manages conversions to and from lists.
  """
  use Want.Type

  @type element :: any()
  @type result  :: {:ok, list(element())} | {:error, binary()}

  @default_separator ","

  @doc ~S"""
  Cast an input into a list. By default this function will simply break up the input into list elements, but
  further casting and validation of elements can be performed by providing an `element` option. The separator
  used to split the list defaults to the comma character and this can be controlled using the `separator` option.

  ## Options

    * `:separator` - Determines the character(s) used to separate list items. Defaults to the comma character.
    * `:element` - Provides the ability to further control how list elements are cast and validated. Similar to the
    `map` and `keywords` functions, accepts a keyword list with its own `:type` field and validation options.
    * `:on_error` - Controls behaviour when an element cast fails. `:drop` (default) silently removes the
    failed element. `:error` halts and returns the first error.
    * `:min` - Minimum allowable number of elements in the resulting list.
    * `:max` - Maximum allowable number of elements in the resulting list.

  ## Examples

      iex> Want.List.cast("1")
      {:ok, ["1"]}

      iex> Want.List.cast("1", element: [type: :integer])
      {:ok, [1]}

      iex> Want.List.cast("1,2,3,4", element: [type: :integer])
      {:ok, [1, 2, 3, 4]}

      iex> Want.List.cast("1:2:3:4", separator: ":", element: [type: :integer])
      {:ok, [1, 2, 3, 4]}

      iex> Want.List.cast("hello:world", separator: ":", element: [type: :enum, valid: [:hello, :world]])
      {:ok, [:hello, :world]}

      iex> Want.List.cast("hello:world", separator: ":", element: [type: :enum, valid: [:hello]])
      {:ok, [:hello]}

      iex> Want.List.cast("hello:world", separator: ":", element: [type: :enum, valid: [:hello]], on_error: :error)
      {:error, "\"world\" did not match any valid enum values."}

      iex> Want.List.cast("a,b,c", min: 2)
      {:ok, ["a", "b", "c"]}

      iex> Want.List.cast("a", min: 2)
      {:error, "List length below minimum of 2."}

      iex> Want.List.cast("a,b,c,d,e", max: 3)
      {:error, "List length exceeds maximum of 3."}

  """
  @spec cast(value :: any(), opts :: Keyword.t()) :: result()
  def cast(value),
    do: cast(value, [])
  def cast(value, opts) when is_binary(value) do
    value
    |> String.split(Keyword.get(opts, :separator, @default_separator))
    |> cast(opts)
  end
  def cast(value, opts) when is_list(value) do
    result =
      case opts[:element] do
        nil ->
          {:ok, value}
        element_opts ->
          type     = Keyword.get(element_opts, :type, :string)
          on_error = Keyword.get(opts, :on_error, :drop)
          cast_elements(value, type, element_opts, on_error)
      end
    validate_length(result, opts)
  end
  def cast(value, _),
    do: {:error, "Failed to convert value #{inspect(value)} to list."}

  #
  # Cast a single element to the given type.
  #
  @spec cast_element(any(), atom() | tuple(), Keyword.t()) :: {:ok, any()} | {:error, binary()}
  defp cast_element(elem, :any, _opts),       do: {:ok, elem}
  defp cast_element(elem, :atom, opts),       do: Want.Atom.cast(elem, opts)
  defp cast_element(elem, :boolean, opts),    do: Want.Boolean.cast(elem, opts)
  defp cast_element(elem, :date, opts),       do: Want.Date.cast(elem, opts)
  defp cast_element(elem, :datetime, opts),   do: Want.DateTime.cast(elem, opts)
  defp cast_element(elem, :enum, opts),       do: Want.Enum.cast(elem, opts)
  defp cast_element(elem, :float, opts),      do: Want.Float.cast(elem, opts)
  defp cast_element(elem, :integer, opts),    do: Want.Integer.cast(elem, opts)
  defp cast_element(elem, :keywords, opts),   do: Want.Keyword.cast(elem, opts)
  defp cast_element(elem, :list, opts),       do: Want.List.cast(elem, opts)
  defp cast_element(elem, :map, opts),        do: Want.Map.cast(elem, opts)
  defp cast_element(elem, :sort, opts),       do: Want.Sort.cast(elem, opts)
  defp cast_element(elem, :string, opts),     do: Want.String.cast(elem, opts)
  defp cast_element(elem, type, _opts) when is_atom(type) do
    cond do
      Want.Shape.is_shape?(type)      -> Want.Shape.cast(type, elem)
      Want.Type.is_custom_type?(type) -> type.cast(elem, [])
      true -> {:error, "Unknown element type #{inspect(type)} specified."}
    end
  end
  defp cast_element(_elem, type, _opts),
    do: {:error, "Unknown element type #{inspect(type)} specified."}

  #
  # Reduce a list of elements through cast_element/3, respecting the :on_error policy.
  #
  defp cast_elements(list, type, element_opts, on_error) do
    result =
      Enum.reduce_while(list, {:ok, []}, fn(elem, {:ok, out}) ->
        case cast_element(elem, type, element_opts) do
          {:ok, value} ->
            {:cont, {:ok, [value | out]}}
          {:error, _reason} when on_error == :drop ->
            {:cont, {:ok, out}}
          {:error, _reason} = err ->
            {:halt, err}
        end
      end)

    case result do
      {:ok, list}       -> {:ok, Enum.reverse(list)}
      {:error, _} = err -> err
    end
  end

  #
  # Validate the length of the resulting list against :min and :max options.
  #
  defp validate_length({:error, _} = err, _opts), do: err
  defp validate_length({:ok, list} = result, opts) do
    min = Keyword.get(opts, :min)
    max = Keyword.get(opts, :max)
    len = length(list)
    cond do
      is_integer(min) and len < min -> {:error, "List length below minimum of #{min}."}
      is_integer(max) and len > max -> {:error, "List length exceeds maximum of #{max}."}
      true                          -> result
    end
  end
end
