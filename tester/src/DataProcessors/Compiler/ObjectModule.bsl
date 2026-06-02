var Scenario export;
var Script export;
var ServerOnly export;
var ClientSyntax;
var ServerSyntax;
var Compiled;
var Program;
var RunSelected;
var Module;
var IsVersion;
var Procedures;
var CurrentRow;
var ProcedureStarts;
var ProcedureEnds;
var Directives;
var Clauses;
var AtDefault;
var AtClient;
var AtServer;
var ParametersLimit;
var ProgressStep;
var ModuleSize;

function Compile() export
	
	init();
	enumerate();
	compileProcedures(Program, false);
	assemble();
	return result();
	
endfunction

procedure init()
	
	Program = new Array();
	Module = DF.Pick(Scenario, "Code");
	IsVersion = ? ( TypeOf(Scenario) = Type("CatalogRef.Versions"), "true", "false" );
	RunSelected = Script <> undefined;
	if (not RunSelected) then
		Script = DF.Pick(Scenario, "Script");
	endif;
	
endprocedure

function extractServerCode(Scope)
	
	boundaries = getBoundaries(Scope);
	if (boundaries = undefined) then
		return undefined;
	endif;
	removeClientCode(Scope, boundaries);
	return StrConcat(Scope, Chars.LF);
	
endfunction

function getBoundaries(Scope)
	
	start = - 1;
	end = - 1;
	edgeFound = false;
	for each row in Procedures do
		if (row.Directive = AtServer) then
			end = row.End;
			if (start = - 1) then
				start = row.Start;
			endif;
			if (not edgeFound) then
				line = row.Start + 1;
				if (line < end) then
					Scope[line] = "goto ~_end;" + Scope[line];
					edgeFound = true;
				endif;
			endif;
		endif;
	enddo;
	if (edgeFound) then
		return new Structure("Start, End", start, end);
	else
		return undefined;
	endif;
	
endfunction

procedure removeClientCode(Scope, Boundaries)
	
	for i = 0 to Boundaries.Start - 2 do
		Scope[i] = "";
	enddo;
	end = Boundaries.End;
	for i = end + 1 to Scope.UBound() do
		Scope[i] = "";
	enddo;
	Scope.Insert(end, "~_end:");
	
endprocedure

procedure fixReturn(Scope, SyntaxOnly)
	
	running = not SyntaxOnly;
	i = 0;
	while (i <= Scope.UBound()) do
		row = Scope[i];
		pattern = "((^\s+)|^)(return;|возврат;|return\s+;|возврат\s+;)";
		if (Regexp.Test(row, pattern)) then
			if ( running ) then
				Scope[i] = Regexp.Replace(row, pattern, "$1goto ~_return;");
			else
				Scope[i] = Regexp.Replace(row, pattern, "$1");
			endif;
		else
			pattern = "((^\s+)|^)(return\s+|возврат\s+)";
			if (Regexp.Test(row, pattern)) then
				Scope[i] = Regexp.Replace(row, pattern, "$1functionReturnsValue = true;result = ");
				if (running) then
					returnEnds = findLogicalLineEnd(Scope, i);
					Scope.Insert(returnEnds + 1, "goto ~_return;");
					i = returnEnds + 1;
				endif;
			endif;
		endif;
		i = i + 1;
	enddo;
	
endprocedure

function findLogicalLineEnd(Scope, StartLine)

	state = newLogicalLineState();
	size = Scope.UBound();
	for i = StartLine to size do
		if (IsBlankString(Scope[i])) then
			continue;
		endif;
		state = logicalLineState(Scope, i, state);
		if (state.Ended) then
			return i;
		endif;
	enddo;
	return size;

endfunction

procedure finalize(Scope, SyntaxOnly)
	
	s = "
	|~_return:
	|";
	if ( not ( ServerOnly or SyntaxOnly ) ) then
		s = s + "
		|// Do not use if Client because of bug in 1C eval scope function
		|" + Clauses.IfNotServer + "
		|Debugger.ShowProgress ( Debug, """ + Scenario + """, 100 );
		|if ( StandardProcessing
		|	and СтандартнаяОбработка
		|	and MCPRequestProcessing = undefined ) then
		|	if ( AppData.Connected ) then
		|		CheckErrors ();
		|	endif;
		|	if ( _oldSource <> undefined
		|		and _oldSource <> CurrentSource ) then
		|		With ( _oldSource );
		|		CurrentSource = _oldSource;
		|		ТекущийОбъект = CurrentSource;
		|	endif;
		|endif;
		|" + Clauses.IfEnd;
	endif;
	Scope.Add(s);
	
