
procedure CompareTables ( Table, Standard, Params = undefined, Options = undefined, Debug ) export
	
	this = createContext ( Debug );
	types = This.TableTypes.Standard;
	table1 = readTable ( this, Table, types.Testing, Params, false );
	table2 = readTable ( this, Standard, types.Standard, Params, false );
	compare ( this, table1, table2, Params, Options );

endprocedure

function createContext ( Debug )
	
	this = new Structure ();
	this.Insert ( "Debug", Debug );
	this.Insert ( "TableTypes", new Structure ( "Standard, Testing, Formatting", 1, 2, 3 ) );
	this.Insert ( "Types", new Structure ( "Column, Quote, Escape, EscapeInQuote", 0, 1, 2, 4 ) );
	this.Insert ( "Anchor1", Char ( 1 ) );
	this.Insert ( "Anchor2", Char ( 2 ) );
	this.Insert ( "Anchor3", Char ( 3 ) );
	this.Insert ( "Anchor4", Char ( 4 ) );
	this.Insert ( "Anchor5", Char ( 5 ) );
	separators = new Map ();
	separators.Insert ( "|", " | " );
	separators.Insert ( ",", ", " );
	this.Insert ( "Separators", separators );
	return this;
	
endfunction

function readTable ( This, Table, TableType, Params, Designer )
	
	name = undefined;
	header = undefined;
	format = 0;
	body = new Array ();
	part = 1;
	workingTable = tablePresentation ( This, TableType );
	formatting = TableType = This.TableTypes.Formatting;
	for i = 1 to StrLineCount ( Table ) do
		row = StrGetLine ( Table, i );
		if ( IsBlankString ( row ) ) then
			continue;
		endif;
		if ( part = 3 ) then
			values = ? ( formatting, textToValue ( This, row ).Values, expressionToValue ( This, row ).Values );
			if ( values.Count () <> format ) then
				msg = new Structure ( "Table, Row", workingTable, Format ( i, "NG=" ) );
				error = Output.TableFormatErrorColumns ( msg );
				if ( Designer ) then
					raise error;
				else
					Runtime.ThrowError ( error, This.Debug );
				endif;
			endif;
			body.Add ( values );
		elsif ( part = 2 ) then
			header = readHeader ( This, row, TableType, Params );
			format = header.Values.Count ();
			part = 3;
		else
			name = TrimAll ( row );
			part = 2;
		endif;
	enddo;
	if ( name = undefined ) then
		error = Output.TableFormatErrorName ( new Structure ( "Table", workingTable ) );
		if ( Designer ) then
			raise error;
		else
			Runtime.ThrowError ( error, This.Debug );
		endif;
	endif;
	if ( header = undefined ) then
		error = Output.TableFormatErrorHeader ( new Structure ( "Table", workingTable ) );
		if ( Designer ) then
			raise error;
		else
			Runtime.ThrowError ( error, This.Debug );
		endif;
	endif;
	return createTable ( name, header, body );
	
endfunction

function tablePresentation ( This, Type )

	tableType = This.TableTypes;
	if ( Type = tableType.Standard ) then
		return Output.TableFormatErrorStandard ();
	elsif ( Type = tableType.Testing ) then
		return Output.TableFormatErrorTesting ();
	elsif ( Type = tableType.Formatting ) then
		return Output.TableFormatErrorFormatting ();
	endif;

endfunction

