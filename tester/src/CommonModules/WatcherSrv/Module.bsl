function Repositories () export
	
	table = getFolders ();
	result = new Structure ();
	result.Insert ( "Applications", table.UnloadColumn ( "Application" ) );
	result.Insert ( "Folders", table.UnloadColumn ( "Folder" ) );
	result.Insert ( "Mapped", table.UnloadColumn ( "Mapped" ) );
	return result;
	
endfunction

function getFolders ()
	
	s = "
	|select allowed Repositories.Application as Application, Repositories.Folder as Folder,
	|	Repositories.Mapping as Mapped
	|from ExchangePlan.Repositories as Repositories
	|where Repositories.Session = &Session
	|";
	q = new Query ( s );
	q.SetParameter ( "Session", SessionParameters.Session );
	return q.Execute ().Unload ();
	
endfunction

function Update ( val Context, val Data, Error ) export
	
	var errors;
	
	scenario = WatcherSrv.FindScenario(Context);
	if (scenario = undefined) then
		Error = Output.UndefinedScenario(new Structure("File", Context.File));
		return undefined;
	endif;
	LockingForm.Lock ( wrapScenario ( scenario, false ), undefined, errors );
	if ( errors <> undefined ) then
		Error = Output.LockingError ( errors [ 0 ] );
		return undefined;
	endif;
	if ( updateScenario ( scenario, Data, Context, Error ) ) then
		return scenario;
	endif;
	
endfunction

function FindScenario ( val Context, val EvenRemoved = false ) export

	return RuntimeSrv.FindScenario ( Context.Path, Context.Application, undefined, undefined, true, EvenRemoved );

endfunction

function wrapScenario ( Scenario, Hierarchy )
	
	if ( Hierarchy ) then
		s = "select allowed Scenarios.Ref as Ref
		|from Catalog.Scenarios as Scenarios
		|where Scenarios.Ref in hierarchy ( &Scenario )
		|union all
		|select &Scenario";
		q = new Query ( s );
		q.SetParameter ( "Scenario", Scenario );
		table = q.Execute ().Unload ();
	else
		table = new ValueTable ();
		table.Columns.Add ( "Ref", new TypeDescription ( "CatalogRef.Scenarios" ) );
		row = table.Add ();
		row.Ref = Scenario;
	endif;
	return table;
	
endfunction

function updateScenario ( Scenario, Data, Context, Error )
	
	obj = Scenario.GetObject ();
	ext = Context.Extension;
	if ( ext = RepositoryFiles.MXLFile () ) then
		DataProcessors.Load.AssembleTemplate ( Data, obj );
	elsif ( ext = RepositoryFiles.JSONFile () ) then
		try
			DataProcessors.Load.Properties ( Data, obj );
		except
			raise Output.ScenarioPropertiesLoadingError (
				new Structure ( "File, Error", Context.File, ErrorDescription () ) );
		endtry;
	else
		obj.Script = Data;
	endif;
	obj.Changed = Max ( Context.Changed, obj.Changed );
	Catalogs.Scenarios.SetSorting ( obj );
	Catalogs.Scenarios.UpdateFiles ( obj );
	obj.DataExchange.Load = true;
	try
		ExchangeKillers.Write ( obj );
	except
		why = ErrorDescription ();
		Error = Output.WatcherUpdatingError ( new Structure ( "Error, Scenario", why, Scenario ) );
		return false;
	endtry;
	enrollChanges ( obj, Context.Application, Enum.FSUserActionsChange () );
	return true;
		
endfunction

