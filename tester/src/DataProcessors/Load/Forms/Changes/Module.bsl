#if ( server or thinclient or thickclientmanagedapplication ) then

&atserver
var Tree;
&atserver
var CurrentApplication;
&atserver
var CurrentData;
&atclient
var ScenarioIndex;
&atclient
var LastScenario;
&atserver
var CommonApplication;
&atclient
var ScenariosSet;
&atclient
var CurrentData;
&atclient
var FilesContent;
&atclient
var FilesList;
&atclient
var CurrentFile;
&atclient
var FileIndex;
&atclient
var LastFile;
&atclient
var RenewList;
&atserver
var CommonRows;

// *****************************************
// *********** Form events

&atserver
procedure OnCreateAtServer ( Cancel, StandardProcessing )
	
	loadScenarios ();
	
endprocedure

&atserver
procedure loadScenarios ()
	
	createTree ();
	q = getQuery ();
	for each CurrentApplication in getApplications () do
		q.SetParameter ( "Application", CurrentApplication );
		selection = q.Execute ().Select ( QueryResultIteration.ByGroupsWithHierarchy, "Scenario" );
		loadSelection ( selection, newApplication () );
	enddo; 
	loadChanges ();
	formatTree ( Tree.Rows );
	ValueToFormAttribute ( Tree, "ChangesTree" );
	
endprocedure 

&atserver
procedure createTree ()
	
	Tree = new ValueTree ();
	columns = Tree.Columns;
	boolean = new TypeDescription ( "Boolean" );
	string = new TypeDescription ( "String" );
	number = new TypeDescription ( "Number" );
	datetime = new TypeDescription ( "Date" );
	columns.Add ( "Presentation", string );
	columns.Add ( "Application", new TypeDescription ( "CatalogRef.Applications" ) );
	columns.Add ( "Use", boolean );
	columns.Add ( "Scenario", new TypeDescription ( "CatalogRef.Scenarios" ) );
	columns.Add ( "Path", string );
	columns.Add ( "New", boolean );
	columns.Add ( "File", string );
	columns.Add ( "Locked", number );
	columns.Add ( "Type", new TypeDescription ( "EnumRef.Scenarios" ) );
	columns.Add ( "Picture", number );
	columns.Add ( "Sorting", number );
	columns.Add ( "Found", boolean );
	columns.Add ( "Changed", datetime );
	columns.Add ( "Usage", boolean );
	columns.Add ( "UTC", datetime );
	columns.Add ( "Extensions", string );
	
endprocedure 

&atserver
function getApplications ()
	
	list = new Array ();
	for each row in Parameters.Changes do
		list.Add ( row.Application );
	enddo; 
	return list;
	
endfunction 

&atserver
function getQuery ()
	
	s = "
	|select allowed Scenarios.Ref as Scenario, Scenarios.Application as Application, Scenarios.Path as Path,
	|	Scenarios.Type as Type, Scenarios.Changed as Changed, Scenarios.Sorting as Sorting,
	|	case when Editing.Scenario is null then 0
	|		when Editing.User = &User then 1
	|		else 2
	|	end as Locked,
	|	case when Scenarios.Spreadsheet then 4 else 0 end
	|	+
	|	case when Scenarios.Type = value ( Enum.Scenarios.Library ) then 0
	|		when Scenarios.Type = value ( Enum.Scenarios.Folder ) then 1
	|		when Scenarios.Type = value ( Enum.Scenarios.Method ) then 2
	|		else 3
	|	end as Picture
	|from Catalog.Scenarios as Scenarios
	|	//
	|	// Editing
	|	//
	|	left join InformationRegister.Editing as Editing
	|	on Editing.Scenario = Scenarios.Ref
	|where Scenarios.Application = &Application
	|and not Scenarios.DeletionMark
	|order by Application, Tree desc, Sorting, Path
	|totals by Scenario hierarchy
	|";
	q = new Query ( s );
	q.SetParameter ( "User", SessionParameters.User );
	return q;
	
endfunction

