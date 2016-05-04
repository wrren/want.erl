# want.erl

Simple erlang library for converting between types conveniently

# Example Usage

```erlang

1 			= want:integer( "1" ),
1.0 		= want:float( "1" ),
"1.0"		= want:string( 1 ),
<<"1.0">>	= want:binary( 1 ),
true		= want:boolean( "true" ),
	
```
