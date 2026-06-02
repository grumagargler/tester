
&atclient
procedure CommandProcessing ( Scenario, CommandExecuteParameters )

	p = new Structure ( "Scenario", Scenario );
	OpenForm ( "InformationRegister.Versions.ListForm", p );
	
endprocedure
