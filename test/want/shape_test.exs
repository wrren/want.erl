defmodule Want.ShapeTest do
  use Want.Shape
  use ExUnit.Case, async: true

  shape do
    field :is_valid,    :boolean, default: false
    field :is_integer,  :integer, default: 100
    field :from,        :string, from: "WierdField", default: "Hello, World!"
    field :hello,       :enum, valid: [:default, :world], default: :default
    field :multi_from,  :integer, from: [{"a", "b", "c"}, "OtherField"], default: 0
  end

  describe "cast/1" do
    test "successfully casts a valid map with present fields" do
      assert Want.ShapeTest.cast!(%{
        "is_valid"    => "true",
        "is_integer"  => "1",
        "hello"       => "World"
      }) == %Want.ShapeTest{
        is_valid: true,
        is_integer: 1,
        from: "Hello, World!",
        hello: :world,
        multi_from: 0
      }
    end

    test "successfully casts a valid map with missing fields" do
      assert Want.ShapeTest.cast!(%{
        "is_integer" => "1"
      }) == %Want.ShapeTest{
        is_valid: false,
        is_integer: 1,
        from: "Hello, World!",
        hello: :default,
        multi_from: 0
      }

      assert Want.ShapeTest.cast!(%{
        "is_valid" => "true"
      }) == %Want.ShapeTest{
        is_valid: true,
        is_integer: 100,
        from: "Hello, World!",
        hello: :default,
        multi_from: 0
      }
    end

    test "successfully casts from different field names" do
      assert Want.ShapeTest.cast!(%{
        "is_integer" => "1",
        "WierdField" => "Bar"
      }) == %Want.ShapeTest{
        is_valid: false,
        is_integer: 1,
        from: "Bar",
        hello: :default,
        multi_from: 0
      }

      assert Want.ShapeTest.cast!(%{
        "is_integer"  => "1",
        "WierdField"  => "Bar",
        "OtherField"  => 2
      }) == %Want.ShapeTest{
        is_valid: false,
        is_integer: 1,
        from: "Bar",
        hello: :default,
        multi_from: 2
      }

      assert Want.ShapeTest.cast!(%{
        "is_integer"  => "1",
        "WierdField"  => "Bar",
        "a"           => %{"b" => %{"c" => "100"}}
      }) == %Want.ShapeTest{
        is_valid: false,
        is_integer: 1,
        from: "Bar",
        hello: :default,
        multi_from: 100
      }
    end
  end
end
