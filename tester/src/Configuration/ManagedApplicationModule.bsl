#region BSDLicense

// Copyright (c) 2016, Reshitko Dmitry
// All rights reserved.
//
// Redistribution and use in source and binary forms, with or without
// modification, are permitted provided that the following conditions are met:
//
// 1. Redistributions of source code must retain the above copyright notice, this
//    clist of conditions and the following disclaimer.
// 2. Redistributions in binary form must reproduce the above copyright notice,
//    this list of conditions and the following disclaimer in the documentation
//    and/or other materials provided with the distribution.
//
// THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND
// ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
// WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
// DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE FOR
// ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
// (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
// LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND
// ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
// (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
// SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

#endregion

var LaunchParameters export;
var ПараметрыЗапуска export;
var App export;
var Приложение export;
var AppName export;
var ИмяПриложения export;
var AppData export;
var СвойстваПриложения export;
var DialogsTitle export;
var ЗаголовокДиалогов export;
var MainWindow export;
var ГлавноеОкно export;
var CurrentSource export;
var ТекущийОбъект export;
var Debug export;
var IgnoreErrors export;
var ИгнорироватьОшибки export;
var __ export;
var AppMeta export;
var Meta export;
var Мета export;
var TestManager export;
var SessionUser export;
var SessionApplication export;
var SessionScenario export;
var SpecialFields export;
var СпециальныеПоля export;
var OpenedScenarios export;
var ScreenshotsLocator export;
var ScreenshotsCompressed export;
var ExternalLibrary export;
var ExternalMeta export;
var FoldersWatchdog export;
var TesterAgentConnectionString export;
var TesterSystemFolder export;
var TesterGitMask export;
var TesterExternalRequests export;
var TesterExternalRequestObject export;
var TesterExternalRequestsApplication export;
var TesterExternalRequestsScenario export;
var TesterExternalRequestsRenaming export;
var TesterExternalResponses export;
var TesterExternalBroadcasting export;
var TesterWatcherBuffer;
var TesterWatcherListeningMessage;
var TesterWatcherSyncingMessage;
var TesterWatcherIndicationThreshold;
var TesterWatcherBSLServerSettings export;
var TesterServerMode export;
var TesterServerMessages export;
var TesterDynamicListSearchWaitTime export;
var IAmAgent export;
var ЯАгент export;
var RunningDelegatedJob export;
var ВыполняетсяДелегированноеЗадание export;
var CurrentDelegatedJob export;
var PlatformFeatures export;
var FrameworkVersion export;
var UserDocumentsFolder export;
var PathSeparator export;
var MCPD export;
var MCPRequestProcessing export;
var LastScenarioReturn export;
var RepositoryFilesSynchingCallback export;
var LastActiveWindowControls export;
var CachedControlTooltips export;

procedure BeforeStart ( Cancel )
	
	if ( UserName () = "" ) then
		Logins.Init ();
		Cancel = true;
		Exit ( false, true );
	else
		defineTestManager ();
	endif; 
	initSession ();
	
endprocedure

procedure defineTestManager ()
	
	#if ( WebClient or MobileClient ) then
		TestManager = false;
	#else
		try
			TestManager = Type ( "TestedClientApplicationWindow" ) <> undefined;
		except
			TestManager = false;
		endtry;
	#endif
	
endprocedure 

procedure OnStart ()
	
	if ( not Starting.Allowed () ) then
		return;
	endif;
	rereadData = defingeExchange ();
	if ( rereadData ) then
		Exchange.RereadData ();
		return;
	endif;
	init ();
	Environment.DisplayCaption ();
	openScenario ();
	startAgent ();
	applyParameters ();
	
endprocedure

function defingeExchange ()

	return ( StrFind ( LaunchParameter, "READ_EXCHANGE_DATA" ) > 0 );
	
endfunction

procedure init ()

	si = new SystemInfo ();
	FrameworkVersion = si.AppVersion;
	TesterSystemFolder = RepositoryFiles.SystemFolder (); 
	PathSeparator = GetPathSeparator ();
	TesterGitMask = PathSeparator + RepositoryFiles.GitFolder ();
	folder = TesterSystemFolder + PathSeparator;
	TesterExternalRequests = folder + "request";
	TesterExternalResponses = folder + "response";
	TesterWatcherBuffer = new Array ();
	TesterWatcherListeningMessage = Output.WatcherListeningEvents ();
	TesterWatcherSyncingMessage = Output.WatcherSyncingMessage ();
	TesterWatcherIndicationThreshold = 10;
	TesterWatcherBSLServerSettings = RepositoryFiles.BSLServerSettings ();
	TesterDynamicListSearchWaitTime = 2;
	TesterServerMode = false;
	RunningDelegatedJob = false;
	CachedControlTooltips = new Map ();
	initFeatures ();
	initSpecialFields ();
	initExtender ();
	Watcher.Init ();
	MCPServer.Init ();
	ScenariosPanel.Init ();

endprocedure

procedure initSession ()
	
	#if ( WebClient ) then
		computer = "WebClient";
		webClient = true;
	#else
		webClient = false;
		computer = ComputerName ();
	#endif
	#if ( MobileClient ) then
		mobileClient = true;
	#else
		mobileClient = false;
	#endif
	#if ( ThinClient ) then
		thinClient = true;
	#else
		thinClient = false;
	#endif
	#if ( ThickClientManagedApplication ) then
		thickClient = true;
	#else
		thickClient = false;
	#endif
	data = EnvironmentSrv.InitSession ( computer, webClient, mobileClient, thinClient, thickClient );
	SessionUser = data.User;
	SessionScenario = data.Scenario;
	SessionApplication = data.Application;
	set = new Structure ( "Connection", data.Connection );
	SetInterfaceFunctionalOptionParameters ( set );
	