&atserver
function newApplication ()
	
	row = Tree.Rows.Add ();
	row.Application = CurrentApplication;
	row.Presentation = "" + ? ( CurrentApplication.IsEmpty (), Output.CommonApplicationName (), CurrentApplication );
	return row.Rows;

endfunction 

&atserver
procedure loadSelection ( Selection, Destination, LastScenario = undefined )
	
	detail = QueryRecordType.DetailRecord;
	bygroup = QueryRecordType.GroupTotal;
	hierarchy = QueryRecordType.TotalByHierarchy;
	deep = QueryResultIteration.ByGroupsWithHierarchy;
	while ( Selection.Next () ) do
		scenario = Selection.Scenario;
		type = Selection.RecordType ();
		if ( type = detail ) then
			if ( scenario = LastScenario ) then
				FillPropertyValues ( Destination.Parent, Selection );
			endif;
		else
			if ( scenario = LastScenario ) then
				rows = Destination;
			else
				row = Destination.Add ();
				FillPropertyValues ( row, Selection );
				rows = row.Rows;
			endif;
			if ( type = hierarchy ) then
				next = Selection.Select ( deep, "Scenario" );
			elsif ( type = bygroup ) then
				next = Selection.Select ();
			endif; 
			loadSelection ( next, rows, Selection.Scenario );
		endif;
	enddo; 
	
endprocedure

&atserver
procedure loadChanges ()
	
	defineCommon ();
	for each repository in Parameters.Changes do
		CurrentApplication = repository.Application;
		for each CurrentData in repository.Changes do
			addScenario ();
		enddo; 
	enddo; 
	
endprocedure 

&atserver
procedure defineCommon ()
	
	CommonApplication = Catalogs.Applications.EmptyRef ();
	row = Tree.Rows.Find ( CommonApplication, "Application" );
	CommonRows = ? ( row = undefined, undefined, row.Rows );
	
endprocedure 

&atserver
procedure addScenario ()
	
	path = CurrentData.Path;
	row = findScenario ( path );
	if ( row = undefined ) then
		row = newRow ( defineParent (), path );
	else
		row.Found = not row.New;
	endif; 
	row.UTC = Max ( CurrentData.UTC, row.UTC );
	row.File = CurrentData.File;
	ext = CurrentData.Extension;
	if ( ext <> "" ) then
		row.Extensions = row.Extensions + ext + ";";
	endif; 
	
endprocedure 

&atserver
function findScenario ( Path )
	
	found = Tree.Rows.FindRows ( new Structure ( "Application, Path", CurrentApplication, Path ), true );
	if ( found.Count () = 0 ) then
		rows = findRoot ();
		found = rows.FindRows ( new Structure ( "Application, Path", CommonApplication, Path ), true );
	endif;
	return ? ( found.Count () = 0, undefined, found [ 0 ] );
	
endfunction 

&atserver
function findRoot ()
	
	row = Tree.Rows.Find ( CurrentApplication, "Application" );
	return ? ( row = undefined, undefined, row.Rows );
	
endfunction 

&atserver
function newRow ( Rows, Path )
	
	row = Rows.Add ();
	if ( CommonRows = undefined ) then
		commonRow = undefined;
	else
		commonRow = CommonRows.Find ( Path, "Path", true );
	endif; 
	if ( commonRow = undefined ) then
		row.Path = Path;
		row.New = true;
		row.Application = CurrentApplication;
	else
		FillPropertyValues ( row, commonRow );
	endif; 
	return row;
	
endfunction 

&atserver
function defineParent ()
	
	parts = StrSplit ( CurrentData.Path, "." );
	parts.Delete ( parts.UBound () );
	path = "";
	parent = findRoot ();
	for each part in parts do
		path = path + part;
		row = findScenario ( path );
		if ( row = undefined ) then
			row = newRow ( parent, path );
		endif; 
		parent = row.Rows;
		path = path + ".";
	enddo; 
	return parent;
	
endfunction 

&atserver
procedure formatTree ( Rows )
	
	for each row in Rows do
		setType ( row );
		setPicture ( row );
		setUsage ( row );
		setPresentation ( row );
		next = row.Rows;
		if ( next.Count () > 0 ) then
			formatTree ( next );
		endif; 
	enddo; 
	
