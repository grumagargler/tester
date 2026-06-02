&atclient
procedure CommandProcessing ( CommandParameter, CommandExecuteParameters )
	
	p = ReportsSystem.GetParams ( "Scenarios" );
	p.GenerateOnOpen = true;
	ReportsSystem.Open ( p, CommandExecuteParameters.Source, true, CommandExecuteParameters.Window );

endprocedure
