defmodule Want do
  @moduledoc """
  Type conversion library for Elixir and Erlang.
  """

  @doc """
  Convert a value to a string.

  ## Options

    * `:max` - Maximum allowable string length.
    * `:min` - Minimum allowable string length.
    * ':decode' - Currently only supports :uri; runs URI.decode on the input value
    * `:matches` - The resulting string must match the given regex.
    * `:default` - If conversion fails, this value should be returned instead.

  ## Examples

    iex> Want.string(1)
    {:ok, "1"}

    iex> Want.string({:a, :b}, default: "string")
    {:ok, "string"}

    iex> Want.string(:hello, max: 3)
    {:error, "String length exceeds maximum of 3."}

    iex> Want.string("hello%20world", decode: :uri)
    {:ok, "hello world"}

    iex> Want.string(:a, min: 3)
    {:error, "String length below minimum of 3."}

    iex> Want.string(:a, matches: ~r/a/)
    {:ok, "a"}
  """
  def string(value),
    do: string(value, [])
  def string(value, default) when not is_list(default),
    do: string(value, default: default)
  def string(value, opts),
    do: maybe_default(Want.String.cast(value, opts), opts)
  def string!(value),
    do: string!(value, [])
  def string!(value, default) when not is_list(default),
    do: string!(value, default: default)
  def string!(value, opts),
    do: maybe_default!(Want.String.cast(value, opts), opts)

  @doc """
  Convert a value to an integer.

  ## Options

    * `:max` - Maximum allowable integer value.
    * `:min` - Minimum allowable integer value.
    * `:default` - If conversion fails, this value should be returned instead.

  ## Examples

    iex> Want.integer(1.0)
    {:ok, 1}

    iex> Want.integer({:a, :b}, default: 1)
    {:ok, 1}

    iex> Want.integer(:'5', max: 3)
    {:error, "Integer value exceeds maximum 3."}

    iex> Want.integer("1", min: 3)
    {:error, "Integer value below minimum 3."}
  """
  def integer(value),
    do: integer(value, [])
  def integer(value, default) when not is_list(default),
    do: integer(value, default: default)
  def integer(value, opts),
    do: maybe_default(Want.Integer.cast(value, opts), opts)
  def integer!(value),
    do: integer!(value, [])
  def integer!(value, default) when not is_list(default),
    do: integer!(value, default: default)
  def integer!(value, opts),
    do: maybe_default!(Want.Integer.cast(value, opts), opts)

  @doc """
  Convert a value to a float.

  ## Options

    * `:max` - Maximum allowable float value.
    * `:min` - Minimum allowable float value.
    * `:default` - If conversion fails, this value should be returned instead.

  ## Examples

    iex> Want.float(1.0)
    {:ok, 1.0}

    iex> Want.float({:a, :b}, default: 1.0)
    {:ok, 1.0}

    iex> Want.float(:'5.0', max: 3.0)
    {:error, "Float value exceeds maximum 3.0."}

    iex> Want.float("1.0", min: 3.0)
    {:error, "Float value below minimum 3.0."}
  """
  def float(value),
    do: float(value, [])
  def float(value, default) when not is_list(default),
    do: float(value, default: default)
  def float(value, opts),
    do: maybe_default(Want.Float.cast(value, opts), opts)
  def float!(value),
    do: float!(value, [])
  def float!(value, default) when not is_list(default),
    do: float!(value, default: default)
  def float!(value, opts),
    do: maybe_default!(Want.Float.cast(value, opts), opts)

  @doc """
  Cast a value to an atom.

  ## Options

    * `:exists` - If true, only convert to an atom if a matching atom already exists.
    * `:default` - If conversion fails, this value should be returned instead.

  ## Examples

    iex> Want.atom("hello")
    {:ok, :hello}

    iex> Want.atom(1.0)
    {:ok, :'1.0'}

    iex> Want.atom({:a, :b})
    {:error, "Failed to convert value {:a, :b} to atom."}

    iex> Want.atom({:a, :b}, default: :c)
    {:ok, :c}

    iex> Want.atom("10", exists: true)
    {:error, "An atom matching the given value does not exist."}
  """
  def atom(value),
    do: atom(value, [])
  def atom(value, default) when not is_list(default),
    do: atom(value, default: default)
  def atom(value, opts),
    do: maybe_default(Want.Atom.cast(value, opts), opts)
  def atom!(value),
    do: atom!(value, [])
  def atom!(value, default) when not is_list(default),
    do: atom!(value, default: default)
  def atom!(value, opts),
    do: maybe_default!(Want.Atom.cast(value, opts), opts)

  @doc """
  Cast an input to a sort tuple.

  ## Options

    * `:fields` - List of allowed sort fields. Casting will fail if the input doesn't match any of these.
    * `:default` - If conversion fails, this value should be returned instead.

  ## Examples

    iex> Want.sort("inserted_at:desc", fields: [:inserted_at, :id, :name])
    {:ok, {:inserted_at, :desc}}

    iex> Want.sort("updated_at", fields: [:inserted_at, :id], default: {:id, :asc})
    {:ok, {:id, :asc}}

    iex> Want.sort("updated_at:asc", [])
    {:error, "You must specify a list of valid sort fields using the :fields option."}

  """
  def sort(input, opts),
    do: maybe_default(Want.Sort.cast(input, opts), opts)
  def sort!(input, opts),
    do: maybe_default!(Want.Sort.cast(input, opts), opts)

  @doc """
  Cast an input value to an enum. The input must loosely match one of the allowed values in order for
  the cast to succeed.

  ## Options

    * `:valid` - List of valid enum values. The input must loosely match one of these.
    * `:default` - If conversion fails, this value should be returned instead.

  ## Examples

    iex> Want.enum("hello", valid: [:hello, :world])
    {:ok, :hello}

    iex> Want.enum("hello", valid: ["hello", :world])
    {:ok, "hello"}

    iex> Want.enum("foo", valid: ["hello", :world], default: :bar)
    {:ok, :bar}
  """
  def enum(input, opts),
    do: maybe_default(Want.Enum.cast(input, opts), opts)
  def enum!(input, opts),
    do: maybe_default!(Want.Enum.cast(input, opts), opts)

  @doc """
  Cast an incoming keyword list or map to an output map using the
  provided schema to control conversion rules and validations. Each value in
  the schema map represents conversion options.

  Specify a :type field to cast the input value for a given key to that type, defaults to :string.
  Specific conversion and validation options for each type corresponds to those available
  for `Want.integer/2`, `Want.float/2`, `Want.string/2` and `Want.atom/2`.

  Maps can be nested by using

  ## Examples

    iex> Want.map(%{"id" => 1}, %{id: [type: :integer]})
    {:ok, %{id: 1}}

    iex> Want.map(%{}, %{id: [type: :integer, default: 1]})
    {:ok, %{id: 1}}

    iex> Want.map(%{"id" => "bananas"}, %{id: [type: :integer, default: 1]})
    {:ok, %{id: 1}}

    iex> Want.map(%{"hello" => "world", "foo" => "bar"}, %{hello: [], foo: [type: :atom]})
    {:ok, %{hello: "world", foo: :bar}}

    iex> Want.map(%{"hello" => %{"foo" => "bar"}}, %{hello: %{foo: [type: :atom]}})
    {:ok, %{hello: %{foo: :bar}}}

  """
  def map(input, schema),
    do: Want.Map.cast(input, schema)
  def map!(input, schema) do
    case Want.Map.cast(input, schema) do
      {:ok, output} ->
        output
      {:error, reason} ->
        raise reason
    end
  end

  @doc """
  Dump a casted input into a more serializable form. Typically used to generate
  Phoenix query parameters.

  ## Options

    * `:update` - Update the input value using Want.Update protocol before dumping

  ## Examples

    iex> Want.dump({:inserted_at, :desc})
    {:ok, "inserted_at:desc"}

    iex> Want.dump({:inserted_at, :desc}, update: :inserted_at)
    {:ok, "inserted_at:asc"}

    iex> Want.dump({:inserted_at, :desc}, update: :updated_at)
    {:ok, "updated_at:asc"}

    iex> Want.dump("hello")
    {:ok, "hello"}

    iex> Want.dump(%{hello: :world, sort: {:inserted_at, :desc}})
    {:ok, [hello: :world, sort: "inserted_at:desc"]}

    iex> Want.dump(%{hello: :world, sort: {:inserted_at, :desc}}, update: [sort: :inserted_at])
    {:ok, [hello: :world, sort: "inserted_at:asc"]}

    iex> Want.dump({:a, :b, :c})
    {:error, "Unrecognized dump input {:a, :b, :c}"}
  """
  def dump(input),
    do: dump(input, [])
  def dump(input, opts) do
    with  true        <- Keyword.has_key?(opts, :update),
          {:ok, new}  <- Want.Update.update(input, opts[:update]) do
      Want.Dump.dump(new, opts)
    else
      false ->
        Want.Dump.dump(input, opts)
      other ->
        other
    end
  end
  def dump!(input),
    do: dump!(input, [])
  def dump!(input, opts) do
    case dump(input, opts) do
      {:ok, result} ->
        result
      {:error, reason} ->
        raise reason
    end
  end

  #
  # Handles a cast result by potentially converting an error
  # result to an ok result through the use of a default value.
  #
  defp maybe_default({:ok, result}, _opts),
    do: {:ok, result}
  defp maybe_default({:error, reason}, opts) do
    if Keyword.has_key?(opts, :default) do
      {:ok, opts[:default]}
    else
      {:error, reason}
    end
  end
  defp maybe_default!(result, opts) do
    case maybe_default(result, opts) do
      {:ok, result} ->
        result
      {:error, reason} ->
        raise reason
    end
  end
end
