defmodule Want.StringTest do
  use ExUnit.Case, async: true
  doctest Want.String

  describe "cast/2" do
    test "should cast from an integer to a string" do
      {:ok, "1"} = Want.String.cast(1)
    end

    test "should cast from a float to a string" do
      {:ok, "1.0"} = Want.String.cast(1.0)
    end

    test "should cast from an atom to a string" do
      {:ok, "true"}   = Want.String.cast(true)
      {:ok, "false"}  = Want.String.cast(false)
      {:ok, "hello"}  = Want.String.cast(:hello)
      {:ok, "nil"}    = Want.String.cast(nil)
    end

    test "should fail to cast when the provided value is too long" do
      {:error, _}     = Want.String.cast(:hello, max: 3)
    end
  end
end
