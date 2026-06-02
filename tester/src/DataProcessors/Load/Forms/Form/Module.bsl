&atclient
var TableRow export;
&atclient
var ApplicationIndex;
&atclient
var ApplicationLastIndex;
&atclient
var FilesIndex;
&atclient
var FilesLastIndex;
&atclient
var FilesArray;
&atclient
var CurrentFile;
&atclient
var CurrentExtension;
&atclient
var CurrentObjectName;
&atclient
var ChangedRepositories;
&atclient
var ChangedScenarios;
&atclient
var PathBegins;
&atclient
var FolderSuffix;

// *****************************************
// *********** Form events

&atserver
procedure OnCreateAtServer ( Cancel, StandardProcessing )
	
	loadRepositories ();
	
endprocedure

&atserver
procedure loadRepositories ()
	
	s = "select allowed Repositories.Application as Application, Repositories.Folder as Folder,
	|	case when Settings.Application is null then false else true end as Use
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
	q = new Query ( s );
	q.SetParameter ( "User", SessionParameters.User );
	q.SetParameter ( "Session", SessionParameters.Session );
	Object.Repositories.Load ( q.Execute ().Unload () );
	
endprocedure 

&atclient
procedure Proceed () export
	
	prepareForm ();
	if ( MCPRequestProcessing = true and not CheckFilling () ) then
		raise Output.LoadingFilesCheckFillingError ();
	endif;
	startLoading ();
	
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
	
	FolderSuffix = RepositoryFiles.FolderSuffix ();
	
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
procedure Load ( Command )
	
	if ( CheckFilling () ) then
		startLoading ();
	endif; 
		
endprocedure

&atclient
procedure startLoading ()

	init ();
	loadApplications ();

endprocedure

&atclient
procedure init ()
	
	ApplicationIndex = -1;
	ApplicationLastIndex = Object.Repositories.Count () - 1;
	ChangedRepositories = new Array ();
	
endprocedure 

&atclient
procedure loadApplications ()
	
	ApplicationIndex = ApplicationIndex + 1;
	if ( ApplicationIndex > ApplicationLastIndex ) then
		openChanges ();
		return;
	endif; 
	repo = Object.Repositories [ ApplicationIndex ];
	folder = repo.Folder;
	if ( repo.Use ) then
		ChangedScenarios = new Array ();
		PathBegins = StrLen ( folder ) + 2;
		ChangedRepositories.Add ( new Structure ( "Application, Changes", repo.Application, ChangedScenarios ) );
	else
		loadApplications ();
		return;
	endif; 
	BeginFindingFiles ( new NotifyDescription ( "FindingFiles", ThisObject ), folder, "*.*", true );
	
endprocedure 

&atclient
procedure openChanges ()
	
	OpenForm ( "DataProcessor.Load.Form.Changes",
		new Structure ( "Changes, Silent", ChangedRepositories, Parameters.Silent ), ThisObject, , , ,
		new NotifyDescription ( "AfterApplyingChanges", ThisObject ) );
	
endprocedure 

&atclient
procedure AfterApplyingChanges ( Result, Params ) export
	
	if ( Result <> undefined
		and Result ) then
		Close ();
	endif; 
	
endprocedure 

&atclient
procedure FindingFiles ( Files, Params ) export
	
	FilesIndex = -1;
	FilesLastIndex = Files.Count () - 1;
	FilesArray = Files;
	loadFiles ();
	
endprocedure 

&atclient
procedure loadFiles ()
	
	while ( true ) do
		FilesIndex = FilesIndex + 1;
		if ( FilesIndex > FilesLastIndex ) then
			loadApplications ();
			return;
		endif; 
		CurrentFile = FilesArray [ FilesIndex ];
		CurrentExtension = CurrentFile.Extension;
		CurrentObjectName = RepositoryFiles.FileToName ( CurrentFile.Name );
		if ( validFile () ) then
			CurrentFile.BeginGettingModificationUniversalTime ( new NotifyDescription ( "GettingModificationUniversalTime", ThisObject ) );
			return;
		endif; 
	enddo;
	
endprocedure 

&atclient
function validFile ()
	
	return CurrentExtension = RepositoryFiles.BSLFile ()
	or CurrentExtension = RepositoryFiles.MXLFile ()
	or CurrentExtension = RepositoryFiles.JSONFile ();
	
endfunction 

&atclient
procedure GettingModificationUniversalTime ( Time, Params ) export
	
	enrollChanges ( Time );
	loadFiles ();
	
endprocedure 

&atclient
procedure enrollChanges ( UTC )
	
	p = new Structure ();
	p.Insert ( "Path", RepositoryFiles.FileToPath ( CurrentFile.FullName, PathBegins ) );
	p.Insert ( "File", FileSystem.GetBaseName ( CurrentFile.FullName ) );
	p.Insert ( "Extension", CurrentExtension );
	p.Insert ( "UTC", UTC );
	ChangedScenarios.Add ( p );
	
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
