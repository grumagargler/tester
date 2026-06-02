#if ( server or thinclient or thickclientmanagedapplication ) then

&atclient
function CheckSyntax ( val Code, val Scenario = undefined ) export

	//@skip-warning
	var _, _procedures, _oldSource, this, тут, Chronograph, Хронограф;
	program = Compiler.SyntaxCode ( code );
	try
		Execute ( program.Client );
		if ( program.Server <> undefined ) then
			RuntimeSrv.CheckSyntax ( program.Server );
		endif;
	except
		return ErrorProcessing.BriefErrorDescription ( ErrorInfo () )
			+ ? ( Scenario = undefined, "", " (" + Scenario + ")" );
	endtry;
	return undefined;

endfunction

function RunScript ( val Code, val Params = undefined, DebugInfo = undefined, val _Scenario = undefined ) export

	result = undefined;
	functionReturnsValue = false;
	if ( Params <> undefined ) then
		//@skip-warning
		_ = Params;
	endif;
	//@skip-warning
	_procedures = new Map ();
	Chronograph = new Structure ( "Scenario, Module, Сценарий, Модуль" );
	//@skip-warning
	Хронограф = Chronograph;
	this = new Structure ();
	//@skip-warning
	тут = this;
#if ( server ) then
	Debug = DebugInfo;
#else
	//@skip-warning
	_oldSource = CurrentSource;
#endif
#region ScenarioContext
	//@skip-warning
	StandardProcessing = true;
	//@skip-warning
	СтандартнаяОбработка = true;
#endregion
	_monitoring = _Scenario <> undefined;
	if ( _monitoring ) then
		_level = scenarioLevel ( Debug );
		RuntimeSrv.LogRunning ( _Scenario, _level, Debug.Job );
#if ( thinclient or thickclientmanagedapplication ) then
		agentStatus ( PredefinedValue ( "Enum.AgentStatuses.Busy" ) );
#endif
	endif;
#region ExecutionContext
	_errorInfo = undefined;
	_header = StrFind ( Code, Chars.LF );
	try
		Execute ( Left ( Code, _header ) );
		Execute ( Mid ( Code, _header ) );
	except
		_errorInfo = ErrorInfo ();
#if ( thinclient or thickclientmanagedapplication ) then
		if ( _monitoring
			and not Debug.DebuggingStopped ) then
			RuntimeSrv.FetchServerDebug ( Debug );
		endif;
#endif
	endtry;
#if ( thinclient or thickclientmanagedapplication ) then
	if ( _monitoring ) then
		// If scenario code /Execute ( Code )/ calls server then
		// Debug sctructure will be re-instanced. In order to pass
		// actual Debug information to the caller we need to reassign
		// acquired (from the server) Debug data
		DebugInfo = Debug;
		agentStatus ( PredefinedValue ( "Enum.AgentStatuses.Available" ) );
	endif;
#endif
	if ( _errorInfo = undefined ) then
		if ( _monitoring ) then
			RuntimeSrv.LogSuccess ( _Scenario, _level, Debug.Job );
		endif;
		LastScenarioReturn = ? ( functionReturnsValue, new Structure ( "Result", result ), undefined );
		return result;
	else
#if ( thinclient or thickclientmanagedapplication ) then
		if ( _monitoring ) then
			if ( PlatformFeatures.HasTimeout
				and not Debug.Error
				and not Debug.DebuggingStopped
				and not Debug.JobCanceled ) then
				Debugger.ErrorCheck ( Debug );
			endif;
		endif;
		if ( Debug.Level = 0 ) then
			try
				Disconnect ();
			except
			endtry;
		endif;
#endif
		Runtime.ThrowError ( ErrorProcessing.BriefErrorDescription ( _errorInfo ), Debug );
	endif;
#endregion

endfunction

function scenarioLevel ( DebugInfo )

	level = 0;
	stack = DebugInfo.Stack;
	lastModule = undefined;
	lastType = undefined;
	for i = 0 to DebugInfo.Level - 1 do
		info = stack [ i ];
		module = info.Module;
		type = info.IsVersion;
		if ( lastModule <> module
			or lastType <> type ) then
			level = level + 1;
		endif;
		lastModule = module;
		lastType = type;
	enddo;
	return level;

endfunction

&atclient
procedure agentStatus ( Status )

	if ( IAmAgent
		and not RunningDelegatedJob ) then
		TesterAgent.AgentStatus ( Status );
	endif;

endprocedure

//@skip-warning
&atclient
procedure Debug ( Value ) export

	//.. stop here for analysing Value

endprocedure

