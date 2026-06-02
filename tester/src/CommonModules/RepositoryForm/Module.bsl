&atclient
procedure SetFocus ( Form ) export
	
	items = Form.Items;
	object = Form.Object;
	for each row in object.Repositories do
		if ( row.Use ) then
			items.Repositories.CurrentRow = row.GetID ();
			return;
		endif; 
	enddo; 
	
endprocedure 

&atserver
function CheckSelection ( Object ) export
	
	found = Object.Repositories.FindRows ( new Structure ( "Use", true ) );
	if ( found.Count () = 0 ) then
		Output.RepositoryNotSelected ( , "Repositories" );
		return false;
	endif; 
	return true;

endfunction 

&atserver
function CheckFolders ( Object ) export
	
	error = false;
	msg = new Structure ();
	msg.Insert ( "Field", Metadata.DataProcessors.Load.TabularSections.Repositories.Attributes.Folder.Presentation () );
	for each row in Object.Repositories do
		if ( row.Use
			and row.Folder = "" ) then
			Output.FieldIsEmpty ( msg, Output.Row ( "Repositories", row.LineNumber, "Folder" ) );
			error = true;
		endif; 
	enddo; 
	return not error;
	
endfunction 

&atclient
procedure ChooseFolder ( Form ) export
	
	dialog = new FileDialog ( FileDialogMode.ChooseDirectory );
	dialog.Show ( new NotifyDescription ( "SelectFolder", ThisObject, Form ) );
	
endprocedure 

&atclient
procedure SelectFolder ( Folder, Form ) export
	
	if ( Folder = undefined ) then
		return;
	endif; 
	Form.TableRow.Folder = Folder [ 0 ];
	Form.TableRow.Use = true;
	
endprocedure 

&atclient
procedure ApplyFolder ( Form ) export
	
	adjustPath ( Form );
	markUsage ( Form );
	
endprocedure 

&atclient
procedure adjustPath ( Form )
	
	row = Form.TableRow;
	row.Folder = FileSystem.RemoveSlash ( row.Folder );
	
endprocedure 

&atclient
procedure markUsage ( Form )
	
	row = Form.TableRow;
	row.Use = row.Folder <> "";
	
endprocedure 
