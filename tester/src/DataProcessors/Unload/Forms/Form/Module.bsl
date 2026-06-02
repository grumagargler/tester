&atclient
var TableRow export;
&atserver
var DeletionType;
&atserver
var Node;
&atserver
var CurrentData;
&atserver
var CurrentApplication;
&atserver
var DataType;
&atserver
var PathFinder;
&atserver
var ChildHunter;
&atserver
var RemovingSet;
&atclient
var FolderSuffix;
&atclient
var MXLExtension;
&atclient
var JSONExtension;
&atclient
var ContinueUnloading;
&atclient
var CurrentIndex;
&atclient
var LastIndex;
&atclient
var Roots;

// *****************************************
// *********** Form events

&atserver
procedure OnCreateAtServer ( Cancel, StandardProcessing )
	
	saveChangesOnly ();
	loadRepositories ();

endprocedure

&atserver
procedure saveChangesOnly ()
	
	Object.Changes = true;

endprocedure 

&atserver
procedure loadRepositories ()
	
	if ( silentMode ( Parameters ) ) then
		s = "select Repositories.Application as Application, Repositories.Folder as Folder, true as Use, Repositories.Ref as Node
		|from ExchangePlan.Repositories as Repositories
		|where Repositories.Session = &Session
		|and not Repositories.DeletionMark";
	else
		s = "select allowed Repositories.Application as Application, Repositories.Folder as Folder,
		|	case when Settings.Application is null then false else true end as Use, Repositories.Ref as Node
		|from ExchangePlan.Repositories as Repositories
		|	//
		|	// Settings
		|	//
		|	left join InformationRegister.Applications as Settings
		|	on Settings.User = &User
		|	and Settings.Application = Repositories.Application
		|where Repositories.Session = &Session
		|and not Repositories.DeletionMark
		|order by Application";
	endif;
	q = new Query ( s );
	q.SetParameter ( "User", SessionParameters.User );
	q.SetParameter ( "Session", SessionParameters.Session );
	Object.Repositories.Load ( q.Execute ().Unload () );
	
endprocedure 

&atclientatservernocontext
function silentMode ( Parameters )
	
	return Parameters.Silent;
	
endfunction

&atclient
procedure Proceed () export
	
	prepareForm ();
	if ( not CheckFilling () ) then
		raise Output.UnloadingFilesCheckFillingError ();
	endif;
	startUnloading ();

endprocedure

&atclient
procedure OnOpen ( Cancel )
	
	prepareForm ();

endprocedure

&atclient
procedure prepareForm ()

	setConstants ();
	RepositoryForm.SetFocus ( ThisObject );
	LocalFiles.Prepare ();

endprocedure

&atclient
procedure setConstants ()
	
	Slash = GetPathSeparator ();
	FolderSuffix = RepositoryFiles.FolderSuffix ();
	MXLExtension = RepositoryFiles.MXLFile ();
	JSONExtension = RepositoryFiles.JSONFile ();
	
endprocedure 

&atclient
procedure startUnloading ()
	
	prepareScenarios ();
	prepareCounters ();
	getRoots ();
	toggleWatching ( false );
	createSystemFolders ();
	unloadScenarios ();
	
endprocedure

&atserver
procedure prepareScenarios ()
	
	init ();
	fillScenarios ();
	
endprocedure 

&atserver
procedure init ()
	
	DeletionType = Type ( "ObjectDeletion" );
	PathFinder = getPathFinder ();
	ChildHunter = getChildHunter ();
	
endprocedure 

&atserver
function getPathFinder ()
	
	s = "
	|select top 1 1
	|from Catalog.Scenarios as Scenarios
	|where Scenarios.Path = &Path
	|and Scenarios.Application = &Application
	|and Scenarios.Tree = &Tree
	|and not Scenarios.DeletionMark
	|";
	return new Query ( s );
	
endfunction 

