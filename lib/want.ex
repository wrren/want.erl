defmodule Want do
  @moduledoc """
  Type conversion library for Elixir and Erlang. Want allows you to convert between Elixir and Erlang types using an intuitive interface. In
  addition, Elixir users have access to more complex type conversion via the `Want.map/3`, `Want.keywords/3` and `Want.Shape` functions and
  macros.
  """
  @type enumerable  :: map() | keyword()

  @doc """
  Return a list of atoms describing the types that `Want` recognizes.
  """
  def valid_types do
    [
      :any,
      :atom,
      :boolean,
      :date,
      :datetime,
      :enum,
      :float,
      :integer,
      :sort,
      :string,
      :map,
      :keywords
    ]
  end

  @doc """
  Determine whether the given type name is valid.
  """
  def is_valid_type?({:array, type}),
    do: Enum.member?(valid_types(), type) or (is_atom(type) and Want.Shape.is_shape?(type)) or (is_atom(type) and Want.Type.is_custom_type?(type))
  def is_valid_type?(type),
    do: Enum.member?(valid_types(), type) or (is_atom(type) and Want.Shape.is_shape?(type)) or (is_atom(type) and Want.Type.is_custom_type?(type))
  @doc """
  Check whether the given type name is valid and raise if not.
  """
  def check_type!(type) do
    if is_valid_type?(type) do
      true
    else
      raise "Invalid type specified: #{inspect(type)}"
    end
  end

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
  Cast a value to a boolean.

  ## Options

    * `:default` - If conversion fails, this value should be returned instead.

  ## Examples

      iex> Want.boolean("true")
      {:ok, true}

      iex> Want.boolean("FALSE")
      {:ok, false}

      iex> Want.boolean(1.0)
      {:ok, true}

      iex> Want.boolean({:a, :b})
      {:error, "Failed to convert value {:a, :b} to boolean."}

      iex> Want.boolean({:a, :b}, default: true)
      {:ok, true}

  """
  def boolean(value),
    do: boolean(value, [])
  def boolean(value, default) when is_boolean(default),
    do: boolean(value, default: default)
  def boolean(value, opts),
    do: maybe_default(Want.Boolean.cast(value, opts), opts)
  def boolean!(value),
    do: boolean!(value, [])
  def boolean!(value, default) when is_boolean(default),
    do: boolean!(value, default: default)
  def boolean!(value, opts),
    do: maybe_default!(Want.Boolean.cast(value, opts), opts)

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
  Cast an incoming value to a datetime.

  ## Examples

      iex> Want.datetime("2020-02-06 18:23:55.850218Z")
      {:ok, ~U[2020-02-06 18:23:55.850218Z]}

      iex> Want.datetime({{2020, 02, 06}, {18, 23, 55}})
      {:ok, ~U[2020-02-06 18:23:55Z]}

      iex> Want.datetime({{2020, 02, 06}, {18, 23, 55, 123456}})
      {:ok, ~U[2020-02-06 18:23:55.123456Z]}

  """
  def datetime(value),
    do: datetime(value, [])
  def datetime(value, default) when not is_list(default),
    do: datetime(value, default: default)
  def datetime(value, opts),
    do: maybe_default(Want.DateTime.cast(value, opts), opts)
  def datetime!(value),
    do: datetime!(value, [])
  def datetime!(value, default) when not is_list(default),
    do: datetime!(value, default: default)
  def datetime!(value, opts),
    do: maybe_default!(Want.DateTime.cast(value, opts), opts)

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
  Cast an input into a list. By default this function will simply break up the input into list elements, but
  further casting and validation of elements can be performed by providing an `element` option. The separator
  used to split the list defaults to the comma character and this can be controlled using the `separator` option.

  ## Options

    * `:separator` - Determines the character(s) used to separate list items. Defaults to the comma character.
    * `:element` - Provides the ability to further control how list elements are cast and validated. Similar to the
    `map` and `keywords` functions, accepts a keyword list with its own `:type` field and validation options.
    * `:default` - If conversion fails, this value should be returned instead.

  ## Examples

      iex> Want.list("1")
      {:ok, ["1"]}

      iex> Want.list("1", element: [type: :integer])
      {:ok, [1]}

      iex> Want.list("1,2,3,4", element: [type: :integer])
      {:ok, [1, 2, 3, 4]}

      iex> Want.list("1:2:3:4", separator: ":", element: [type: :integer])
      {:ok, [1, 2, 3, 4]}

      iex> Want.list("hello:world", separator: ":", element: [type: :enum, valid: [:hello, :world]])
      {:ok, [:hello, :world]}

      iex> Want.list("hello:world", separator: ":", element: [type: :enum, valid: [:hello]])
      {:ok, [:hello]}

  """
  def list(input, opts \\ []),
    do: maybe_default(Want.List.cast(input, opts), opts)
  def list!(input, opts \\ []),
    do: maybe_default!(Want.List.cast(input, opts), opts)

  @doc """
  Cast an incoming keyword list or map to an output map using the
  provided schema to control conversion rules and validations. Each value in
  the schema map represents conversion options.

  Specify a :type field to cast the input value for a given key to that type, defaults to :string.
  Specific conversion and validation options for each type corresponds to those available
  for `Want.integer/2`, `Want.float/2`, `Want.string/2` and `Want.atom/2`.

  Maps can be nested by using a new schema map as a value in a parent schema. The field from which
  a given value is derived can also be modified using the `:from` option.

  ## Options

    * `:merge` - Provide a map matching the given schema that contains default values to be
      used if the input value does not contain a particular field. Useful when updating a map
      with new inputs without overwriting all fields.

  ## Examples

      iex> Want.map(%{"id" => 1}, %{id: [type: :integer]})
      {:ok, %{id: 1}}

      iex> Want.map(%{"identifier" => 1}, %{id: [type: :integer, from: :identifier]})
      {:ok, %{id: 1}}

      iex> Want.map(%{}, %{id: [type: :integer, default: 1]})
      {:ok, %{id: 1}}

      iex> Want.map(%{"id" => "bananas"}, %{id: [type: :integer, default: 1]})
      {:ok, %{id: 1}}

      iex> Want.map(%{"hello" => "world", "foo" => "bar"}, %{hello: [], foo: [type: :atom]})
      {:ok, %{hello: "world", foo: :bar}}

      iex> Want.map(%{"hello" => %{"foo" => "bar"}}, %{hello: %{foo: [type: :atom]}})
      {:ok, %{hello: %{foo: :bar}}}

      iex> Want.map(%{"id" => "bananas"}, %{id: [type: :integer, default: 1]}, merge: %{id: 2})
      {:ok, %{id: 2}}

  """
  def map(input, schema, opts \\ []),
    do: Want.Map.cast(input, schema, opts)
  def map!(input, schema, opts \\ []) do
    case Want.Map.cast(input, schema, opts) do
      {:ok, output} ->
        output
      {:error, reason} ->
        raise ArgumentError, message: reason
    end
  end

  @doc """
  Cast an incoming keyword list or map to an output keyword list using the provided schema to control
  conversion rules and validations. Each value in the schema map represents conversion options.

  Specify a :type field to cast the input value for a given key to that type, defaults to :string.
  Specific conversion and validation options for each type corresponds to those available
  for `Want.integer/2`, `Want.float/2`, `Want.string/2` and `Want.atom/2`.

  Keyword lists can be nested by using a new schema map as a value in a parent schema. The field from which
  a given value is derived can also be modified using the `:from` option.

  ## Examples

      iex> Want.keywords(%{"id" => 1}, %{id: [type: :integer]})
      {:ok, [id: 1]}

      iex> Want.keywords(%{"identifier" => 1}, %{id: [type: :integer, from: :identifier]})
      {:ok, [id: 1]}

      iex> Want.keywords(%{}, %{id: [type: :integer, default: 1]})
      {:ok, [id: 1]}

      iex> Want.keywords(%{"id" => "bananas"}, %{id: [type: :integer, default: 1]})
      {:ok, [id: 1]}

      iex> Want.keywords(%{"identifier" => "bananas"}, %{id: [type: :integer, default: 1, from: :identifier]})
      {:ok, [id: 1]}

      iex> Want.keywords(%{"hello" => "world", "foo" => "bar"}, %{hello: [], foo: [type: :atom]})
      {:ok, [hello: "world", foo: :bar]}

      iex> Want.keywords(%{"hello" => %{"foo" => "bar"}}, %{hello: %{foo: [type: :atom]}})
      {:ok, [hello: [foo: :bar]]}

      iex> Want.keywords(%{"id" => "bananas"}, %{id: [type: :integer, default: 1]}, merge: [id: 2])
      {:ok, [id: 2]}

  """
  def keywords(input, schema, opts \\ []),
    do: Want.Keyword.cast(input, schema, opts)
  def keywords!(input, schema, opts \\ []) do
    case Want.Keyword.cast(input, schema, opts) do
      {:ok, output} ->
        output
      {:error, reason} ->
        raise ArgumentError, message: reason
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
        raise ArgumentError, message: reason
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
        raise ArgumentError, message: reason
    end
  end
end
