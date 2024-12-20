defmodule Want.Type do
  @moduledoc """
  Behaviour for type casting modules.
  """

  defmacro __using__(_) do
    quote do
      @behaviour Want.Type
    end
  end

  @type opts    :: Keyword.t()
  @type schema  :: map()

  #
  # Cast an incoming value to a given type
  #
  @callback cast(input :: any(), opts() | schema()) :: {:ok, result :: any()} | {:error, reason :: any()}

  @doc """
  Determine whether a module represents a custom type.
  """
  @spec is_custom_type?(module()) :: boolean()
  def is_custom_type?(module) do
    case Code.ensure_compiled(module) do
      {:module, _}  -> Kernel.function_exported?(module, :cast, 2)
      _             -> false
    end
  end

  @doc """
  Invoke the `cast/2` function on the given custom type module.
  """
  @spec cast(module(), input :: any(), opts()) :: {:ok, result :: any()} | {:error, reason :: any()}
  def cast(module, input, opts),
    do: Kernel.apply(module, :cast, [input, opts])
end
