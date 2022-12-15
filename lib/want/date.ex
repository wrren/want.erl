defmodule Want.Date do
  @moduledoc """
  Provides conversions to and from Elixir Date structs.
  """
  @type result      :: {:ok, %Date{}} | {:error, binary()} | {:error, atom()}

  @doc """
  Cast a value to an date.

  ## Options

    * `:decode` - If set to `:uri`, executes a URI decode on the input value before casting it.

  ## Examples

    iex> Want.Date.cast("2022-03-04")
    {:ok, %Date{year: 2022, month: 03, day: 04}}
  """
  @spec cast(value :: any()) :: result()
  def cast(value),
    do: cast(value, [])

  @spec cast(input :: any(), opts :: Keyword.t()) :: result()
  def cast(input, opts) when is_binary(input) and is_list(opts) do
    cond do
      opts[:decode] == :uri ->
        cast(URI.decode(input), Keyword.delete(opts, :decode))
      true ->
        cast(Date.from_iso8601(input), opts)
    end
  end
  def cast({year, month, day}, opts) when is_integer(year) and is_integer(month) and is_integer(day),
    do: cast(Date.from_erl({year, month, day}, Calendar.get_time_zone_database()), opts)
  def cast({:ok, %Date{} = date}, opts),
    do: cast(date, opts)
  def cast(%Date{} = date, _opts),
    do: {:ok, date}
  def cast({:ok, date, _offset}, _opts),
    do: {:ok, date}
  def cast({:error, reason}, _opts),
    do: {:error, reason}
  def cast({:ambiguous, _, _}, _opts),
    do: {:error, :ambiguous_conversion}

  defimpl Want.Dump, for: Date do
    @doc """
    Dump a date value to a string
    """
    @spec dump(Date.t(), keyword()) :: {:ok, String.t()}
    def dump(date, _opts),
      do: {:ok, Date.to_string(date)}
  end
end