endprocedure 

&atserver
procedure setType ( Row )
	
	if ( not Row.New ) then
		return;
	endif; 
	folder = StrEndsWith ( Row.File, RepositoryFiles.FolderSuffix () );
	type = ? ( folder, Enums.Scenarios.Folder, Enums.Scenarios.Scenario );
	Row.Type = type;
		
endprocedure 

&atserver
procedure setPicture ( Row )
	
	if ( not Row.New ) then
		return;
	endif; 
	type = Row.Type;
	if ( type = Enums.Scenarios.Library ) then
		picture = 0;
	elsif ( type = Enums.Scenarios.Folder ) then
		picture = 1;
	elsif ( type = Enums.Scenarios.Method ) then
		picture = 2;
	else
		picture = 3;
	endif;
	if ( StrFind ( Row.Extensions, RepositoryFiles.MXLFile () + ";" ) > 0 ) then
		picture = 4 + picture;
	endif;
	Row.Picture = picture;
		
endprocedure 

&atserver
procedure setUsage ( Row )
	
	usage = Row.Path <> ""
	and ( Row.Extensions <> "" and ( Row.New or Row.Locked = 1 )
		or ( not Row.Found and Row.Application = CurrentApplication )
	);
	Row.Usage = usage;
	if ( Row.Found ) then
		Row.Use = usage and ( Row.Changed < Row.UTC );
	else
		Row.Use = usage;
	endif; 
		
endprocedure 

&atserver
procedure setPresentation ( Row )
	
	if ( Row.Presentation = "" ) then
		Row.Presentation = Row.Path;
	endif; 
		
endprocedure 

&atclient
procedure OnOpen ( Cancel )

	if ( Parameters.Silent ) then
		Cancel = true;
		runLoading ();
	endif;

endprocedure

// *****************************************
// *********** Group Form

&atclient
procedure Load ( Command )
	
	runLoading ();

endprocedure

&atclient
procedure runLoading ()

	prepareScenarios ();
	prepareCounters ();
	initProgress ();
	startLoading ();
	
endprocedure

&atclient
procedure prepareScenarios ()
	
	ScenariosSet = new Array ();
	fillScenarios ( ChangesTree.GetItems () );
	
endprocedure 

&atclient
procedure fillScenarios ( Rows )
	
	for each row in Rows do
		if ( row.Use ) then
			ScenariosSet.Add ( row );
		endif;
		next = row.GetItems ();
		if ( next.Count () > 0 ) then
			fillScenarios ( next );
		endif; 
	enddo; 
	
endprocedure 

&atclient
procedure prepareCounters ()
	
	ScenarioIndex = -1;
	LastScenario = ScenariosSet.UBound ();
	RenewList = new Array ();
	
endprocedure 

&atclient
procedure initProgress ()
	
	ProgressBar = 0;
	Items.ProgressBar.MaxValue = 1 + LastScenario;
	Items.ProgressBar.ShowPercent = true;
	
endprocedure 

&atclient
procedure startLoading ()
	
	ScenarioIndex = ScenarioIndex + 1;
	ProgressBar = ProgressBar + 1;
	RefreshDataRepresentation ( Items.ProgressBar );
	if ( ScenarioIndex > LastScenario ) then
		if ( Parameters.Silent ) then
			broadcastChanges ();
			if ( RepositoryFilesSynchingCallback <> undefined ) then
				RunCallback ( RepositoryFilesSynchingCallback );
				RepositoryFilesSynchingCallback = undefined;
			endif;
		else
			showInfo ();
		endif;
		return;
	endif; 
	CurrentData = ScenariosSet [ ScenarioIndex ];
	FilesContent = new Map ();
	FilesList = filesList ();
	FileIndex = -1;
	LastFile = FilesList.UBound ();
	loadFiles ();
	
endprocedure 

&atclient
function filesList ()
	
	list = new Array ();
	for each ext in StrSplit ( CurrentData.Extensions, ";", false ) do
		list.Add ( new Structure ( "Name, Extension", CurrentData.File, ext ) );
	enddo; 
	return list;
	
