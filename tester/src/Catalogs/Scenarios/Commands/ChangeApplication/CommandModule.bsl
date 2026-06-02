
&atclient
procedure CommandProcessing ( Scenarios, CommandExecuteParameters )
	
	callback = new NotifyDescription ( "Changed", ThisObject );
	p = new Structure ( "Scenarios", Scenarios );
	OpenForm ( "Catalog.Scenarios.Form.ChangeApplication", p, CommandExecuteParameters.Source, CommandExecuteParameters.Uniqueness, CommandExecuteParameters.Window, CommandExecuteParameters.URL, callback );
	
endprocedure

&atclient
procedure Changed ( Result, Params ) export
	
	if ( Result = undefined ) then
		return;
	endif; 
	set = Result.AlreadyLocked;
	if ( set <> undefined ) then
		for each msg in set do
			Output.LockError ( msg );
		enddo; 
	endif; 
	set = Result.Errors;
	if ( set <> undefined ) then
		for each msg in set do
			Output.ApplicationChangingError ( msg );
		enddo; 
	endif; 
	
endprocedure 