&atserver
function getChildHunter ()

	s = "
	|select top 1 1
	|from Catalog.Scenarios as Scenarios
	|where not Scenarios.DeletionMark
	|and Scenarios.Parent = &Ref
	|and Scenarios.Application = &Application";
	return new Query ( s );

endfunction

&atserver
procedure fillScenarios ()
	
	ScenariosCounter = 0;
	RemovingSet = new Array ();
	ChangedScenarios.Clear ();
	for each repository in Object.Repositories do
		if ( not repository.Use ) then
			continue;
		endif; 
		Node = repository.Node;
		CurrentApplication = repository.Application;
		changes = getChanges ();
		while ( changes.Next () ) do
			try // there is no way to avoid RLS restrictions
				CurrentData = changes.Get ();
			except
				continue;
			endtry; 
			DataType = TypeOf ( CurrentData );
			if ( DataType = DeletionType
				or CurrentData.DeletionMark ) then
				addDeletion ();
			else
				addRenaming ();
				if ( CurrentData.Application = CurrentApplication ) then
					addScenario ();
				endif; 
			endif; 
		enddo;
	enddo;
	ChangedScenarios.Sort ( "Application, Delete desc" );
	RemovingIDs = new FixedArray ( RemovingSet );

endprocedure 

&atserver
function getChanges ()
	
	if ( not Object.Changes ) then
		ExchangePlans.Repositories.Reset ( Node );
	endif; 
	return ExchangePlans.SelectChanges ( Node, Node.SentNo );
	
endfunction 

&atserver
procedure addDeletion ()
	
	if ( DataType = DeletionType ) then
		id = CurrentData.Ref.UUID ();
		r = InformationRegisters.Removing.Get ( new Structure ( "Repository, ID", Node, id ) );
		if ( r.path = "" ) then
			return;
		endif; 
		RemovingSet.Add ( new Structure ( "ID, Repository", id, Node ) );
		path = r.Path;
		tree = r.Tree;
	else
		path = CurrentData.Path;
		tree = CurrentData.Tree;
	endif;
	if ( scenarioRecreated ( path, tree ) ) then
		return;
	endif; 
	row = ChangedScenarios.Add ();
	row.Application = CurrentApplication;
	row.Delete = deletedFile ( path );
	ScenariosCounter = ScenariosCounter + 1;

endprocedure

&atserver
function deletedFile ( Path )
	
	systemPath = StrReplace ( Path, ".", Slash );
	deleteHash ( systemPath + RepositoryFiles.BSLFile () );
	deleteHash ( systemPath + RepositoryFiles.JSONFile () );
	deleteHash ( systemPath + RepositoryFiles.MXLFile () );
	return systemPath + ".*";
	
endfunction 

&atserver
procedure deleteHash ( File )

	r = InformationRegisters.Files.CreateRecordManager ();
	r.ID = CoreLibrary.GetStringHash ( File, false );
	r.Delete ();

endprocedure

&atserver
function scenarioRecreated ( Path, Tree )
	
	PathFinder.SetParameter ( "Path", Path );
	PathFinder.SetParameter ( "Application", CurrentApplication );
	PathFinder.SetParameter ( "Tree", Tree );
	return not PathFinder.Execute ().IsEmpty ();
	
endfunction 

&atserver
procedure addRenaming ()
	
	id = CurrentData.Ref.UUID ();
	r = InformationRegisters.Removing.Get ( new Structure ( "Repository, ID", Node, id ) );
	path = r.Path;
	tree = r.Tree;
	if ( path = ""
		or scenarioRecreated ( path, tree ) ) then
		return;
	endif;
	row = ChangedScenarios.Add ();
	row.Application = CurrentApplication;
	scenarioBecameCommon = ( path = CurrentData.Path )
	and CurrentData.Application.IsEmpty ()
	and not CurrentApplication.IsEmpty ();
	if ( scenarioBecameCommon
		and hasChildren () ) then
		row.Delete = unbindFolder ( path );
	else
		row.Delete = deletedFile ( path );
	endif;
	RemovingSet.Add ( new Structure ( "ID, Repository", id, Node ) );
		
