defprotocol Want.Update do
  @moduledoc """
  Behaviour for type casting modules.
  """

  @doc """
  Updates an existing value with a new one
  """
  @fallback_to_any true
  def update(old, new)
end
