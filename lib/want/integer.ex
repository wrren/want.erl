defmodule Want.Integer do
  @moduledoc """
  Manages conversions to and from integers.
  """
  use Want.Type

  @type result :: {:ok, integer()} | {:error, binary()}

  @doc """
  Cast a value to an integer.

  ## Options

    * `:max` - Maximum allowable integer value.
    * `:min` - Minimum allowable integer value.

  ## Examples

      iex> Want.Integer.cast("1")
      {:ok, 1}

      iex> Want.Integer.cast(1.0)
      {:ok, 1}

      iex> Want.Integer.cast(:'1')
      {:ok, 1}

      iex> Want.Integer.cast({:a, :b})
      {:error, "Failed to convert value {:a, :b} to integer."}

      iex> Want.Integer.cast("10", max: 3)
      {:error, "Integer value exceeds maximum 3."}

      iex> Want.Integer.cast(1.0, min: 3)
      {:error, "Integer value below minimum 3."}
  """
  @spec cast(value :: any(), opts :: Keyword.t()) :: result()
  def cast(value),
    do: cast(value, [])
  def cast(value, opts) when is_binary(value) do
    case Integer.parse(value) do
      {value, _}  -> cast(value, opts)
      :error      -> {:error, "Failed to convert #{value} to integer."}
    end
  end
  def cast(value, opts) when is_atom(value) do
    with  {:ok, value}  <- Want.string(value),
          {value, _}    <- Integer.parse(value) do
      cast(value, opts)
    else
      _ ->
        {:error, "Failed to convert #{value} to integer"}
    end
  end
  def cast(value, opts) when is_float(value),
    do: cast(Kernel.trunc(value), opts)
  def cast(value, [{:max, max} | _]) when is_integer(value) and value > max,
    do: {:error, "Integer value exceeds maximum #{max}."}
  def cast(value, [{:min, min} | _]) when is_integer(value) and value < min,
    do: {:error, "Integer value below minimum #{min}."}
  def cast(value, [_ | t]) when is_integer(value),
    do: cast(value, t)
  def cast(value, []) when is_integer(value),
    do: {:ok, value}
  def cast(value, _),
    do: {:error, "Failed to convert value #{inspect value} to integer."}
end
