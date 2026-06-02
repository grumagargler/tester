
function FolderSuffix () export
	
	return ".dir";
	
endfunction 

function MXLFile () export
	
	return ".mxl";
	
endfunction 

function BSLFile () export
	
	return ".bsl";
	
endfunction 

function JSONFile () export
	
	return ".json";
	
endfunction 

&atclient
function VSCodeWorkspace () export
	
	return ".code-workspace";
	
endfunction 

&atclient
function Gitignore () export
	
	return ".gitignore";
	
endfunction 

&atclient
function GitFolder () export
	
	return ".git";
	
endfunction 

&atclient
function BSLServerSettings () export
	
	return ".bsl-language-server.json";
	
endfunction 

&atserver
function Signature () export
	
	return "92b895ac-0620-4a28-a128-76e2bd1a5ca4";
	
endfunction 

&atclient
function SystemFolder () export
	
	return ".tester";
	
endfunction

function ScenarioFile ( Scenario, Error = undefined ) export
	
	if ( TypeOf ( Scenario ) = Type ( "CatalogRef.Scenarios" ) ) then
		if ( Scenario.IsEmpty () ) then
			return undefined;
		endif;
		data = DF.Values ( Scenario, "Application, Path, Type, Tree" );
	else
		data = Scenario;
	endif;
	folder = scenarioFolder ( data );
	if ( folder = undefined ) then
		Error = Output.ScenarioApplicationUnmapped ( new Structure ( "Path", data.Path ) );
		return undefined;
	endif;
	slash = GetClientPathSeparator ();
	path = StrReplace ( data.Path, ".", slash );
	parts = StrSplit ( path, slash );
	name = parts [ parts.UBound() ];
	if ( data.Tree ) then
		return folder + slash + path + slash + name + RepositoryFiles.FolderSuffix ();
	else
		return folder + slash + path;
	endif;
	
endfunction

function scenarioFolder ( Object )

	application = Object.Application;
	#if ( Server ) then
		q = new Query ( "
		|select Folder as Folder
		|from ExchangePlan.Repositories
		|where not DeletionMark
		|and Session = &Session
		|and Application = &Application
		|" );
		q.SetParameter ( "Session", SessionParameters.Session );
		q.SetParameter ( "Application", application );
		table = q.Execute ().Unload ();
		return ? ( table.Count () = 0, undefined, table [ 0 ].Folder );
	#else
		if ( FoldersWatchdog = undefined ) then
			return undefined;
		endif;
		node = FoldersWatchdog [ application ];
		return ? ( node = undefined, undefined, node.Folder );
	#endif

endfunction

&atclient
function FileToPath ( File, PathBegins ) export

	slash = GetPathSeparator ();
	name = FileSystem.GetFileName(File);
	id = Mid ( name, 1, StrFind ( name, "." ) - 1 );
	isFolder = StrFind ( name, RepositoryFiles.FolderSuffix () ) > 0;
	path = FileSystem.GetParent ( File ) + ? ( isFolder, "", slash + id );
	path = StrReplace ( Mid ( path, PathBegins ), slash, "." );
	return path;
	
endfunction

function FileToName ( File ) export
	
	name = FileSystem.GetFileName ( File );
	i = StrFind ( name, "." );
	return ? ( i = 0, name, Left ( name, i - 1 ) );
	
endfunction

&atclient
procedure Sync ( Callback = undefined ) export
	
	MCPCall = Callback <> undefined;
	nothingToSync = FoldersWatchdog = undefined or FoldersWatchdog.Count () = 0;
	if ( nothingToSync )  then
		if ( MCPCall ) then
			RunCallback ( Callback );
		endif;
	else
		RepositoryFilesSynchingCallback = Callback;
		startSyncing ();
	endif;
	
endprocedure

&atclient
procedure startSyncing ()
	
	GetForm ( "DataProcessor.Unload.Form", new Structure ( "Silent", true ) ).Proceed ();
	
endprocedure
