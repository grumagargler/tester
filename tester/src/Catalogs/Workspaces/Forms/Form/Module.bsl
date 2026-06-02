// *****************************************
// *********** Form events

&atserver
procedure OnCreateAtServer ( Cancel, StandardProcessing )
	
	if ( Object.Ref.IsEmpty () ) then
		initNew ();		
	endif;
	
endprocedure

&atserver
procedure initNew ()
	
	Object.Owner = SessionParameters.User;
	Object.Computer = DF.Pick ( SessionParameters.Session, "Computer" );

endprocedure

&atclient
procedure OnOpen ( Cancel )
	
	LocalFiles.SetDocumentsFolder ();
	
endprocedure

&atserver
procedure BeforeWriteAtServer ( Cancel, CurrentObject, WriteParameters )
	
	groupApplications ( CurrentObject );
	
endprocedure

&atserver
procedure groupApplications ( CurrentObject )
	
	CurrentObject.Applications.GroupBy ( "Application" );
	
endprocedure

&atclient
procedure AfterWrite ( WriteParameters )
	
	if ( not Object.DeletionMark ) then
		WorkspaceForm.Create ( Object.Ref );
	endif;
	
endprocedure

// *****************************************
// *********** Group Form

&atclient
procedure WorkspaceStartChoice ( Item, ChoiceData, StandardProcessing )
	
	StandardProcessing = false;
	chooseFile ();
	
endprocedure

&atclient
procedure chooseFile ()
	
	dialog = new FileDialog ( FileDialogMode.Save );
	dialog.Filter = Output.VSCodeWorkspace ( new Structure ( "Extension", RepositoryFiles.VSCodeWorkspace () ) );
	dialog.Show ( new NotifyDescription ( "SelectFile", ThisObject ) );
	
endprocedure 

&atclient
procedure SelectFile ( File, Params ) export
	
	if ( File = undefined ) then
		return;
	endif;
	Modified = true;
	Object.Workspace = File [ 0 ];
	
endprocedure

// *****************************************
// *********** Applications List

&atclient
procedure ApplicationsOnChange ( Item )
	
	updateFile ();
	
endprocedure

&atclient
procedure updateFile ()
	
	list = new Array ();
	for each row in Object.Applications do
		list.Add ( row.Application );
	enddo;
	fileName = fileName ( list );
	Object.Description = fileName; 
	Object.Workspace = UserDocumentsFolder + fileName + RepositoryFiles.VSCodeWorkspace ();
	
endprocedure

&atservernocontext
function fileName ( val Applications )
	
	s = "select Applications.Code as Code
	|from Catalog.Applications as Applications
	|where Applications.Ref in ( &Applications )
	|order by Applications.Code";
	q = new Query ( s );
	q.SetParameter ( "Applications", Applications );
	return StrConcat ( q.Execute ().Unload ().UnloadColumn ( "Code" ), "-" );
	
endfunction
