defmodule Want.List do
  @moduledoc """
  Manages conversions to and from lists.
  """
  use Want.Type

  @type element :: any()
  @type result  :: {:ok, list(element())} | {:error, binary()}

  @default_separator ","

  @doc """
  Cast an input into a list. By default this function will simply break up the input into list elements, but
  further casting and validation of elements can be performed by providing an `element` option. The separator
  used to split the list defaults to the comma character and this can be controlled using the `separator` option.

  ## Options

    * `:separator` - Determines the character(s) used to separate list items. Defaults to the comma character.
    * `:element` - Provides the ability to further control how list elements are cast and validated. Similar to the
    `map` and `keywords` functions, accepts a keyword list with its own `:type` field and validation options.

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
    case {opts[:element], Keyword.get(Keyword.get(opts, :element, []), :type)} do
      {nil, _} ->
        {:ok, value}
      {o, :any} ->
        {:ok, cast_elements(value, Want.Any, o)}
      {o, :enum} ->
        {:ok, cast_elements(value, Want.Enum, o)}
      {o, :integer} ->
        {:ok, cast_elements(value, Want.Integer, o)}
      {o, :atom} ->
        {:ok, cast_elements(value, Want.Atom, o)}
      {o, :float} ->
        {:ok, cast_elements(value, Want.Float, o)}
      {o, :sort} ->
        {:ok, cast_elements(value, Want.Sort, o)}
      {o, :string} ->
        {:ok, cast_elements(value, Want.String, o)}
      {o, :list} ->
        {:ok, cast_elements(value, Want.List, o)}
      {o, :map} ->
        {:ok, cast_elements(value, Want.Map, o)}
      {o, :keywords} ->
        {:ok, cast_elements(value, Want.Keyword, o)}
    end
  end
  def cast(value, _),
    do: {:error, "Failed to convert value #{inspect value} to integer."}

  @doc false
  defp cast_elements(list, mod, opts) do
    list
    |> Enum.reduce([], fn(elem, out) ->
      case mod.cast(elem, opts) do
        {:ok, elem} ->
          [elem | out]
        {:error, _reason} ->
          out
      end
    end)
    |> Enum.reverse()
  end
end
