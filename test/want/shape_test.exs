defmodule Want.ShapeTest do
  use Want.Shape
  use ExUnit.Case, async: true

  defmodule Inner do
    use Want.Shape

    shape do
      field :int,   :integer
    end
  end

  shape transform: &__MODULE__.shape_transform/1 do
    field :is_valid,    :boolean, default: false
    field :is_integer,  :integer, default: 100
    field :from,        :string, from: "WeirdField", default: "Hello, World!", transform: &String.upcase/1
    field :hello,       :enum, valid: [:default, :world, :bar], default: :default
    field :multi_from,  :integer, from: [{"a", "b", "c"}, "OtherField"], default: 0
    field :inner,       Want.ShapeTest.Inner, default: nil
    field :inner_array, {:array, Want.ShapeTest.Inner}, from: "list", default: []
    field :transformed, :integer, default: 1
    field :map_field,   {:map, :atom, :string}, default: %{}
  end

  @spec shape_transform(Want.ShapeTest.t()) :: Want.ShapeTest.t()
  def shape_transform(%Want.ShapeTest{transformed: t} = result),
    do: %{result | transformed: t * 2}

  describe "cast/1" do
    test "successfully casts a valid map with present fields" do
      assert Want.ShapeTest.cast!(%{
        "is_valid"    => "true",
        "is_integer"  => "1",
        "hello"       => "World",
        "inner"       => %{"int" => 150},
        "map_field"   => %{
          "foo"   => "bar",
          "hello" => "world"
        }
      }) == %Want.ShapeTest{
        is_valid:     true,
        is_integer:   1,
        from:         "HELLO, WORLD!",
        hello:        :world,
        multi_from:   0,
        inner:        %Want.ShapeTest.Inner{int: 150},
        inner_array:  [],
        transformed:  2,
        map_field:    %{
          foo:    "bar",
          hello:  "world"
        }
      }
    end

    test "successfully casts a valid map with nil fields" do
      assert Want.ShapeTest.cast!(%{
        "is_valid"    => "true",
        "is_integer"  => "1",
        "hello"       => "World",
        "inner"       => nil,
        "inner_array" => nil,
        "map_field"   => nil
      }) == %Want.ShapeTest{
        is_valid:     true,
        is_integer:   1,
        from:         "HELLO, WORLD!",
        hello:        :world,
        multi_from:   0,
        inner:        nil,
        inner_array:  [],
        transformed:  2,
        map_field:    %{}
      }
    end

    test "successfully casts a list of valid maps with present fields" do
      assert Want.ShapeTest.cast_all!([%{
          "is_valid"    => "true",
          "is_integer"  => "1",
          "hello"       => "World",
          "inner"       => %{"int" => 150},
          "transformed" => "15"
        },
        %{
          "is_valid"    => "false",
          "is_integer"  => "2",
          "hello"       => "bar",
          "inner"       => %{"int" => 250}
        }]) == [%Want.ShapeTest{
          is_valid:     true,
          is_integer:   1,
          from:         "HELLO, WORLD!",
          hello:        :world,
          multi_from:   0,
          inner:        %Want.ShapeTest.Inner{int: 150},
          inner_array:  [],
          transformed:  30,
          map_field:    %{}
        },
        %Want.ShapeTest{
          is_valid:     false,
          is_integer:   2,
          from:         "HELLO, WORLD!",
          hello:        :bar,
          multi_from:   0,
          inner:        %Want.ShapeTest.Inner{int: 250},
          inner_array:  [],          transformed:  2,
          map_field:    %{}
        }]
    end

    test "successfully casts a valid map with missing fields" do
      assert Want.ShapeTest.cast!(%{
        "is_integer" => "1",
        "list"        => [%{"int" => 100}, %{"int" => "200"}]
      }) == %Want.ShapeTest{
        is_valid:       false,
        is_integer:     1,
        from:           "HELLO, WORLD!",
        hello:          :default,
        multi_from:     0,
        inner:          nil,
        inner_array:    [%Want.ShapeTest.Inner{int: 100}, %Want.ShapeTest.Inner{int: 200}],
        transformed:    2,
        map_field:      %{}
      }

      assert Want.ShapeTest.cast!(%{
        "is_valid" => "true"
      }) == %Want.ShapeTest{
        is_valid:       true,
        is_integer:     100,
        from:           "HELLO, WORLD!",
        hello:          :default,
        multi_from:     0,
        inner:          nil,
        inner_array:    [],
        transformed:    2,
        map_field:      %{}
      }
    end

    test "successfully casts from different field names" do
      assert Want.ShapeTest.cast!(%{
        "is_integer" => "1",
        "WeirdField" => "Bar"
      }) == %Want.ShapeTest{
        is_valid:       false,
        is_integer:     1,
        from:           "BAR",
        hello:          :default,
        multi_from:     0,
        inner:          nil,
        inner_array:    [],
        transformed:    2,
        map_field:      %{}
      }

      assert Want.ShapeTest.cast!(%{
        "is_integer"  => "1",
        "WeirdField"  => "Bar",
        "OtherField"  => 2
      }) == %Want.ShapeTest{
        is_valid:       false,
        is_integer:     1,
        from:           "BAR",
        hello:          :default,
        multi_from:     2,
        inner:          nil,
        inner_array:    [],
        transformed:    2,
        map_field:      %{}
      }

      assert Want.ShapeTest.cast!(%{
        "is_integer"  => "1",
        "WeirdField"  => "Bar",
        "a"           => %{"b" => %{"c" => "100"}}
      }) == %Want.ShapeTest{
        is_valid:       false,
        is_integer:     1,
        from:           "BAR",
        hello:          :default,
        multi_from:     100,
        inner:          nil,
        inner_array:    [],
        transformed:    2,
        map_field:      %{}
      }
    end
  end
end
