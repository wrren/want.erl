defmodule Want.String do
  @moduledoc """
  Manages conversions to and from strings.
  """
  use Want.Type

  @type result :: {:ok, binary()} | {:error, binary()}

  @doc ~S"""
  Casts a given value to a string.

  ## Options

    * `:trim` - If true, strips leading and trailing whitespace before applying any other options.
    * `:max` - Maximum allowable string length (character count).
    * `:min` - Minimum allowable string length (character count).
    * ':decode' - Currently only supports :uri; runs URI.decode on the input value
    * `:matches` - The resulting string must match the given regex.

  ## Examples

      iex> Want.String.cast(1)
      {:ok, "1"}

      iex> Want.String.cast({:a, :b})
      {:error, "Failed to convert value {:a, :b} to string."}

      iex> Want.String.cast(:hello, max: 3)
      {:error, "String length exceeds maximum of 3."}

      iex> Want.String.cast(:a, min: 3)
      {:error, "String length below minimum of 3."}

      iex> Want.String.cast("hello%20world", decode: :uri)
      {:ok, "hello world"}

      iex> Want.String.cast(:a, matches: ~r/a/)
      {:ok, "a"}

      iex> Want.String.cast("  hello  ", trim: true)
      {:ok, "hello"}

      iex> Want.String.cast("  hi  ", trim: true, max: 2)
      {:ok, "hi"}

  """
  @spec cast(value :: any()) :: result()
  def cast(value),
    do: cast(value, [])

  @spec cast(value :: any(), opts :: Keyword.t()) :: result()
  def cast(value, opts) when is_atom(value),
    do: cast(Atom.to_string(value), opts)
  def cast(value, opts) when is_integer(value),
    do: cast(Integer.to_string(value), opts)
  def cast(value, opts) when is_float(value),
    do: cast(Float.to_string(value), opts)
  def cast(value, opts) when is_binary(value) do
    value = if Keyword.get(opts, :trim, false), do: String.trim(value), else: value
    apply_string_opts(value, Keyword.delete(opts, :trim))
  end
  def cast(value, _opts),
    do: {:error, "Failed to convert value #{inspect(value)} to string."}

  defp apply_string_opts(value, [{:max, length} | rest]) when is_integer(length) do
    if String.length(value) > length do
      {:error, "String length exceeds maximum of #{length}."}
    else
      apply_string_opts(value, rest)
    end
  end
  defp apply_string_opts(value, [{:min, length} | rest]) when is_integer(length) do
    if String.length(value) < length do
      {:error, "String length below minimum of #{length}."}
    else
      apply_string_opts(value, rest)
    end
  end
  defp apply_string_opts(value, [{:matches, %Regex{} = regex} | rest]) do
    if Regex.match?(regex, value) do
      apply_string_opts(value, rest)
    else
      {:error, "String does not match provided regex."}
    end
  end
  defp apply_string_opts(value, [{:decode, :uri} | rest]),
    do: apply_string_opts(URI.decode(value), rest)
  defp apply_string_opts(value, [_ | rest]),
    do: apply_string_opts(value, rest)
  defp apply_string_opts(value, []),
    do: {:ok, value}
end
