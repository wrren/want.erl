defmodule Want.Map do
  @moduledoc """
  Manages conversions to and from maps.
  """

  @type input       :: Want.enumerable()
  @type schema      :: map()
  @type key         :: binary() | atom()
  @type type        :: :atom | :boolean | :date | :datetime | :enum | :float | :integer | {:array, any()} | {:map, any(), any()} | module() | :string
  @type opts        :: Keyword.t()
  @type result      :: {:ok, result :: map()} | {:error, reason :: binary() | map()}
  @type enumerable  :: Want.enumerable()

  defimpl Want.Dump, for: Map do
    @doc """
    Dump a map value to a keyword list. All values inside the map will
    be dumped using the associated `Want` module `dump/1` clauses.
    """
    @spec dump(Want.enumerable(), keyword()) :: {:ok, keyword()} | {:error, term()}
    def dump(input, _opts) do
      input
      |> Map.to_list()
      |> Enum.reduce_while([], fn({k, v}, out) ->
        case Want.dump(v) do
          {:ok, v} ->
            {:cont, [{k, v} | out]}
          {:error, reason} ->
            {:halt, "Failed to dump value for key #{k}: #{inspect reason}"}
        end
      end)
      |> case do
        kv when is_list(kv) ->
          {:ok, Enum.sort_by(kv, fn {k, _v} -> k end, :asc)}
        error ->
          {:error, error}
      end
    end
  end

  defimpl Want.Update, for: Map do
    @doc """
    Update a Map type. For every key specified in the new value, corresponding
    keys in the old value will be updated using the `Want.Update` protocol. Any
    keys in :new that do not exist in :old will be added.
    """
    @spec update(Want.enumerable(), Want.enumerable()) :: {:ok, keyword()}
    def update(old, new) when is_map(new) or is_list(new) do
      {:ok, new
      |> Enum.reduce(old, fn({key, value}, out) ->
        Map.update(out, key, value, fn v ->
          case Want.Update.update(v, value) do
            {:ok, new} ->
              new
            {:error, _reason} ->
              v
          end
        end)
      end)}
    end
  end

  @doc """
  Cast an incoming keyword list or map to an output map using the
  provided schema to control conversion rules and validations.

  ## Options

    * `:merge` - Provide a map matching the given schema that contains default values to be
      used if the input value does not contain a particular field. Useful when updating a map
      with new inputs without overwriting all fields.
    * `:collect_errors` - If true, all field errors are accumulated into a `%{field => reason}`
      map and returned as `{:error, errors}` rather than halting on the first failure.
    * `:unknown` - Controls handling of input keys not present in the schema.
      `:ignore` (default) discards them. `:error` returns an error if any are present.
      `:include` passes them through to the output map unchanged.

  ## Examples

      iex> Want.Map.cast(%{"id" => 1}, %{id: [type: :integer]})
      {:ok, %{id: 1}}

      iex> Want.Map.cast(%{"identifier" => 1}, %{id: [type: :integer, from: :identifier]})
      {:ok, %{id: 1}}

      iex> Want.Map.cast(%{}, %{id: [type: :integer, default: 1]})
      {:ok, %{id: 1}}

      iex> Want.Map.cast(%{"id" => "bananas"}, %{id: [type: :integer, default: 1]})
      {:ok, %{id: 1}}

      iex> Want.Map.cast(%{"hello" => "world", "foo" => "bar"}, %{hello: [], foo: [type: :atom]})
      {:ok, %{hello: "world", foo: :bar}}

      iex> Want.Map.cast(%{"hello" => %{"foo" => "bar"}}, %{hello: %{foo: [type: :atom]}})
      {:ok, %{hello: %{foo: :bar}}}

      iex> Want.Map.cast(%{"id" => "bananas"}, %{id: [type: :integer, default: 1]}, merge: %{id: 2})
      {:ok, %{id: 2}}

      iex> Want.Map.cast(%{"id" => "bananas"}, %{id: [type: :any]})
      {:ok, %{id: "bananas"}}

      iex> Want.Map.cast(%{"a" => %{"b" => %{"c" => 100}}}, %{id: [type: :integer, from: {"a", "b", "c"}]})
      {:ok, %{id: 100}}

      iex> Want.Map.cast(%{"a" => [1, 2, 3, 4]}, %{a: [type: {:array, :integer}]})
      {:ok, %{a: [1, 2, 3, 4]}}

      iex> Want.Map.cast(%{"a" => %{"b" => %{"c" => 100}}}, %{id: [type: :integer, from: {"a", "b", "c"}, transform: fn x -> x * 2 end]})
      {:ok, %{id: 200}}

      iex> Want.Map.cast(%{"hello" => "world"}, %{hello: [], foo: [required: true]})
      {:error, "Failed to cast key foo (key :foo not found) and no default value provided."}

      iex> Want.Map.cast(%{"c" => "world"}, %{foo: [type: :string, from: ["a", "b", "c"]]})
      {:ok, %{foo: "world"}}

      iex> Want.Map.cast(%{"hello" => "world"}, %{hello: [type: :enum, valid: [:world]]})
      {:ok, %{hello: :world}}

      iex> Want.Map.cast(%{"hello" => "world"}, %{hello: [], foo: []})
      {:ok, %{hello: "world"}}

      iex> Want.Map.cast(%{"date" => %Date{year: 2022, month: 01, day: 02}}, %{date: [type: :date]})
      {:ok, %{date: %Date{year: 2022, month: 01, day: 02}}}

      iex> Want.Map.cast(%{"date" => "2022-01-02"}, %{date: [type: :date]})
      {:ok, %{date: %Date{year: 2022, month: 01, day: 02}}}

      iex> Want.Map.cast(%{"archived" => "true"}, %{archived: [type: :boolean, default: false]})
      {:ok, %{archived: true}}

      iex> Want.Map.cast(%{"archived" => "false"}, %{archived: [type: :boolean, default: false]})
      {:ok, %{archived: false}}

      iex> Want.Map.cast(%{}, %{archived: [type: :boolean, default: false]})
      {:ok, %{archived: false}}

  """
  @spec cast(input(), schema()) :: result()
  def cast(input, schema),
    do: cast(input, schema, [])

  @spec cast(input(), key() | list(key()) | tuple() | schema(), opts :: keyword()) :: result()
  def cast(input, schema, opts) when is_map(schema) and (is_list(input) or is_map(input)) and not is_atom(schema) do
    collect_errors = Keyword.get(opts, :collect_errors, false)

    cast_result =
      if collect_errors do
        schema
        |> Enum.reduce({%{}, %{}}, fn({key, field_opts}, {out, errors}) ->
          case cast_field(input, key, field_opts, opts) do
            {:ok, value}     -> {Map.put(out, key, value), errors}
            :skip            -> {out, errors}
            {:error, reason} -> {out, Map.put(errors, key, reason)}
          end
        end)
        |> case do
          {result, errors} when map_size(errors) == 0 -> {:ok, result}
          {_, errors}                                  -> {:error, errors}
        end
      else
        schema
        |> Enum.reduce_while(%{}, fn({key, field_opts}, out) ->
          case cast_field(input, key, field_opts, opts) do
            {:ok, value}     -> {:cont, Map.put(out, key, value)}
            :skip            -> {:cont, out}
            {:error, reason} -> {:halt, {:error, reason}}
          end
        end)
        |> case do
          result when is_map(result) -> {:ok, result}
          {:error, _} = err          -> err
        end
      end

    apply_unknown(cast_result, input, schema, opts)
  end
  def cast(_input, [], _opts),
    do: {:error, "key not found"}
  def cast(input, [key | t], opts) do
    case cast(input, key, opts) do
      {:ok, v}    -> {:ok, v}
      {:error, _} -> cast(input, t, opts)
    end
  end
  def cast(input, key, opts) when is_tuple(key) and (is_list(input) or is_map(input)) do
    key
    |> :erlang.tuple_to_list()
    |> Enum.reduce_while({input, :error}, fn
      (key, {input, _out}) when is_binary(key) and (is_list(input) or is_map(input)) ->
        input
        |> Enum.find(fn
          {k, _v} when is_atom(k)     -> Atom.to_string(k) == key
          {k, _v} when is_binary(k)   -> k == key
          _                           -> false
        end)
        |> case do
          {_, v}  -> {:cont, {v, :ok}}
          nil     -> {:halt, {input, :error}}
        end
      (key, {input, _out}) when is_atom(key) and (is_list(input) or is_map(input)) ->
        input
        |> Enum.find(fn
          {k, _v} when is_atom(k)     -> k == key
          {k, _v} when is_binary(k)   -> k == Atom.to_string(key)
          _                           -> false
        end)
        |> case do
          {_, v}  -> {:cont, {v, :ok}}
          nil     -> {:halt, {input, :error}}
        end
      (_key, {input, _out}) ->
        {:halt, {input, :error}}
    end)
    |> case do
      {v, :ok}      -> cast_value(v, type(opts), opts)
      {_v, :error}  -> {:error, :key_not_found}
    end
  end
  def cast(input, key, opts) when (is_list(input) or (is_map(input) and not is_struct(input))) and is_binary(key) and not is_nil(key) do
    input
    |> Enum.find(fn
      {k, _v} when is_atom(k)     -> Atom.to_string(k) == key
      {k, _v} when is_binary(k)   -> k == key
      _                           -> false
    end)
    |> then(fn res -> {res, type(opts), is_map(opts)} end)
    |> case do
      {{_, v}, nil, true}     -> cast(v, opts)
      {{_, v}, type, false}   -> cast_value(v, type, opts)
      {_, nil, true}          -> {:error, "key #{inspect key} does not specify a type field"}
      _                       -> {:error, "key #{inspect key} not found"}
    end
  end
  def cast(input, :any, _opts),
    do: {:ok, input}
  def cast(input, key, opts) when (is_list(input) or (is_map(input) and not is_struct(input))) and is_atom(key) and not is_nil(key) do
    input
    |> Enum.find(fn
      {k, _v} when is_atom(k)     -> k == key
      {k, _v} when is_binary(k)   -> k == Atom.to_string(key)
      _                           -> false
    end)
    |> then(fn res -> {res, type(opts), is_map(opts)} end)
    |> case do
      {{_, v}, nil, true}     -> cast(v, opts)
      {{_, v}, type, false}   -> cast_value(v, type, opts)
      {_, nil, true}          -> {:error, "key #{inspect key} does not specify a type field"}
      _                       -> {:error, "key #{inspect key} not found"}
    end
  end

  #
  # Cast and validate a single schema field, returning {:ok, value}, :skip, or {:error, reason}.
  # Returns :skip only when the field is genuinely absent from the input and not required.
  # Returns {:error, reason} when the field is present but fails to cast, or when required and missing.
  # With collect_errors: true, cast failures on present-but-invalid fields are always surfaced as errors.
  #
  @spec cast_field(input(), key(), keyword() | map(), keyword()) ::
    {:ok, any()} | :skip | {:error, binary()}
  defp cast_field(input, key, field_opts, cast_opts) do
    collect_errors = Keyword.get(cast_opts, :collect_errors, false)

    case cast(input, field_opts[:from] || key, field_opts) do
      {:ok, value} ->
        value
        |> maybe_transform(field_opts)
        |> apply_validate(field_opts)

      {:error, reason} when is_map(field_opts) ->
        {:error, "Failed to cast key #{key} to map: #{reason}"}

      {:error, reason} ->
        case merge_or_default(key, field_opts, cast_opts) do
          {:ok, default} ->
            {:ok, maybe_transform(default, field_opts)}

          {:error, :no_default} ->
            if field_opts[:required] do
              {:error, "Failed to cast key #{key} (#{reason}) and no default value provided."}
            else
              # When the key is present in the input but its value failed to cast, surface
              # the error (especially important for collect_errors mode). When the key is
              # genuinely absent, silently skip the optional field.
              if collect_errors and not key_not_found_error?(reason) do
                {:error, reason}
              else
                :skip
              end
            end
        end
    end
  end

  # Returns true when an error reason indicates the key was simply absent from the input,
  # as opposed to the key being present but the value failing to cast.
  defp key_not_found_error?(:key_not_found), do: true
  defp key_not_found_error?(reason) when is_binary(reason), do: String.ends_with?(reason, "not found")
  defp key_not_found_error?(_), do: false

  #
  # Apply a :validate function to an already-cast value.
  # The function receives the value and must return :ok | true | {:ok, result} | false | {:error, reason}.
  #
  defp apply_validate(value, opts) when is_list(opts) do
    case opts[:validate] do
      nil ->
        {:ok, value}
      f when is_function(f, 1) ->
        case f.(value) do
          :ok              -> {:ok, value}
          true             -> {:ok, value}
          {:ok, result}    -> {:ok, result}
          false            -> {:error, "Validation failed for value #{inspect(value)}."}
          {:error, _} = e  -> e
        end
      _ ->
        {:ok, value}
    end
  end
  defp apply_validate(value, _opts), do: {:ok, value}

  #
  # Handle unknown input keys according to the :unknown option.
  #
  defp apply_unknown({:error, _} = err, _input, _schema, _opts), do: err
  defp apply_unknown({:ok, output} = result, input, schema, opts) do
    case Keyword.get(opts, :unknown, :ignore) do
      :ignore ->
        result

      :error ->
        case unknown_keys(input, schema) do
          []   -> result
          keys -> {:error, "Unexpected keys in input: #{inspect(keys)}"}
        end

      :include ->
        known = MapSet.new(known_source_keys(schema))
        extra =
          Enum.reduce(input, %{}, fn {k, v}, acc ->
            if MapSet.member?(known, to_string_key(k)), do: acc, else: Map.put(acc, k, v)
          end)
        {:ok, Map.merge(output, extra)}

      _ ->
        result
    end
  end

  defp unknown_keys(input, schema) do
    known = MapSet.new(known_source_keys(schema))
    input
    |> Enum.map(fn {k, _} -> k end)
    |> Enum.reject(fn k -> MapSet.member?(known, to_string_key(k)) end)
  end

  #
  # Collect all keys that are "known" to a schema — the output key names and
  # any :from sources — as strings so they can be compared against input keys
  # regardless of whether those are atoms or binaries.
  #
  defp known_source_keys(schema) do
    Enum.flat_map(schema, fn {key, field_opts} ->
      froms =
        case field_opts do
          opts when is_list(opts) ->
            opts
            |> Keyword.get(:from, key)
            |> List.wrap()
          _ ->
            [key]
        end

      # For nested paths like {"a", "b", "c"}, only the first element is a top-level key.
      Enum.flat_map(froms, fn
        f when is_tuple(f) -> [to_string_key(elem(f, 0))]
        f                  -> [to_string_key(f)]
      end)
    end)
  end

  defp to_string_key(k) when is_atom(k),   do: Atom.to_string(k)
  defp to_string_key(k) when is_binary(k), do: k
  defp to_string_key(k),                   do: inspect(k)

  #
  # Cast a single value to a target type.
  #
  @spec cast_value(any(), type(), keyword()) :: {:ok, any()} | {:error, reason :: term()}
  defp cast_value(input, :boolean, opts),
    do: Want.Boolean.cast(input, opts)
  defp cast_value(input, :integer, opts),
    do: Want.Integer.cast(input, opts)
  defp cast_value(input, :string, opts),
    do: Want.String.cast(input, opts)
  defp cast_value(input, :float, opts),
    do: Want.Float.cast(input, opts)
  defp cast_value(input, :atom, opts),
    do: Want.Atom.cast(input, opts)
  defp cast_value(input, :sort, opts),
    do: Want.Sort.cast(input, opts)
  defp cast_value(input, :enum, opts),
    do: Want.Enum.cast(input, opts)
  defp cast_value(input, :datetime, opts),
    do: Want.DateTime.cast(input, opts)
  defp cast_value(input, :date, opts),
    do: Want.Date.cast(input, opts)
  defp cast_value(input, {:array, type}, opts) when is_list(input) do
    Enum.reduce_while(input, {:ok, []}, fn(elem, {:ok, out}) ->
      case cast_value(elem, type, opts) do
        {:ok, value}      -> {:cont, {:ok, [maybe_transform(value, opts) | out]}}
        {:error, reason}  -> {:halt, {:error, reason}}
      end
    end)
    |> case do
      {:ok, list}   -> {:ok, Enum.reverse(list)}
      other         -> other
    end
  end
  defp cast_value(_, {:array, _type}, opts),
    do: {:ok, maybe_transform([], opts)}
  defp cast_value(input, {:map, key_type, value_type}, opts) when is_map(input) do
    Enum.reduce_while(input, {:ok, %{}}, fn({key, value}, {:ok, map}) ->
      with  {:ok, key}          <- cast_value(key, key_type, []),
            {:ok, value}        <- cast_value(value, value_type, []) do
        {:cont, {:ok, Map.put(map, key, maybe_transform(value, opts))}}
      else
        {:error, reason} -> {:halt, {:error, reason}}
      end
    end)
  end
  defp cast_value(_, {:map, _key_type, _value_type}, opts),
    do: {:ok, maybe_transform(%{}, opts)}
  defp cast_value(input, :any, opts),
    do: {:ok, maybe_transform(input, opts)}
  defp cast_value(input, type, opts) when is_atom(type) do
    cond do
      Want.Shape.is_shape?(type)        -> Want.Shape.cast(type, input)
      Want.Type.is_custom_type?(type)   -> Want.Type.cast(type, input, opts)
      true                              -> {:error, "unknown cast type #{inspect type} specified"}
    end
  end
  defp cast_value(_input, type, _opts),
    do: {:error, "unknown cast type #{inspect type} specified"}

  #
  # Attempt to generate a value for a given map key, either using the cast options'
  # `merge` map or a default value from the field options.
  #
  defp merge_or_default(key, field_opts, cast_opts) do
    cond do
      Map.has_key?(Keyword.get(cast_opts, :merge, %{}), key) ->
        {:ok, Map.get(Keyword.get(cast_opts, :merge, %{}), key)}
      Keyword.has_key?(field_opts, :default) ->
        {:ok, field_opts[:default]}
      true ->
        {:error, :no_default}
    end
  end

  #
  # Conditionally apply a transformation to a derived value based on whether the
  # `:transform` option has been specified and is valid.
  #
  @spec maybe_transform(term(), Keyword.t()) :: term()
  defp maybe_transform(value, opts) when is_list(opts) do
    with  true  <- Keyword.has_key?(opts, :transform),
          true  <- Kernel.is_function(opts[:transform], 1) do
      Kernel.apply(opts[:transform], [value])
    else
      _ -> value
    end
  end
  defp maybe_transform(value, _),
    do: value

  #
  # Pull a type specified from a set of options
  #
  defp type(opts) when is_list(opts),
    do: Keyword.get(opts, :type, :string)
  defp type(opts) when is_map(opts),
    do: nil
end