endprocedure

&atserver
function hasChildren ()
	
	ChildHunter.SetParameter ( "Ref", CurrentData.Ref );
	ChildHunter.SetParameter ( "Application", CurrentApplication );
	return not ChildHunter.Execute ().IsEmpty ();
	
endfunction 

&atserver
function unbindFolder ( Path )
	
	name = Mid ( Path, StrFind ( Path, ".", SearchDirection.FromEnd ) + 1 );
	systemPath = StrReplace ( Path, ".", Slash ) + Slash;
	suffix = RepositoryFiles.FolderSuffix ();
	filePath = systemPath + name + suffix;
	deleteHash ( filePath + RepositoryFiles.BSLFile () );
	deleteHash ( filePath + RepositoryFiles.JSONFile () );
	deleteHash ( filePath + RepositoryFiles.MXLFile () );
	return systemPath + "*" + suffix + ".*";
	
endfunction 

&atserver
procedure addScenario ()
	
	row = ChangedScenarios.Add ();
	row.Application = CurrentApplication;
	row.Scenario = CurrentData.Ref;
	ScenariosCounter = ScenariosCounter + 1;

endprocedure 

&atclient
procedure prepareCounters ()
	
	CurrentIndex = -1;
	LastIndex = ChangedScenarios.Count () - 1;
	initProgress ();
	ContinueUnloading = new NotifyDescription ( "ContinueUnloading", ThisObject );
	
endprocedure 

&atclient
procedure initProgress ()
	
	ProgressBar = 0;
	Items.ProgressBar.MaxValue = 1 + LastIndex;
	Items.ProgressBar.ShowPercent = true;
	
endprocedure 

&atclient
procedure getRoots ()
	
	Roots = new Map ();
	for each row in Object.Repositories do
		if ( row.Use ) then
			roots [ row.Application ] = row.Folder;
		endif; 
	enddo; 
	
endprocedure

&atclient
procedure toggleWatching ( On )
	
	if ( FoldersWatchdog = undefined ) then
		return;
	endif;
	for each root in Roots do
		entry = FoldersWatchdog [ root.Key ];
		if ( entry = undefined or not entry.Mapped ) then
			continue;
		endif;
		if ( On ) then
			entry.Lib.Resume ();
		else
			entry.Lib.Pause ();
		endif;
	enddo;
	
endprocedure

&atclient
procedure createSystemFolders ()
	
	stub = new NotifyDescription ( "Stub", ThisObject );
	for each root in Roots do
		if ( FoldersWatchdog [ root.Key ].Mapped ) then
			BeginCreatingDirectory ( stub, root.Value + slash + TesterSystemFolder );
		endif;
	enddo;
	
endprocedure

&atclient
procedure Stub ( Result, Params ) export
	
	//@skip-warning
	noerrors = true;
	
endprocedure

&atclient
procedure ContinueUnloading ( Result ) export
	
	unloadScenarios ();
	
endprocedure 

&atclient
procedure unloadScenarios ()
	
	CurrentIndex = CurrentIndex + 1;
	ProgressBar = ProgressBar + 1;
	RefreshDataRepresentation ( Items.ProgressBar );
	if ( CurrentIndex > LastIndex ) then
		toggleWatching ( true );
		deleteRecords ();
		showInfo ();
		if ( silentMode ( Parameters ) ) then
			GetForm ( "DataProcessor.Load.Form", new Structure ( "Silent", true ) ).Proceed ();
		endif;
		return;
	endif; 
	row = ChangedScenarios [ CurrentIndex ];
	root = Roots [ row.Application ];
	if ( row.Delete = "" ) then
		data = scenarioData ( row.Scenario );
		p = new Structure ( "Root, Data, BaseName", root, data );
		p.BaseName = getBaseName ( p );
		createFolder ( p );
	else
		victim = row.Delete;
		BeginDeletingFiles ( ContinueUnloading,
			root + Slash + FileSystem.GetParent ( victim ),
			FileSystem.GetFileName ( victim ) );
	endif; 
	
