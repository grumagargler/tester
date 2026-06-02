&atclient
var ScriptRow;
&atclient
var CurrentScriptRow;

// *****************************************
// *********** Form events

&atserver
procedure OnCreateAtServer ( Cancel, StandardProcessing )
	
	loadParams ();
	setTitle ();
	readAppearance ();
	Appearance.Apply ( ThisObject );
	
endprocedure

&atserver
procedure readAppearance ()

	rules = new Array ();
	rules.Add ( "
	|ScenarioOutdated show ScenarioOutdated
	|" );
	Appearance.Read ( ThisObject, rules );

endprocedure

&atserver
procedure loadParams ()
	
	if ( not Parameters.Error.IsEmpty () ) then
		data = errorData ();
		if ( data = undefined ) then
			raise Output.ScenarioNotFilmed ();
		endif;
		Scenario = data.Scenario;
		Session = data.Session;
		DateStart = data.Start;
		DateEnd = data.End;
	elsif ( Parameters.Scenario <> undefined ) then
		Scenario = Parameters.Scenario;
		Session = Parameters.Session;
		data = sessionData ();
		DateStart = data.Start;
		DateEnd = data.End;
	endif;
	fill ();
	
endprocedure

&atserver
function errorData ()
	
	s = "
	|select top 1 Log.Session as Session, Log.Start as Start, Log.End as End, Log.Scenario as Scenario
	|from (
	|	select top 1 Sessions.Session as Session, Sessions.Started as Start,
	|		Sessions.Finished as End, Log.Scenario as Scenario
	|	from InformationRegister.Sessions as Sessions
	|		//
	|		// Filter by Log
	|		//
	|		join (
	|			select Log.Scenario as Scenario, Log.Session as Session, Log.Date as Date
	|			from Catalog.ErrorLog as Log
	|			where Log.Ref = &Ref
	|		) as Log
	|		on Sessions.Started <= Log.Date
	|		and Sessions.Session = Log.Session
	|	order by Sessions.Started desc
	|	) as Log
	|	//
	|	// Filmed only
	|	//
	|	join InformationRegister.Timelapse as Timelapses
	|	on Timelapses.Session = Log.Session
	|	and Timelapses.Scenario = Log.Scenario
	|	and Timelapses.Date between Log.Start and Log.End
	|";
	q = new Query ( s );
	q.SetParameter ( "Ref", Parameters.Error );
	result = q.Execute ().Unload ();
	if ( result.Count () = 0 ) then
		return undefined;
	endif;
	data = new Structure ( "Scenario, Session, Start, End" );
	FillPropertyValues ( data, result [ 0 ] );
	return data;
	
endfunction

&atserver
function sessionData ()
	
	s = "
	|select Start.Started as Start,
	|	min ( isnull ( dateadd ( Finish.Started, second, -1 ), datetime ( 3999, 12, 31 ) ) ) as End
	|from ( select &Date as Started ) as Start
	|	//
	|	// Finish
	|	//
	|	left join (
	|		select min ( Finish.Started ) as Started
	|		from InformationRegister.Sessions as Finish
	|		where Finish.Started > &Date
	|		and Finish.Session = &Session
	|	) as Finish
	|	on true
	|group by Start.Started
	|";
	q = new Query ( s );
	q.SetParameter ( "Session", Parameters.Session );
	q.SetParameter ( "Date", Parameters.Date );
	q.SetParameter ( "Scenario", Scenario );
	return q.Execute ().Unload () [ 0 ];
	
endfunction

&atserver
procedure fill ()
	
	data = scriptData ();
	module = data.Module;
	if ( module = undefined ) then
		return;
	endif;
	ScenarioOutdated = module.ModuleChanged <> module.ScenarioChanged;
	Script.Clear ();
	i = 1;
	InitialLine = module.FirstRow;
	for each row in StrSplit ( module.Script, Chars.LF ) do
		line = Script.Add ();
		line.Number = i;
		line.Line = row;
		i = i + 1;
	enddo;
	for each row in data.Calls do
		Script [ row.Row - 1 ].Calls = row.Count;
	enddo;
	for each row in data.Transitions do
		line = Script [ row.Row - 1 ];
		line.Next = row.Next;
		line.Previous = row.Previous;
	enddo;
	errorLog = Parameters.Error;
	for each row in data.Errors do
		i = row.Row;
		line = Script [ i - 1 ];
		error = row.Error;
		line.Error = error;
		if ( error = errorLog ) then
			InitialLine = i;
		endif;
	enddo;
	Appearance.Apply ( ThisObject, "ScenarioOutdated" );
	
endprocedure

&atserver
function scriptData ()
	
	s = "
	|select Timelapse.Scenario as Scenario, Timelapse.Module as Module,
	|	Timelapse.Row as Row, Timelapse.Pointer as Pointer
	|into Dump
	|from InformationRegister.Timelapse as Timelapse
	|where Timelapse.Session = &Session
	|and Timelapse.Date between &DateStart and &DateEnd
	|;
	|// Module
	|select top 1 Dump.Pointer as Pointer, Dump.Row as FirstRow, Dump.Module.Script as Script,
	|	Dump.Module.Changed as ModuleChanged, Dump.Module.Scenario.Changed as ScenarioChanged
	|from Dump as Dump
	|where Dump.Scenario = &Scenario
	|order by Dump.Pointer
	|;
	|// Calls
	|select Dump.Row as Row, count ( Calls.Row ) - 1 as Count
	|from Dump as Dump
	|	//
	|	// Calls
	|	//
	|	left join Dump as Calls
	|	on Calls.Row = Dump.Row
	|	and Calls.Scenario = Dump.Scenario
	|	and Calls.Pointer = Dump.Pointer
	|where Dump.Scenario = &Scenario
	|group by Dump.Module, Dump.Row
	|having count ( Calls.Row ) > 1
	|;
	|// Transitions
	|select distinct Dump.Row as Row,
	|	case when Forward.Scenario is null then false else true end as Next,
	|	case when Backward.Scenario is null then false else true end as Previous
	|from Dump as Dump
	|	//
	|	// Forward
	|	//
	|	left join Dump as Forward
	|	on Forward.Pointer = Dump.Pointer + 1
	|	and Forward.Scenario <> Dump.Scenario
	|	//
	|	// Backward
	|	//
	|	left join Dump as Backward
	|	on Backward.Pointer = Dump.Pointer - 1
	|	and Backward.Scenario <> Dump.Scenario
	|where Dump.Scenario = &Scenario
	|and not ( Forward.Module is null
	|	and Backward.Module is null )
	|;
	|// Errors
	|select Errors.Ref as Error, Errors.Line as Row
	|from Catalog.ErrorLog as Errors
	|where Errors.Session = &Session
	|and Errors.Scenario = &Scenario
	|and Errors.Date between &DateStart and &DateEnd
	|";
	q = new Query ( s );
	q.SetParameter ( "Session", Session );
	q.SetParameter ( "Scenario", Scenario );
	q.SetParameter ( "DateStart", DateStart );
	q.SetParameter ( "DateEnd", DateEnd );
	data = q.ExecuteBatch ();
	result = new Structure ();
	result.Insert ( "Module", Conversion.RowToStructure ( data [ 1 ].Unload () ) );
	result.Insert ( "Calls", data [ 2 ].Unload () );
	result.Insert ( "Transitions", data [ 3 ].Unload () );
	result.Insert ( "Errors", data [ 4 ].Unload () );
	return result;
	
endfunction

&atserver
procedure setTitle ()
	
	Title = "@" + Scenario;
	
endprocedure

&atclient
procedure OnOpen ( Cancel )
	
	activateLine ( InitialLine, false );
	
endprocedure

&atclient
procedure activateLine ( Line, Debugging )
	
	row = Script [ Line - 1 ];
	if ( Debugging ) then
		changeCurrentRow ( row );
	endif;
	Items.Script.CurrentRow = row.GetID ();

endprocedure

&atclient
procedure changeCurrentRow ( Row )
	
	if ( CurrentScriptRow <> undefined ) then
		CurrentScriptRow.Current = 0;
	endif;
	CurrentScriptRow = row;
	CurrentScriptRow.Current = 1;
	
endprocedure

// *****************************************
// *********** Script

&atclient
procedure GoForward ( Command )
	
	nextStep ( 1, not ScriptRow.Next );
	
endprocedure

&atclient
procedure nextStep ( Direction, ThisScenario )
	
	if ( moving ( Direction, ThisScenario ) ) then
		displayInfo ();
	else
		Output.NoStepsInChronograph ();
	endif;
	
endprocedure

&atclient
function moving ( Direction, ThisScenario )
	
	pointer = CurrentPointer + Direction;
	if ( pointer < 0 ) then
		return false;
	endif;
	data = stepData ( context (), pointer, ThisScenario, Screenshot, UUID );
	if ( data = undefined ) then
		return false;
	endif;
	newScenario = data.Scenario;
	if ( Scenario <> newScenario ) then
		Scenario = newScenario;
		fill ();
	endif;
	setPointer ( pointer );
	activateLine ( data.Row, true );
	return true;
	
endfunction

&atservernocontext
function stepData ( val Params, val Pointer, val ThisScenario, Screenshot, val UUID )
	
	info = getStepData ( Params, Pointer, ThisScenario );
	if ( info = undefined ) then
		return undefined;
	endif;
	data = info.Screenshot.Get ();
	if ( data = undefined ) then
		Screenshot = "";
	else
		Screenshot = PutToTempStorage ( data, UUID );
	endif;
	result = new Structure ();
	result.Insert ( "Scenario", info.Scenario );
	result.Insert ( "Row", info.Row );
	return result;
	
endfunction

&atservernocontext
function getStepData ( Params, Pointer, ThisScenario )
	
	s = "
	|select Timelapse.Scenario as Scenario, Timelapse.Row as Row, Timelapse.Screenshot as Screenshot
	|from InformationRegister.Timelapse as Timelapse
	|where Timelapse.Session = &Session
	|and Timelapse.Pointer = &Pointer
	|and Timelapse.Date between &DateStart and &DateEnd
	|";
	if ( ThisScenario ) then
		s = s + "and Timelapse.Scenario = &Scenario";
	endif;
	q = new Query ( s );
	q.SetParameter ( "Session", Params.Session );
	q.SetParameter ( "DateStart", Params.DateStart );
	q.SetParameter ( "DateEnd", Params.DateEnd );
	q.SetParameter ( "Pointer", Pointer );
	q.SetParameter ( "Scenario", Params.Scenario );
	return Conversion.RowToStructure ( q.Execute ().Unload () );
	
endfunction

&atclient
procedure GoBack ( Command )
	
	nextStep ( -1, not ScriptRow.Previous );
	
endprocedure

&atclient
procedure ScriptOnActivateRow ( Item )
	
	ScriptRow = Item.CurrentData;
	AttachIdleHandler ( "update", 0.1, true );
	
endprocedure

&atclient
procedure update () export
	
	if ( ScriptRow = undefined ) then
		setPointer ( 0 );
		Screenshot = "";
	else
		if ( ScriptRow = CurrentScriptRow ) then
			return;
		endif; 
		newPointer = displayLastScreen ( context (), Screenshot, UUID );
		if ( newPointer <> undefined ) then
			changeCurrentRow ( ScriptRow );
			setPointer ( newPointer );
		endif;
	endif; 
	displayInfo ();

endprocedure

&atclient
procedure setPointer ( Pointer )
	
	CurrentPointer = Pointer;
	RowPointer = Pointer;
	
endprocedure

&atclient
function context ()
	
	p = new Structure ();
	p.Insert ( "Session", Session );
	p.Insert ( "Scenario", Scenario );
	p.Insert ( "DateStart", DateStart );
	p.Insert ( "DateEnd", DateEnd );
	p.Insert ( "Row", ScriptRow.Number );
	return p;
	
endfunction

&atservernocontext
function displayLastScreen ( val Params, Screenshot, val UUID )
	
	Screenshot = "";
	info = getLastScreen ( Params );
	if ( info = undefined ) then
		return undefined;
	endif;
	data = info.Screenshot.Get ();
	if ( data <> undefined ) then
		Screenshot = PutToTempStorage ( data, UUID );
	endif;
	return info.Pointer;

endfunction

&atservernocontext
function getLastScreen ( Params )
	
	s = "
	|select Timelapse.Screenshot as Screenshot, Timelapse.Pointer as Pointer
	|from InformationRegister.Timelapse as Timelapse
	|	//
	|	// LastPointer
	|	//
	|	join (
	|		select max ( Timelapse.Date ) as Date, max ( Timelapse.Pointer ) as Pointer
	|		from InformationRegister.Timelapse as Timelapse
	|		where Timelapse.Session = &Session
	|		and Timelapse.Scenario = &Scenario
	|		and Timelapse.Date between &DateStart and &DateEnd
	|		and Timelapse.Row = &Row
	|	) as LastPointer
	|	on Timelapse.Session = &Session
	|	and Timelapse.Scenario = &Scenario
	|	and Timelapse.Date = LastPointer.Date
	|	and Timelapse.Pointer = LastPointer.Pointer
	|";
	q = new Query ( s );
	q.SetParameter ( "Session", Params.Session );
	q.SetParameter ( "Scenario", Params.Scenario );
	q.SetParameter ( "DateStart", Params.DateStart );
	q.SetParameter ( "DateEnd", Params.DateEnd );
	q.SetParameter ( "Row", Params.Row );
	return Conversion.RowToStructure ( q.Execute ().Unload () );
	
endfunction

&atclient
procedure displayInfo ()
	
	if ( Screenshot = "" ) then
		if ( ScriptRow = undefined ) then
			Items.Pages.CurrentPage = Items.UndefinedCode;
		elsif ( RowPointer = CurrentPointer ) then
			Items.Pages.CurrentPage = Items.InfoPage;
		else
			Items.Pages.CurrentPage = Items.UndefinedPointer;
		endif; 
	else
		Items.Pages.CurrentPage = Items.ScreenshotPage;
	endif; 
	Items.ScriptError.Visible = not ScriptRow.Error.IsEmpty ();
	
endprocedure 

&atclient
procedure ScriptSelection ( Item, SelectedRow, Field, StandardProcessing )
	
	StandardProcessing = false;
	editScenario ();
	
endprocedure

&atclient
procedure editScenario ()
	
	if ( TypeOf ( Scenario ) = Type ( "CatalogRef.Versions" ) ) then
		target = DF.Pick ( Scenario, "Scenario" );
	else
		target = Scenario;
	endif;
	ScenarioForm.GotoLine ( target, ScriptRow.Number, ScriptRow.Error );
	
endprocedure

// *****************************************
// *********** Screenshot Field

&atclient
procedure ScreenshotClick ( Item, StandardProcessing )
	
	StandardProcessing = false;
	showPicture ();
	
endprocedure

&atclient
procedure showPicture ()
	
	if ( Screenshot = "" ) then
		return;
	endif; 
	p = new Structure ();
	p.Insert ( "Title", Scenario );
	p.Insert ( "URL", Screenshot );
	OpenForm ( "CommonForm.Screenshot", p );
	
endprocedure 
