function ValueToString ( Value ) export
	
	return ? ( ValueIsFilled ( Value ), String ( Value ), "<...>" );

endfunction

function ValuesToString ( Value1 = undefined, Value2 = undefined, Value3 = undefined ) export
	
	s = "";
	if ( ValueIsFilled ( Value1 ) ) then
		s = s + ", " + String ( Value1 );
	endif;
	if ( ValueIsFilled ( Value2 ) ) then
		s = s + ", " + String ( Value2 );
	endif;
	if ( ValueIsFilled ( Value3 ) ) then
		s = s + ", " + String ( Value3 );
	endif;
	return Mid ( s, 3 );

endfunction
 
function DateToString ( D, StringFormat = "DLF=D; DE=..." ) export

	return Format ( D, StringFormat );

endfunction

function StringToArray ( String, Separator = "," ) export
	
	a = StrSplit ( String, Separator, false );
	j = a.UBound ();
	for i = 0 to j do
		a [ i ] = TrimAll ( a [ i ] );
	enddo; 
	return a;
	
endfunction

function findMinPos ( Str, CharsFind )
	
	minPosResult = 0;
	findCharsLen = StrLen ( CharsFind );
	// Find equal pos
	if ( findCharsLen = 1 ) then
		minPosResult = Find ( Str, CharsFind );
	else
		for i = 1 To findCharsLen do
			equalPosCur = Find ( Str, Mid ( CharsFind, i, 1 ) );
			if ( minPosResult = 0 ) or ( ( equalPosCur < minPosResult ) and ( equalPosCur <> 0 ) ) then
				minPosResult = equalPosCur;
			endif;
		enddo;
	endif;	
	return minPosResult;
	
endfunction

function StringToStructure ( StringValue, EqualChars = "=:", SplitteChars = ",;" ) export
	
	resultSructure = new Structure;
	templateStr = StringValue;	
	while ( not IsBlankString ( templateStr ) ) do
		equalPos = findMinPos ( templateStr, EqualChars );
		splitePos = findMinPos ( templateStr, SplitteChars );
		equalPos = ? ( ( equalPos > splitePos ) and splitePos, 0, equalPos ); // "a;b=0"
		if ( equalPos = 0 ) and ( splitePos = 0 ) then // "a"
			keyStructure = templateStr;
			valueStructure = "";
			templateStr = "";
		elsif ( equalPos = 0 ) or ( splitePos = 0 ) then // "a;..." or "a=0"
			keyStructure = Left ( templateStr, max ( equalPos, splitePos ) - 1 );
			valueStructure = ? ( equalPos = 0, "", Mid ( templateStr, equalPos + 1 ) );
			templateStr = ? ( splitePos = 0, "", Mid ( templateStr, splitePos + 1 ) );
		else // "a=0;..."
			keyStructure = Left ( templateStr, min ( equalPos, splitePos ) - 1 );
			valueStructure = Mid ( templateStr, equalPos + 1, splitePos - equalPos - 1 );
			templateStr = Mid ( templateStr, splitePos + 1 );
		endif;
		if ( IsBlankString ( keyStructure ) ) then
			continue;
		endif; 
		resultSructure.Insert ( StrReplace ( keyStructure, " ", "" ), valueStructure );
	enddo;
	return resultSructure;
	
endfunction

&atclient
function NameToCode ( Name, Len ) export
	
	s = Upper ( TrimAll ( StrReplace ( Name, " ", "" ) ) );
	nameLen = StrLen ( s );
	if ( nameLen < Len ) then
		return flushString ( s, Len - nameLen );
	endif; 
	code = Mid ( s, 2 );
	vowels = "EYUIOAЙУЕЫАОЯИЁЭЬЪЮ.-@#&* ";
	for i = 1 to 25 do // StrLen ( vowels );
		code = StrReplace ( code, Mid ( vowels, i, 1 ), "" );
	enddo; 
	code = Left ( Left ( s, 1 ) + code, Len );
	codeLen = StrLen ( code );
	return ? ( codeLen < Len, Left ( s, Len ), code );
	
endfunction 

&atclient
function flushString ( String, Count, Symbol = "0" )
	
	a = new Array ();
	for i = 1 to Count do
		a.Add ( Symbol );
	enddo; 
	return String + StrConcat ( a );
	
endfunction 

#if ( server or thinclient or thickclientmanagedapplication ) then
	
function FromJSON ( JSON ) export
	
	reader = new JSONReader ();
	reader.SetString ( JSON );
	return ReadJSON ( reader );
		
endfunction 

function ToJSON ( Object, Formatted = true ) export
	
	js = new JSONWriter ();
	if ( Formatted ) then
		settings = new JSONWriterSettings ( JSONLineBreak.Unix, Chars.Tab );
	else
		settings = new JSONWriterSettings ( JSONLineBreak.None );
	endif;
	js.SetString ( settings );
	WriteJSON ( js, Object, , "JSONValueToString", Conversion );
	return js.Close ();
	
endfunction 

function JSONValueToString ( Name, Value, Params, Cancel ) export 
	
	return String ( Value );
	
endfunction
	
function JSONToObject ( JSON, Type = undefined ) export
	
	reader = new JSONReader ();
	reader.SetString ( JSON );
	return XDTOSerializer.ReadJSON ( reader, Type );
		
endfunction 

function ObjectToJSON ( Value, Explicit = false ) export
	
	writer = new JSONWriter ();
	writer.SetString ( new JSONWriterSettings ( JSONLineBreak.None ) );
	XDTOSerializer.WriteJSON ( writer, Value, ? ( Explicit, XMLTypeAssignment.Explicit, XMLTypeAssignment.Implicit ) );
	return writer.Close ();
	
