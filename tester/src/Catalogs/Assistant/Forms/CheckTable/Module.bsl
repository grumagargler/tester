&atclient
var TableField;

// *****************************************
// *********** Form events

&atserver
procedure OnCreateAtServer ( Cancel, StandardProcessing )

	init ();
	
endprocedure

&atserver
procedure init ()
	
	Splitter = "|";
	Method = TrimR ( Left ( Parameters.Method, StrFind ( Parameters.Method, "(" ) - 1 ) );
	
endprocedure

&atclient
procedure OnOpen ( Cancel )
	
	try
		fill ();
	except
		raise Output.ErrorObtainingTableParameters ();
	endtry;
	
endprocedure

&atclient
procedure fill ()
	
	With ( Parameters.Form );
	field = Type ( "TestedFormField" );
	TableField = Get ( Parameters.Table );
	for each column in TableField.FindObjects () do
		if ( TypeOf ( column ) <> field ) then
			continue;
		endif;
		row = TestingTable.Add ();
		row.Title = column.TitleText;
		name = column.Name;
		row.Name = name;
		try
			Fields.RemoveSeachingTags(TableField.GetCellText ( name ));
			available = true;
		except
			available = false;
		endtry;
		row.Check = available;
	enddo;
	
endprocedure

&atserver
procedure FillCheckProcessingAtServer ( Cancel, CheckedAttributes )
	
	if ( not checkColumns () ) then
		Cancel = true;
	endif;
	
endprocedure

&atserver
function checkColumns ()
	
	for each row in TestingTable do
		if ( row.Check ) then
			return true;
		endif;
	enddo;
	Output.ColumnsNotSelected ();
	return false;
	
endfunction

// *****************************************
// *********** TestingTable

&atclient
procedure OK ( Command )
	
	if ( not CheckFilling () ) then
		return;
	endif;
	Close ( TableProcessor.CheckingScript ( Method, TableField, selectedColumns (), ByNames, Splitter ) );
		
endprocedure

&atclient
function selectedColumns ()
	
	list = new Array ();	
	for each row in TestingTable do
		if ( row.Check ) then
			list.Add ( ? ( ByNames, row.Name, row.Title ) );
		endif;
	enddo;
	return list;
	
endfunction

&atclient
procedure MarkAll ( Command )
	
	checkbox ( true );
	
endprocedure

&atclient
procedure checkbox ( Value )
	
	for each row in TestingTable do
		row.Check = Value;
	enddo; 
	
endprocedure 

&atclient
procedure UnmarkAll ( Command )
	
	checkbox ( false );
	
endprocedure