endprocedure 

&atserver
procedure deleteRecords ()
	
	for each repository in Object.Repositories do
		if ( repository.Use ) then
			Node = repository.Node;
			ExchangePlans.DeleteChangeRecords ( Node, Node.ReceivedNo );
		endif; 
	enddo; 
	commitRemoving ();
	
endprocedure 

&atserver
procedure commitRemoving ()
	
	for each record in RemovingIDs do
		r = InformationRegisters.Removing.CreateRecordManager ();
		r.Repository = record.Repository;
		r.ID = record.ID;
		r.Delete ();
	enddo; 
	
endprocedure 

&atclient
procedure showInfo ()
	
	p = new Structure ( "Counter", Format ( ScenariosCounter, "NZ=; NG=" ) );
	if ( silentMode ( Parameters ) ) then
		Output.ScenariosProcessedNotification ( p );
	else
		Output.ScenariosProcessed ( ThisObject, , p );
	endif;
	
endprocedure 

&atclient
procedure ScenariosProcessed ( Params ) export
	
	Close ();
	
endprocedure 

&atservernocontext
function scenarioData ( val Scenario )
	
	data = new Structure ();
	data.Insert ( "Properties", Catalogs.Scenarios.GetProperties ( Scenario ) );
	data.Insert ( "Path", Scenario.Path );
	data.Insert ( "Script", Scenario.Script );
	data.Insert ( "Spreadsheet", Scenario.Spreadsheet );
	data.Insert ( "Template", getTemplate ( Scenario ) );
	data.Insert ( "Tree", Scenario.Tree );
	changed = ? ( Scenario.Changed = Date ( 1, 1, 1 ), Date ( 2000, 1, 1 ), Scenario.Changed );
	data.Insert ( "Changed", changed );
	return data;
	
endfunction

&atservernocontext
function getTemplate ( Scenario )
	
	tabDoc = Scenario.Template.Get ();
	if ( Scenario.Spreadsheet ) then
		anchor = tabDoc.TableHeight + 1;
		tabDoc.Area ( anchor, 1, anchor, 1 ).Text = RepositoryFiles.Signature ();
		anchor = anchor + 1;
		tabDoc.Area ( anchor, 1, anchor, 1 ).Text = serializeAreas ( Scenario );
	endif; 
	return tabDoc;

endfunction 

&atservernocontext
function serializeAreas ( Scenario )
	
	parts = new Array ();
	for each area in Scenario.Areas do
		data = new Structure ( "Name, Top, Left, Bottom, Right" );
		FillPropertyValues ( data, area );
		parts.Add ( data );
	enddo; 
	return Conversion.ToJSON ( parts, false );
	
endfunction 

&atclient
function getBaseName ( Params )
	
	data = Params.Data;
	path = data.Path;
	file = Params.Root + Slash + StrReplace ( path, ".", Slash );
	if ( data.Tree ) then
		dirname = Mid ( path, 1 + StrFind ( path, ".", SearchDirection.FromEnd ) ) + FolderSuffix;
		file = file + Slash + dirname;
	endif;
	return file;
	
endfunction 

&atclient
procedure createFolder ( Params )
	
	data = Params.Data;
	path = data.Path;
	if ( data.Tree ) then
		folder = Params.Root + Slash + StrReplace ( path, ".", Slash );
	else
		folder = Left ( path, StrFind ( path, ".", SearchDirection.FromEnd ) - 1 );
		folder = Params.Root + Slash + StrReplace ( folder, ".", Slash );
	endif; 
	BeginCreatingDirectory ( new NotifyDescription ( "CreatingDirectory", ThisObject, Params ), folder );

endprocedure 

&atclient
procedure CreatingDirectory ( Folder, Params ) export
	
	createScript ( Params );
	
endprocedure 

