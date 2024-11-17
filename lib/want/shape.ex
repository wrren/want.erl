defmodule Want.Shape do
  @moduledoc """
  Provides macros for declaring an Ecto-like schema definition that can be used
  to cast incoming data. Most of the macro logic here was adapted from `Ecto.Schema`.
  """

  @doc false
  defmacro __using__(_) do
    quote do
      import Want.Shape, only: [shape: 1, field: 1, field: 2, field: 3]

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

    end
  end

  @doc """
  Determine whether the given module represents a shape.
  """
  @spec is_shape?(module()) :: boolean()
  def is_shape?(module) when is_atom(module),
    do: Kernel.function_exported?(module, :__fields__, 0)

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
      {:ok, Kernel.struct(shape, m)}
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
  Define a schema. Generates a struct definition for the current module that includes the data
  needed to correctly cast incoming JSON/map data into that struct, including field sourcing, type
  conversions, etc.
  """
  defmacro shape(do: block) do
    shape(__CALLER__, block)
  end

  defp shape(caller, block) do
    prelude =
      quote do
        if line = Module.get_attribute(__MODULE__, :want_shape_defined) do
          raise "Shape already defined for #{inspect(__MODULE__)} on line #{line}"
        end

        @want_shape_defined unquote(caller.line)

        Module.register_attribute(__MODULE__, :want_shape_fields,   accumulate: true)
        Module.register_attribute(__MODULE__, :want_field_info,     accumulate: true)

        try do
          import Want.Shape
          unquote(block)
        after
          :ok
        end
      end

    postlude =
      quote unquote: false do
        defstruct Enum.reverse(@want_shape_fields)

        def __fields__,
          do: @want_shape_fields

        def __schema__,
          do: @want_field_info

        @type t() :: %__MODULE__{}
      end

    quote do
      unquote(prelude)
      unquote(postlude)
    end
  end
end
