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
    * `:clamp` - If true, values outside `:min`/`:max` are clamped to the boundary instead of failing.

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

      iex> Want.Float.cast(1.5, max: 1.0, clamp: true)
      {:ok, 1.0}

      iex> Want.Float.cast(-0.5, min: 0.0, clamp: true)
      {:ok, 0.0}

  """
  @spec cast(value :: any()) :: result()
  def cast(value),
    do: cast(value, [])

  @spec cast(value :: any(), opts :: Keyword.t()) :: result()
  def cast(value, opts) when is_binary(value) do
    case Float.parse(value) do
      {value, ""}  -> cast(value, opts)
      {_, _}       -> {:error, "Failed to convert value #{inspect(value)} to float."}
      :error       -> {:error, "Failed to convert value #{inspect(value)} to float."}
    end
  end
  def cast(value, opts) when is_atom(value) do
    with  {:ok, str}    <- Want.string(value),
          {parsed, ""}  <- Float.parse(str) do
      cast(parsed, opts)
    else
      _ -> {:error, "Failed to convert value #{inspect(value)} to float."}
    end
  end
  def cast(value, opts) when is_integer(value),
    do: cast(value / 1, opts)
  def cast(value, opts) when is_float(value) do
    clamp = Keyword.get(opts, :clamp, false)
    max   = Keyword.get(opts, :max)
    min   = Keyword.get(opts, :min)
    cond do
      is_number(max) and value > max and clamp -> {:ok, max * 1.0}
      is_number(max) and value > max           -> {:error, "Float value exceeds maximum #{max}."}
      is_number(min) and value < min and clamp -> {:ok, min * 1.0}
      is_number(min) and value < min           -> {:error, "Float value below minimum #{min}."}
      true                                      -> {:ok, value}
    end
  end
  def cast(value, _),
    do: {:error, "Failed to convert value #{inspect(value)} to float."}
end
