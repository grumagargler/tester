var DebuggerStack;
var ProcedureStarts;
var ProcedureEnds;
var RegionStarts;
var RegionEnds;
var Script;
var Deep;
var Floor;
var Entry;
var CurrentLine;

function Compose ( Debug, Error, Picture ) export
	
	DebuggerStack = RuntimeSrv.Stack ( Debug );
	Date = CurrentSessionDate ();
	Scenario = DebuggerStack.Scenario;
	msg = completeError ( DebuggerStack, Error );
	Description = msg.Short;
	FullText = msg.Long;
	Session = SessionParameters.Session;
	Line = DebuggerStack.Line;
	User = SessionParameters.User;
	data = RuntimeSrv.GetSource ( Scenario );
	Source = data.Scenario;
	Application = data.Application;
	if ( Picture <> undefined ) then
		Screenshot = new ValueStorage ( Picture );
		ScreenshotExists = true;
	endif; 
	jobData = Debug.Job;
	RuntimeSrv.AssignJob ( ThisObject, jobData );
	loadStack ();
	loadApplicationStack ( Debug );
	loadModule ();
	Write ();
	RuntimeSrv.WriteError ( data, Scenario, Date, Ref, Debug.Level, jobData );
	return Ref;
	
endfunction

function completeError ( Stack, Error )
	
	p = new Structure ();
	p.Insert ( "Message", Error );
	p.Insert ( "Line", stack.Line );
	p.Insert ( "Stack", stack.Source );
	prefix = Output.RuntimeMessagePrefix ( p );
	body = Output.RuntimeMessage ( p );
	long = prefix + body;
	//@skip-warning
	max = Metadata.Catalogs.ErrorLog.StandardAttributes.Description.Type.StringQualifiers.Length;
	tooLong = StrLen ( long ) > max;
	if ( tooLong ) then
		cutPrefix = Output.RuntimeMessageCutPrefix ();
		rest = max - StrLen ( prefix ) - StrLen ( cutPrefix );
		short = prefix + cutPrefix + Right ( long, rest );
	else
		short = long;
	endif;
	return new Structure ( "Long, Short", long, short );
	
endfunction 

procedure loadStack ()
	
	firstArea = undefined;
	for each call in DebuggerStack.Calls do
		newRow = Stack.Insert ( 0 );
		newRow.Row = call.Row;
		newRow.Scenario = call.Scenario;
		fall = findArea ( call );
		newRow.Area = fall;
		if ( firstArea = undefined
			and fall <> undefined ) then
			firstArea = fall;
		endif;
	enddo; 
	Area = fall;
	
endprocedure

function findArea ( Call )
	
	Script = CachedCalls.DF_Pick ( Call.Scenario, "Script" );
	CurrentLine = Call.Row;
	while ( CurrentLine > 1 ) do
		CurrentLine = CurrentLine - 1;
		span = StrGetLine ( Script, CurrentLine );
		fall = Lexer.AreaComment ( span );
		if ( fall = undefined ) then
			fall = Lexer.DeclarationName ( span );
		endif;
		if ( fall <> undefined ) then
			return getArea ( fall );
		endif;
	enddo;
	
endfunction

function getArea ( Fall )
	
	item = Catalogs.Areas.FindByDescription ( Fall, true );
	if ( item.IsEmpty () ) then
		obj = Catalogs.Areas.CreateItem ();
		obj.Description = Fall;
		obj.Write ();
		item = obj.Ref;
	endif;
	return item;
	
endfunction

procedure loadApplicationStack ( Debug )
	
	erorrs = Debug.ApplicationStack;
	if ( erorrs = undefined ) then
		return;
	endif;
	for each item in StrSplit ( erorrs, Chars.LF ) do
		if ( StrFind ( item, ".Tester." ) > 0 ) then
			continue;
		endif;
		record = ApplicationStack.Add ();
		record.Row = item;
	enddo;
	ApplicationError = ApplicationStack.Count () > 0;
	
endprocedure

procedure loadModule ()
	
	Deep = Stack.Count ();
	Floor = 0;
	while ( Deep > 0 ) do
		Deep = Deep - 1;
		Floor = Floor + 1;
		Entry = Stack [ Deep ];
		Script = CachedCalls.DF_Pick ( Entry.Scenario, "Script" );
		for CurrentLine = contextBegins () to Entry.Row do
			loadScript ();
		enddo;
	enddo;
	
endprocedure

function contextBegins ()
	
	insideProcedure = Floor > 1
	and Stack [ Deep ].Scenario = Stack [ Deep + 1 ].Scenario;
	if ( insideProcedure ) then
		begin = Entry.Row;
		while ( begin > 1 ) do
			begin = begin - 1;
			if ( imProcedure ( begin ) ) then
				return begin;
			endif;
		enddo;
	endif;
	return 1;
	
endfunction

function imProcedure ( LineNumber )
	
	normal = TrimL ( Lower ( StrGetLine ( Script, LineNumber ) ) );
	return Lexer.Declaration ( procedureStarts, normal ) <> undefined;
	
endfunction

procedure loadScript ()
	
	newRow = Module.Add ();
	newRow.Level = Floor;
	stackScenario = Entry.Scenario;
	newRow.Scenario = stackScenario;
	newRow.Line = CurrentLine;
	span = StrGetLine ( Script, CurrentLine );
	if ( CurrentLine = Entry.Row ) then
		newRow.Type = Enums.Module.Error;
		indent = Left ( span, StrFind ( span, TrimL ( span ) ) - 1 );
		if ( Deep = 0 ) then
			newRow.Row = span + Chars.LF + indent + FullText;
		else
			newRow.Row = span;
			newRow = Module.Add ();
			newRow.Level = Floor;
			newRow.Line = CurrentLine;
			calling = Stack [ Deep - 1 ].Scenario;
			newRow.Row = indent + calling;
			newRow.Scenario = stackScenario;
			newRow.Type = Enums.Module.Valve;
			newRow.Calling = calling;
		endif;
	else
		newRow.Row = span;
		normal = TrimL ( Lower ( span ) );
		if ( Lexer.IsComment ( normal ) ) then
			newRow.Type = Enums.Module.Comment;
		elsif ( Lexer.Declaration ( procedureStarts, normal ) <> undefined ) then
			newRow.Type = Enums.Module.Procedure;
		elsif ( Lexer.DeclarationEnds ( procedureEnds, normal ) ) then
			newRow.Type = Enums.Module.EndProcedure;
		elsif ( Lexer.Declaration ( regionStarts, normal ) <> undefined ) then
			newRow.Type = Enums.Module.Region;
		elsif ( Lexer.DeclarationEnds ( regionEnds, normal ) ) then
			newRow.Type = Enums.Module.EndRegion;
		endif;
	endif;
	
endprocedure

// *****************************************
// *********** Variables Initialization

Lexer.ProcedureDescriptors ( ProcedureStarts, ProcedureEnds );
Lexer.RegionDescriptors ( RegionStarts, RegionEnds );
