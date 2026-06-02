// *****************************************
// *********** Form events

&atserver
procedure OnCreateAtServer ( Cancel, StandardProcessing )
	
	ScenarioForm.InitPort ( Items.Port );
	setTitle ();
	setDefaults ();
	readAppearance ();
	Appearance.Apply ( ThisObject );
	
endprocedure

&atserver
procedure readAppearance ()

	rules = new Array ();
	rules.Add ( "
	|FormStartRecording show not Connected;
	|FormPauseRecording Recording show Status = ""R"";
	|FormResumeRecording show Status = ""P"";
	|FormStopRecording show inlist ( Status, ""R"", ""P"" );
	|Disconnect show Connected;
	|Port enable not Connected
	|" );
	Appearance.Read ( ThisObject, rules );

endprocedure

&atserver
procedure setTitle ()
	
	Title = Output.RecordSenario ();
	
endprocedure 

&atserver
procedure setDefaults ()
	
	Mode = Enums.Recording.Tester;
	
endprocedure 

&atclient
procedure OnOpen ( Cancel )
	
	init ();
	fixLang ();
	start ( true );
	
endprocedure

&atclient
procedure init ()
	
	Test.AttachApplication ( SessionScenario );
	Port = AppData.Port;
	flagConnected ();
	
endprocedure

&atclient
procedure flagConnected ()
	
	Connected = AppData.Connected;
	Appearance.Apply ( ThisObject, "Connected" );
	
endprocedure

&atclient
procedure fixLang ()
	
	if ( Items.Lang.ChoiceList.FindByValue ( Lang ) = undefined ) then
		Lang = CurrentLanguage ();
	endif; 
	
endprocedure 

&atclient
procedure start ( Silently )
	
	if ( attach ( Silently ) ) then
		App.StartUILogRecording ();
		setStatus ( "R" );
	endif;
	
endprocedure 

&atclient
function attach ( Silently )
	
	if ( Silently ) then
		try
			Test.Attach ( Port );
			attached = true;
		except
			attached = false;
		endtry;
	else
		Test.Attach ( Port );
		attached = true;
	endif;
	flagConnected ();
	return attached;
	
endfunction

&atclient
procedure setStatus ( Value )
	
	Status = Value;
	if ( Status = "R" ) then
		Title = Output.RecordingSenario ();
	elsif ( Status = "P" ) then
		Title = Output.PauseScenario ();
	else
		Title = Output.RecordSenario ();
	endif; 
	Appearance.Apply ( ThisObject, "Status" );
	
endprocedure 

&atclient
procedure OnClose ( Exit )
	
	detach ();
	
endprocedure

&atclient
procedure detach ()
	
	#if ( ThinClient or ThickClientManagedApplication ) then
		if ( Connected ) then
			if ( Status <> "" ) then
				App.CancelUILogRecording ();
			endif;
			Disconnect ();
		endif; 
	#endif
	
endprocedure 

// *****************************************
// *********** Group Form

&atclient
procedure StartRecording ( Command )
	
	start ( false );
	
endprocedure

&atclient
procedure PauseRecording ( Command )
	
	App.PauseUILogRecording ();
	setStatus ( "P" );
	
endprocedure

&atclient
procedure StopRecording ( Command )
	
	setStatus ( "" );
	Close ( getLog () );
	
endprocedure

&atclient
function getLog ()
	
	log = App.FinishUILogRecording ();
	return new Structure ( "Log, Lang, Mode", log, Lang, Mode );
	
endfunction 

&atclient
procedure ResumeRecording ( Command )
	
	App.ResumeUILogRecording ();
	setStatus ( "R" );
	
endprocedure

&atclient
procedure ModeClearing ( Item, StandardProcessing )
	
	StandardProcessing = false;
	
endprocedure

&atclient
procedure DisconnectClient ( Command )
	
	#if ( ThinClient or ThickClientManagedApplication ) then
		App.CancelUILogRecording ();
		Disconnect ();
		flagConnected ();
		setStatus ( "" );
	#endif
	
endprocedure
