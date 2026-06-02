
procedure Exec ( Scenario, Application = undefined, ProgramCode = undefined, Debugging = false, Offset = 0,
	Filming = false, Params = undefined ) export
	
	LastScenarioResult = undefined;
	data = Test.FindScenario ( Scenario, Application );
	Test.AttachApplication ( data.Scenario );
	program = ? ( data.Application.IsEmpty (), SessionApplication, data.Application );
	Runtime.Exec ( program, ProgramCode, true, Debugging, Offset, Filming, , Params );
	
endprocedure

function FindScenario ( Scenario, Application = undefined, IgnoreLocking = false ) export
	
	if ( TypeOf ( Scenario ) = Type ( "String" ) ) then
		if ( Application = undefined ) then
			default = EnvironmentSrv.GetApplication ();
		endif; 
		value = RuntimeSrv.FindScenario ( Scenario, default, Application, undefined, IgnoreLocking );
		if ( value = undefined ) then
			raise Output.ScenarioNotFound ( new Structure ( "Name", Scenario ) );
		else
			ref = value;
		endif; 
	else
		ref = ? ( IgnoreLocking, Scenario, RuntimeSrv.ActualScenario ( Scenario ) );
	endif; 
	result = new Structure ();
	result.Insert ( "Scenario", ref );
	result.Insert ( "Application", DF.Pick ( ref, "Application" ) );
	return result;
	
endfunction 

procedure AttachApplication ( Scenario ) export
	
	AppData = TestSrv.Data ( Scenario );
	СвойстваПриложения = AppData;
	
endprocedure
	
procedure DisconnectClient ( Close = false ) export
	
	if ( Close and ( MainWindow <> undefined ) ) then
		MainWindow.Close ();
	endif; 
	if ( App <> undefined ) then
		App.Disconnect ();
		App = undefined;
		Приложение = undefined;
	endif;
	if ( AppData <> undefined ) then
		AppData.Connected = false;
	endif; 
	CurrentSource = undefined;
	ТекущийОбъект = undefined;
	MainWindow = undefined;
	ГлавноеОкно = undefined;
	
endprocedure 

procedure ConnectClient ( ClearErrors = true, Port = undefined, Computer = undefined ) export
	
	#if ( ThinClient or ThickClientManagedApplication ) then
		try
			tryConnect ( ClearErrors, Port, Computer );
		except
			try
				Disconnect ();
			except
			endtry;
			tryConnect ( ClearErrors, Port, Computer );
		endtry;
	#endif

endprocedure 

procedure tryConnect ( ClearErrors, Port, Computer )
	
	#if ( ThinClient or ThickClientManagedApplication ) then
		host = ? ( Computer = undefined, AppData.Computer, Computer );
		hostPort = ? ( Port = undefined, AppData.Port, Port );
		AppData.ConnectedHost = host;
		AppData.ConnectedPort = hostPort;
		// Evaluation is required because TestedApplication is not defined as a Type
		// outside of TestManager running mode
		try
			App = Eval ( "new TestedApplication ( host, hostPort, AppData.ClientID )" );
			App.Connect ();
		except
			raise ErrorProcessing.BriefErrorDescription ( ErrorInfo () );
		endtry;
		Приложение = App;
		AppData.Connected = true;
		initMainWindow ();
		mcpProcessing = true = MCPRequestProcessing;
		if ( ClearErrors and not mcpProcessing ) then
			error = App.GetCurrentErrorInfo ();
			if ( error = undefined ) then
				try
					CheckErrors ();
					return;
				except
				endtry;
			endif; 
			Forms.CloseWindows ();
		endif; 
	#endif
	
endprocedure

procedure initMainWindow ()
	
	frames = App.FindObjects ( Type ( "TestedClientApplicationWindow" ) );
	for each item in frames do
		if ( item.IsMain ) then
			break;
		endif; 
	enddo; 
	MainWindow = item;
	ГлавноеОкно = MainWindow;
	if ( frames.Count () = 1 ) then
		MainWindow.Activate ();
	endif; 

endprocedure 

procedure CheckSyntax ( ProgramCode ) export
	
	error = Runtime.CheckSyntax ( ProgramCode );
	if ( error = undefined ) then
		OpenForm ( "CommonForm.SyntaxPassed" );
	else
		Output.SyntaxError ( undefined, new Structure ( "Error", error ) );
	endif;
	
endprocedure 

procedure Start ( Scenario, Application = undefined, IgnoreLocking = false ) export
	
	data = Test.FindScenario ( Scenario, Application );
	Test.AttachApplication ( data.Scenario );
	Runtime.NextLevel ( Debug );
	Runtime.Exec ( , , false );
	Runtime.PreviousLevel ( Debug );
	
endprocedure

procedure Attach ( Port = undefined ) export
	
	Test.AttachApplication ( SessionScenario );
	Test.ConnectClient ( false, Port );

endprocedure

procedure CheckConnection () export
	
	if ( App = undefined
		or MainWindow = undefined ) then
		raise Output.TestedApplicationOffline ();
	endif;
	
endprocedure

procedure PauseExecution ( Seconds ) export
	
	ExternalLibrary.Pause ( Seconds );
	
endprocedure

procedure GotoSystemConsole () export
	
	ExternalLibrary.GotoConsole ();
	
endprocedure
