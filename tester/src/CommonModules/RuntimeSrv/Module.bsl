function StartSession ( val Application, val Job ) export
	
	r = InformationRegisters.Sessions.CreateRecordManager ();
	r.Session = SessionParameters.Session;
	started = CurrentSessionDate ();
	r.Started = started;
	r.Application = Application;
	r.Job = Job;
	ExchangeKillers.Write ( r );
	return started;
	
endfunction 

procedure StopSession ( val Started ) export
	
	r = InformationRegisters.Sessions.CreateRecordManager ();
	r.Session = SessionParameters.Session;;
	r.Started = Started;
	r.Read ();
	r.Finished = CurrentSessionDate ();
	ExchangeKillers.Write ( r );
	
endprocedure 

function FindScenario ( val Scenario, val DefaultApplication, val Application, val Parent, val EvenLocked = false, val EvenRemoved = false ) export
	
	s = "
	|select allowed top 1 1 as Priority, Scenarios.Ref as Ref
	|into Main
	|from Catalog.Scenarios as Scenarios
	|where Scenarios.Path = &Scenario
	|and Scenarios.Application.Description = &Application
	|and not Scenarios.DeletionMark
	|union all
	|select top 1 0, Scenarios.Ref
	|from Catalog.Scenarios as Scenarios
	|where Scenarios.Path = &Scenario
	|and Scenarios.Application = &Application
	|";
	if ( not EvenRemoved ) then
		s = s + "and not Scenarios.DeletionMark"; 
	endif;
	if ( Application = undefined ) then
		s = s + "
		|union all
		|select top 1 2 as Priority, Scenarios.Ref as Ref
		|from Catalog.Scenarios as Scenarios
		|where Scenarios.Path = &Scenario
		|and Scenarios.Application = value ( Catalog.Applications.EmptyRef )
		|";
		if ( not EvenRemoved ) then
			s = s + "and not Scenarios.DeletionMark"; 
		endif;
	endif; 
	s = s + "
	|order by Priority
	|;";
	if ( EvenLocked ) then
		s = s + "
		|select Main.Ref as Ref
		|from Main as Main
		|";
	else
		s = s + "
		|select case when isnull ( Editing.User, &User ) = &User then Main.Ref
		|			else isnull ( Versions.Version, Main.Ref )
		|		end as Ref
		|from Main as Main
		|	//
		|	// Versions
		|	//
		|	left join InformationRegister.Versions.SliceLast ( , Scenario in ( select Ref from Main ) ) as Versions
		|	on Versions.Scenario = Main.Ref
		|	//
		|	// Editing
		|	//
		|	left join InformationRegister.Editing as Editing
		|	on Editing.Scenario = Main.Ref
		|";
	endif; 
	q = new Query ( s );
	if ( Parent = undefined ) then
		path = Scenario;
	else
		parentPath = DF.Pick ( Parent, "Path" );
		path = ? ( parentPath = "", Scenario, parentPath + "." + Scenario );
	endif; 
	q.SetParameter ( "User", SessionParameters.User );
	q.SetParameter ( "Scenario", path );
	q.SetParameter ( "Application", ? ( Application = undefined, DefaultApplication, Application ) );
	table = q.Execute ().Unload ();
	return ? ( table.Count () = 0, undefined, table [ 0 ].Ref );
	
endfunction 

function ActualScenario ( val Scenario ) export
	
	s = "
	|select case when isnull ( Editing.User, &User ) = &User then Main.Ref else isnull ( Versions.Version, &Scenario ) end as Ref
	|from ( select &Scenario as Ref ) as Main
	|	//
	|	// Versions
	|	//
	|	left join InformationRegister.Versions.SliceLast ( , Scenario = &Scenario ) as Versions
	|	on Versions.Scenario = Main.Ref
	|	//
	|	// Editing
	|	//
	|	left join InformationRegister.Editing as Editing
	|	on Editing.Scenario = Main.Ref
	|";
	q = new Query ( s );
	q.SetParameter ( "User", SessionParameters.User );
	q.SetParameter ( "Scenario", Scenario );
	return q.Execute ().Unload () [ 0 ].Ref;
	
endfunction 

function LogError ( val Debug, val Error, val Screenshot ) export
	
	SetPrivilegedMode ( true );
	return Catalogs.ErrorLog.Add ( Debug, Error, Screenshot );

endfunction