procedure enrollChanges ( Object, RepoApplication, Action, OldPath = undefined )

	Object.FullExchange ();
	scenario = Object.Ref;
	application = Object.Application;
	ExchangePlans.Repositories.Sync ( scenario, application, application = RepoApplication );
	if ( Action = Enum.FSUserActionsRename ()
		or Action = Enum.FSUserActionsDelete () ) then
		commonFolder = Object.Tree and application.IsEmpty (); 
		if ( commonFolder ) then
			syncingBack = new Array ();
			for each reference in Catalogs.Scenarios.ApplicationsInside ( scenario, RepoApplication ) do
				alreadyHappened = reference = RepoApplication;
				ExchangePlans.Repositories.Sync ( scenario, reference, alreadyHappened );
				Catalogs.Scenarios.RemoveFile ( scenario, reference, OldPath, true, alreadyHappened );
				syncingBack.Add ( ? ( reference.IsEmpty (), Output.CommonApplicationName (), reference ) );
			enddo;
			if ( syncingBack.Count () > 0 ) then
				msg = new Structure ( "Folder, Apps", Object.Path, StrConcat ( syncingBack, ", " ) );
				Output.SyncingBackRequred ( msg );
			endif;
		endif;
	endif;

endprocedure

function Create ( val Context, val IsFolder, Error ) export
	
	scenario = fetchScenario ( Context, Error );
	if ( Error <> undefined ) then
		return undefined;
	endif;
	parent = lockParent ( Context, Error );
	if ( Error <> undefined ) then
		return undefined;
	endif;
	if ( initScenario ( parent, scenario, Context, IsFolder, Error ) ) then
		InformationRegisters.Editing.Lock ( SessionParameters.User, scenario );
		if ( not IsFolder ) then
			changes = new Array ();
			if ( parent <> undefined ) then
				changes.Add ( parent );
			endif;
			changes.Add ( scenario );
			return changes;
		endif;
	endif;

endfunction

function fetchScenario ( Context, Error )

	var errors;
	
	scenario = WatcherSrv.FindScenario ( Context, true );
	if ( scenario <> undefined ) then
		LockingForm.Lock ( wrapScenario ( scenario, false ), undefined, errors );
		if ( errors <> undefined ) then
			Error = Output.LockingError ( errors [ 0 ] );
			return undefined;
		endif;
	endif;
	return scenario;

endfunction

function lockParent ( Context, Error )
	
	var errors;
	
	path = Left ( Context.Path, StrFind ( Context.Path, ".", SearchDirection.FromEnd ) - 1 );
	if ( path = "" ) then
		return undefined;
	endif;
	parent = RuntimeSrv.FindScenario ( path, Context.Application, undefined, undefined, true );
	if ( parent = undefined ) then
		Error = Output.WatcherParentNotFound ( new Structure ( "File", Context.File ) );
		return undefined;
	endif;
	LockingForm.Lock ( wrapScenario ( parent, false ), undefined, errors );
	if ( errors <> undefined ) then
		Error = Output.LockingError ( errors [ 0 ] );
		return undefined;
	endif;
	return parent;

endfunction

function initScenario ( Parent, Scenario, Context, IsFolder, Error )
	
	application = Context.Application;
	if ( Scenario = undefined ) then
		obj = Catalogs.Scenarios.CreateItem ();
		obj.SetNewCode ();
		obj.Description = RepositoryFiles.FileToName ( Context.File );
		obj.Parent = Parent;
		Catalogs.Scenarios.SetPath ( obj );
		obj.Script = "";
		obj.Application = application;
		obj.Creator = SessionParameters.User;
		obj.Users.Clear ();
		DataProcessors.Load.ResetTemplate ( obj );
		if ( IsFolder ) then
			obj.Type = Enums.Scenarios.Folder;
			obj.Tree = true;
		else
			obj.Type = Enums.Scenarios.Scenario;
		endif;
		obj.Changed = Context.Changed;
		obj.DataExchange.Load = true;
		Catalogs.Scenarios.SetSorting ( obj );
		Catalogs.Scenarios.UpdateFiles ( obj );
		try
			ExchangeKillers.Write ( obj );
		except
			why = ErrorDescription ();
			Error = Output.WatcherCreatingError ( new Structure ( "Error, Parent, File", why, Parent, Context.File ) );
			return false;
		endtry;
		enrollChanges ( obj, application, Enum.FSUserActionsCreate () );
		Scenario = obj.Ref;
	elsif ( DF.Pick ( Scenario, "DeletionMark" ) ) then
		obj = Scenario.GetObject ();
		obj.DataExchange.Load = true;
		obj.DeletionMark = false;
		obj.Changed = Context.Changed;
		try
			ExchangeKillers.Write ( obj );
		except
			why = ErrorDescription ();
			Error = Output.WatcherRestorationError ( new Structure ( "Error, Scenario, File", why, scenario, Context.File ) );
			return false;
		endtry;
		enrollChanges ( obj, application, Enum.FSUserActionsCreate () );
	endif;
	return true;
	
