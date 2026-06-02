
&atclient
procedure CommandProcessing ( Source, ExecuteParameters )
	
	if ( TypeOf ( Source ) = Type ( "CatalogRef.ErrorLog" ) ) then
		openByError ( Source, ExecuteParameters );
	else
		openByScenario ( Source, ExecuteParameters );
	endif;
	
endprocedure

&atclient
procedure openByError ( Error, ExecuteParameters )
	
	p = new Structure ( "Error", Error );
	OpenForm ( "InformationRegister.Timelapse.Form.Form", p, executeParameters.Source, executeParameters.Uniqueness, executeParameters.Window, executeParameters.URL );
	
endprocedure

&atclient
procedure openByScenario ( Source, ExecuteParameters )
	
	p = new Structure ( "Scenario", Source );
	callback = new NotifyDescription ( "SessionSelected", ThisObject, ExecuteParameters );
	OpenForm ( "InformationRegister.Timelapse.Form.Sessions", p, ExecuteParameters.Source, ExecuteParameters.Uniqueness, ExecuteParameters.Window, ExecuteParameters.URL, callback );
	
endprocedure

&atclient
procedure SessionSelected ( Value, Params ) export
	
	if ( Value = undefined ) then
		return;
	endif;
	p = new Structure ();
	p.Insert ( "Scenario", Value.Scenario );
	p.Insert ( "Session", Value.Session );
	p.Insert ( "Date", Value.Started );
	OpenForm ( "InformationRegister.Timelapse.Form.Form", p, Params.Source, Params.Uniqueness, Params.Window, Params.URL );
	
endprocedure