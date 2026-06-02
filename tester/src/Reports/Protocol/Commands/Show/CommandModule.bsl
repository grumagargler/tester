&atclient
procedure CommandProcessing ( CommandParameter, CommandExecuteParameters )
	
	p = ReportsSystem.GetParams ( "Protocol" );
	p.GenerateOnOpen = true;
	ReportsSystem.Open ( p, CommandExecuteParameters.Source, true, CommandExecuteParameters.Window );
	
endprocedure