endfunction

function GetMethods ( val Starting ) export
	
	table = getScenarios ( Starting );
	result = new Array ();
	for each row in table do
		result.Add ( new Structure ( "Path, Application", row.Path, row.Application ) );
	enddo;
	return result;
	
endfunction

function getScenarios ( Starting )
	
	q = new Query ();
	s = "
	|select allowed Scenarios.Path as Path,
	|	isnull ( Scenarios.Application.Description, &Common ) as Application
	|from Catalog.Scenarios as Scenarios
	|where not Scenarios.DeletionMark
	|and Scenarios.Type = value ( Enum.Scenarios.Method )
	|";
	if ( Starting <> undefined ) then
		s = s + "
		|and Scenarios.Parent in hierarchy ( &Folder )";
		q.SetParameter ( "Folder", DF.Pick ( Starting, "Parent" ) );
	endif;
	s = s + "
	|order by Path, Application
	|";
	q.Text = s;
	q.SetParameter ( "Common", Output.CommonApplicationName () );
	return q.Execute ().Unload ();
	
endfunction

function Rename ( val Context, val NewFile, val NewPath, val IsFolder, Error ) export
	
	var errors;
	
	scenario = WatcherSrv.FindScenario(Context);
	if (scenario = undefined) then
		scenario = RuntimeSrv.FindScenario ( NewPath, Context.Application, undefined, undefined, true );
		alreadyRenamed = scenario <> undefined; 
		if ( alreadyRenamed ) then
			return scenario; 
		else
			Error = Output.UndefinedScenario(new Structure("File", Context.File));
			return undefined;
		endif;
	endif;
	LockingForm.Lock ( wrapScenario ( Scenario, true ), undefined, errors );
	if ( errors <> undefined ) then
		Output.LockingError ( errors [ 0 ] );
		return undefined;
	endif;
	if ( renameScenario ( scenario, Context.Application, NewFile, IsFolder, Error ) ) then
		return scenario;
	endif;

endfunction

function renameScenario ( Scenario, Application, NewFile, IsFolder, Error )
	
	BeginTransaction ();
	obj = Scenario.GetObject ();
	oldPath = obj.Path;
	obj.Description = RepositoryFiles.FileToName ( NewFile );
	Catalogs.Scenarios.SetPath ( obj );
	obj.DataExchange.Load = true;
	try
		ExchangeKillers.Write ( obj );
	except
		why = ErrorDescription ();
		Error = Output.WatcherRenamingError ( new Structure ( "Error, Scenario, File", why, Scenario, NewFile ) );
		RollbackTransaction ();
		return false;
	endtry;
	enrollChanges ( obj, Application, Enum.FSUserActionsRename (), oldPath );
	if ( IsFolder ) then
		if ( not Catalogs.Scenarios.ChangeChildren ( Scenario, oldPath, obj.Path, Application, Application, true ) ) then
			Error = Output.WatcherRenamingChildrenError ( new Structure ( "Scenario", Scenario ) );
			RollbackTransaction ();
			return false;
		endif;
	endif;
	CommitTransaction ();
	return true;
		
endfunction

function Remove ( val Context, Error ) export
	
	var errors;
	
	scenario = WatcherSrv.FindScenario ( Context, true );
	if ( scenario = undefined ) then
		if ( Context.Extension = RepositoryFiles.JSONFile () ) then
			Error = Output.UndefinedScenario ( new Structure ( "File", Context.File ) );
		endif;
		return undefined;
	endif;
	LockingForm.Lock ( wrapScenario ( scenario, true ), undefined, errors );
	if ( errors <> undefined ) then
		Output.LockingError ( errors [ 0 ] );
		return undefined;		
	endif;
	if ( removeScenario ( scenario, Context, Error ) ) then
		return scenario;
	endif;
	