&atclient
procedure createScript ( Params )
	
	#if ( ThinClient or ThickClientManagedApplication ) then
		data = Params.Data;
		file = Params.BaseName + RepositoryFiles.BSLFile ();
		p = new Structure ( "File, Params", file, Params );
		doc = new TextDocument ();
		doc.SetText ( data.Script );
		doc.BeginWriting ( new NotifyDescription ( "ScriptCreated", ThisObject, p ), file, , Chars.LF );
	#endif
		
endprocedure 

&atclient
procedure ScriptCreated ( Result, Params ) export
	
	p = Params.Params;
	callback = new NotifyDescription ( "ScriptTimeChanged", ThisObject, p );
	file = new File ( Params.File );
	file.BeginSettingModificationUniversalTime ( callback, p.Data.Changed );

endprocedure 

&atclient
procedure ScriptTimeChanged ( Params ) export
	
	createPropeties ( Params );
	
endprocedure

&atclient
procedure createPropeties ( Params )
	
	#if ( ThinClient or ThickClientManagedApplication ) then
		data = Params.Data;
		file = Params.BaseName + JSONExtension;
		p = new Structure ( "File, Params", file, Params );
		doc = new TextDocument ();
		doc.SetText ( data.Properties );
		doc.BeginWriting ( new NotifyDescription ( "PropertiesCreated", ThisObject, p ), file, , Chars.LF );
	#endif
		
endprocedure 

&atclient
procedure PropertiesCreated ( Result, Params ) export
	
	p = Params.Params;
	callback = new NotifyDescription ( "PropertiesTimeChanged", ThisObject, p );
	file = new File ( Params.File );
	file.BeginSettingModificationUniversalTime ( callback, p.Data.Changed );

endprocedure

&atclient
procedure PropertiesTimeChanged ( Params ) export
	
	createSpreadsheet ( Params );
	
endprocedure 

&atclient
procedure createSpreadsheet ( Params )
	
	file = Params.BaseName + MXLExtension;
	data = Params.Data;
	if ( data.Spreadsheet ) then
		data.Template.Write ( file );
		modifyFile ( file, data.Changed );
		unloadScenarios ();
	else
		BeginDeletingFiles ( ContinueUnloading, file );
	endif; 
		
endprocedure 

&atclient
procedure modifyFile ( File, Date )
	
	file = new File ( File );
	file.SetModificationUniversalTime ( Date );
	
endprocedure 

&atserver
procedure FillCheckProcessingAtServer ( Cancel, CheckedAttributes )
	
	if ( not RepositoryForm.CheckSelection ( Object ) ) then
		Cancel = true;
	endif; 
	if ( not RepositoryForm.CheckFolders ( Object ) ) then
		Cancel = true;
	endif; 
	
endprocedure

// *****************************************
// *********** Group Form

&atclient
procedure Unload ( Command )
	
	if ( CheckFilling () ) then
		startUnloading ();
	endif;

endprocedure

// *****************************************
// *********** Table Repositories

&atclient
procedure MarkAll ( Command )
	
	checkbox ( true );
	
endprocedure

&atclient
procedure checkbox ( Value )
	
	for each row in Object.Repositories do
		row.Use = Value;
	enddo; 
	
endprocedure 

&atclient
procedure UnmarkAll ( Command )
	
	checkbox ( false );
	
endprocedure

&atclient
procedure RepositoriesOnActivateRow ( Item )
	
	TableRow = Item.CurrentData;
	
endprocedure

&atclient
procedure ReporitoriesFolderStartChoice ( Item, ChoiceData, StandardProcessing )
	
	StandardProcessing = false;
	RepositoryForm.ChooseFolder ( ThisObject );
	
endprocedure

&atclient
procedure ReporitoriesFolderOnChange ( Item )
	
	RepositoryForm.ApplyFolder ( ThisObject );
	
endprocedure

&atclient
procedure RepositoriesBeforeAddRow ( Item, Cancel, Clone, Parent, Folder, Parameter )
	
	Cancel = true;
	
endprocedure

&atclient
procedure RepositoriesBeforeDeleteRow ( Item, Cancel )
	
	Cancel = true;
	
endprocedure
