defmodule Want.TypeTest do
  @moduledoc """
  Tests custom type support.
  """
  use Want.Type
  use ExUnit.Case, async: true

  def cast(input, opts) when is_binary(input),
    do: {:ok, opts[:substitute] || String.capitalize(input)}
  def cast(_input, _opts),
    do: {:error, "Want.TypeTest can only operate on binaries"}

  describe "casting" do
    test "custom types are applied during map casting" do
      {:ok, %{hello: "World"}} = Want.map(%{"hello" => "world"}, %{hello: [type: Want.TypeTest]})
    end

    test "custom types options are applied during map casting" do
      {:ok, %{hello: "Substituted"}} = Want.map(%{"hello" => "world"}, %{hello: [type: Want.TypeTest, substitute: "Substituted"]})
    end

    test "defaults are honoured on casting failure" do
      {:ok, %{hello: "default"}} = Want.map(%{"hello" => 1}, %{hello: [type: Want.TypeTest, substitute: "Substituted", default: "default"]})
    end
  end
end
