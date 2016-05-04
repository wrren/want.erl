-module( want_tests ).
-author( "Warren Kenny <warren.kenny@gmail.com>" ).

-include_lib( "eunit/include/eunit.hrl" ).

% This should fail
basic_test() ->
    ?assert( want:string( 1 ) 		=:= "1" ),
	?assert( want:integer( "1" )	=:= 1 ).