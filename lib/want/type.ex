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
end
