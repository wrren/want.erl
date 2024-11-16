# want

Erlang and Elixir library for performing easy type conversions. The Elixir interface
is now a lot more complex than the Erlang one; supporting schema-based conversions between
container types along with validation and default values.

# Example Usage

Basic conversion between types in Erlang.

```erlang

1 			= want:integer( "1" ),
1.0 		= want:float( "1" ),
"1.0"		= want:string( 1 ),
<<"1.0">>	= want:binary( 1 ),
true		= want:boolean( "true" ),
	
```

Basic conversion between types in Elixir.

```elixir

{:ok, 1}    = Want.integer("1")
1           = Want.integer!("1")
{:ok, 1.0}  = Want.float("1")
1.0         = Want.float!("1")
{:ok, "1"}  = Want.string(1)
"1"         = Want.string!(1)
{:ok, true} = Want.boolean("true")
true        = Want.boolean!("true")

```

Complex type conversions in Elixir.

```elixir
{:ok, 1}                                = Want.integer("foo", default: 1)
{:ok, [id: 1]}                          = Want.keywords(%{"id" => "bananas"}, %{id: [type: :integer, default: 1]})
{:ok, %{hello: "world", foo: :bar}}     = Want.map(%{"hello" => "world", "foo" => "bar"}, %{hello: [], foo: [type: :atom]}) 

```

## Shape Definitions

It can be useful to define the shape of your data, similar to how `Ecto.Schema` works; simultaneously defining a struct and
the means to parse it from incoming data. You can use `Want.Shape` to do this.

```elixir
defmodule MyModule do
    use Want.Shape

    shape do
        field :is_valid,    :boolean, default: false
        field :count,       :integer, default: 0
        field :from,        :string, from: "FromField"
    end
end

{:ok, %MyModule{is_valid: true, count: 10, from: "Foo"}} = MyModule.cast(%{
    "is_valid"  => "true",
    "count"     => "10",
    "from"      => "Foo"
})

```