function Stack ( Debug ) export
	
	stack = Debug.Stack;
	s = new Array ();
	calls = new Array ();
	for i = 0 to Min ( stack.Ubound (), Debug.Level ) do
		info = stack [ i ];
		module = getModule ( info );
		scenario = module.Ref;
		position = info.Row + ? ( i = 0, Debug.Offset, 0 );
		line = Format ( position, "NG=;NZ=" );
		s.Add ( module.Name + "[" + line + "]" );
		calls.Add ( new Structure ( "Scenario, Row", scenario, position ) );
	enddo; 
	data = new Structure ( "Line, Source, Scenario, Calls" );
	data.Line = Format ( line, "NG=;NZ=" );
	data.Source = StrConcat ( s, " -> " );
	data.Scenario = scenario;
	data.Calls = calls;
	return data;
	
endfunction 

function getModule ( Stack )
	
	source = ? ( Stack.IsVersion, "Catalog.Versions", "Catalog.Scenarios" );
	s = "
	|select top 1 Scenarios.Path as Name, Scenarios.Ref as Ref
	|from " + source + " as Scenarios
	|where Scenarios.Code = &Module
	|";
	q = new Query ( s );
	q.SetParameter ( "Module", Stack.Module );
	return q.Execute ().Unload () [ 0 ];

endfunction 

function GetSource ( Scenario ) export
	
	result = new Structure ( "Application, Scenario" );
	if ( TypeOf ( Scenario ) = Type ( "CatalogRef.Versions" ) ) then
		data = DF.Values ( Scenario, "Application, Scenario" );
		result.Scenario = data.Scenario;
		result.Application = data.Application;
	else
		result.Scenario = Scenario;
		result.Application = DF.Pick ( Scenario, "Application" );
	endif;
	return result;
	
endfunction

procedure WriteError ( Source, Scenario, Date, Error, Level, Job ) export
	
	SetPrivilegedMode ( true );
	r = InformationRegisters.Log.CreateRecordManager ();
	r.Period = CurrentSessionDate ();
	r.Session = SessionParameters.Session;
	r.Scenario = Scenario;
	r.Level = Level;
	r.Status = Enums.Statuses.Fault;
	r.Error = Error;
	r.Source = Source.Scenario;
	r.Application = Source.Application;
	r.Area = errorArea ( Error, Level );
	RuntimeSrv.AssignJob ( r, Job );
	BeginTransaction ();
	ExchangeKillers.Wait ();
	completeRunning ( r );
	ExchangeKillers.Write ( r );
	CommitTransaction ();
	
endprocedure

function errorArea ( Error, Level )
	
	stack = Error.Stack; // Error object had been created and cached
	return stack [ Max ( 0, stack.Count () - ( Level + 1 ) ) ].Area;
	
endfunction

procedure completeRunning ( Record )
	
	completed = CurrentUniversalDateInMilliseconds ();
	session = SessionParameters.Session;
	data = InformationRegisters.Log.SliceLast ( , new Structure ( "Scenario, Session", Record.Scenario, session ) );
	if ( data.Count () = 1 ) then
		log = data [ 0 ];
		if ( log.Status = Enums.Statuses.Running ) then
			r = InformationRegisters.Log.CreateRecordManager ();
			FillPropertyValues ( r, log, "Period, Scenario, Session" );
			ExchangeKillers.Delete ( r );
			started = log.Started;
			Record.Started = started;
			Record.Duration = completed - started;
		endif; 
	endif;
	
endprocedure 

procedure AssignJob ( Record, Job ) export
	
	if ( Job <> undefined ) then
		ref = Job.Job;
		Record.Job = ref;
		parent = DF.Pick ( ref, "Job" );
		Record.ParentJob = ? ( parent.IsEmpty (), ref, parent );
		Record.Row = Job.Row;
	endif;
	
endprocedure

procedure LogRunning ( val Scenario, val Level, val Job ) export
	
	SetPrivilegedMode ( true );
	r = InformationRegisters.Log.CreateRecordManager ();
	r.Period = CurrentSessionDate ();
	r.Session = SessionParameters.Session;
	r.Scenario = Scenario;
	r.Level = Level;
	r.Status = Enums.Statuses.Running;
	r.Started = CurrentUniversalDateInMilliseconds ();
	source = RuntimeSrv.GetSource ( Scenario );
	r.Source = source.Scenario;
	r.Application = source.Application;
	RuntimeSrv.AssignJob ( r, Job );
	ExchangeKillers.Write ( r );
	
endprocedure 

