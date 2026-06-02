
&atclient
procedure CommandProcessing ( Scenario, CommandExecuteParameters )
	
	p = new Structure ( "Scenario", Scenario );
	OpenForm ( "InformationRegister.Log.ListForm", p, CommandExecuteParameters.Source, true, CommandExecuteParameters.Window, CommandExecuteParameters.URL );
	
endprocedure