&atclient
procedure Exec ( Application = undefined, ProgramCode = undefined, ResetDebugger, Debugging = false, Offset = 0,
	Filming = false, NewSession = false, Params = undefined ) export

	Runtime.UpdateConstants ();
	Runtime.InitEnv ();
	initMeta ();
	if ( ResetDebugger ) then
		Runtime.InitDebug ( Application, Offset );
	endif;
	if ( Debugging ) then
		DebugStart ();
	endif;
	if ( Filming ) then
		RecorderStart ();
	endif;
	scenario = AppData.Scenario;
	result = Compiler.Build ( scenario, ProgramCode );
	Runtime.RunScript ( result.Compiled, Params, , scenario );
#if ( thinclient or thickclientmanagedapplication ) then
	Runtime.StopSession ();
#endif

endprocedure

&atclient
procedure UpdateConstants () export

	properties = DF.Values ( AppData.Application,
		"Description, DialogsTitle, ScreenshotsLocator, OriginalQuality, Agent" );
	AppName = properties.Description;
	ИмяПриложения = AppName;
	DialogsTitle = properties.DialogsTitle;
	ЗаголовокДиалогов = DialogsTitle;
	ScreenshotsLocator = properties.ScreenshotsLocator;
	ScreenshotsCompressed = not properties.OriginalQuality;
	TesterAgentConnectionString = properties.Agent;

endprocedure

&atclient
procedure InitEnv () export

	Runtime.UpdateConstants ();
	__ = undefined;
	IgnoreErrors = false;
	ИгнорироватьОшибки = false;
	CurrentSource = undefined;
	ТекущийОбъект = undefined;

endprocedure

&atclient
procedure initMeta ( Reset = false ) export

	application = AppData.Application;
	if ( Meta <> undefined
		and AppMeta = application ) then
		return;
	endif;
	AppMeta = application;
	s = DF.Pick ( application, "Metadata" );
	if ( IsBlankString ( s ) ) then
		return;
	endif;
	try
		Runtime.UpdateMeta ( s );
	except
		Runtime.ThrowError ( ErrorDescription (), Debug );
	endtry;

endprocedure

&atclient
procedure UpdateMeta ( JSON ) export

	if ( IsBlankString ( JSON ) ) then
		Meta = undefined;
	else
		Meta = Conversion.FromJSON ( JSON );
	endif;
	Мета = Meta;

endprocedure

&atclient
procedure InitDebug ( Application, Offset ) export

	Debug = new Structure ();
	Debug.Insert ( "Stack", new Array () );
	Debug.Insert ( "ApplicationStack" );
	Debug.Insert ( "ShowProgress", true );
	Debug.Insert ( "Level", 0 );
	Debug.Insert ( "Delay", 0 );
	Debug.Insert ( "Error", false );
	Debug.Insert ( "PreviousError", undefined );
	Debug.Insert ( "ErrorLog" );
	Debug.Insert ( "ErrorLine" );
	Debug.Insert ( "FallenScenario" );
	Debug.Insert ( "Debugging", false );
	Debug.Insert ( "DebuggingStopped", false );
	Debug.Insert ( "SteppingOver", false );
	Debug.Insert ( "SteppingOverPoint", undefined );
	Debug.Insert ( "Running", false );
	Debug.Insert ( "Recording", false );
	Debug.Insert ( "Pointer", 0 );
	Debug.Insert ( "Evaluate", "" );
	Debug.Insert ( "EvaluationResult", "" );
	Debug.Insert ( "EvaluationError", false );
	job = ? ( RunningDelegatedJob, CurrentDelegatedJob, undefined );
	Debug.Insert ( "Job", job );
	Debug.Insert ( "CancelationCheck", CurrentDate () );
	Debug.Insert ( "JobCanceled", false );
	Debug.Insert ( "Offset", Max ( 0, Offset - 1 ) );
	started = ? ( Application = undefined, undefined, RuntimeSrv.StartSession ( Application, ? ( job = undefined, undefined, job.Job ) ) );
	Debug.Insert ( "Started", started );

endprocedure

&atclient
procedure StopSession () export

	started = Debug.Started;
	if ( started = undefined
		or Debug.Level > 0 ) then
		return;
	endif;
	RuntimeSrv.StopSession ( started );

endprocedure

procedure ThrowError ( Text, DebugInfo ) export

	if ( syntaxError ( DebugInfo ) ) then
		throwSyntaxError ( Text, , DebugInfo.Offset );
	elsif ( DebugInfo.Error ) then
		RuntimeSrv.LogFailing ( DebugInfo );
	else
		saveError ( Text, DebugInfo );
	endif;
	rethrow ( DebugInfo );

endprocedure

