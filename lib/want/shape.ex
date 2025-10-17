defmodule Want.Shape do
  @moduledoc """
  Provides macros for declaring an Ecto-like schema definition that can be used
  to cast incoming data. Most of the macro logic here was adapted from `Ecto.Schema`.
  """

  @doc false
  defmacro __using__(_) do
    quote do
      import Want.Shape, only: [shape: 1, shape: 2, field: 1, field: 2, field: 3]

      @doc """
      Cast incoming data to this Shape.
      """
      @spec cast(map()) :: {:ok, t()} | {:error, reason :: term()}
      def cast(data),
        do: Want.Shape.cast(__MODULE__, data)

      @doc """
      Cast incoming data to this Shape. Raises on error.
      """
      @spec cast!(map()) :: t()
      def cast!(data),
        do: Want.Shape.cast!(__MODULE__, data)

      @doc """
      Cast a list of maps to a list of Shapes.
      """
      @spec cast_all(list(map())) :: {:ok, list(t())} | {:error, reason :: term()}
      def cast_all(data),
        do: Want.Shape.cast_all(__MODULE__, data)

      @doc """
      Cast a list of maps to a list of Shapes.
      """
      @spec cast_all!(list(map())) :: list(t())
      def cast_all!(data),
        do: Want.Shape.cast_all!(__MODULE__, data)
    end
  end

  @doc """
  Determine whether the given module represents a shape.
  """
  @spec is_shape?(module()) :: boolean()
  def is_shape?(module) when is_atom(module) do
    case Code.ensure_compiled(module) do
      {:module, _}  -> Kernel.function_exported?(module, :__fields__, 0)
      _             -> false
    end
  end

  @doc """
  Define a field within a shape.
  """
  defmacro field(name, type \\ :string, opts \\ []) do
    quote do
      Want.Shape.__field__(__MODULE__, unquote(name), unquote(type), unquote(opts))
    end
  end

  @doc false
  def __field__(mod, name, type, opts \\ []) do
    if Want.is_valid_type?(type) do
      Module.put_attribute(mod, :want_field_info,   {name, [{:type, type} | opts]})
      Module.put_attribute(mod, :want_shape_fields, name)
    else
      raise "Invalid shape field type #{type} specified."
    end
  end

  @doc """
  Cast incoming data based on a Shape definition.
  """
  @spec cast(module(), map()) :: {:ok, struct()} | {:error, reason :: term()}
  def cast(shape, data) when is_atom(shape) and is_map(data) do
    with {:ok, m} <- Want.map(data, Map.new(Kernel.apply(shape, :__schema__, []))) do
      {:ok, maybe_transform(shape, Kernel.struct(shape, m))}
    end
  end

  @doc """
  Cast incoming data based on a Shape definition. Raises on error.
  """
  @spec cast!(module(), map()) :: struct()
  def cast!(shape, data) when is_atom(shape) and is_map(data) do
    case cast(shape, data) do
      {:ok, struct}     -> struct
      {:error, reason}  -> raise reason
    end
  end

  @doc """
  Cast a list of maps to a list of Shapes.
  """
  @spec cast_all(module(), list(map())) :: {:ok, list(struct())} | {:error, reason :: term()}
  def cast_all(shape, data) when is_atom(shape) and is_list(data) do
    Enum.reduce_while(data, {:ok, []}, fn(data, {:ok, out}) ->
      case cast(shape, data) do
        {:ok, struct}     -> {:cont, {:ok, [struct | out]}}
        {:error, reason}  -> {:halt, {:error, reason}}
      end
    end)
    |> case do
      {:ok, structs}    -> {:ok, Enum.reverse(structs)}
      {:error, reason}  -> {:error, reason}
    end
  end

  @doc """
  Cast a list of maps to a list of Shapes.
  """
  @spec cast_all!(module(), list(map())) :: list(struct())
  def cast_all!(shape, data) when is_atom(shape) and is_list(data) do
    case cast_all(shape, data) do
      {:ok, structs}    -> structs
      {:error, reason}  -> raise reason
    end
  end

  #
  # Perform any configured transformations on the result of a shape cast.
  #
  @spec maybe_transform(module(), struct()) :: struct()
  defp maybe_transform(shape, out) do
    with  true                                      <- Kernel.function_exported?(shape, :__transform__, 0),
          transform when is_function(transform, 1)  <- Kernel.apply(shape, :__transform__, []) do
      transform.(out)
    else
      _ -> out
    end
  end

  @doc """
  Define a shape schema. Generates a struct definition for the current module that includes the data
  needed to correctly cast incoming JSON/map data into that struct, including field sourcing, type
  conversions, etc.
  """
  defmacro shape(do: block),
    do: shape(__CALLER__, [], block)

  @doc """
  Define a shape schema. Generates a struct definition for the current module that includes the data
  needed to correctly cast incoming JSON/map data into that struct, including field sourcing, type
  conversions, etc.

  ## Options

    * `:transform` - A function that accepts the generated shape struct and performs any transformations required. Called after
    a successful cast.

  """
  defmacro shape(opts, do: block),
    do: shape(__CALLER__, opts, block)

  defp shape(caller, opts, block) do
    transform = opts[:transform]

    prelude =
      quote do
        if line = Module.get_attribute(__MODULE__, :want_shape_defined) do
          raise "Shape already defined for #{inspect(__MODULE__)} on line #{line}"
        end

        @want_shape_defined unquote(caller.line)

        Module.register_attribute(__MODULE__, :want_shape_fields,   accumulate: true)
        Module.register_attribute(__MODULE__, :want_field_info,     accumulate: true)

        @want_transform unquote(transform)

        try do
          import Want.Shape
          unquote(block)
        after
          :ok
        end
      end

    postlude =
      quote unquote: false do
        all_fields = Enum.reverse(@want_field_info)

        defstruct Enum.reverse(@want_shape_fields)

        def __fields__,
          do: @want_shape_fields

        def __schema__,
          do: @want_field_info

        def __transform__,
          do: @want_transform

        @type t() :: %__MODULE__{
          unquote_splicing(
            Enum.map(all_fields, fn {name, [{:type, type} | _]} ->
              {name, Want.Type.to_typespec(type)}
            end)
          )
        }
      end

    quote do
      unquote(prelude)
      unquote(postlude)
    end
  end
end
