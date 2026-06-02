
&atclient
procedure CommandProcessing ( Scenario, ExecuteParameters )
	
	runExplorer ( Scenario );
	
endprocedure

&atclient
procedure runExplorer ( Scenario )
	
	var error;
	file = RepositoryFiles.ScenarioFile ( Scenario, error );
	if ( error <> undefined ) then
		Message ( error );
		return;
	endif;
	#if ( WebClient or MobileClient ) then
		Output.ClientDoesNotSupport ();
	#else
		RunApp ( FileSystem.GetParent ( file ) );
	#endif
	
endprocedure
