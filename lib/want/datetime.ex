defmodule Want.DateTime do
  @moduledoc """
  Provides conversions to and from Elixir DateTime structs.
  """
  @type t() :: DateTime.t()

  @type result      :: {:ok, t()} | {:error, binary()} | {:error, atom()} | {:gap, t(), t()} | {:ambiguous, t(), t()}

  @doc """
  Cast an input to a DateTime.

  ## Options

  ## Options

    * `:decode` - If set to `:uri`, executes a URI decode on the input value before casting it.
    * `:format` - If set to `:unix_ms`, interprets the input as a unix timestamp with millisecond accuracy. Otherwise as seconds since the epoch

  ## Examples

      iex> Want.DateTime.cast("2024-11-18T09:51:39.0Z", [])
      {:ok, %DateTime{time_zone: "Etc/UTC", zone_abbr: "UTC", utc_offset: 0, std_offset: 0, year: 2024, month: 11, day: 18, hour: 09, minute: 51, second: 39, microsecond: {0, 1}}}

      iex> Want.DateTime.cast(1731671182000, format: :unix_ms)
      {:ok, %DateTime{time_zone: "Etc/UTC", zone_abbr: "UTC", utc_offset: 0, std_offset: 0, year: 2024, month: 11, day: 15, hour: 11, minute: 46, second: 22}}

      iex> Want.DateTime.cast(1731671182, [])
      {:ok, %DateTime{time_zone: "Etc/UTC", zone_abbr: "UTC", utc_offset: 0, std_offset: 0, year: 2024, month: 11, day: 15, hour: 11, minute: 46, second: 22}}
  """
  @spec cast(input :: any(), opts :: Keyword.t()) :: result()
  def cast(input, opts) when is_binary(input) and is_list(opts) do
    cond do
      opts[:decode] == :uri ->
        cast(URI.decode(input), Keyword.delete(opts, :decode))
      true ->
        cast(DateTime.from_iso8601(input), opts)
    end
  end
  def cast(input, opts) when is_integer(input) and is_list(opts) do
    cond do
      opts[:format] == :unix_ms ->
        cast(DateTime.from_unix(div(input, 1000)), opts)
      true ->
        cast(DateTime.from_unix(input), opts)
    end
  end
  def cast({{_year, _month, _day}, {_hour, _minute, _second}} = erl, opts),
    do: cast(NaiveDateTime.from_erl(erl), opts)
  def cast({{year, month, day}, {hour, minute, second, millisecond}}, opts),
    do: cast(NaiveDateTime.from_erl({{year, month, day}, {hour, minute, second}}, {millisecond, opts[:precision] || 6}), opts)
  def cast({:ok, %NaiveDateTime{} = datetime}, opts),
    do: cast(DateTime.from_naive(datetime, opts[:calendar] || "Etc/UTC", opts[:database] || Calendar.get_time_zone_database()), opts)
  def cast(%DateTime{} = datetime, _opts),
    do: {:ok, datetime}
  def cast({:ok, %DateTime{} = datetime}, _opts),
    do: {:ok, datetime}
  def cast({:ok, datetime, _offset}, _opts),
    do: {:ok, datetime}
  def cast({:error, reason}, _opts),
    do: {:error, reason}
  def cast({:ambiguous, _, _}, _opts),
    do: {:error, :ambiguous_conversion}

  defimpl Want.Dump, for: DateTime do
    @doc """
    Dump a datetime value to a string
    """
    @spec dump(DateTime.t(), keyword()) :: {:ok, String.t()}
    def dump(datetime, _opts),
      do: {:ok, DateTime.to_string(datetime)}
  end
end