procedure LogSuccess ( val Scenario, val Level, val Job ) export
	
	SetPrivilegedMode ( true );
	r = InformationRegisters.Log.CreateRecordManager ();
	r.Period = CurrentSessionDate ();
	r.Session = SessionParameters.Session;
	r.Scenario = Scenario;
	r.Level = Level;
	r.Status = Enums.Statuses.Passed;
	source = RuntimeSrv.GetSource ( Scenario );
	r.Source = source.Scenario;
	r.Application = source.Application;
	RuntimeSrv.AssignJob ( r, Job );
	BeginTransaction ();
	ExchangeKillers.Wait ();
	completeRunning ( r );
	ExchangeKillers.Write ( r );
	CommitTransaction ();
	
endprocedure 

procedure LogFailing ( val Debug ) export
	
	SetPrivilegedMode ( true );
	stack = stack ( Debug );
	scenario = stack.Scenario;
	if ( scenario = Debug.FallenScenario ) then
		return;
	endif; 
	source = RuntimeSrv.GetSource ( scenario );
	RuntimeSrv.WriteError ( source, scenario, CurrentSessionDate (), Debug.ErrorLog, Debug.Level, Debug.Job );
	
endprocedure

function GetSpreadsheet ( Module, IsVersion ) export
	
	data = spreadsheetData ( Module, IsVersion );
	t = data.Template;
	if ( t = undefined ) then
		return undefined;
	endif; 
	tabDoc = t.Get ();
	if ( tabDoc = undefined ) then
		return undefined;
	endif;
	areas = data.Areas;
	if ( areas.Count () = 0 ) then
		x = tabDoc.TableWidth;
		y = tabDoc.TableHeight;
		if ( x = 0 and y = 0 ) then
			return undefined;
		endif;
		row = areas.Add ();
		row.Left = 1;
		row.Right = x;
		row.Up = 1;
		row.Bottom = y;
	endif; 
	return new Structure ( "Template, Areas", tabDoc, Collections.Serialize ( areas ) );

endfunction 

function spreadsheetData ( Module, IsVersion )
	
	source = ? ( IsVersion, "Catalog.Versions", "Catalog.Scenarios" );
	s = "
	|select top 1 Scenarios.Template as Template
	|from " + source + " as Scenarios
	|where Scenarios.Code = &Module
	|;
	|select Areas.Left as Left, Areas.Right as Right, Areas.Top as Up, Areas.Bottom as Bottom
	|from " + source + ".Areas as Areas
	|where Areas.Ref.Code = &Module
	|";
	q = new Query ( s );
	q.SetParameter ( "Module", Module );
	data = q.ExecuteBatch ();
	template = data [ 0 ].Unload () [ 0 ].Template;
	areas = data [ 1 ].Unload ();
	return new Structure ( "Template, Areas", template, areas );
	
endfunction 

function FindErrors ( val Template, val Messages ) export
	
	pattern = prepareTemplate ( Template );
	result = new Array ();
	for each msg in Messages do
		if ( Regexp.Test ( msg, pattern ) ) then
			result.Add ( msg );
		endif;
	enddo; 
	return result;
	
endfunction 

function prepareTemplate ( Template )
	
	s = Template;
	s = StrReplace ( s, "*", ".+" );
	s = StrReplace ( s, "?", "." );
	return s;
	
endfunction 

procedure CheckSyntax ( val Code ) export
	
	//@skip-warning
	var Debug, _procedures, this, тут, Chronograph, Хронограф;
	Execute ( Code );

endprocedure 

function DeepFunction ( This, Chronograph, Debug, val _Procedures, _Name, _P1 = undefined, _P2 = undefined, _P3 = undefined, _P4 = undefined, _P5 = undefined, _P6 = undefined, _P7 = undefined, _P8 = undefined, _P9 = undefined, _P10 = undefined, _P11 = undefined, _P12 = undefined, _P13 = undefined, _P14 = undefined, _P15 = undefined, _P16 = undefined, _P17 = undefined, _P18 = undefined, _P19 = undefined, _P20 = undefined ) export
	
	initDebugStorage ();
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
	_errorInfo = undefined;
	try
		Execute ( _script );
	except
		_errorInfo = ErrorInfo ();
	endtry;
	if ( _errorInfo = undefined ) then
		Runtime.PreviousLevel ( Debug );
		return result;
	else
		Runtime.ThrowError ( ErrorProcessing.BriefErrorDescription ( _errorInfo ), Debug );
	endif; 
	#endregion
	
endfunction 

procedure initDebugStorage ()
	
	r = InformationRegisters.ServerDebug.CreateRecordManager ();
	r.Session = SessionParameters.Session;
	r.Delete ();
	
endprocedure

