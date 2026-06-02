// *****************************************
// *********** Form events

&atserver
procedure OnCreateAtServer ( Cancel, StandardProcessing )
	
	loadParams ();
	if ( FixedUserFilter.IsEmpty () ) then
		setUser ();
	endif;
	filterByUser ();
	readAppearance ();
	Appearance.Apply ( ThisObject );
	
endprocedure

&atserver
procedure readAppearance ()

	rules = new Array ();
	rules.Add ( "
	|User SourcesUser WorkspacesOwner show ( empty ( UserFilter ) and empty ( FixedUserFilter ) );
	|UserFilter show empty ( FixedUserFilter )
	|" );
	Appearance.Read ( ThisObject, rules );

endprocedure

&atserver
procedure loadParams ()

	FixedUserFilter = Parameters.User;
	UserFilter = FixedUserFilter; 
	
endprocedure 

&atserver
procedure setUser ()
	
	UserFilter = SessionParameters.User;
	
endprocedure

&atserver
procedure filterByUser ()
	
	filter = not UserFilter.IsEmpty ();
	DC.ChangeFilter ( List, "Session.User", UserFilter, filter );
	DC.ChangeFilter ( Sources, "Session.User", UserFilter, filter );
	DC.ChangeFilter ( Workspaces, "Owner", UserFilter, filter );
	Appearance.Apply ( ThisObject, "UserFilter" );
	
endprocedure 

// *****************************************
// *********** Group Form

&atclient
procedure UserFilterOnChange ( Item )
	
	filterByUser ();
	
endprocedure
