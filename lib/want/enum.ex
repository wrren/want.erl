defmodule Want.Enum do
  @moduledoc """
  Provides type conversions to enumerations.
  """
  use Want.Type

  @type result :: {:ok, result :: any()} | {:error, reason :: binary()}

  @doc """
  Cast a given value to an enum value. The given options keyword list must
  include an array of valid enum values under the :valid key, otherwise the
  function will return an error tuple.

  ## Options

    * `:valid` - List of valid enum values. The input must loosely match one of these.

  ## Examples

    iex> Want.Enum.cast("hello", valid: [:hello, :world])
    {:ok, :hello}

    iex> Want.Enum.cast("hello", valid: ["hello", :world])
    {:ok, "hello"}
  """
  @spec cast(value :: any(), opts :: Keyword.t()) :: result()
  def cast(value, opts) when is_list(opts) do
    with {:ok, opts} <- validate_opts(opts) do
      cast(value, opts, Keyword.get(opts, :valid))
    end
  end
  def cast(value, _opts, [value | _]),
    do: {:ok, value}
  def cast(value, opts, [v | t]) when is_binary(value) and is_binary(v),
    do: cast(value, opts, t)
  def cast(value, opts, [v | t]) when is_atom(value) and is_atom(v),
    do: cast(value, opts, t)
  def cast(value, opts, [v | t]) when is_number(value) and is_number(v),
    do: cast(value, opts, t)
  def cast(value, opts, [v | t] = valid) when is_binary(v) do
    case Want.String.cast(value) do
      {:ok, value}  -> cast(value, opts, valid)
      {:error, _}   -> cast(value, opts, t)
    end
  end
  def cast(value, opts, [v | t] = valid) when is_integer(v) do
    case Want.Integer.cast(value) do
      {:ok, value}  -> cast(value, opts, valid)
      {:error, _}   -> cast(value, opts, t)
    end
  end
  def cast(value, opts, [v | t] = valid) when is_float(v) do
    case Want.Float.cast(value) do
      {:ok, value}  -> cast(value, opts, valid)
      {:error, _}   -> cast(value, opts, t)
    end
  end
  def cast(value, opts, [v | t]) when is_atom(v) and is_binary(value) do
    if String.downcase(Atom.to_string(v)) == String.downcase(value) do
      {:ok, v}
    else
      cast(value, opts, t)
    end
  end
  def cast(value, opts, [v | t] = valid) when is_atom(v) do
    case Want.Atom.cast(value, exists: true) do
      {:ok, value}  -> cast(value, opts, valid)
      {:error, _}   -> cast(value, opts, t)
    end
  end
  def cast(value, _opts, []),
    do: {:error, "#{inspect value} did not match any valid enum values."}


  #
  # Validate that casting options contain required keys.
  #
  defp validate_opts(opts) do
    if is_list(Keyword.get(opts, :valid)) do
      {:ok, opts}
    else
      {:error, "Enum casting options must include a list of valid values under the :valid key."}
    end
  end
end
