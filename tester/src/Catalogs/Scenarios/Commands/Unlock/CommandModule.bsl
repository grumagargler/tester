
&atclient
procedure CommandProcessing ( Scenarios, CommandExecuteParameters )
	
	p = new Structure ( "Scenarios", Scenarios );
	OpenForm ( "Catalog.Scenarios.Form.Unlock", p, CommandExecuteParameters.Source, CommandExecuteParameters.Uniqueness, CommandExecuteParameters.Window, CommandExecuteParameters.URL );
	
endprocedure
