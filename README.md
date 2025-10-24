# Want [![Hex Version](https://img.shields.io/hexpm/v/want.svg)](https://hex.pm/packages/want) [![Hex Docs](https://img.shields.io/badge/docs-hexpm-blue.svg)](https://hexdocs.pm/want/)

Erlang and Elixir library for performing easy type conversions. The Elixir interface
is now a lot more complex than the Erlang one; supporting schema-based conversions between
container types along with validation and default values.

## Installation

The package can be installed by adding `want` to your list of dependencies
in `mix.exs`:

```elixir
def deps do
  [{:want, "~> 1.21"}]
end
```

## Basic Usage

Conversion between types in Erlang.

```erlang
% String to integer
1 = want:integer( "1" ),
% String to float
1.0 = want:float( "1" ),
% Integer to String
"1.0" = want:string( 1 ),
% Integer to binary
<<"1.0">> = want:binary( 1 ),
% String to boolean
true = want:boolean( "true" ),
```

Conversion between types in Elixir.

```elixir
# String to integer
{:ok, 1} = Want.integer("1")
# String to integer, raise on failure
1 = Want.integer!("1")
# String to float
{:ok, 1.0} = Want.float("1")
# String to float, raise on failure
1.0 = Want.float!("1")
# Integer to string
{:ok, "1"} = Want.string(1)
# Integer to string, raise on failure
"1" = Want.string!(1)
# String to boolean
{:ok, true} = Want.boolean("true")
{:ok, false} = Want.boolean("FALSE")
# String to boolean, raise on failure
true = Want.boolean!("true")
```

## Complex Type Conversions in Elixir

```elixir

# Binary to Integer with default value used on conversion failure
{:ok, 1} = Want.integer("foo", default: 1)
# Map to Keyword List with default values used on conversion failure
{:ok, [id: 1]} = Want.keywords(%{"id" => "bananas"}, %{id: [type: :integer, default: 1]})
# Map to Map with field type conversions
{:ok, %{hello: "world", foo: :bar}} = Want.map(%{"hello" => "world", "foo" => "bar"}, %{hello: [], foo: [type: :atom]}) 
# Nested Key Extraction
{:ok, %{id: 100}} = Want.Map.cast(%{"a" => %{"b" => %{"c" => 100}}}, %{id: [type: :integer, from: {"a", "b", "c"}]})
# Key extraction from multiple potential fields, first match wins
{:ok, %{id: 100}} = Want.Map.cast(%{"b" => "100", "c" => "200"}, %{id: [type: :integer, from: ["a", "b", "c"]]})
```

## Shape Definitions

It can be useful to define the shape of your data, similar to how `Ecto.Schema` works; simultaneously defining a struct and
the means to parse it from incoming data. You can use `Want.Shape` to do this.

```elixir
defmodule MyModule do
    use Want.Shape

    shape do
        field :is_valid,    :boolean,   default: false
        field :count,       :integer,   default: 0
        field :from,        :string,    from: "FromField"
        field :multi_from,  :integer,   from: ["a", {"b", "c", "d"}], default: 0
    end
end

{:ok, %MyModule{is_valid: true, count: 10, from: "Foo", multi_from: 10}} = MyModule.cast(%{
    "is_valid"  => "true",
    "count"     => "10",
    "from"      => "Foo",
    "b"         => %{
        "c" => %{
            "d" => 10
        }
    }
})

```

## Custom Types

You can define your own types for `map`, `keyword` and `shape` conversions by implementing the `Want.Type` behaviour, specifically the `cast/2` callback.

```elixir
defmodule MyCustomType do
    use Want.Type

    @doc """
    Capitalizes a binary input.
    """
    @spec cast(input :: any(), opts :: Keyword.t()) :: {:ok, String.t()} | {:error, String.t()}
    def cast(input, opts) when is_binary(input),
        do: {:ok, opts[:substitute] || String.capitalize(input)}
    def cast(_input, _opts),
        do: {:error, "Want.TypeTest can only operate on binaries"}
end

{:ok, %{hello: "World"}} = Want.map(%{"hello" => "world"}, %{hello: [type: MyCustomType]})
```