endprocedure

procedure enumerate()
	
	lastLine = 0;
	checking = false;
	statementOpened = false;
	statement = newLogicalLineState();
	rows = StrSplit(Script, Chars.LF);
	ModuleSize = moduleEnds(rows);
	ProgressStep = 100 / ModuleSize;
	for i = 0 to rows.UBound() do
		row = rows[i];
		line = i + 1;
		if (IsBlankString(row)) then
			continue;
		endif;
		normal = Lower(TrimL(row));
		if (not statementOpened
				and operation(normal)) then
			if (checking) then
				addCheck();
				lastLine = Program.Count();
			else
				checking = true;
			endif;
			debugInfo(line, lastLine);
			statementOpened = true;
			statement = newLogicalLineState();
		endif;
		Program.Add(row);
		if (statementOpened) then
			statement = logicalLineState(rows, i, statement);
			statementOpened = not statement.Ended;
		endif;
	enddo;
	if (checking) then
		addCheck();
	endif;
	
endprocedure

function newLogicalLineState()

	return new Structure("InString, Nesting, Ended", false, 0, false);

endfunction

function logicalLineState(Scope, Line, State)

	row = Scope[Line];
	inString = State.InString;
	nesting = State.Nesting;
	code = "";
	length = StrLen(row);
	i = 1;
	while (i <= length) do
		char = Mid(row, i, 1);
		nextChar = Mid(row, i + 1, 1);
		if (inString) then
			if (char = """") then
				if (nextChar = """") then
					i = i + 1;
				else
					inString = false;
				endif;
			endif;
		else
			if (char = "/" and nextChar = "/") then
				break;
			endif;
			if (char = """") then
				inString = true;
			else
				code = code + char;
				if (char = "("
						or char = "[") then
					nesting = nesting + 1;
				elsif ((char = ")"
						or char = "]")
						and nesting > 0) then
					nesting = nesting - 1;
				endif;
			endif;
		endif;
		i = i + 1;
	enddo;
	normal = Lower(TrimAll(code));
	ended = not logicalLineContinues(Scope, Line, normal, inString, nesting);
	return new Structure("InString, Nesting, Ended", inString, nesting, ended);

endfunction

function logicalLineContinues(Scope, Line, Normal, InString, Nesting)

	if (InString
			or Nesting > 0) then
		return true;
	endif;
	if (not ValueIsFilled(Normal)) then
		return true;
	endif;
	lastChar = Right(Normal, 1);
	if (StrFind(",+-*/\%?.=<>", lastChar) > 0) then
		return true;
	endif;
	if (Normal = "return"
			or Normal = "возврат"
			or Normal = "or"
			or Normal = "and"
			or Normal = "not"
			or Normal = "или"
			or Normal = "и"
			or Normal = "не"
			or StrEndsWith(Normal, " or")
			or StrEndsWith(Normal, " and")
			or StrEndsWith(Normal, " not")
			or StrEndsWith(Normal, " или")
			or StrEndsWith(Normal, " и")
			or StrEndsWith(Normal, " не")) then
		return true;
	endif;
	return nextLineContinues(Scope, Line);

endfunction

function nextLineContinues(Scope, Line)

	for i = Line + 1 to Scope.UBound() do
		row = Scope[i];
		if (IsBlankString(row)) then
			continue;
		endif;
		normal = Lower(TrimL(row));
		if (Lexer.IsComment(normal)) then
			continue;
		endif;
		return continuationRow(normal);
	enddo;
	return false;

endfunction

function moduleEnds(Rows)
	
	count = 0;
	for each row in rows do
		count = count + 1;
		if (endOfModule(row)) then
			return count;
		endif;
	enddo;
	return count;
	
endfunction

function endOfModule(Row)
	
	normal = Lower(TrimL(Row));
	for each item in ProcedureStarts do
		if (StrStartsWith(normal, item.Key)) then
			return true;
		endif;
	enddo;
	for each item in Directives do
		if (StrStartsWith(normal, item.Key)) then
			return true;
		endif;
	enddo;
	return false;
	
endfunction

function operation(Row)
	
	passing = continuationRow(Row)
		or StrStartsWith(Row, "//")
		or StrStartsWith(Row, "&at")
		or StrStartsWith(Row, "&на")
		or StrStartsWith(Row, "#if")
		or StrStartsWith(Row, "#если")
		or StrStartsWith(Row, "процедура ")
		or StrStartsWith(Row, "procedure ")
		or StrStartsWith(Row, "функция ")
		or StrStartsWith(Row, "function ");
	return not passing;

endfunction

function continuationRow(Row)

	return StrStartsWith(Row, "|")
		or StrStartsWith(Row, "(")
		or StrStartsWith(Row, ")")
		or StrStartsWith(Row, "[")
		or StrStartsWith(Row, "]")
		or StrStartsWith(Row, ",")
		or StrStartsWith(Row, "+")
		or StrStartsWith(Row, "-")
		or StrStartsWith(Row, "*")
		or StrStartsWith(Row, "/")
		or StrStartsWith(Row, "\")
		or StrStartsWith(Row, "%")
		or StrStartsWith(Row, "?")
		or StrStartsWith(Row, ".")
		or StrStartsWith(Row, "or ")
		or StrStartsWith(Row, "and ")
		or StrStartsWith(Row, "not ")
		or StrStartsWith(Row, "or(")
		or StrStartsWith(Row, "and(")
		or StrStartsWith(Row, "not(")
		or StrStartsWith(Row, "или ")
		or StrStartsWith(Row, "и ")
		or StrStartsWith(Row, "не ")
		or StrStartsWith(Row, "или(")
		or StrStartsWith(Row, "и(")
		or StrStartsWith(Row, "не(");

endfunction

procedure addCheck()
	
	Program.Add(";Debugger.ErrorCheck ( Debug );");
	
endprocedure

procedure debugInfo(Line, LastLine)
	
	command = hook("""" + Module + """", Line);
	Program.Insert(LastLine, command);
	
endprocedure

function hook(Module, Line)
	
	debugCall = debugger ( Line );
	if ( ServerOnly ) then
		s = ";" + debugCall + ";";
	else
		s = ";if ( Runtime.IsClient () ) then
			|	if ( Debug.DebuggingStopped ) then
			|		raise Output.StopDebugging ();
			|	endif;
			|	while ( true ) do
			|		if ( Debug.Evaluate <> """""""" ) then
			|			try
			|				Debug.EvaluationResult = Eval ( Debug.Evaluate );
			|				Debug.EvaluationError = false;
			|			except
			|				Debug.EvaluationResult = ErrorProcessing.BriefErrorDescription ( ErrorInfo () );
			|				Debug.EvaluationError = true;
			|			endtry;
			|		endif;
			|		if ( " + debugCall + " = Enum.DebuggerEval () ) then
			|			continue;
			|		endif; 
			|		break;
			|	enddo;
			|else
			|	" + debugCall + ";
			|endif;";
	endif;
	return StrReplace(s, Chars.LF, " ");
	
endfunction

function debugger ( Line )

	row = Format(Line, "NG=;NZ=");
	progressing = ?(Line > ModuleSize, "undefined", Format(Round(Line * ProgressStep, 0, RoundMode.Round15as20), "NG=;NZ="));
	return "Debugger.Line ( Chronograph, Debug, """ + Module + """, "
		+ row + ", " + IsVersion + ", """ + Scenario + """, " + progressing + " )";
	
endfunction

procedure compileProcedures(Scope, SyntaxOnly)
	
	extractProcedures(Scope, SyntaxOnly);
	replaceCalls(Scope);
	if (not SyntaxOnly) then
		prepareProcedures();
	endif;
	
endprocedure

procedure extractProcedures(Scope, SyntaxOnly)
	
	details = undefined;
	begin = false;
	directive = AtDefault;
	ifend = Clauses.IfEnd;
	ifClient = Clauses.IfClient;
	ifserver = Clauses.IfServer;
	Procedures = new Array();
	for i = 0 to Scope.UBound() do
		if (not rowDefined(Scope, i)) then
			continue;
		endif;
		if (begin) then
			end = Lexer.DeclarationEnds(ProcedureEnds, CurrentRow);
			if ( end ) then
				details.End = i;
			endif;
		else
			details = procedureBegins(Scope, i, directive);
			if (details <> undefined) then
				begin = true;
				end = false;
				params = details.Params;
				if (SyntaxOnly) then
					if (directive <> AtDefault) then
						Scope[i - 1] = ?(directive = AtServer, ifServer, ifClient);
					endif;
					declareParams(Scope, i, params);
				else
					proceduresScript = details.Script;
				endif;
				Procedures.Add(details);
			endif;
		endif;
		if (begin) then
			if (SyntaxOnly) then
				if (end) then
					Scope[i] = ?(directive = AtDefault, "", ifend);
				endif;
			else
				if (i > params.Line
						and not end) then
					proceduresScript.Add(Scope[i]);
				endif;
				Scope[i] = "";
			endif;
			if (end) then
				directive = AtDefault;
			endif;
		else
			directive = getDirective();
			if (directive <> AtDefault) then
				Scope[i] = "";
			endif;
		endif;
		begin = begin and not end;
	enddo;
	
endprocedure

function rowDefined(Scope, Line)
	
	row = Scope[Line];
	if (IsBlankString(row)) then
		return false;
	endif;
	CurrentRow = TrimAll(Lower(row));
	return true;
	
endfunction

function procedureBegins(Scope, Line, Directive)
	
	descriptor = Lexer.Declaration ( ProcedureStarts, CurrentRow );
	if (descriptor = undefined) then
		return undefined;
	endif;
	name = procName(Scope, Line, descriptor.Len);
	if (name = undefined) then
		return undefined;
	endif;
	params = procParams(Scope, name);
	return new Structure("Name, Function, Params, Script, Directive, Start, End", name, descriptor.Function, params, new Array(), Directive, Line, Line);
	
endfunction

function procName(Scope, Line, NameBegins)
	
	for i = Line to Scope.UBound() do
		normal = Lower(Scope[i]);
		s = TrimAll(Mid(normal, NameBegins));
		if (s = "") then
			i = i + 1;
			NameBegins = 1;
		else
			nameEnds = StrFind(s, "(");
			if (nameEnds = 0) then
				nameEnds = StrLen(s);
			endif;
			name = TrimAll(Left(s, nameEnds - 1));
			return new Structure("Name, Line, End, Len", name, i, nameEnds, StrLen(name));
		endif;
	enddo;
	
endfunction

function procParams(Scope, Name)
	
	list = "";
	started = false;
	finished = false;
	nameEnds = Name.End;
	for i = Name.Line to Scope.UBound() do
		row = Scope[i];
		if (started) then
			paramsStart = 1;
		else
			paramsStart = 1 + StrFind(row, "(", , nameEnds);
			if (paramsStart > 1) then
				started = true;
			else
				nameEnds = 1;
			endif;
		endif;
		paramsEnd = StrFind(row, ")", SearchDirection.FromEnd);
		if (paramsEnd = 0) then
			paramsEnd = StrLen(row);
		else
			finished = true;
		endif;
		if (started) then
			list = list + Mid(row, paramsStart, paramsEnd - paramsStart);
		endif;
		if (finished) then
			params = Conversion.StringToStructure(list, "=", ",");
			if (params.Count() > ParametersLimit) then
				raise Output.ParametersCountError(new Structure("Name, Limit", Name.Name, ParametersLimit));
			endif;
			result = new Structure();
			result.Insert("Line", i);
			result.Insert("Params", params);
			result.Insert("Loader", paramsLoader(params));
			return result;
		endif;
		i = i + 1;
	enddo;
	
endfunction

function paramsLoader(Params)
	
	loader = "";
	counter = 1;
	for each param in Params do
		incomingParam = "_P" + counter;
		value = param.Value;
		defaultValue = ?(ValueIsFilled(value), value, "undefined");
		loader = loader + param.Key + " = ? ( " + incomingParam + " = undefined, " + defaultValue + ", " + incomingParam + ");";
		counter = counter + 1;
	enddo;
	return loader;
	
endfunction

procedure declareParams(Scope, Line, Params)
	
	declaration = "";
	for each param in Params.Params do
		declaration = declaration + param.Key + " = undefined;";
	enddo;
	Scope[Line] = declaration;
	for i = Line + 1 to Params.Line do
		Scope[i] = "";
	enddo;
	
endprocedure

function getDirective()
	
	directive = Directives[CurrentRow];
	return ?(directive = undefined, 0, directive);
	
endfunction

procedure replaceCalls(Scope)
	
	for i = 0 to Scope.UBound() do
		row = Scope[i];
		if (IsBlankString(row)) then
			continue;
		endif;
		for each proc in Procedures do
			name = proc.Name;
			procName = name.Name;
			count = proc.Params.Params.Count();
			if (proc.Directive = AtServer) then
				valve = ?(proc.Function, "RuntimeSrv.DeepFunction", "RuntimeSrv.DeepProcedure");
				caller = valve + " ( this, Chronograph, Debug, _procedures, """ + procName + """" + ?(count = 0, " ", ", ");
			else
				valve = ?(proc.Function, "Runtime.DeepFunction", "Runtime.DeepProcedure");
				caller = valve + " ( this, Chronograph, _procedures, """ + procName + """" + ?(count = 0, " ", ", ");
			endif;
			pattern = "(^| +|\t+|=|\+|-|;|/|\*|\\|\,|%|\(|\))(" + procName + "( +|\t+|)\()";
			if (Regexp.Test(row, pattern)) then
				row = Regexp.Replace(row, pattern, "$1" + caller);
			endif;
		enddo;
		Scope[i] = row;
	enddo;
	
endprocedure

procedure prepareProcedures()
	
	for each proc in Procedures do
		rows = proc.Script;
		rows.Insert(0, proc.Params.Loader);
		replaceCalls(rows);
		fixReturn(rows, false);
		finalizeProcedure(rows);
	enddo;
	
endprocedure

procedure finalizeProcedure(Scope)
	
	Scope.Add("~_return:");
	
endprocedure

procedure assemble()
	
	if (RunSelected) then
		Program.Insert(0, attachEnvironment());
	endif;
	if ( Procedures.Count () > 0 ) then
		Program.Insert(0, getProcedures());
	endif;
	Program.Insert(0, debugger(1));
	fixReturn(Program, false);
	finalize(Program, false);
	Compiled = StrConcat(Program, Chars.LF);
	
endprocedure

function attachEnvironment()
	
	s = "
		|try
		|	With ();
		|except
		|endtry;
		|";
	return s;
	
endfunction

function getProcedures()
	
	enter = Chars.LF;
	splitter = enter + "|";
	list = new Array();
	for each proc in Procedures do
		code = StrConcat(proc.Script, splitter);
		s = "_procedures [ """ + proc.Name.Name + """ ] = """ + StrReplace(code, """", """""") + """;";
		list.Add(s);
	enddo;
	return StrConcat(list, enter);
	
endfunction

function result()
	
	p = new Structure("Compiled");
	p.Compiled = Compiled;
	return p;
	
endfunction

function SyntaxCode() export
	
	rows = StrSplit(Script, Chars.LF);
	compileProcedures(rows, true);
	fixReturn(rows, true);
	finalize(rows, true);
	composeClient(rows);
	composeServer(rows);
	return new Structure("Client, Server", ClientSyntax, ServerSyntax);
	
endfunction

procedure composeClient(Scope)
	
	clientCode = "if ( false ) then " + StrConcat(Scope, Chars.LF) + Chars.LF + "endif;";
	ClientSyntax = StrReplace(clientCode, Clauses.IfClient, Clauses.IfNotServer);
	
endprocedure

procedure composeServer(Scope)
	
	serverCode = extractServerCode(Scope);
	if (serverCode = undefined) then
		return;
	endif;
	ServerSyntax = StrReplace(serverCode, Clauses.IfServer, Clauses.IfNotClient);
	
endprocedure

// *****************************************
// *********** Variables Initialization

Lexer.ProcedureDescriptors ( ProcedureStarts, ProcedureEnds );

AtDefault = 0;
AtClient = 1;
AtServer = 2;

Directives = new Map();
Directives["&atclient"] = AtClient;
Directives["&наклиенте"] = AtClient;
Directives["&atserver"] = AtServer;
Directives["&насервере"] = AtServer;

Clauses = new Structure();
Clauses.Insert("IfServer", "#if ( Server ) then");
Clauses.Insert("IfClient", "#if ( ThinClient or ThickClientManagedApplication ) then");
Clauses.Insert("IfNotServer", "#if ( not Server ) then");
Clauses.Insert("IfNotClient", "#if ( not Client ) then");
Clauses.Insert("IfEnd", "#endif");

ParametersLimit = 20;
