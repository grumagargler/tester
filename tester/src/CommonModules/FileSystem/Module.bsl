
&atserver
function SpreadsheetType ( TableType ) export
	
	if ( TableType = Enums.TableTypes.PDF ) then
		return SpreadsheetDocumentFileType.PDF;
	elsif ( TableType = Enums.TableTypes.XLS ) then
		return SpreadsheetDocumentFileType.XLS;
	elsif ( TableType = Enums.TableTypes.XLSX ) then
		return SpreadsheetDocumentFileType.XLSX;
	elsif ( TableType = Enums.TableTypes.DOCX ) then
		return SpreadsheetDocumentFileType.DOCX;
	elsif ( TableType = Enums.TableTypes.ODS ) then
		return SpreadsheetDocumentFileType.ODS;
	elsif ( TableType = Enums.TableTypes.MXL ) then
		return SpreadsheetDocumentFileType.MXL;
	endif; 
	
endfunction 

&atserver
function TableExtension ( TableType ) export
	
	if ( TableType = Enums.TableTypes.DOCX ) then
		return "docx";
	elsif ( TableType = Enums.TableTypes.PDF ) then
		return "pdf";
	elsif ( TableType = Enums.TableTypes.XLS ) then
		return "xls";
	elsif ( TableType = Enums.TableTypes.XLSX ) then
		return "xlsx";
	elsif ( TableType = Enums.TableTypes.MXL ) then
		return "mxl";
	elsif ( TableType = Enums.TableTypes.ODS ) then
		return "ods";
	endif; 
	
endfunction 

function GetBaseName ( File ) export

	dot = StrFind ( File, ".", SearchDirection.FromEnd );
	return ? ( dot = 0, File, Mid ( File, 1, dot - 1 ) );

endfunction

function Extension ( File ) export

	separator = StrFind ( File, GetPathSeparator (), SearchDirection.FromEnd );
	dot = StrFind ( File, ".", SearchDirection.FromEnd );
	return ? ( dot > separator, Lower ( Mid ( File, dot ) ), "" );

endfunction

&atclient
function RemoveSlash ( Path ) export
	
	s = TrimAll ( Path );
	while ( StrEndsWith ( s, GetPathSeparator () ) ) do
		s = Left ( s, StrLen ( s ) - 1 );
	enddo; 
	return s;
	
endfunction

function GetParent ( Folder ) export
	
	// Do not use GetPathSeparator () bacause we do not know from where files come
	dot = StrFind ( Folder, "/", SearchDirection.FromEnd );
	if ( dot = 0 ) then
		dot = StrFind ( Folder, "\", SearchDirection.FromEnd );
	endif; 
	return ? ( dot = 0, undefined, Left ( Folder, dot - 1 ) );

endfunction

function GetFileName ( Path ) export

	a = StrFind ( Path, "\", SearchDirection.FromEnd );
	if ( a = 0 ) then
		a = StrFind ( Path, "/", SearchDirection.FromEnd );
	endif;
	return ? ( a = 0, Path, Mid ( Path, a + 1 ) );
	
endfunction