endfunction 

#endif

&atserver
function RowToStructure ( Table ) export
	
	row = ? ( Table.Count () = 0, undefined, Table [ 0 ] );
	result = new Structure ();
	columns = Table.Columns;
	if ( row = undefined ) then
		for each column in columns do
			result.Insert ( column.Name );
		enddo; 
	else
		for each column in columns do
			result.Insert ( column.Name, row [ column.Name ] );
		enddo; 
	endif; 
	return result;
	
endfunction 

&atserver
function StringToHash ( Str ) export
	
	hash = new DataHashing ( HashFunction.SHA256 );
	hash.Append ( Str );
	return StrReplace ( String ( hash.HashSum ), " ", "" );
	
endfunction 

&atserver
function XMLToStandard ( val Text ) export
	
	position = FindDisallowedXMLCharacters ( Text );
	while ( position > 0 ) do
		Text = StrReplace ( Text, Mid ( Text, position, 1 ), "" );
		position = FindDisallowedXMLCharacters ( text );
	enddo;
	return Text;
	
endfunction

&atserver
function ToXML ( Object ) export
	
	xml = new XMLWriter ();
	xml.SetString ( "UTF-8" );
	xml.WriteXMLDeclaration ();
	XDTOSerializer.WriteXML ( xml, Object );
	return xml.Close ();
	
endfunction 

&atserver
function FromXML ( XML ) export
	
	reader = new XMLReader ();
	reader.SetString ( XML );
	return XDTOSerializer.ReadXML ( reader );
	
endfunction 

&atserver
function EnumToName ( Item ) export
	
	if ( Item.IsEmpty () ) then
		return undefined;
	endif; 
	meta = Item.Metadata ();
	i = Enums [ meta.Name ].IndexOf ( Item );
	return meta.EnumValues [ i ].Name;
	
endfunction

function Wrap ( Value ) export
	
	return """" + StrReplace ( Value, """", """""" ) + """";

endfunction 

&atclient
function DecToHex ( Number ) export
	
	set = "0123456789ABCDEF"; 
	value = Number; 
	s = ""; 
	while ( value > 0 ) do
		s = Mid ( set, 1 + ( value % 16 ), 1 ) + s; 
		value = Int ( value / 16 );
	enddo;
	return s; 
	
endfunction

&atserver
function ObjectToURL ( Ref ) export
	
	url = Cloud.ApplicationURL ();
	return url + "/#" + GetURL ( Ref );
	
endfunction 

&atserver
function MillisecondsToTime ( Milliseconds ) export
	
	if ( Milliseconds = 0
		or Milliseconds = null ) then
		return "";
	endif; 
	hours = Int ( Milliseconds / 3600000 );
	minutes = Int ( Milliseconds / 60000 );
	seconds = Int ( Milliseconds / 1000 );
	if ( hours > 0 ) then
		return Format ( hours, "NZ=0; NG=0" )
		+ "h " + Format ( minutes - 60 * Int ( minutes / 60 ), "NZ=0" )
		+ "m " + Format ( seconds - 60 * Int ( seconds / 60 ), "ND=2; NZ=00; NLZ=" )
		+ "." + Format ( Milliseconds % 1000, "ND=3; NLZ=" );
	elsif ( minutes > 0 ) then
		return Format ( minutes - 60 * Int ( minutes / 60 ), "NZ=0" )
		+ "m " + Format ( seconds - 60 * Int ( seconds / 60 ), "ND=2; NZ=00; NLZ=" )
		+ "." + Format ( Milliseconds % 1000, "ND=3; NLZ=" );
	else
		return Format ( Milliseconds, "NS=3" );
	endif; 
	
endfunction 

&atserver
function PeriodToDuration ( Start, Finish ) export
	
	if ( Start = 0
		or Finish = 0 ) then
		return "";
	else
		return Conversion.MillisecondsToTime ( Finish - Start );
	endif;
	
endfunction

&atclient
function ParametersToMap ( Parameters ) export
	
	keys = new Array ();
	values = new Array ();
	mustbeKey = false;
	keyStarted = false;
	valueStarted = false;
	quoteStarted = false;
	for i = 1 to StrLen ( Parameters ) do
		c = Mid ( Parameters, i, 1 );
		if ( c = """" ) then
			quoteStarted = not quoteStarted;
			continue;
		endif; 
		if ( not quoteStarted ) then
			if ( c = "-" ) then
				mustbeKey = true;
				valueStarted = false;
				continue;
			elsif ( c = " " ) then
				mustbeKey = false;
				if ( keyStarted ) then
					keyStarted = false;
					valueStarted = true;
					values.Add ( new Array () );
				endif;
				continue;
			endif;
		endif; 
		if ( mustbeKey ) then
			mustbeKey = false;
			keyStarted = true;
			keys.Add ( new Array () );
			keyIndex = keys.UBound ();
		endif;
		if ( keyStarted ) then
			keys [ keyIndex ].Add ( c );
		elsif ( valueStarted ) then
			values [ keyIndex ].Add ( c );
		endif; 
	enddo; 
	result = new Map ();
	for i = 0 to keys.UBound () do
		result [ StrConcat ( keys [ i ] ) ] = StrConcat ( values [ i ] );
	enddo; 
	return result;
	
endfunction 

&atserver
function CodeToNumber ( Number ) export
	
	try
		value = Number ( Number );
	except
		return Number;
	endtry;
	return Format ( value, "NG=" );
	
endfunction