function expressionToValue ( This, Row )
	
	values = new Array ();
	parts = new Array ();
	types = This.Types;
	type = types.Column;
	quote = This.Anchor1;
	separator = undefined;
	for i = 1 to StrLen ( Row ) do
		current = Mid ( Row, i, 1 );
		if ( type = types.Column ) then
			if ( current = "," or current = "|" ) then
				addValues ( This, values, parts );
				if ( separator = undefined ) then
					separator = current; 
				endif;
			elsif ( current = "\" ) then
				type = types.Escape;
			else
				if ( current = "'" ) then
					type = types.Quote;
				endif;
				parts.Add ( current );
			endif;
		elsif ( type = types.Quote ) then
			if ( current = "\" ) then
				type = types.EscapeInQuote;
			else
				if ( current = "'" ) then
					type = types.Column;
				endif;
				parts.Add ( current );
			endif;
		elsif ( type = types.Escape ) then
			if ( StrFind ( ",|\'", current ) ) then
				prefix = "";
			else
				prefix = "\";
			endif;
			parts.Add ( prefix + ? ( current = "'", quote, current ) );
			type = types.Column;
		elsif ( type = types.EscapeInQuote ) then
			if ( current = "\" ) then
				parts.Add ( current );
			else
				parts.Add ( ? ( current = "'", quote, "\" + current ) );
			endif;
			type = types.Quote;
		endif;
	enddo;
	addValues ( This, values, Parts );
	values.Delete ( 0 );
	return new Structure ( "Values, Separator", values, separator );
	
endfunction

procedure addValues ( This, Values, Parts )
	
	s = TrimAll ( StrConcat ( Parts ) );
	if ( Left ( s, 1 ) = "'"
		and Right ( s, 1 ) = "'" ) then
		s = Mid ( s, 2, StrLen ( s ) - 2 );
	endif;
	quote = This.Anchor1;
	Values.Add ( StrReplace ( s, quote, "'" ) );
	Parts.Clear ();
	
endprocedure

function textToValue ( This, Row )
	
	values = new Array ();
	parts = new Array ();
	types = This.Types;
	type = types.Column;
	quote = This.Anchor1;
	separator = undefined;
	for i = 1 to StrLen ( Row ) do
		current = Mid ( Row, i, 1 );
		if ( type = types.Column ) then
			if ( current = "," or current = "|" ) then
				addRawValues ( This, values, parts );
				if ( separator = undefined ) then
					separator = current; 
				endif;
			else
				if ( current = "\" ) then
					type = types.Escape;
				elsif ( current = "'" ) then
					type = types.Quote;
				endif;
				parts.Add ( current );
			endif;
		elsif ( type = types.Quote ) then
			if ( current = "\" ) then
				type = types.EscapeInQuote;
			elsif ( current = "'" ) then
				type = types.Column;
			endif;
			parts.Add ( current );
		elsif ( type = types.Escape ) then
			parts.Add ( ? ( current = "'", quote, current ) );
			type = types.Column;
		elsif ( type = types.EscapeInQuote ) then
			parts.Add ( ? ( current = "'", quote, current ) );
			type = types.Quote;
		endif;
	enddo;
	addRawValues ( This, values, Parts );
	values.Delete ( 0 );
	return new Structure ( "Values, Separator", values, separator );
	
endfunction

procedure addRawValues ( This, Values, Parts )
	
	s = TrimAll ( StrConcat ( Parts ) );
	quote = This.Anchor1;
	Values.Add ( StrReplace ( s, quote, "'" ) );
	Parts.Clear ();
	
endprocedure

function readHeader ( This, Row, TableType, Params )
	
	result = new Structure ( "Values, EvaluatedValues, Separator" );
	tableTypes = This.TableTypes;
	if ( TableType = tableTypes.Formatting ) then
		data = textToValue ( This, Row );
	else
		data = expressionToValue ( This, Row );
		if ( TableType = tableTypes.Standard ) then
			evaluatedValues = new Array ();
			for each value in data.Values do
				evaluatedValues.Add ( applyParams ( This, value, Params ) );
			enddo;
			result.EvaluatedValues = evaluatedValues;
		endif;
	endif;
	result.Values = data.Values;
	result.Separator = ? ( data.Separator = undefined, "|", data.Separator );
	return result;
	
endfunction

function applyParams ( This, Value, Params )
	
	prefix = Left ( Value, 1 );
	if ( prefix = "#"
		or prefix = "!" ) then
		return Value;
	else
		anchor1 = This.Anchor1;
		s = StrReplace ( Value, "\%", anchor1 );
		s = Output.Sformat ( s, Params );
		s = StrReplace ( s, anchor1, "%" );
		s = StrReplace ( s, "\|", "|" );
		s = StrReplace ( s, "\,", "," );
		return s;
	endif;
	
endfunction

function createTable ( Name, Header, Body )
	
	return new Structure ( "Name, Header, Body", Name, Header, Body );
	
endfunction

procedure compare ( This, Table, Standard, Params, Options )
	
	compareHeader ( This, Table, Standard, Params, Options );
	compareBodies ( This, Table, Standard, Params, Options );
	
endprocedure

procedure compareHeader ( This, Table, Standard, Params, Options )
	
	name = Table.Name;
	testedHeader = Table.Header.Titles;
	standardHeader = Standard.Header.EvaluatedValues;
	for i = 0 to standardHeader.UBound () do
		column = standardHeader [ i ];
		if ( testedHeader.Find ( column ) = undefined ) then
			sourceColumn = Standard.Header.Values [ i ];
			msg = new Structure ( "Table, Column", name, columnPresentation ( sourceColumn, column ) );
			Runtime.ThrowError ( Output.TableColumnNotFound ( msg ), This.Debug );
		endif;
	enddo;
	if ( Options = undefined
		or not Options.Strictly ) then
		return;
	endif;
	testedCount = testedHeader.UBound ();
	standardCount = standardHeader.UBound ();
	if ( testedCount = standardCount ) then
		return;
	endif;
	msg = new Structure ( "Table", name );
	if ( testedCount > standardCount ) then
		Runtime.ThrowError ( Output.TableHasManyColumns ( msg ), This.Debug );
	elsif ( testedCount < standardCount ) then
		Runtime.ThrowError ( Output.TableHasFewerColumns ( msg ), This.Debug );
	endif;
	
endprocedure

function columnPresentation ( Column, EvaluatedColumn )
	
	return ? ( Column = EvaluatedColumn, Column, EvaluatedColumn + "(" + Column + ")" );
	
endfunction

procedure compareBodies ( This, Table, Standard, Params, Options )
	
	stardardRows = Standard.Body;
	standardCount = stardardRows.UBound ();
	name = Table.Name;
	testedHeader = Table.Header.Titles;
	standardHeader = Standard.Header.EvaluatedValues;
	strictly = Options <> undefined and Options.Strictly;
	testingRows = getBody ( Table );
	testingColumns = Table.Header.Names;
	testingType = TypeOf ( testingRows );
	iArray = testingType = Type ( "Array" );
	iControl = false;
	iValueTable = false;
	if ( not iArray ) then
		#if ( Server ) then
			iValueTable = testingType = Type ( "ValueTable" );
		#else
			iControl = testingType = Type ( "TestedFormTable" );
		#endif
	endif;
	testedBound = ? ( iArray or iValueTable, testingRows.Count () - 1, 0 );
	if ( iControl ) then
		moving = startIteration ( testingRows );
	endif; 
	for i = 0 to standardCount do
		standardRow = stardardRows [ i ];
		if ( iControl ) then
			if ( moving ) then
				testedRow = fetchCells ( testingRows, testingColumns );
				testedBound = i;
			else
				break;
			endif;
		elsif ( i < testedBound ) then
			row = testingRows [ i ];
			testedRow = ? ( iArray, row, fetchCells ( row, testingColumns ) );
		else
			break;
		endif;
		j = 0;
		for each standardColumn in standardHeader do
			k = ? ( strictly, j, testedHeader.Find ( standardColumn ) );
			testedValue = testedRow [ k ];
			standardValue = standardRow [ j ];
			result = compareValues ( This, testedValue, standardValue, Params );
			if ( not result.Equal ) then
				#if ( Client ) then
					if ( iControl ) then
						try
							Activate ( standardColumn, testingRows );
						except
						endtry;
					endif;
				#endif
				ln = Format ( i + 1, "NG=" );
				sourceColumn = Standard.Header.Values [ j ];
				msg = new Structure ( "Table, Row, Column, Standard, Tested",
					name, ln, columnPresentation ( sourceColumn, standardColumn ), result.EvaluatedValue, testedValue );
				Runtime.ThrowError ( Output.TableValuesDifferent ( msg ), This.Debug );
			endif;
			j = j + 1;
		enddo;
		#if ( Client ) then
			moving = iControl and nextRow ( testingRows );
		#endif
	enddo;
	if ( iControl and moving ) then
		atLeastOneMoreLine = 1;
		testedBound = testedBound + atLeastOneMoreLine;
	endif;
	if ( testedBound <> standardCount ) then
		msg = new Structure ( "Table, TestedRows, StandardRows", name,
			Format ( testedBound + 1, "NG=;NZ=" ), Format ( standardCount + 1, "NG=;NZ=" ) );
		if ( testedBound > standardCount ) then
			if ( iControl ) then
				weDoNotIterateTheWholeTable = "~" ;
				msg.TestedRows = weDoNotIterateTheWholeTable + msg.TestedRows; 
			endif;
			Runtime.ThrowError ( Output.TableHasManyRows ( msg ), This.Debug );
		else
			Runtime.ThrowError ( Output.TableHasFewerRows ( msg ), This.Debug );
		endif;
	endif;
	
endprocedure

function getBody ( TestingTable )
	
	body = TestingTable.Body;
	#if ( Server ) then
		if ( Framework.IsWindows () ) then
			if ( TypeOf ( body ) = Type ( "COMObject" ) ) then
				table = new ValueTable ();
				columns = table.Columns;
				for each bodyColumn in body.Columns do
					columns.Add ( bodyColumn.Name, , bodyColumn.Title );
				enddo;
				for each bodyRow in body do
					row = table.Add ();
					FillPropertyValues ( row, bodyRow );
				enddo;
				return table;
			endif;
		endif;
	#endif	
	return body;
	
endfunction

function compareValues ( This, Tested, Standard, Params )
	
	if ( Left ( Standard, 1 ) = "%" ) then
		id = Mid ( Standard, 2 );
		value = undefined;
		if ( Params.Property ( id, value ) ) then
			return comparisonResult ( TableProcessor.ValuesEqual ( Tested, value ), value );
		endif;
	elsif ( TypeOf ( Tested ) = Type ( "Number" )
		and TableProcessor.ValuesEqual ( Standard, Tested ) ) then
		return comparisonResult ( true, Standard );
	endif;
	value = StrReplace ( Standard, "\%", This.Anchor1 );
	value = Output.Sformat ( value, Params );
	value = StrReplace ( value, This.Anchor1, "%" );
	evaluatedStandard  = value;
	value = StrReplace ( value, "\*", This.Anchor2 );
	value = StrReplace ( value, "\?", This.Anchor3 );
	regular = StrFind ( value, "*" ) > 0 or StrFind ( value, "?" ) > 0;
	if ( regular ) then
		value = StrReplace ( value, "*", This.Anchor4 );
		value = StrReplace ( value, "?", This.Anchor5 );
	endif;
	value = StrReplace ( value, This.Anchor2, "*" );
	value = StrReplace ( value, This.Anchor3, "?" );
	if ( regular ) then
		value = StrReplace ( value, "\", "\\" );
		value = StrReplace ( value, ".", "\." );
		value = StrReplace ( value, "*", "\*" );
		value = StrReplace ( value, "?", "\?" );
		value = StrReplace ( value, This.Anchor4, ".+" );
		value = StrReplace ( value, This.Anchor5, "." );
		return comparisonResult ( Regexp.Test ( Tested, value ), evaluatedStandard );
	else
		return comparisonResult ( Tested = value, evaluatedStandard );
	endif;

endfunction

function ValuesEqual ( Tested, Standard ) export
	
	type = TypeOf ( Standard );
	if ( type = Type ( "Number" ) ) then
		try
			value1 = ? ( Tested = "", 0, Number ( Tested ) );
			value2 = Number ( Standard );
		except
			return false;
		endtry;
		return value1 = value2;
	elsif ( type = Type ( "Date" ) ) then
		try
			value1 = Date ( Tested );
			value2 = Date ( Standard );
		except
			return false;
		endtry;
		return value1 = value2;
	else
		return Tested = Standard;
	endif;
	
endfunction

function comparisonResult ( Equal, EvaluatedValue )
	
	return new Structure ( "Equal, EvaluatedValue", Equal, EvaluatedValue );
	
endfunction

&atclient
procedure CompareFieldAndTable ( Table, Params, Options, Source ) export
	
	this = createContext ( Debug );
	standardTable = readTable ( this, Table, This.TableTypes.Standard, Params, false );
	tableName = standardTable.Name;
	tableField = Fields.GetControl ( tableName, Source ).Field;
	columns = fetchColumns ( tableField, standardTable.Header.EvaluatedValues, Options );
	testingTable = createTable ( tableName, columns, tableField );
	compare ( this, testingTable, standardTable, Params, Options );
	
endprocedure

function fetchColumns ( Control, Header, Options )
	
	names = new Array ();
	titles = new Array ();
	strictly = Options <> undefined and Options.Strictly;
	#if ( Server ) then
		columns = Control.Columns;
	#else
		columns = Control.FindObjects ();
		field = Type ( "TestedFormField" );
	#endif
	for each column in columns do
		#if ( Server ) then
			title = escapedTitle ( column.Title );
		#else
			if ( TypeOf ( column ) <> field ) then
				continue;
			endif;
			title = escapedTitle ( column.TitleText );
		#endif
		name = column.Name;
		id = "#" + name;
		idFound = Header.Find ( id ) <> undefined;
		if ( not idFound ) then
			id = "!" + name;
			idFound = Header.Find ( id ) <> undefined;
		endif;
		if ( idFound
			or strictly
			or Header.Find ( title ) <> undefined ) then
			names.Add ( name );
			titles.Add ( ? ( idFound, id, title ) );
		endif;
	enddo;
	return new Structure ( "Names, Titles", names, titles );
	
endfunction

function escapedTitle ( Title )
	
	prefix = Left ( Title, 1 );
	return ? ( prefix = "#" or prefix = "!", "\", "" ) + Title;
	
endfunction

function startIteration ( Table )

	#if ( Server ) then
		empty = Table.Count () = 0;
	#else
		if ( Table.CurrentModeIsEdit () ) then
			Table.EndEditRow ();
		endif;
		Table.GotoFirstRow ();
		empty = Table.GetSelectedRows ().Count () = 0;
	#endif
	return not empty;

endfunction

&atclient
function CheckingScript ( Method, Table, SelectedColumns, ByNames, Splitter ) export

	this = createContext ( Debug );
	columns = fetchColumns ( Table, SelectedColumns, undefined );
	rows = fetchRows ( this, Table, columns.Names );
	escaped = readValues ( this, SelectedColumns, ByNames );
	text = buildScript ( Method, Table.Name, escaped, rows, this.Separators [ Splitter ], 0 );
	return text;
	
endfunction

&atclient
function readValues ( This, Columns, ByNames )
	
	prefix = ScenarioForm.NamePrefix ( CurrentLanguage () );
	list = new Array ();
	for each column in Columns do
		if ( ByNames ) then
			list.Add ( prefix + column );
		else
			list.Add ( valueToExpression ( This, column, true ) );
		endif;
	enddo;
	return list;
	
endfunction

&atclient
function valueToExpression ( This, Value, IsColumn )

	prefix = Left ( Value, 1 );
	if ( prefix = "" ) then
		return Value;
	endif;
	special = "\%#'";
	wildcart = "*?";
	alwaysEscape = special + ? ( IsColumn, "", wildcart );
	inQuotes = ( prefix = " " ) or ( Right ( Value, 1 ) = " " );
	if ( inQuotes ) then
		return "'" + escapeValue ( Value, alwaysEscape ) + "'";
	else
		splitters = ",|";
		return escapeValue ( Value, alwaysEscape + splitters );
	endif;
	
endfunction

&atclient
function escapeValue ( Value, Escape )
	
	s = Value;
	for i = 1 to StrLen ( Escape ) do
		char = Mid ( Escape, i, 1 );
		s = StrReplace ( s, char, "\" + char );
	enddo;
	s = StrReplace ( s, """", """""" );
	return s;

endfunction

&atclient
function fetchRows ( This, Table, Columns )
	
	rows = new Array ();
	moving = startIteration ( Table );
	while ( moving ) do
		rows.Add ( extractCells ( This, Table, Columns ) );
		moving = nextRow ( Table );
	enddo;
	return rows;
	
endfunction

&atclient
function extractCells ( This, Table, Columns )

	cells = new Array ();
	for each column in Columns do
		try
			value = Fields.RemoveSeachingTags(Table.GetCellText ( column ));
		except
			value = "";
		endtry;
		cells.Add ( valueToExpression ( This, value, false ) );
	enddo;
	return cells;	
	
endfunction

#if ( server ) then

&atserver
function fetchCells ( Row, Columns )

	cells = new Array ();
	for each column in Columns do
		value = Row [ column ];
		cells.Add ( value );
	enddo;
	return cells;
	
endfunction

#endif

#if ( client ) then

&atclient
function fetchCells ( Table, Columns )

	cells = new Array ();
	for each column in Columns do
		try
			value = Fields.RemoveSeachingTags ( Table.GetCellText ( column ) );
		except
			value = "";
		endtry;
		cells.Add ( value );
	enddo;
	return cells;
	
endfunction

#endif

&atclient
function nextRow ( Table )
	
	try
		Table.GotoNextRow ( false );
	except
		return false;
	endtry;
	return true;

endfunction

&atclient
function buildScript ( Method, Name, Columns, Rows, Splitter, Margin )
	
	injectLineNumber ( Columns, Rows );
	body = new Array ();
	body.Add ( ScenarioForm.NamePrefix ( CurrentLanguage () ) + Name );
	parts = new Array ();
	width = columnsWidth ( Columns, Rows );
	for i = 0 to Columns.UBound () do
		column = Columns [ i ];
		parts.Add ( formatValue ( column, width [ i ] ) );
	enddo;
	body.Add ( StrConcat ( parts, Splitter ) );
	for each row in Rows do
		parts.Clear ();
		for i = 0 to row.UBound () do
			cell = row [ i ];
			parts.Add ( formatValue ( cell, width [ i ] ) );
		enddo;
		body.Add ( StrConcat ( parts, Splitter ) );
	enddo;
	body = StrConcat ( body, Chars.LF + "|" );
	script = new Array ();
	script.Add ( Method + " ( """ );
	script.Add ( Chars.LF + "|" );
	script.Add ( body );
	script.Add ( Chars.LF + "|"" );" );
	return StrConcat ( script );
	
endfunction

&atclient
procedure injectLineNumber ( Columns, Rows )
	
	Columns.Insert ( 0, "#" );
	line = 1;
	for each row in Rows do
		row.Insert ( 0, Format ( line, "NG=" ) );
		line = line + 1;
	enddo;
	
endprocedure

&atclient
function columnsWidth ( Columns, Rows )
	
	width = new Array ();
	for i = 0 to Columns.UBound () - 1 do
		column = Columns [ i ];
		max = StrLen ( column ); 
		for each row in Rows do
			len = StrLen ( row [ i ] );
			if ( len > max ) then
				max = len;
			endif;
		enddo;
		width.Add ( placeholder ( max ) );
	enddo;
	width.Add ( "" );
	return width;
	
endfunction

&atclient
function placeholder ( Width )
	
	pad = new Array ();
	for i = 1 to Width do
		pad.Add ( " " );
	enddo;
	return StrConcat ( pad );
	
endfunction

&atclient
function formatValue ( Value, Placeholder )
	
	return Value + Mid ( Placeholder, StrLen ( Value ) + 1 );
	
endfunction

&atserver
procedure CompareVTAndTable ( Debug, VT, Table, Params, Options ) export
	
	this = createContext ( Debug );
	standardTable = readTable ( this, Table, This.TableTypes.Standard, Params, false );
	tableName = standardTable.Name;
	columns = fetchColumns ( VT, standardTable.Header.EvaluatedValues, Options );
	testingTable = createTable ( tableName, columns, VT );
	compare ( this, testingTable, standardTable, Params, Options );
	
endprocedure

&atclient
function Formatting ( Text, Indent ) export
	
	this = createContext ( Debug );
	table = readTable ( this, Text, This.TableTypes.Formatting, undefined, true );
	body = formatBody ( this, table, Indent );
	return body;
	
endfunction

&atclient
function formatBody ( This, Table, Indent )

	body = new Array ();
	margin = ? ( Indent = undefined, "", Indent );
	body.Add ( margin + "|" + Table.Name );
	parts = new Array ();
	separator = This.Separators [ Table.Header.Separator ];
	columns = Table.Header.Values;
	rows = Table.Body;
	injectLineNumber ( Columns, rows );
	width = columnsWidth ( columns, rows );
	for i = 0 to columns.UBound () do
		column = columns [ i ];
		parts.Add ( formatValue ( column, width [ i ] ) );
	enddo;
	body.Add ( StrConcat ( parts, separator ) );
	for each row in rows do
		parts.Clear ();
		for i = 0 to row.UBound () do
			cell = row [ i ];
			parts.Add ( formatValue ( cell, width [ i ] ) );
		enddo;
		body.Add ( StrConcat ( parts, separator ) );
	enddo;
	body = StrConcat ( body, Chars.LF + margin + "|" );
	return body;

endfunction
