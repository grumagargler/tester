// *****************************************
// *********** Form events

&atserver
procedure OnCreateAtServer ( Cancel, StandardProcessing )
	
	setUser ();
	filterByUser ();
	readAppearance ();
	Appearance.Apply ( ThisObject );
	
endprocedure

&atserver
procedure readAppearance ()

	rules = new Array ();
	rules.Add ( "
	|User show empty ( UserFilter )
	|" );
	Appearance.Read ( ThisObject, rules );

endprocedure

&atserver
procedure setUser ()
	
	UserFilter = SessionParameters.User;
	
endprocedure

&atserver
procedure filterByUser ()
	
	DC.ChangeFilter ( List, "Session.User", UserFilter, not UserFilter.IsEmpty () );
	Appearance.Apply ( ThisObject, "UserFilter" );
	
endprocedure 

// *****************************************
// *********** Group Form

&atclient
procedure UserFilterOnChange ( Item )
	
	filterByUser ();
	
endprocedure
