var Params export;

procedure OnCompose () export
	
	filterByStatus ();
	
endprocedure

procedure filterByStatus ()
	
	settings = Params.Settings;
	filter = DC.GetParameter ( settings, "Status" );
	if ( filter.Use ) then
		DC.ChangeFilter ( settings, "Status", filter.Value, true );
	endif; 
	
endprocedure 