endfunction 

&atclient
procedure loadFiles ()
	
	FileIndex = FileIndex + 1;
	if ( FileIndex > LastFile ) then
		remove = not CurrentData.Found and not CurrentData.New;
		application = CurrentData.Application;
		if ( CurrentData.Extensions = "" ) then
			isCommon = application.IsEmpty () or not remove;
		else
			isCommon = false;
		endif;
		parent = CurrentData.GetParent ().Scenario;
		CurrentData.Scenario = updateScenario ( application, isCommon, parent, CurrentData.Path, FilesContent,
			CurrentData.Type, remove, CurrentData.UTC, CurrentData.File );
		RenewList.Add ( CurrentData.Scenario );
		startLoading ();
		return;
	endif; 
	CurrentFile = FilesList [ FileIndex ];
	file = CurrentFile.Name + CurrentFile.Extension;
	if ( CurrentFile.Extension = RepositoryFiles.MXLFile () ) then
		BeginPutFile ( new NotifyDescription ( "PutMXL", ThisObject ), , file, false, UUID );
	else
		doc = new TextDocument ();
		doc.BeginReading ( new NotifyDescription ( "ReadingComplete", ThisObject, doc ), file, TextEncoding.UTF8 );
	endif; 
	
endprocedure 

&atclient
procedure PutMXL ( Result, Address, File, Params ) export
	
	if ( Result ) then
		FilesContent [ CurrentFile.Extension ] = Address;
	endif; 
	loadFiles ();
	
endprocedure 

&atclient
procedure broadcastChanges ()

	Notify ( Enum.MessageReload (), RenewList );
	NotifyChanged ( Type ( "CatalogRef.Scenarios" ) );

endprocedure

&atclient
procedure showInfo ()
	
	Output.ScenariosProcessed ( ThisObject, , new Structure ( "Counter", Format ( LastScenario + 1, "NZ=; NG=" ) ) );
	
endprocedure 

&atclient
procedure ScenariosProcessed ( Params ) export
	
	broadcastChanges ();
	Close ( true );
	
endprocedure 

&atclient
procedure ReadingComplete ( Document ) export
	
	FilesContent [ CurrentFile.Extension ] = Document.GetText ();
	loadFiles ();
	
endprocedure 

&atservernocontext
function updateScenario ( val Application, val IsCommon, val Parent, val Path, val Content, val Type, val Remove, val UTC, val SourceFile )
	
	targetApplication = ? ( IsCommon, Catalogs.Applications.EmptyRef (), Application );
	scenario = getScenario ( Path, targetApplication );
	wasDeleted = ? ( scenario = undefined, false, DF.Pick ( scenario, "DeletionMark" ) );
	if ( Remove ) then
		if ( scenario <> undefined
			and not wasDeleted ) then
			deleteScenario ( scenario );
		endif; 
		return undefined;
	endif;
	isNew = scenario = undefined;
	if ( isNew ) then
		obj = Catalogs.Scenarios.CreateItem ();
		loadFields ( obj, Path, Parent );
	else
		if ( Catalogs.Scenarios.Locked ( scenario ) ) then
			raise Output.LoadingError ();
		endif;
		Catalogs.Versions.Create ( scenario, Output.LoadingProcessVersionMemo () );
		obj = scenario.GetObject ();
		obj.DeletionMark = false;
	endif;
	obj.Application = targetApplication;
	obj.Type = Type;
	if ( not IsCommon ) then
		loadProperties ( obj, Content, SourceFile + RepositoryFiles.JSONFile () );
		loadScript ( obj, Content );
		loadTemplate ( obj, Content );
	endif;
	Catalogs.Scenarios.SetSorting ( obj );
	Catalogs.Scenarios.UpdateFiles ( obj );
	obj.DataExchange.Load = true;
	if ( not Catalogs.Scenarios.CheckDoubles ( obj ) ) then
		raise Output.LoadingError ();
	endif;
	obj.Changed = UTC;
	obj.Write ();
	obj.FullExchange ();
	ref = obj.Ref;
	ExchangePlans.Repositories.Sync ( ref, targetApplication, true );
	if ( isNew ) then
		InformationRegisters.Editing.Lock ( SessionParameters.User, ref );
	endif;
	return ref;
	
