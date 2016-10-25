-module( want_tests ).
-author( "Warren Kenny <warren.kenny@gmail.com>" ).

-include_lib( "eunit/include/eunit.hrl" ).

want_test() ->
	?assert( want:atom( "hello" )		=:= hello ),
	?assert( want:atom( <<"hello">> ) 	=:= hello ),
	?assert( want:atom( 1 )				=:= '1' ),
	?assertEqual( want:atom( 1.5 ), 	'1.5' ),
    ?assert( want:string( 1 ) 			=:= "1" ),
	?assert( want:integer( "1" )		=:= 1 ),
	?assert( want:binary( 1 ) 			=:= <<"1">> ),
	?assert( want:binary( '1' )			=:= <<"1">> ),
	?assert( want:boolean( true )		=:=	true ),
	?assert( want:float( <<"1.0">> )	=:= 1.0 ),
	?assert( want:string( hello )		=:= "hello" ),
	?assert( want:integer( 1.23 ) 		=:= 1 ),
	?assert( want:integer( <<"1">> )	=:= 1 ).