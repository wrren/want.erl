defmodule Want.String do
  @moduledoc """
  Manages conversions to and from strings.
  """
  use Want.Type

  @type result :: {:ok, binary()} | {:error, binary()}

  @doc """
  Casts a given value to a string.

  ## Options

    * `:max` - Maximum allowable string length.
    * `:min` - Minimum allowable string length.
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

    iex> Want.String.cast(:a, matches: ~r/a/)
    {:ok, "a"}
  """
  @spec cast(value :: any()) :: result()
  def cast(value),
    do: cast(value, [])

  @spec cast(value :: any(), opts :: Keyword.t()) :: result()
  def cast(value, [{:max, length} | _]) when is_binary(value) and is_integer(length) and byte_size(value) > length,
    do: {:error, "String length exceeds maximum of #{length}."}
  def cast(value, [{:min, length} | _]) when is_binary(value) and is_integer(length) and byte_size(value) < length,
    do: {:error, "String length below minimum of #{length}."}
  def cast(value, [{:matches, %Regex{} = regex} | t]) when is_binary(value) do
    if Regex.match?(regex, value) do
      cast(value, t)
    else
      {:error, "String does not match provided regex."}
    end
  end
  def cast(value, [_ | t]) when is_binary(value),
    do: cast(value, t)
  def cast(value, []) when is_binary(value),
    do: {:ok, value}
  def cast(value, opts) when is_atom(value),
    do: cast(Atom.to_string(value), opts)
  def cast(value, opts) when is_integer(value),
    do: cast(Integer.to_string(value), opts)
  def cast(value, opts) when is_float(value),
    do: cast(Float.to_string(value), opts)
  def cast(value, _opts),
    do: {:error, "Failed to convert value #{inspect value} to string."}
end
