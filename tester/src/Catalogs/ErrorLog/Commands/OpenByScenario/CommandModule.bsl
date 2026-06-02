
&atclient
procedure CommandProcessing ( Scenario, CommandExecuteParameters )
	
	p = new Structure ( "Scenario", Scenario );
	OpenForm ( "Catalog.ErrorLog.ListForm", p, CommandExecuteParameters.Source, true, CommandExecuteParameters.Window, CommandExecuteParameters.URL );
	
endprocedure
