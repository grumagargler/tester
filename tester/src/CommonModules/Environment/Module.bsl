
procedure SetApplication ( Application ) export
	
	SessionApplication = Application;
	Environment.DisplayCaption ();
	
endprocedure 

procedure DisplayCaption () export
	
	parts = new Array ();
	parts.Add ( Output.MetadataPresentation () );
	if ( not SessionApplication.IsEmpty () ) then
		parts.Add ( EnvironmentSrv.GetApplication () );
	endif; 
	parts.Add ( SessionUser );
	ClientApplication.SetCaption ( StrConcat ( parts, "." ) );
	
endprocedure 

procedure ChangeApplication ( Application ) export
	
	reference = EnvironmentSrv.SetApplication ( Application );
	SessionApplication = reference;
	Environment.DisplayCaption ();
	if ( AppData <> undefined
		and AppData.Application <> reference ) then
		if ( AppData.Connected ) then
			Test.DisconnectClient ( false );
		endif;
		updateAppData ( reference );
		Runtime.UpdateConstants ();
		Runtime.InitEnv ();
	endif;
	
endprocedure 

procedure updateAppData ( Application )
	
	FillPropertyValues ( AppData, DF.Values ( Application, "Computer, Port, ClientID" ) );
	AppData.Application = Application;
	AppData.Connected = false;

endprocedure

procedure ChangeScenario ( Scenario ) export
	
	var newApp;
	SessionScenario = Scenario;
	EnvironmentSrv.ChangeScenario ( Scenario, newApp );
	if ( newApp <> undefined
		and newApp <> SessionApplication ) then
		SessionApplication = newApp;
		Environment.DisplayCaption ();
	endif; 
	Notify ( Enum.MessageMainScenarioChanged () );
	NotifyChanged ( Scenario );
	
endprocedure 

function FindByID ( ID ) export
	
	return EnvironmentSrv.FindByID ( ID, AppData.Application );
	
endfunction 

function GetData ( ID ) export
	
	return EnvironmentSrv.GetData ( ID, AppData.Application );
	
endfunction 

procedure Register ( ID, Data ) export
	
	EnvironmentSrv.Register ( ID, AppData.Application, Data );
	
endprocedure 

procedure ApplyVersion ( Version ) export
	
	pinVersion ( Version, false );
	
endprocedure

procedure pinVersion ( Version, Running )
	
	EnvironmentSrv.SetVersion ( Version, Running );
	NotifyChanged ( Version );
	
endprocedure

procedure SetApplicationVersion ( Version, Application ) export
	
	ref = TestSrv.GetVersion ( Version, ? ( Application = undefined, AppName, Application ) );
	pinVersion ( ref, true );
	
endprocedure

function GetVariable ( Name ) export
	
	return ExternalLibrary.GetEnv ( Name );
	
endfunction 
