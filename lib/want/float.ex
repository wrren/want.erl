defmodule Want.Float do
  @moduledoc """
  Performs type conversions to float values.
  """
  use Want.Type

  @type result :: {:ok, float()} | {:error, binary()}

  @doc """
  Cast a value to a float.

  ## Options

    * `:max` - Maximum allowable float value.
    * `:min` - Minimum allowable float value.

  ## Examples

      iex> Want.Float.cast("1")
      {:ok, 1.0}

      iex> Want.Float.cast(1.0)
      {:ok, 1.0}

      iex> Want.Float.cast(:'1')
      {:ok, 1.0}

      iex> Want.Float.cast({:a, :b})
      {:error, "Failed to convert value {:a, :b} to float."}

      iex> Want.Float.cast("10", max: 3.0)
      {:error, "Float value exceeds maximum 3.0."}

      iex> Want.Float.cast(1.0, min: 3.0)
      {:error, "Float value below minimum 3.0."}
  """
  @spec cast(value :: any()) :: result()
  def cast(value),
    do: cast(value, [])

  @spec cast(value :: any(), opts :: Keyword.t()) :: result()
  def cast(value, opts) when is_binary(value) do
    case Float.parse(value) do
      {value, _}  -> cast(value, opts)
      :error      -> {:error, "Failed to convert #{value} to float."}
    end
  end
  def cast(value, opts) when is_atom(value) do
    with  {:ok, value}  <- Want.string(value),
          {value, _}    <- Float.parse(value) do
      cast(value, opts)
    else
      _ ->
        {:error, "Failed to convert #{value} to float"}
    end
  end
  def cast(value, opts) when is_integer(value),
    do: cast(value / 1, opts)
  def cast(value, [{:max, max} | _]) when is_float(value) and value > max,
    do: {:error, "Float value exceeds maximum #{max}."}
  def cast(value, [{:min, min} | _]) when is_float(value) and value < min,
    do: {:error, "Float value below minimum #{min}."}
  def cast(value, [_ | t]) when is_float(value),
    do: cast(value, t)
  def cast(value, []) when is_float(value),
    do: {:ok, value}
  def cast(value, _),
    do: {:error, "Failed to convert value #{inspect value} to float."}
end