endfunction

&atservernocontext
function getScenario ( Path, Application )
	
	s = "
	|select top 1 Scenarios.Ref as Ref
	|from Catalog.Scenarios as Scenarios
	|where Scenarios.Path = &Path
	|and Scenarios.Application = &Application
	|";
	q = new Query ( s );
	q.SetParameter ( "Path", Path );
	q.SetParameter ( "Application", Application );
	table = q.Execute ().Unload ();
	return ? ( table.Count () = 0, undefined, table [ 0 ].Ref );
	
endfunction

&atservernocontext
procedure deleteScenario ( Scenario )
	
	if ( Catalogs.Scenarios.Locked ( Scenario ) ) then
		raise Output.LoadingError ();
	endif;
	obj = Scenario.GetObject ();
	obj.DataExchange.Load = true;
	obj.DeletionMark = true;
	obj.Write ();
	obj.FullExchange ();
	application = obj.Application;
	ExchangePlans.Repositories.Sync ( Scenario, application, true );
	if ( not obj.Tree ) then
		return;
	endif;
	if ( application.IsEmpty () ) then
		for each reference in Catalogs.Scenarios.ApplicationsInside ( Scenario, application ) do
			alreadyHappened = reference = application;
			ExchangePlans.Repositories.Sync ( Scenario, reference, alreadyHappened );
			Catalogs.Scenarios.RemoveFile ( Scenario, reference, undefined, true, alreadyHappened );
		enddo;
	endif;
	if ( not Catalogs.Scenarios.DeleteChildren ( Scenario, application ) ) then
		Output.LoadingError ();
	endif;

endprocedure

&atservernocontext
procedure loadFields ( Obj, Path, Parent )
	
	Obj.SetNewCode ();
	Obj.Creator = SessionParameters.User;
	Obj.Path = Path;
	parts = StrSplit ( Path, "." );
	level = parts.UBound ();
	Obj.Description = parts [ level ];
	Obj.Parent = Parent;
	
endprocedure 

&atservernocontext
procedure loadProperties ( Scenario, Content, File )
	
	s = Content [ RepositoryFiles.JSONFile () ];
	if ( s = undefined ) then
		return;
	endif;
	try
		DataProcessors.Load.Properties ( s, Scenario );
	except
		raise Output.ScenarioPropertiesLoadingError ( new Structure ( "File, Error", File, ErrorDescription () ) );
	endtry;

endprocedure 

&atservernocontext
procedure loadScript ( Scenario, Content )
	
	Scenario.Script = Content [ RepositoryFiles.BSLFile () ];

endprocedure 

&atservernocontext
procedure loadTemplate ( Scenario, Content )
	
	address = Content [ RepositoryFiles.MXLFile () ];
	if ( address = undefined ) then
		DataProcessors.Load.ResetTemplate ( Scenario );
	else
		DataProcessors.Load.AssembleTemplate ( address, Scenario );
	endif; 

endprocedure 

// *****************************************
// *********** Group Tree

&atclient
procedure MarkAll ( Command )
	
	checkbox ( ChangesTree.GetItems (), true );
	
endprocedure

&atclient
procedure checkbox ( Rows, Value )
	
	for each row in Rows do
		if ( row.Usage ) then
			row.Use = Value;
		endif; 
		next = row.GetItems ();
		if ( next.Count () > 0 ) then
			checkbox ( next, Value );
		endif; 
	enddo; 
	
endprocedure 

&atclient
procedure UnmarkAll ( Command )
	
	checkbox ( ChangesTree.GetItems (), false );
	
endprocedure

&atclient
procedure ChangesTreeBeforeAddRow ( Item, Cancel, Clone, Parent, Folder, Parameter )
	
	Cancel = true;
	
endprocedure

&atclient
procedure ChangesTreeBeforeDeleteRow ( Item, Cancel )
	
	Cancel = true;
	
endprocedure

#endif