procedure DeepProcedure ( This, Chronograph, Debug, val _Procedures, _Name, _P1 = undefined, _P2 = undefined, _P3 = undefined, _P4 = undefined, _P5 = undefined, _P6 = undefined, _P7 = undefined, _P8 = undefined, _P9 = undefined, _P10 = undefined, _P11 = undefined, _P12 = undefined, _P13 = undefined, _P14 = undefined, _P15 = undefined, _P16 = undefined, _P17 = undefined, _P18 = undefined, _P19 = undefined, _P20 = undefined ) export
	
	initDebugStorage ();
	_script = _Procedures [ _Name ];
	#region ScenarioContext
	//@skip-warning
	тут = This;
	//@skip-warning
	Хронограф = Chronograph;
	#endregion
	#region ExecutionContext
	Runtime.NextLevel ( Debug );
	_errorInfo = undefined;
	try
		Execute ( _script );
	except
		_errorInfo = ErrorInfo ();
	endtry;
	if ( _errorInfo = undefined ) then
		Runtime.PreviousLevel ( Debug );
	else
		Runtime.ThrowError ( ErrorProcessing.BriefErrorDescription ( _errorInfo ), Debug );
	endif; 
	#endregion

endprocedure

function RecordingContext ( val Code, val IsVersion ) export
	
	SetPrivilegedMode ( true );
	BeginTransaction ();
	result = scenarioAndModule ( Code, IsVersion );
	if ( result.Module = null ) then
		data = scenarioData ( result.Scenario, IsVersion );
		obj = Catalogs.Modules.CreateItem ();
		scenario = result.Scenario;
		obj.Scenario = scenario;
		obj.Description = data.Description;
		obj.Path = data.Path;
		obj.Changed = data.Changed;
		obj.Application = data.Application;
		obj.Script = data.Script;
		obj.IsVersion = IsVersion;
		obj.Source = ? ( IsVersion, data.Source, scenario );
		obj.Write ();
		result.Module = obj.Ref;
	endif;
	CommitTransaction ();
	return result;
	
endfunction

function scenarioAndModule ( Code, IsVersion )
	
	source = "Catalog." + ? ( IsVersion, "Versions", "Scenarios" );
	lock = new DataLock ();
	item = lock.Add ( source );
	item.SetValue ( "Code", Code );
	item.Mode = DataLockMode.Exclusive;
	lock.Lock ();
	s = "
	|select Scenarios.Ref as Scenario, Modules.Ref as Module
	|from " + source + " as Scenarios
	|	//
	|	// Modules
	|	//
	|	left join Catalog.Modules as Modules
	|	on Modules.Scenario = Scenarios.Ref
	|	and Modules.Changed = Scenarios.Changed
	|where Scenarios.Code = &Code
	|";
	q = new Query ( s );
	q.SetParameter ( "Code", Code );
	return Conversion.RowToStructure ( q.Execute ().Unload () );
	
endfunction

function scenarioData ( Scenario, IsVersion )
	
	s = "
	|select Scenarios.Description as Description, Scenarios.Path as Path,
	|	Scenarios.Changed as Changed, Scenarios.Application as Application,
	|	Scenarios.Script as Script";
	if ( IsVersion ) then
		s = s + ", Scenarios.Scenario as Source"
	endif;
	s = s + "
	|from Catalog." + ? ( IsVersion, "Versions", "Scenarios" ) + " as Scenarios
	|where Scenarios.Ref = &Ref
	|";
	q = new Query ( s );
	q.SetParameter ( "Ref", Scenario );
	return q.Execute ().Unload () [ 0 ];
	
endfunction

procedure Recording ( val Params ) export
	
	SetPrivilegedMode ( true );
	r = InformationRegisters.Timelapse.CreateRecordManager ();
	r.Session = SessionParameters.Session;
	r.Scenario = Params.Scenario;
	r.Row = Params.Row;
	r.Date = CurrentSessionDate ();
	r.Pointer = Params.Pointer;
	r.Module = Params.Module;
	r.Screenshot = new ValueStorage ( Params.Screenshot );
	r.Write ();	
	
endprocedure

procedure FetchServerDebug ( Debug ) export
	
	r = InformationRegisters.ServerDebug.CreateRecordManager ();
	r.Session = SessionParameters.Session;
	r.Read ();
	if ( r.Selected () ) then
		try
			Debug = r.Debug.Get ();
		except
		endtry;
	endif;
	r.Delete ();
	
endprocedure

procedure LogException ( val Subsystem, val Exception, val Level = undefined ) export
	
	logLevel = ? ( Level = undefined, EventLogLevel.Information, EventLogLevel [ Level ] );
	WriteLogEvent ( "ExternalMeta", logLevel, , , Exception );

endprocedure
