
&atserver
procedure Sort ( A ) export
	
	list = new ValueList ();
	list.LoadValues ( A );
	list.SortByValue ();
	A = list.UnloadValues ();
	
endprocedure 

procedure Group ( A ) export

	groupped = new Array ();
	for each item in A do
		if ( groupped.Find ( item ) = undefined ) then
			groupped.Add ( item );
		endif; 
	enddo; 
	A = groupped;
	
endprocedure

&atserver
function Serialize ( Table ) export
	
	result = new Structure ();
	colums = new Array ();
	for each column in Table.Columns do
		result.Insert ( column.Name, new Array () );
		colums.Add ( column.Name );
	enddo; 
	for each row in Table do
		for each column in colums do
			result [ column ].Add ( row [ column ] );
		enddo; 
	enddo; 
	result.Insert ( "_Ubound", Table.Count () - 1 );
	result.Insert ( "_Columns", colums );
	return result;
	
endfunction

&atclient
function DeserializeTable ( SerializedTable ) export
	
	result = new Array ();
	a = SerializedTable._Columns;
	columns = StrConcat ( a, "," );
	row = new Structure ( columns );
	for i = 0 to SerializedTable._Ubound do
		resultRow = new Structure ( columns );
		deserializeTableRow ( row, SerializedTable, i );
		FillPropertyValues ( resultRow, row );
		result.Add ( resultRow );
	enddo; 
	return result;
	
endfunction

&atclient
procedure deserializeTableRow ( Row, SerializedTable, Index ) export
	
	for each column in SerializedTable._Columns do
		Row [ column ] = SerializedTable [ column ] [ Index ];
	enddo; 
	
endprocedure 

&atserver
procedure Join ( Table1, Table2 ) export
	
	if ( TypeOf ( Table1 ) = Type ( "ValueTable" ) ) then
		if ( Table1.Columns.Count () = 0 ) then
			Table1 = Table2.CopyColumns ();
		endif;
	endif; 
	for each row in Table2 do
		newRow = Table1.Add ();
		FillPropertyValues ( newRow, row );
	enddo; 
	
endprocedure

&atclient
function CopyStructure ( Struct ) export

	newStructure = new Structure ();
	for each item in Struct do
		newStructure.Insert ( item.Key, item.Value );
	enddo; 
	return newStructure;
		
endfunction 
