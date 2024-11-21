defmodule Want.Boolean do
  @moduledoc """
  Performs type conversions to boolean values.
  """
  use Want.Type

  @type result :: {:ok, boolean()} | {:error, binary()}

  @doc """
  Cast a value to a boolean.

  ## Examples

      iex> Want.Boolean.cast("true")
      {:ok, true}

      iex> Want.Boolean.cast("false")
      {:ok, false}

      iex> Want.Boolean.cast("TRUE")
      {:ok, true}

      iex> Want.Boolean.cast(1.0)
      {:ok, true}

      iex> Want.Boolean.cast(0)
      {:ok, false}

      iex> Want.Boolean.cast({:a, :b})
      {:error, "Failed to convert value {:a, :b} to boolean."}
  """
  @spec cast(value :: any()) :: result()
  def cast(value),
    do: cast(value, [])

  @spec cast(value :: any(), opts :: Keyword.t()) :: result()
  def cast(value, _opts) when is_atom(value) and value in [true, false],
    do: {:ok, value}
  def cast(value, _opts) when is_integer(value),
    do: {:ok, value != 0}
  def cast(value, _opts) when is_float(value),
    do: {:ok, value != 0.0}
  def cast(value, _opts) when is_binary(value) do
   case value
    |> String.trim()
    |> String.downcase() do
      value when value in ~w"true t yes y 1" -> {:ok, true}
      value when value in ~w"false f no n 0" -> {:ok, false}
      _ -> {:error, "Failed to convert value #{inspect(value)} to boolean."}
    end
  end
  def cast(value, _opts),
    do: {:error, "Failed to convert value #{inspect value} to boolean."}
end
