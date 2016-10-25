-module( want ).
-author( "Warren Kenny <warren.kenny@gmail.com>" ).

-export( [atom/1, boolean/1, string/1, binary/1, integer/1, float/1] ).

%%
%%  @doc Convert the given value to an atom
%%
-spec atom( any() ) -> atom().
atom( V ) when is_atom( V )             -> V;
atom( V ) when is_binary( V )           -> binary_to_atom( V, utf8 );
atom( V ) when is_list( V )             -> list_to_atom( V );
atom( V ) when is_integer( V )          -> want:atom( integer_to_list( V ) );
atom( V ) when is_float( V )            -> want:atom( float_to_list( V ) ).

%%
%%	@doc Convert the given value to a binary
%%
-spec binary( any() ) -> binary().
binary( V ) when is_binary( V ) 	    -> V;
binary( V ) when is_atom( V )           -> atom_to_binary( V, utf8 );
binary( V ) when is_float( V )		    -> float_to_binary( V );
binary( V ) when is_integer( V )	    -> integer_to_binary( V );
binary( V ) when is_list( V )		    -> list_to_binary( V );
binary( V )							    -> term_to_binary( V ).

%%
%%	@doc Convert the given value to a string
%%
-spec string( any() ) -> string().
string( true )							-> "true";
string( false )							-> "false";
string( V ) when is_atom( V )			-> atom_to_list( V );
string( V ) when is_integer( V )	    -> integer_to_list( V );
string( V ) when is_float( V ) 		    -> float_to_list( V ); 
string( V ) when is_binary( V )		    -> binary_to_list( V );
string( V ) when is_list( V )		    -> V.

%%
%%	@doc Convert the given value to a boolean
%%
-spec boolean( any() ) -> boolean().
boolean( true )							-> true;
boolean( false )						-> false;
boolean( 1 )                            -> true;
boolean( 0 )                            -> false;
boolean( <<"true">> )					-> true;
boolean( <<"false">> )					-> false;
boolean( "true" )						-> true;
boolean( "false" )						-> false.

%%
%%  @doc Convert the given value to an integer
%%
-spec integer( any() ) -> integer().
integer( V ) when is_integer( V )       -> V;
integer( V ) when is_float( V )			-> list_to_integer( float_to_list( V, [{ decimals, 0 } ] ) );
integer( true )                         -> 1;
integer( false )                        -> 0;
integer( V ) when is_atom( V )          -> integer( atom_to_binary( V, unicode ) );
integer( V ) when is_binary( V )        -> binary_to_integer( V );
integer( V ) when is_list( V )          -> list_to_integer( V ).

%%
%%  @doc Convert the given value to an float
%%
-spec float( any() ) -> float().
float( V ) when is_float( V )           -> V;
float( V ) when is_integer( V )         -> erlang:float( V );
float( true )                           -> 1.0;
float( false )                          -> 0.0;
float( V ) when is_atom( V )            -> erlang:float( integer( V ) );
float( V ) when is_binary( V )          -> binary_to_float( V );
float( V ) when is_list( V )            -> list_to_float( V ).