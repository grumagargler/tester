
procedure Go ( Scenario, Debugging ) export
	
	if ( SessionScenario.IsEmpty () ) then
		if ( Scenario = undefined ) then
			Output.UndefinedMainScenario ();
		else
			Output.SetupMainScenario ( ThisObject, new Structure ( "Scenario, Debugging", Scenario, Debugging ) );
		endif;
	else
		runScenario ( Debugging );
	endif; 
	
endprocedure

procedure SetupMainScenario ( Answer, Params ) export
	
	if ( Answer = DialogReturnCode.No ) then
		return;
	endif; 
	Environment.ChangeScenario ( Params.Scenario );
	runScenario ( Params.Debugging );
	
endprocedure 

procedure runScenario ( Debugging )
	
	saveAll ();
	ClearMessages ();
	Test.Exec ( SessionScenario, , , Debugging );
	Output.TestComlete ();
	if ( TesterServerMode ) then
		Watcher.AddMessage ( Output.TestComleteMessage () );
	endif;
	
endprocedure 

procedure saveAll ()
	
	Notify ( Enum.MessageSaveAll () );
	
endprocedure 
