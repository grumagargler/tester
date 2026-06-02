&atserver
procedure ProcedureDescriptors ( Start, End ) export
	
	Start = new Map ();
	Start [ "процедура" ] = new Structure ( "Len, Function", 10, false );
	Start [ "procedure" ] = new Structure ( "Len, Function", 10, false );
	Start [ "функция" ] = new Structure ( "Len, Function", 8, true );
	Start [ "function" ] = new Structure ( "Len, Function", 9, true );
	End = new Array ();
	End.Add ( "конецпроцедуры" );
	End.Add ( "endprocedure" );
	End.Add ( "конецфункции" );
	End.Add ( "endfunction" );
	
endprocedure

&atserver
procedure RegionDescriptors ( Start, End ) export
	
	Start = new Map ();
	Start [ "#область" ] = new Structure ( "Len", 9 );
	Start [ "#region" ] = new Structure ( "Len", 8 );
	End = new Array ();
	End.Add ( "#конецобласти" );
	End.Add ( "#endregion" );
	
endprocedure

&atserver
function Declaration ( Descriptors, NormalRow ) export
	
	for each item in Descriptors do
		if ( StrStartsWith ( NormalRow, item.Key ) ) then
			descriptor = item.Value;
			next = Mid ( NormalRow, descriptor.Len, 1 );
			if ( not ValueIsFilled ( next ) ) then
				return descriptor;
			endif;
		endif;
	enddo;
	
endfunction

&atserver
function DeclarationEnds ( Descriptors, NormalRow ) export
	
	for each item in Descriptors do
		pattern = item + "($|\t| |\n)";
		if ( Regexp.Test ( NormalRow, pattern ) ) then
			return true;
		endif;
	enddo;
	return false;
	
endfunction

function IsComment ( NormalRow ) export
	
	return StrStartsWith ( NormalRow, "//" );
	
endfunction

&atserver
function AreaComment ( Row ) export
	
	pattern = "^\s*//\s*(!|#)\s*(.+)"; // #MyArea
	matches = Regexp.Select ( Row, pattern );
	if ( matches.Count () = 0 ) then
		return undefined;
	else
		return matches [ 0 ].Groups [ 1 ];
	endif; 
	
endfunction

&atserver
function DeclarationName ( Row ) export
	
	pattern = "^\s*(процедура|функция|#область|procedure|function|#region)\s+([a-z,_,A-Z,а-я,А-Я,0-9]+)";
	matches = Regexp.Select ( Row, pattern );
	if ( matches.Count () = 0 ) then
		return undefined;
	else
		return matches [ 0 ].Groups [ 1 ];
	endif; 
	
endfunction
