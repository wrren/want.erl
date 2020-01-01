defmodule Want.Any do
  defimpl Want.Dump, for: Any do
    def dump(input, _opts),
      do: {:ok, input}
  end

  defimpl Want.Update, for: Any do
    def update(_old, new),
      do: {:ok, new}
  end
end
