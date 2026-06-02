// *****************************************
// *********** Form events

&atserver
procedure OnCreateAtServer ( Cancel, StandardProcessing )
	
	init ();
	
endprocedure

&atserver
procedure init ()
	
	MySession = SessionParameters.Session;
	DC.SetParameter ( List, "Scenario", Parameters.Scenario );
	
endprocedure

// *****************************************
// *********** List

&atclient
procedure SessionFilterOnChange ( Item )
	
	filterBySession ();
	
endprocedure

&atserver
procedure filterBySession ()
	
	DC.ChangeFilter ( List, "Session", SessionFilter, not SessionFilter.IsEmpty () );
	
endprocedure

&atclient
procedure ListValueChoice ( Item, Value, StandardProcessing )
	
	if ( Framework.VersionLess ( "8.3.14" ) ) then
		StandardProcessing = false;
		Close ( Item.CurrentData );
	endif;

endprocedure
