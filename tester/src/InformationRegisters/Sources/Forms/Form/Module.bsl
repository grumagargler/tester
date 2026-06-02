// *****************************************
// *********** Form events

&atserver
procedure OnCreateAtServer ( Cancel, StandardProcessing )
	
	if ( Record.SourceRecordKey.IsEmpty () ) then
		fillNew ();
	endif;
	
endprocedure

&atserver
procedure fillNew ()
	
	if ( not Parameters.CopyingValue.IsEmpty () ) then
		return;
	endif;
	Record.Session = SessionParameters.Session;
	
endprocedure

&atserver
procedure FillCheckProcessingAtServer ( Cancel, CheckedAttributes )
	
	if ( not checkFolder () ) then
		Cancel = true;
		return;
	endif;
	
endprocedure

&atserver
function checkFolder ()
	
	error = IsBlankString ( Record.Designer ) and IsBlankString ( Record.EDT );
	if ( error ) then
		Output.SourcesFolderError ( , "Designer", , "Record" );
	endif;
	return not error;
	
endfunction

// *****************************************
// *********** Group Form

&atclient
procedure FolderStartChoice ( Item, ChoiceData, StandardProcessing )
	
	StandardProcessing = false;
	chooseFolder ( Item );
	
endprocedure

&atclient
procedure chooseFolder ( Item )
	
	dialog = new FileDialog ( FileDialogMode.ChooseDirectory );
	dialog.Show ( new CallbackDescription ( "selectFolder", ThisObject, Item ) );
	
endprocedure 

&atclient
procedure selectFolder ( Folder, Item ) export
	
	if ( Folder = undefined ) then
		return;
	endif; 
	Record [ Item.Name ] = Folder [ 0 ];
	
endprocedure 

&atclient
procedure FolderOnChange ( Item )
	
	adjustPath ( Item );
	
endprocedure

&atclient
procedure adjustPath ( Item )
	
	Record [ Item.Name ] = FileSystem.RemoveSlash ( Record [ Item.Name ] );
	
endprocedure 
