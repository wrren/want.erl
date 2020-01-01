defmodule Want.Atom do
  @moduledoc """
  Performs type conversions to atom values.
  """
  use Want.Type

  @type result :: {:ok, atom()} | {:error, binary()}

  @doc """
  Cast a value to an atom.

  ## Options

    * `:exists` - If true, only convert to an atom if a matching atom already exists.

  ## Examples

    iex> Want.Atom.cast("hello")
    {:ok, :hello}

    iex> Want.Atom.cast(1.0)
    {:ok, :'1.0'}

    iex> Want.Atom.cast({:a, :b})
    {:error, "Failed to convert value {:a, :b} to atom."}

    iex> Want.Atom.cast("10", exists: true)
    {:error, "An atom matching the given value does not exist."}
  """
  @spec cast(value :: any()) :: result()
  def cast(value),
    do: cast(value, [])

  @spec cast(value :: any(), opts :: Keyword.t()) :: result()
  def cast(value, _opts) when is_atom(value),
    do: {:ok, value}
  def cast(value, opts) when is_integer(value) or is_float(value) do
    case Want.String.cast(value) do
      {:ok, value} -> cast(value, opts)
    end
  end
  def cast(value, [{:exists, true} | t]) when is_binary(value) do
    try do
      cast(String.to_existing_atom(value), t)
    rescue
      ArgumentError ->
        {:error, "An atom matching the given value does not exist."}
    end
  end
  def cast(value, [_ | t]) when is_binary(value),
    do: cast(value, t)
  def cast(value, []) when is_binary(value),
    do: {:ok, String.to_atom(value)}
  def cast(value, _opts),
    do: {:error, "Failed to convert value #{inspect value} to atom."}
end
