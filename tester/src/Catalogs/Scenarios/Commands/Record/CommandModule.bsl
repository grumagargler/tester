
&atclient
procedure CommandProcessing ( Scenarios, CommandExecuteParameters )
	
	saveAll ();
	ClearMessages ();
	for each scenario in Scenarios do
		Test.Exec ( Scenario, DF.Pick ( Scenario, "Application" ), , , , true );
	enddo; 
	Output.TestComlete ();
	
endprocedure

&atclient
procedure saveAll ()
	
	Notify ( Enum.MessageSaveAll () );
	
endprocedure 