endfunction

function removeScenario ( Scenario, Context, Error )
	
	obj = Scenario.GetObject ();
	obj.DataExchange.Load = true;
	extension = Context.Extension;
	application = Context.Application;
	if ( extension = RepositoryFiles.MXLFile () ) then
		DataProcessors.Load.ResetTemplate ( obj );
		try
			ExchangeKillers.Write ( obj );
		except
			why = ErrorDescription ();
			Error = Output.WatcherTemplateRemovingError ( new Structure ( "Error, Scenario", why, Scenario ) );
			return false;
		endtry;
		enrollChanges ( obj, application, Enum.FSUserActionsChange () );
	elsif ( extension = RepositoryFiles.BSLFile () ) then
		obj.Script = "";
		try
			ExchangeKillers.Write ( obj );
		except
			why = ErrorDescription ();
			Error = Output.WatcherScriptRemovingError ( new Structure ( "Error, Scenario", why, Scenario ) );
			return false;
		endtry;
		enrollChanges ( obj, application, Enum.FSUserActionsChange () );
	elsif ( not obj.DeletionMark ) then
		if ( obj.Application = application ) then
			obj.DeletionMark = true;
			try
				ExchangeKillers.Write ( obj );
			except
				why = ErrorDescription ();
				Error = Output.WatcherRemovingError ( new Structure ( "Error, Scenario", why, Scenario ) );
				return false;
			endtry;
			enrollChanges ( obj, application, Enum.FSUserActionsDelete () );
		endif;
		if ( obj.Tree ) then
			if ( not Catalogs.Scenarios.DeleteChildren ( Scenario, application ) ) then
				Error = Output.WatcherRenamingChildrenError ( new Structure ( "Scenario", Scenario ) );
				RollbackTransaction ();
				return false;
			endif;
		endif;
	endif;
	return true;
		
endfunction

function ExtractIDs ( Changes, Application ) export

	q = new Query ( "
	|select Changes.ID as ID, Changes.File as File
	|into Changes
	|from &Changes as Changes
	|index by ID
	|;
	|// #Changes
	|select Files.ID as ID, Files.File as File
	|from InformationRegister.Files as Files
	|where Files.ID in ( select ID from Changes )
	|and Files.Application = &Application
	|and Files.Session = &Session
	|;
	|// #New
	|select Changes.ID as ID, Changes.File
	|from Changes as Changes
	|	//
	|	// Files
	|	//
	|	left join InformationRegister.Files as Files
	|	on Files.ID = Changes.ID
	| and Files.Session = &Session
	|	and Files.Application = &Application
	|where Files.ID is null
	|" );
	q.SetParameter ( "Application", Application );
	q.SetParameter ( "Session", SessionParameters.Session );
	q.SetParameter ( "Changes", changesTable ( Changes ) );
	return serializeChanges ( SQL.Exec ( q ) );

endfunction

function changesTable ( Changes )
	
	table = new ValueTable ();
	columns = table.Columns;
	columns.Add ( "ID", new TypeDescription ( "Number", new NumberQualifiers ( 20 ) ) );
	columns.Add ( "File", new TypeDescription ( "String" ) );
	list = Conversion.FromJSON ( Changes );
	for each change in list do
		row = table.Add ();
		row.ID = change.id;
		row.File = change.path;
	enddo;
	return table;

endfunction

function serializeChanges ( Data )

	changes = Collections.Serialize ( Data.Changes );
	newFiles = Collections.Serialize ( Data.New );
	return new Structure ( "Changes, New", changes, newFiles );

endfunction

function GetContent ( val ID ) export

	return InformationRegisters.Files.Get (
		new Structure ( "Session, ID", SessionParameters.Session, ID ) ).Content;

endfunction
