
procedure Prepare ( Callback = undefined ) export
	
	BeginAttachingFileSystemExtension ( new NotifyDescription ( "AttachingFileSystemExtension", ThisObject, Callback ) );
	
endprocedure 

procedure AttachingFileSystemExtension ( Connected, Callback ) export
	
	if ( Connected ) then
		if ( Callback <> undefined ) then
			ExecuteNotifyProcessing ( Callback );
		endif; 
	else
		BeginInstallFileSystemExtension ( new NotifyDescription ( "InstallingFileSystemExtension", ThisObject, Callback ) );
	endif; 
	
endprocedure 

procedure InstallingFileSystemExtension ( Callback ) export
	
	Prepare ( Callback );
	
endprocedure 

procedure SetDocumentsFolder ( Callback = undefined ) export
	
	p = new NotifyDescription ( "StartSetDocumentsFolder", ThisObject, Callback );
	LocalFiles.Prepare ( p );

endprocedure

procedure StartSetDocumentsFolder ( Result, Callback ) export
	
	BeginGettingDocumentsDir ( new NotifyDescription ( "GettingDocumentsFilesDir", ThisObject, Callback ) );
	
endprocedure 

procedure GettingDocumentsFilesDir ( Result, Callback ) export
	
	UserDocumentsFolder = Result;
	if ( Callback <> undefined ) then
		ExecuteNotifyProcessing ( Callback );
	endif; 
	
endprocedure 

procedure CheckExistence ( Path, Callback ) export
	
	p = new Structure ( "Path, Callback", Path, Callback );
	bridge = new NotifyDescription ( "StartCheckExistence", ThisObject, p );
	LocalFiles.Prepare ( bridge );
	
endprocedure 

procedure StartCheckExistence ( Result, Params ) export
	
	file = new File ( Params.Path );
	file.BeginCheckingExistence ( Params.Callback );
	
endprocedure 

procedure CreateFolder ( Folder, Callback = undefined ) export
	
	p = new Structure ( "Folder, Callback", Folder, Callback );
	bridge = new NotifyDescription ( "FolderExists", ThisObject, p );
	LocalFiles.CheckExistence ( Folder, bridge );
	
endprocedure 

procedure FolderExists ( Exists, Params ) export
	
	if ( Exists ) then
		if ( Params.Callback <> undefined ) then
			ExecuteNotifyProcessing ( Params.Callback, true );
		endif;
	else
		bridge = new NotifyDescription ( "BeginCreatingFolder", ThisObject, Params.Callback );
		BeginCreatingDirectory ( bridge, Params.Folder );
	endif; 
	
endprocedure 

procedure BeginCreatingFolder ( Result, Callback ) export
	
	if ( Callback <> undefined ) then
		ExecuteNotifyProcessing ( Callback, Result <> undefined );
	endif;
	
endprocedure 

procedure Modification ( Path, Callback ) export
	
	p = new Structure ( "Path, Callback", Path, Callback );
	bridge = new NotifyDescription ( "StartModification", ThisObject, p );
	LocalFiles.CheckExistence ( Path, bridge );
	
endprocedure 

procedure StartModification ( Exists, Params ) export
	
	if ( Exists ) then
		file = new File ( Params.Path );
		file.BeginGettingModificationTime ( Params.Callback );
	else
		ExecuteNotifyProcessing ( Params.Callback, undefined );
	endif; 
	
endprocedure 

procedure Rename ( Path, NewPath, Callback ) export
	
	p = new Structure ( "Path, NewPath, Callback", Path, NewPath, Callback );
	bridge = new NotifyDescription ( "StartRenaming", ThisObject, p );
	LocalFiles.Prepare ( bridge );
	
endprocedure 

procedure StartRenaming ( Result, Params ) export
	
	BeginMovingFile ( Params.Callback, Params.Path, Params.NewPath );
	
endprocedure 