endprocedure 

procedure initFeatures ()
	
	PlatformFeatures = new Structure ();
	PlatformFeatures.Insert ( "HasTimeout", not Framework.VersionLess ( "8.3.12" ) );
	
endprocedure

procedure initSpecialFields ()
	
	SpecialFields = new Structure ();
	if ( CurrentLanguage () = "en" ) then
		column = "#";
	else
		column = "N";
	endif; 
	SpecialFields.Insert ( "LineNo", column );
	СпециальныеПоля = SpecialFields;
	
endprocedure 

procedure initExtender ()
	
	#if ( not WebClient and not MobileClient ) then
		info = new SystemInfo ();
		type = info.PlatformType;
		if ( type = PlatformType.MacOS_x86
			or type = PlatformType.MacOS_x86 ) then
			raise Output.OSNotSupported ();
		endif;
		Libraries.Load ();
		ExternalLibrary = new ( "AddIn.Extender.Root" );
		ExternalMeta = new ( "AddIn.Extender.Metadata" );
	#endif

endprocedure 

procedure openScenario ()
	
	if ( SessionScenario.IsEmpty ()
		and not Logins.CanEditScenarios () ) then
		OpenForm ( "Catalog.Scenarios.Form.List" );
	else
		OpenForm ( "Catalog.Scenarios.ObjectForm", new Structure ( "Key", SessionScenario ) );
	endif;
	
endprocedure 

procedure startAgent ()
	
	IAmAgent = EnvironmentSrv.StartAgent ();
	ЯАгент = IAmAgent;
	AgentRunner.Listen ();
	
endprocedure

procedure agentListener () export

	AgentRunner.Serve ();	
	
endprocedure

procedure applyParameters ()
	
	LaunchParameters = new Map ();
	ПараметрыЗапуска = LaunchParameters;
	if ( LaunchParameter = "" ) then
		return;
	endif; 
	LaunchParameters = Conversion.ParametersToMap ( LaunchParameter );
	ПараметрыЗапуска = LaunchParameters;
	AttachIdleHandler ( "delayedScenarioRun", 0.5, true );
	
endprocedure 

procedure delayedScenarioRun () export
	
	scenario = LaunchParameters [ "Scenario" ];
	application = LaunchParameters [ "Application" ];
	oldStyle = LaunchParameters.Count () = 0;
	if ( oldStyle
		and scenario = undefined ) then
		s = TrimAll ( LaunchParameter );
		i = StrFind ( s, "#" );
		if ( i = 0 ) then
			application = undefined;
			scenario = s;
		else
			application = Left ( s, i - 1 );
			scenario = Mid ( s, i + 1 );
		endif; 
		if ( application <> undefined ) then
			Environment.ChangeApplication ( application );
		endif; 
	endif; 
	if ( scenario <> undefined ) then
		Test.Exec ( scenario, application );
	endif;
	
endprocedure

procedure ExternEventProcessing ( Source, Event, Data )
	
	if ( Source = "Watcher"
		and Event <> "###E###" ) then
		stopListener ();
		DetachIdleHandler ( "WatcherStartSyncing" );
		TesterWatcherBuffer.Add ( new Structure ( "Event, Data", Event, Data ) );
		if ( TesterWatcherBuffer.UBound () > TesterWatcherIndicationThreshold ) then
			Status ( TesterWatcherListeningMessage );
		endif;
		AttachIdleHandler ( "WatcherStartSyncing", 0.1, true );
	elsif ( Source = "MCPServer"
		and Event = "MCP"
		and Event <> "###E###" ) then
		MCPServer.Proceed ( Data );
	endif;

endprocedure

procedure WatcherStartSyncing () export
	
	total = TesterWatcherBuffer.UBound ();
	index = 0;
	indication = total > TesterWatcherIndicationThreshold;
	for each event in TesterWatcherBuffer do
		if ( indication ) then
			Status ( TesterWatcherSyncingMessage, index * 100 / total );
		endif;
		Watcher.Proceed ( event.Event, event.Data );
		index = index + 1;
	enddo;
	TesterWatcherBuffer.Clear ();
	AgentRunner.Listen ();
	
endprocedure

procedure TesterRunsMainScenario () export
	
	TesterServerMode = true;
	try
		RunScenarios.Go ( undefined, false );
	except
	endtry;
	Watcher.SendResponse ();
	TesterServerMode = false;
	
endprocedure

procedure TesterRunsSelectedScript () export

	TesterServerMode = true;
	data = TesterExternalRequestObject.Data;
	try
		Test.Exec ( TesterExternalRequestsScenario, , data.Selection, , data.Start );
	except
	endtry;
	Watcher.SendResponse ();
	TesterServerMode = false;

endprocedure

procedure TesterWatcherBroadcasting () export
	
	if ( TypeOf ( TesterExternalBroadcasting ) = Type ( "Array" ) ) then
		list = TesterExternalBroadcasting;
	else
		list = new Array ();	
		list.Add ( TesterExternalBroadcasting );
	endif;
	Notify ( Enum.MessageReload (), list );
	NotifyChanged ( Type ( "CatalogRef.Scenarios" ) );
	
endprocedure

procedure BeforeExit ( Cancel, MessageText )
	
	if ( IAmAgent ) then
		//@skip-warning
		enforceServerCall = String ( PredefinedValue ( "Catalog.OnExit.DisconnectAgent" ) );
	endif;
	
endprocedure

procedure stopListener ()
	
	if ( IAmAgent ) then
		DetachIdleHandler ( "agentListener" );
	endif;
	
endprocedure
