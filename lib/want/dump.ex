defprotocol Want.Dump do
  @moduledoc """
  Behaviour for type casting modules.
  """

  @doc """
  Dumps an incoming value to an output type.
  """
  @fallback_to_any true
  def dump(input, opts)
end
