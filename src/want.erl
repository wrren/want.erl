-module( want ).
-author( "Warren Kenny <warren.kenny@gmail.com>" ).

-export( [boolean/1, string/1, binary/1, integer/1, float/1] ).

%%
%%	Convert the given value to a binary
%%
binary( V ) when is_binary( V ) 	    -> V;
binary( V ) when is_atom( V )           -> atom_to_binary( V, utf8 );
binary( V ) when is_float( V )		    -> float_to_binary( V );
binary( V ) when is_integer( V )	    -> integer_to_binary( V );
binary( V ) when is_list( V )		    -> list_to_binary( V );
binary( V )							    -> term_to_binary( V ).

%%
%%	Convert the given value to a string
%%
string( true )							-> "true";
string( false )							-> "false";
string( V ) when is_atom( V )			-> atom_to_list( V );
string( V ) when is_integer( V )	    -> integer_to_list( V );
string( V ) when is_float( V ) 		    -> float_to_list( V ); 
string( V ) when is_binary( V )		    -> binary_to_list( V );
string( V ) when is_list( V )		    -> V.

%%
%%	Convert the given value to a boolean
%%
boolean( true )							-> true;
boolean( false )						-> false;
boolean( 1 )                            -> true;
boolean( 0 )                            -> false;
boolean( <<"true">> )					-> true;
boolean( <<"false">> )					-> false;
boolean( "true" )						-> true;
boolean( "false" )						-> false.

%%
%%  Convert the given value to an integer
%%
integer( V ) when is_integer( V )       -> V;
integer( V ) when is_float( V )			-> list_to_integer( float_to_list( V, [{ decimals, 0 } ] ) );
integer( true )                         -> 1;
integer( false )                        -> 0;
integer( V ) when is_atom( V )          -> integer( atom_to_binary( V, unicode ) );
integer( V ) when is_binary( V )        -> binary_to_integer( V );
integer( V ) when is_list( V )          -> list_to_integer( V ).

%%
%%  Convert the given value to an float
%%
float( V ) when is_float( V )           -> V;
float( V ) when is_integer( V )         -> erlang:float( V );
float( true )                           -> 1.0;
float( false )                          -> 0.0;
float( V ) when is_atom( V )            -> erlang:float( atom_to_binary( V, unicode ) );
float( V ) when is_binary( V )          -> binary_to_float( V );
float( V ) when is_list( V )            -> list_to_float( V ).