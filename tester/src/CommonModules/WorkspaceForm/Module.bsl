procedure Create ( Reference ) export
	
	#if ( ThinClient or ThickClientManagedApplication ) then
		workspace = WorkspaceFormSrv.GetFolders ( Reference );
		folders = new Array ();
		for each folder in Collections.DeserializeTable ( workspace.Folders ) do
			folders.Add ( new Structure ( "name, path", folder.Name, folder.Folder ) );
		enddo;
		exclusion = new Map ();
		exclusion [ "**/*.json" ] = new Structure ( "when", "$(basename)" + RepositoryFiles.BSLFile () );
		exclusion [ "**/.tester" ] = true;
		exclusion [ "**/.gitignore" ] = true;
		exclusion [ "**/.vscode" ] = true;
		exclusion [ "**/" + TesterWatcherBSLServerSettings ] = true;
		settings = new Map ();
		settings [ "files.exclude" ] = exclusion;
		files = "[" + Mid ( RepositoryFiles.BSLFile (), 2 ) + "]";
		fileSettings = new Map ();
		fileSettings [ "editor.formatOnSave" ] = false;
		settings [ files ] = fileSettings; 
		body = new Structure ();
		body.Insert ( "folders", folders );
		body.Insert ( "settings", settings );
		doc = new TextDocument ();
		doc.SetText ( Conversion.ToJSON ( body ) );
		path = workspace.Path;
		doc.BeginWriting ( new NotifyDescription ( "WorkspaceCreated", ThisObject, path ), path, , Chars.LF );
	#endif

endprocedure

procedure WorkspaceCreated ( Result, Path ) export
	
	if ( Result ) then
		Output.WorkspaceCreated ( new Structure ( "Path", Path ) );
	endif;
	
endprocedure

procedure RunStudio ( Reference ) export
	
	#if ( WebClient or MobileClient ) then
		Output.ClientDoesNotSupport ();
	#else
		if ( TypeOf ( Reference ) = Type ( "CatalogRef.Scenarios" ) ) then
			error = "";
			file = RepositoryFiles.ScenarioFile ( Reference, error );
			if ( file = undefined ) then
				Message ( error );
			else
				file = file + RepositoryFiles.BSLFile ();
				RepositoryFiles.Sync ();
				info = WorkspaceFormSrv.ScenarioContext ( Reference );
				params = new Structure ( "Info, File", info, file );
				workspaces = info.Workspaces.Count (); 
				if ( workspaces = 0 ) then
					Output.VSCodeWorkspaceUndefined ( ThisObject, , new Structure ( "Application", applicationName ( info.Application ) ) ); 
				elsif ( workspaces = 1 ) then
					executeStudio ( info.VSCode, info.Workspaces [ 0 ], file )
				else
					askUser ( params ); 
				endif;
			endif;
		else
			data = DF.Values ( Reference, "Workspace, Computer.VSCode as VSCode" );
			executeStudio ( data.VSCode, data.Workspace );
		endif;
	#endif

endprocedure

function applicationName ( Application )
	
	if ( Application = PredefinedValue ( "Catalog.Applications.EmptyRef" ) ) then
		return Output.CommonApplicationName ();
	else
		return Application;
	endif;
	
endfunction

procedure VSCodeWorkspaceUndefined ( Params ) export
	
	OpenForm ( "ExchangePlan.Repositories.ListForm" );
	
endprocedure

procedure askUser ( Params )
	
	list = new ValueList ();
	list.LoadValues ( Params.Info.Workspaces );
	list.ShowChooseItem ( new NotifyDescription ( "WorkspaceSelected", ThisObject, Params ), Output.SelectWorkspace () );
	
endprocedure

procedure WorkspaceSelected ( Workspace, Params ) export
	
	if ( Workspace = undefined ) then
		return;
	endif;
	executeStudio ( Params.Info.VSCode, Workspace.Value, Params.File );
	
endprocedure

procedure executeStudio ( VSCode, Workspace, File = undefined )

	#if ( ThinClient or ThickClientManagedApplication ) then
		if ( VSCode = "" ) then
			if ( Framework.IsLinux () ) then
				launcher = """code""";
			else
				launcher = """" + SystemVariable ( "userprofile" ) + "\AppData\Local\Programs\Microsoft VS Code\Code.exe""";
			endif;
		else
			launcher = VSCode;
		endif;
		cmd = new Array ();
		cmd.Add ( launcher );
		cmd.Add ( """" + Workspace + """" );
		if ( File <> undefined ) then
			cmd.Add ( """" + File + """" );
		endif;
		BeginRunningApplication ( new NotifyDescription ( "StudioLaunched", ThisObject ), StrConcat ( cmd, " " ) );
	#endif

endprocedure

procedure StudioLaunched ( Result, Next ) export
	
	//@skip-warning
	noerrors = true;

endprocedure
