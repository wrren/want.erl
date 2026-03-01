defmodule Want.Any do
  use Want.Type

  @spec cast(value :: any(), opts :: Keyword.t()) :: {:ok, any()}
  def cast(value, _opts),
    do: {:ok, value}

  defimpl Want.Dump, for: Any do
    def dump(input, _opts),
      do: {:ok, input}
  end

  defimpl Want.Update, for: Any do
    def update(_old, new),
      do: {:ok, new}
  end
end