function syntaxError ( DebugInfo )

	return ( DebugInfo = undefined
		or DebugInfo.Stack [ 0 ] = undefined )
		and not DebugInfo.DebuggingStopped;

endfunction

procedure saveError ( Text, DebugInfo )

#if ( server ) then
	image = undefined;
#else
	image = Screenshot ();
#endif
	entry = RuntimeSrv.LogError ( DebugInfo, Text, image );
	if ( DebugInfo.DebuggingStopped ) then
		return;
	endif;
	log = entry.Log;
	scenario = entry.Scenario;
	line = entry.Line;
	DebugInfo.Error = true;
	DebugInfo.ErrorLog = log;
	DebugInfo.ErrorLine = line;
	DebugInfo.FallenScenario = scenario;
	error = entry.Error;
	Output.PutMessage ( error, undefined, "", log, "" );
#if ( thinclient or thickclientmanagedapplication ) then
	if ( ScenarioForm.IsOpen ( scenario ) ) then
		Notify ( Enum.MessageActivateError (), line, scenario );
	endif;
	refreshLog ();
	passError ( error, DebugInfo );
#endif

endprocedure

procedure rethrow ( DebugInfo )

	Runtime.PreviousLevel ( DebugInfo );
#if ( server ) then
	storeDebugInfo ( DebugInfo );
#else
	Runtime.StopSession ();
#endif
	if ( DebugInfo.DebuggingStopped ) then
		raise Output.StopDebugging ();
	else
		raise Output.ScenarioError ();
	endif;

endprocedure

&atserver
procedure storeDebugInfo ( DebugInfo )

	r = InformationRegisters.ServerDebug.CreateRecordManager ();
	r.Session = SessionParameters.Session;
	r.Debug = new ValueStorage ( DebugInfo );
	r.Write ();

endprocedure

&atclient
procedure passError ( Error, DebugInfo )

	if ( not TesterServerMode ) then
		return;
	endif;
	splitter = StrFind ( Error, ":" );
	Watcher.AddMessage ( Mid ( Error, splitter + 2 ), Enum.MessageTypesError (), DebugInfo.FallenScenario, DebugInfo.ErrorLine );

endprocedure

procedure throwSyntaxError ( Error, Scenario = undefined, Offset = 0 )

	s = Output.CompilationError () + ":" + Error;
	Output.PutMessage ( s, undefined, "", Scenario, "" );
#if ( thinclient or thickclientmanagedapplication ) then
	if ( TesterServerMode ) then
		Watcher.ThrowError ( Error, Scenario, Offset );
	endif;
	Runtime.StopSession ();
#endif
	raise Output.ScenarioError ();

endprocedure

&atclient
procedure refreshLog ()

	NotifyChanged ( Type ( "CatalogRef.ErrorLog" ) );
	NotifyChanged ( Type ( "InformationRegisterRecordKey.Log" ) );

endprocedure

&atclient
procedure WriteError ( Text ) export

	if ( Debug = undefined
		or Debug.Stack [ 0 ] = undefined ) then
		throwSyntaxError ( Text );
	else
		RuntimeSrv.LogError ( Debug, Text, Screenshot () );
	endif;

endprocedure

&atclient
procedure ShowWarning ( Text ) export

	entry = RuntimeSrv.LogError ( Debug, Text, Screenshot () );
	scenario = entry.Scenario;
	if ( ScenarioForm.IsOpen ( scenario ) ) then
		Notify ( Enum.MessageActivateError (), entry.Line, scenario );
	endif;
	Output.PutMessage ( entry.Error, undefined, , entry.Log, "" );
	Watcher.AddMessage ( Text, Enum.MessageTypesWarning (), entry.Scenario, entry.Line );
	refreshLog ();

endprocedure

function Perform ( Scenario, Params = undefined, Application = undefined, InsideFolder, ServerDebug = undefined ) export

#if ( server ) then
	dbg = ServerDebug;
	onServer = true;
#else
	dbg = Debug;
	onServer = false;
#endif
	level = dbg.Level;
	stack = dbg.Stack [ level ];
	program = Compiler.Call ( Scenario, stack.Module, stack.IsVersion, Application, InsideFolder, onServer );
	return callProgram ( Program, Scenario, Params, dbg );

endfunction

function callProgram ( Program, Scenario, Params, DebugInfo )

	if ( Program = undefined ) then
		error = Output.CallError ( new Structure ( "Scenario", Scenario ) );
		Runtime.ThrowError ( error, DebugInfo );
	else
		compilation = Program.Compilation;
		reference = Program.Scenario;
		Runtime.NextLevel ( DebugInfo );
		result = Runtime.RunScript ( compilation.Compiled, toStructure ( Params ), DebugInfo, reference );
		Runtime.PreviousLevel ( DebugInfo );
		return result;
	endif;

