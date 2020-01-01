defmodule Want.Sort do
  @moduledoc """
  Specialized functions for dealing with sort parameters in
  Phoenix requests.
  """
  use Want.Type

  @type direction   :: :asc | :desc
  @type sort        :: {field :: atom(), direction :: direction()}
  @type result      :: {:ok, sort()} | {:error, binary()}

  @spec cast(input :: any(), opts :: Keyword.t()) :: result()
  def cast(input, opts) when is_list(opts),
    do: cast(input, opts, opts[:fields])
  def cast(_input, _opts, fields) when not is_list(fields),
    do: {:error, "You must specify a list of valid sort fields using the :fields option."}
  def cast(field, opts, fields) when is_binary(field) do
    case String.split(field, ":") do
      [field] ->
        cast({field, "asc"}, opts, fields)
      [field, direction] when direction not in ["asc", "desc"] ->
        cast({field, "asc"}, opts, fields)
      [field, direction] ->
        cast({field, direction}, opts, fields)
    end
  end
  def cast({field, direction}, _opts, fields) when is_binary(field) and direction in ["asc", "desc"] do
    fields
    |> Enum.find(fn
      f when is_binary(f) -> f == field
      f when is_atom(f)   -> Atom.to_string(f) == field
      _                   -> false
    end)
    |> case do
      nil ->
        {:error, "Invalid sort field #{field} specified."}
      f when is_binary(f) ->
        {:ok, {Want.atom!(f), Want.atom!(direction)}}
      f when is_atom(f) ->
        {:ok, {f, Want.atom!(direction)}}
    end
  end
  def cast(input, opts, fields) when not is_binary(input) do
    case Want.string(input) do
      {:ok, string} ->
        cast(string, opts, fields)
      {:error, reason} ->
        {:error, "Failed to convert input to sort field: #{inspect reason}"}
    end
  end

  defimpl Want.Dump, for: Tuple do
    @doc """
    Dump a sort value to a string
    """
    def dump({field, direction}, _opts) when direction in [:asc, :desc],
      do: {:ok, Enum.join([Atom.to_string(field), Atom.to_string(direction)], ":")}
    def dump(other, _opts),
      do: {:error, "Unrecognized dump input #{inspect other}"}
  end

  defimpl Want.Update, for: Tuple do
    @doc """
    Update a sort field. When provided a new value that matches the old sort field, this
    function reverses the sort direction.
    """
    def update({field, :asc}, field),
      do: {:ok, {field, :desc}}
    def update({field, :desc}, field),
      do: {:ok, {field, :asc}}
    def update(_old, {new, direction}),
      do: {:ok, {new, direction}}
    def update(_old, new) when is_atom(new),
      do: {:ok, {new, :asc}}
    def update(old, _new),
      do: {:error, "Unrecognized update tuple #{inspect old}"}
  end
end
