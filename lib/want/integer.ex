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
    * `:clamp` - If true, values outside `:min`/`:max` are clamped to the boundary instead of failing.

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

      iex> Want.Integer.cast(150, max: 100, clamp: true)
      {:ok, 100}

      iex> Want.Integer.cast(-5, min: 0, clamp: true)
      {:ok, 0}

  """
  @spec cast(value :: any(), opts :: Keyword.t()) :: result()
  def cast(value),
    do: cast(value, [])
  def cast(value, opts) when is_binary(value) do
    case Integer.parse(value) do
      {value, ""}  -> cast(value, opts)
      {_, _}       -> {:error, "Failed to convert value #{inspect(value)} to integer."}
      :error       -> {:error, "Failed to convert value #{inspect(value)} to integer."}
    end
  end
  def cast(value, opts) when is_atom(value) do
    with  {:ok, str}    <- Want.string(value),
          {parsed, ""}  <- Integer.parse(str) do
      cast(parsed, opts)
    else
      _ -> {:error, "Failed to convert value #{inspect(value)} to integer."}
    end
  end
  def cast(value, opts) when is_float(value),
    do: cast(Kernel.trunc(value), opts)
  def cast(value, opts) when is_integer(value) do
    clamp = Keyword.get(opts, :clamp, false)
    max   = Keyword.get(opts, :max)
    min   = Keyword.get(opts, :min)
    cond do
      is_integer(max) and value > max and clamp -> {:ok, max}
      is_integer(max) and value > max           -> {:error, "Integer value exceeds maximum #{max}."}
      is_integer(min) and value < min and clamp -> {:ok, min}
      is_integer(min) and value < min           -> {:error, "Integer value below minimum #{min}."}
      true                                       -> {:ok, value}
    end
  end
  def cast(value, _),
    do: {:error, "Failed to convert value #{inspect(value)} to integer."}
end