endfunction

function toStructure ( Params )

	if ( TypeOf ( Params ) = Type ( "String" )
		and StrStartsWith ( Params, "{" )
		and StrEndsWith ( Params, "}" ) ) then
		return Conversion.FromJSON ( Params );
	else
		return Params;
	endif;

endfunction

&atclient
function GetErrors () export

	try
		errors = App.GetActiveWindow ().GetUserMessageTexts ();
	except
		errors = new Array ();
	endtry;
	if ( errors.Count () = 0 ) then
		form = Forms.Get1C ();
		if ( form <> undefined ) then
			if ( Framework.VersionLess ( "8.3.15" ) ) then
				type = Type ( "TestedFormField" );
				label = form.FindObject ( type, , "Field1" );
				if ( label = undefined ) then
					label = form.FindObject ( type, , "Поле1" );
				endif;
				if ( label <> undefined ) then
					errors.Add ( label.TitleText );
				endif;
			else
				type = Type ( "TestedFormDecoration" );
				label = form.FindObject ( type, , "Message" );
				if ( label = undefined ) then
					label = form.FindObject ( type, , "ErrorInfo" );
				endif;
				if ( label <> undefined ) then
					errors.Add ( label.TitleText );
				endif;
			endif;
		endif;
	endif;
	return errors;

endfunction

&atclient
function FindErrors ( Template ) export

	result = new Array ();
	messages = Runtime.GetErrors ();
	if ( messages.Count () > 0 ) then
		result = RuntimeSrv.FindErrors ( Template, messages );
	endif;
	return result;

endfunction

&atclient
function DeepFunction ( This, Chronograph, _Procedures, _Name, _P1 = undefined, _P2 = undefined, _P3 = undefined, _P4 = undefined, _P5 = undefined, _P6 = undefined, _P7 = undefined, _P8 = undefined, _P9 = undefined, _P10 = undefined, _P11 = undefined, _P12 = undefined, _P13 = undefined, _P14 = undefined, _P15 = undefined, _P16 = undefined, _P17 = undefined, _P18 = undefined, _P19 = undefined, _P20 = undefined ) export

	_script = _Procedures [ _Name ];
#region ScenarioContext
	//@skip-warning
	тут = This;
	//@skip-warning
	Хронограф = Chronograph;
	result = undefined;
#endregion
#region ExecutionContext
	Runtime.NextLevel ( Debug );
	try
		Execute ( _script );
	except
		errorInfo = ErrorInfo ();
		RuntimeSrv.FetchServerDebug ( Debug );
		Runtime.ThrowError ( ErrorProcessing.BriefErrorDescription ( errorInfo ), Debug );
	endtry;
	Runtime.PreviousLevel ( Debug );
	return result;
#endregion

endfunction

procedure NextLevel ( DebugInfo ) export

	DebugInfo.Level = DebugInfo.Level + 1;

endprocedure

procedure PreviousLevel ( DebugInfo ) export

	level = DebugInfo.Level;
	if ( level = 0 ) then
		return;
	endif;
	DebugInfo.Level = level - 1;

endprocedure

&atclient
procedure DeepProcedure ( This, Chronograph, _Procedures, _Name, _P1 = undefined, _P2 = undefined, _P3 = undefined, _P4 = undefined, _P5 = undefined, _P6 = undefined, _P7 = undefined, _P8 = undefined, _P9 = undefined, _P10 = undefined, _P11 = undefined, _P12 = undefined, _P13 = undefined, _P14 = undefined, _P15 = undefined, _P16 = undefined, _P17 = undefined, _P18 = undefined, _P19 = undefined, _P20 = undefined ) export

	_script = _Procedures [ _Name ];
#region ScenarioContext
	//@skip-warning
	тут = This;
	//@skip-warning
	Хронограф = Chronograph;
#endregion
#region ExecutionContext
	Runtime.NextLevel ( Debug );
	errorInfo = undefined;
	try
		Execute ( _script );
	except
		errorInfo = ErrorInfo ();
		RuntimeSrv.FetchServerDebug ( Debug );
		Runtime.ThrowError ( ErrorProcessing.BriefErrorDescription ( errorInfo ), Debug );
	endtry;
	Runtime.PreviousLevel ( Debug );
#endregion

endprocedure

function IsClient () export

#if ( thinclient or thickclientmanagedapplication ) then
	return true;
#else
	return false;
#endif

endfunction

function IsServer () export

#if ( server ) then
	return true;
#else
	return false;
#endif

endfunction

#endif
