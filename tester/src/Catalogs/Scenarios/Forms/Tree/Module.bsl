// *****************************************
// *********** Form events

&atserver
procedure OnCreateAtServer ( Cancel, StandardProcessing )
	
	init ();
	
endprocedure

procedure init ()
	
	DC.SetParameter ( List, "User", SessionParameters.User );
	
endprocedure 

// *****************************************
// *********** Group Form

&atclient
procedure ApplicationFilterOnChange ( Item )
	
	filterByApplication ();
	
endprocedure

&atserver
procedure filterByApplication ()
	
	if ( ApplicationFilter.IsEmpty () ) then
		DC.ChangeFilter ( List, "Application", undefined, false );
	else
		filter = new Array ();
		filter.Add ( Catalogs.Applications.EmptyRef () );
		filter.Add ( ApplicationFilter );
		DC.ChangeFilter ( List, "Application", filter, true, DataCompositionComparisonType.InList );
	endif; 
	
endprocedure 
