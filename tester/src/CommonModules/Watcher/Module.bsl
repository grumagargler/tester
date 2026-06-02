procedure Init () export

	stopWatching ();
	type = "AddIn.Extender.Watcher";
	try
		lib = new ( type );
	except
		return;
	endtry;
	FoldersWatchdog = new Map ();
	data = WatcherSrv.Repositories ();
	apps = data.Applications;
	folders = data.Folders;
	mapped = data.Mapped;
	slash = GetPathSeparator ();
	testerFolder = slash + TesterSystemFolder + slash;
	for i = 0 to apps.UBound () do
		folder = folders [ i ];
		DeleteFiles ( folder + testerFolder, "*" );
		lib = new ( type );
		mapping = mapped [ i ];
		FoldersWatchdog [ apps [ i ] ] =
			new Structure ( "Lib, Folder, Mapped", lib, folder, mapping );
		lib.Start ( folder, mapping );
	enddo;

endprocedure

procedure stopWatching ()

	if ( FoldersWatchdog = undefined ) then
		return;
	endif;
	for each item in FoldersWatchdog do
		// There is only one right way to clean the mess properly:
		// - stop thread
		// - execute destructor
		if ( item.Value.Mapped ) then
			item.Value.Lib.Stop ();
		endif;
		item.Value.Lib = undefined;
	enddo;
	FoldersWatchdog = undefined;

endprocedure

procedure Proceed ( Event, Path ) export

	// List of Events:
	// Added = 1
	// Removed = 2
	// Changed = 3
	// RenamedOld = 4
	// RenamedNew = 5
	// FolderAdded = 6
	// FolderRemoved = 7
	// FolderChanged = 8
	// FolderRenamedOld = 9
	// FolderRenamedNew = 0
	// WatcherEntryRemoved = a
	// WatcherEntryMoved = b
	// VolumeUnmounted = c
	// WatcherOverflow = d
	// WatcherDisconnected = e

	if ( externalRequest ( Path ) ) then
		if ( Event = "1" or Event = "3" ) then
			if ( newRequest ( Path ) ) then
				proceedRequest ();
			endif;
		endif;
	elsif ( myResponse ( Path )
		or systemChanges ( Path ) ) then
		return;
	else
		if ( Event = "3" ) then
			proceedChanging ( Path );
		elsif ( Event = "6" ) then
			proceedCreating ( Path, true );
		elsif ( Event = "1" ) then
			proceedCreating ( Path, false );
		elsif ( Event = "4" or Event = "9" ) then
			TesterExternalRequestsRenaming = Path;
		elsif ( Event = "5" ) then
			proceedRenaming ( Path, false );
		elsif ( Event = "0" ) then
			proceedRenaming ( Path, true );
		elsif ( Event = "2" or Event = "7" ) then
			proceedRemoving ( Path );
		endif;
	endif;

endprocedure

function myResponse ( Path )

	return StrEndsWith ( Path, TesterExternalResponses );

endfunction

function systemChanges ( Path )

	return StrFind ( Path, TesterGitMask ) > 0
	or StrStartsWith ( FileSystem.GetFileName ( Path ), "." )
	or StrEndsWith ( Path, TesterWatcherBSLServerSettings );

endfunction

function externalRequest ( Path )

	return StrEndsWith ( Path, TesterExternalRequests );

endfunction

function newRequest ( Path )

	request = Conversion.FromJSON ( readFile ( Path, RepositoryFiles.BSLFile () ) );
	if ( TesterExternalRequestObject <> undefined
			and TesterExternalRequestObject.ID = request.ID ) then
		return false;
	endif;
	TesterExternalRequestObject = request;
	TesterExternalRequestsApplication = FindApplication ( Path );
	return true;

endfunction

function FindApplication ( File ) export

	if ( FoldersWatchdog = undefined ) then
		return undefined;
	endif;
	for each item in FoldersWatchdog do
		path = StrReplace ( File, "\", "/" );
		folder = StrReplace ( item.Value.Folder, "\", "/" );
		if ( StrStartsWith ( path, folder ) ) then
			return item;
		endif;
	enddo;

endfunction

procedure proceedRequest ()

	request = TesterExternalRequestObject.Request;
	if ( request = Enum.ExternalRequestsRun () ) then
		runTesting ();
	elsif ( request = Enum.ExternalRequestsRunSelected () ) then
		runSelected ();
	else
		TesterServerMode = true;
		if ( request = Enum.ExternalRequestsSaveBeforeCheckSyntax ()
				or request = Enum.ExternalRequestsSaveBeforeRun ()
				or request = Enum.ExternalRequestsSaveBeforeRunSelected ()
				or request = Enum.ExternalRequestsSaveBeforeAssigning () ) then
			SendResponse ();
		elsif ( request = Enum.ExternalRequestsSetMain () ) then
			setMain ();
		elsif ( request = Enum.ExternalRequestsCheckSyntax () ) then
			checkSyntax ();
		elsif ( request = Enum.ExternalRequestsPickField () ) then
			pickField ();
		elsif ( request = Enum.ExternalRequestsPickScenario () ) then
			pickScenario ();
		elsif ( request = Enum.ExternalRequestsGenerateID () ) then
			generateID ();
		else
			undefinedRequest ();
		endif;
		TesterServerMode = false;
	endif;

endprocedure

procedure runTesting ()

	// Client session will not survive if exception happens in ExternalEvent processing
	DetachIdleHandler ( "TesterRunsMainScenario" );
	AttachIdleHandler ( "TesterRunsMainScenario", 0.1, true );

endprocedure

procedure setMain ()

	file = TesterExternalRequestObject.File;
	scenario = WatcherSrv.FindScenario ( SyncingContext ( File ) );
	if ( scenario = undefined ) then
		syncingResponse ( Output.UndefinedScenario ( new Structure ( "File", file ) ) );
	else
		Environment.ChangeScenario ( scenario );
		SendResponse ();
	endif;

endprocedure

function SyncingContext ( File, Removing = false ) export

	p = new Structure ( "Application, File, Extension, Path, Changed" );
	p.Application = TesterExternalRequestsApplication.Key;
	p.File = File;
	p.Extension = FileSystem.Extension ( File );
	p.Path = RepositoryFiles.FileToPath ( File, StrLen ( TesterExternalRequestsApplication.Value.Folder ) + 2 );
	if ( not Removing ) then
		handler = new File ( File );
		p.Changed = handler.GetModificationUniversalTime ();
	endif;
	return p;

endfunction

procedure syncingResponse ( Error )

	Message ( Error );
	AddMessage ( Error, Enum.MessageTypesPopupWarning () );
	SendResponse ();

endprocedure

procedure runSelected ()

	file = TesterExternalRequestObject.File;
	scenario = WatcherSrv.FindScenario ( SyncingContext ( File ) );
	if ( scenario = undefined ) then
		syncingResponse ( Output.UndefinedScenario ( new Structure ( "File", file ) ) );
	else
		TesterExternalRequestsScenario = scenario;
		// Client session will not survive if exception happens in ExternalEvent processing
		DetachIdleHandler ( "TesterRunsSelectedScript" );
		AttachIdleHandler ( "TesterRunsSelectedScript", 0.1, true );
	endif;

endprocedure

procedure checkSyntax ()

	file = TesterExternalRequestObject.File;
	error = Runtime.CheckSyntax ( readFile ( file, RepositoryFiles.BSLFile () ) );
	if ( error = undefined ) then
		AddMessage ( Output.ErrorsNotFound () );
	else
		ThrowError ( error );
	endif;
	SendResponse ();

endprocedure

function readFile ( File, Extension )

#if ( WebClient or MobileClient ) then
	raise Output.ClientDoesNotSupport ();
#else
	timeout = CurrentDate () + 7;
	while ( true ) do
		try
			if ( Extension = RepositoryFiles.MXLFile () ) then
				return new BinaryData ( File );
			else
				text = new TextReader ( File, TextEncoding.UTF8, , , true );
				data = text.Read ();
				return ? ( data = undefined, "", data );
			endif;
		except
			if ( CurrentDate () > timeout ) then
				raise Output.FileReadingError ( new Structure ( "File", File ) );
			endif;
		endtry;
	enddo;
#endif

endfunction

procedure ThrowError ( Error, Scenario = undefined, Offset = 0 ) export

	range = errorRange ( Error, Offset );
	AddMessage ( range.Message, Enum.MessageTypesError (), Scenario, range.Line, range.Column );

endprocedure

function errorRange ( Text, Offset )

	i = StrFind ( Text, "{(" );
	j = StrFind ( Text, ")}" );
	core = Mid ( Text, i + 2, j - i - 2 );
	parts = StrSplit ( core, "," );
	message = Mid ( Text, j + 4 );
	return new Structure ( "Message, Line, Column", message, Offset + parts [ 0 ], parts [ 1 ] );

endfunction

procedure pickField ()

	response = prepareResponse ();
	try
		Test.Attach ();
		ok = true;
	except
		error = ErrorProcessing.BriefErrorDescription ( ErrorInfo () );
		ok = false;
	endtry;
	if ( ok ) then
		insertFields ( response );
	else
		AddMessage ( error, Enum.MessageTypesPopupWarning () );
	endif;
	SendResponse ( response );

endprocedure

procedure insertFields ( Response )

	result = new Structure ( "Set, Language, Current" );
	controls = getControls ();
	if ( controls <> undefined ) then
		FillPropertyValues ( result, controls );
	endif;
	result.Language = CurrentLanguage ();
	Response.Insert ( "Fields", result );

endprocedure

function getControls ()

	set = new Array ();
	try
		objects = App.GetActiveWindow ().FindObjects ();
	except
		AddMessage ( ErrorDescription (), Enum.MessageTypesPopupWarning () );
		return undefined;
	endtry;
	currentItem = undefined;
	currentControl = undefined;
	for each control in objects do
		field = new Structure ( "Name, Type, TitleText, TypeDescription" );
		FillPropertyValues ( field, control );
		field.Type = ScenarioForm.FieldType ( control, true );
		type = ScenarioForm.FieldType ( control );
		if ( type = PredefinedValue ( "Enum.Controls.Form" ) ) then
			field.Name = "<" + control.FormName + ">";
			try
				currentItem = control.GetCurrentItem ();
			except
				currentItem = undefined;
			endtry;
		endif;
		field.TypeDescription = String ( type );
		text = control.TitleText;
		field.TitleText = text;
		if ( field.Name = undefined ) then
			field.Name = text;
		endif;
		if ( currentItem = control ) then
			currentControl = field.Name;
		endif;
		set.Add ( field );
	enddo;
	return new Structure ( "Set, Current", set, currentControl );

endfunction

procedure pickScenario ()

	if ( TesterExternalRequestObject.Method = "Run" ) then
		file = TesterExternalRequestObject.File;
		scenario = WatcherSrv.FindScenario ( SyncingContext ( File ) );
		if ( scenario = undefined ) then
			syncingResponse ( Output.UndefinedScenario ( new Structure ( "File", file ) ) );
			return;
		endif;
	else
		scenario = undefined;
	endif;
	response = prepareResponse ();
	response.Insert ( "Scenarios", WatcherSrv.GetMethods ( scenario ) );
	SendResponse ( response );

endprocedure

procedure generateID ()

	response = prepareResponse ();
	response.Insert ( "GeneratedID", TestingID () );
	SendResponse ( response );

endprocedure

procedure undefinedRequest ()

	AddMessage ( Output.UndefinedExternalRequest (), Enum.MessageTypesPopupWarning () );
	SendResponse ();

endprocedure

procedure proceedChanging ( File )

	if ( unchanged ( File )
		or not validFile ( File, false ) ) then
		return;
	endif;
	TesterExternalRequestsApplication = FindApplication ( File );
	error = undefined;
	context = SyncingContext ( File );
	scenario = WatcherSrv.Update ( context, readFile ( File, context.Extension ), error );
	if ( error <> undefined ) then
		syncingResponse ( error );
		return;
	endif;
	if ( scenario <> undefined ) then
		broadcast ( scenario );
	endif;
	if ( savingRequest ( File ) ) then
		comleteSaving ();
	endif;

endprocedure

function unchanged ( File )

	external = Number ( ExternalLibrary.GetHash ( File ) );
	internal = WatcherSrv.GetContent ( Number ( ExternalLibrary.GetStringHash ( File, false ) ) );
	return external = internal;

endfunction

function validFile ( File, IsFolder )

	if ( IsFolder ) then
		return StrFind ( FileSystem.GetFileName ( File ), "." ) = 0;
	else
		entry = new File ( File );
		name = entry.BaseName;
		if ( name = "" or StrStartsWith ( name, "." ) ) then
			return false;
		endif;
		ext = FileSystem.Extension ( File );
		return ext = RepositoryFiles.BSLFile ()
		or ext = RepositoryFiles.MXLFile ()
		or ext = RepositoryFiles.JSONFile ();
	endif;

endfunction

procedure broadcast ( Them )

	DetachIdleHandler ( "TesterWatcherBroadcasting" );
	TesterExternalBroadcasting = them;
	AttachIdleHandler ( "TesterWatcherBroadcasting", 0.5, true );

endprocedure

function savingRequest ( File )

	return TesterExternalRequestObject <> undefined
		and ( TesterExternalRequestObject.Request = Enum.ExternalRequestsSaveBeforeCheckSyntax ()
		or TesterExternalRequestObject.Request = Enum.ExternalRequestsSaveBeforeRun ()
		or TesterExternalRequestObject.Request = Enum.ExternalRequestsSaveBeforeRunSelected ()
		or TesterExternalRequestObject.Request = Enum.ExternalRequestsSaveBeforeAssigning () )
		and Lower ( TesterExternalRequestObject.File ) = Lower ( File );

endfunction

procedure comleteSaving ()

	response = prepareResponse ();
	response.TransactionComplete = true;
	TesterExternalRequestObject = undefined;
	SendResponse ( response );

endprocedure

function prepareResponse ()

	response = new Structure ();
	if ( TesterExternalRequestObject <> undefined ) then
		response.Insert ( "Request", Collections.CopyStructure ( TesterExternalRequestObject ) );
	endif;
	response.Insert ( "Status", Enum.ExternalStatusesCompleted () );
	response.Insert ( "TransactionComplete", false );
	response.Insert ( "Messages" );
	return response;

endfunction

procedure proceedCreating ( File, IsFolder )

	if ( not validFile ( File, IsFolder ) ) then
		return;
	endif;
	TesterExternalRequestsApplication = FindApplication ( File );
	if ( not checkName ( File ) ) then
		return;
	endif;
	error = undefined;
	context = SyncingContext ( File );
	changes = WatcherSrv.Create ( context, IsFolder, error );
	if ( error <> undefined ) then
		syncingResponse ( error );
		return;
	endif;
	if ( IsFolder ) then
		uploadFiles ( File );
	endif;
	broadcast ( changes );

endprocedure

function checkName ( Name )

	if ( not ScenarioForm.CheckName ( RepositoryFiles.FileToName ( Name ) ) ) then
		error = Output.WatcherFileNameError ( new Structure ( "File", Name ) );
		syncingResponse ( error );
		return false;
	endif;
	return true;

endfunction

procedure uploadFiles ( Folder )

	files = FindFiles ( Folder, "*.*" );
	for each file in files do
		isFolder = file.IsDirectory ();
		path = file.FullName;
		proceedCreating ( path, isFolder );
		if ( not isFolder ) then
			proceedChanging ( path );
		endif;
	enddo;

endprocedure

procedure proceedRenaming ( NewFile, IsFolder )

	if ( not validFile ( NewFile, IsFolder ) ) then
		return;
	endif;
	oldFile = TesterExternalRequestsRenaming;
	if ( not validFile ( oldFile, IsFolder ) ) then
		proceedCreating ( NewFile, IsFolder );
		proceedChanging ( NewFile );
		return;
	endif;
	TesterExternalRequestsApplication = FindApplication ( oldFile );
	if ( not checkName ( NewFile ) ) then
		return;
	endif;
	if ( renamingDirFile () ) then
		error = Output.WatcherRenamingFolderError ( new Structure ( "File", oldFile ) );
		syncingResponse ( error );
		return;
	elsif ( renamingDependencies ( IsFolder, NewFile ) ) then
		return;
	endif;
	error = undefined;
	context = SyncingContext ( oldFile, true );
	scenario = WatcherSrv.Rename ( context, NewFile, RepositoryFiles.FileToPath ( NewFile, StrLen ( TesterExternalRequestsApplication.Value.Folder ) + 2 ), IsFolder, error );
	if ( error <> undefined ) then
		syncingResponse ( error );
		return;
	endif;
	broadcast ( scenario );
	syncRenaming ( NewFile, IsFolder );

endprocedure

function renamingDirFile ()

	oldFile = TesterExternalRequestsRenaming;
	renameFolder = StrFind ( oldFile, RepositoryFiles.FolderSuffix () );
	if ( renameFolder ) then
		folder = FileSystem.GetParent ( FileSystem.GetParent ( oldFile ) ) + GetPathSeparator () + RepositoryFiles.FileToName ( oldFile );
		folders = FindFiles ( folder );
		if ( folders.Count () = 1 ) then
			return true;
		endif;
	endif;
	return false;

endfunction

function renamingDependencies ( IsFolder, NewFile )

	return not IsFolder and StrFind ( NewFile, RepositoryFiles.FolderSuffix () );

endfunction

procedure syncRenaming ( NewFile, IsFolder )

	oldFile = TesterExternalRequestsRenaming;
	folderSuffix = RepositoryFiles.FolderSuffix ();
	oldName = FileSystem.GetBaseName ( FileSystem.GetFileName ( OldFile ) );
	newName = FileSystem.GetBaseName ( FileSystem.GetFileName ( NewFile ) );
	if ( IsFolder ) then
		suffix = folderSuffix;
		files = FindFiles ( NewFile, oldName + ".*" );
	else
		suffix = "";
		files = FindFiles ( FileSystem.GetParent ( NewFile ), oldName + ".*" );
	endif;
	for each file in files do
		if ( not IsFolder and StrFind ( file.Name, folderSuffix ) > 0 ) then
			continue;
		endif;
		MoveFile ( file.FullName, file.Path + newName + suffix + file.Extension );
	enddo;

endprocedure

procedure proceedRemoving ( File )

	if ( not validRemoving ( File ) ) then
		return;
	endif;
	TesterExternalRequestsApplication = FindApplication ( File );
	error = undefined;
	context = SyncingContext ( File, true );
	scenario = WatcherSrv.Remove ( context, error );
	if ( error <> undefined ) then
		syncingResponse ( error );
		return;
	endif;
	broadcast ( scenario );

endprocedure

function validRemoving ( File )

	ext = FileSystem.Extension ( File );
	return ext = RepositoryFiles.BSLFile () or ext = RepositoryFiles.MXLFile ()
		or ext = RepositoryFiles.JSONFile () or ext = "";

endfunction

procedure SendResponse ( Response = undefined ) export

#if ( WebClient ) then
	raise Output.WebClientDoesNotSupport ();
#else
	path = TesterExternalRequestsApplication.Value.Folder + GetPathSeparator () + TesterExternalResponses;
	file = new File ( FileSystem.GetParent ( path ) );
	if ( not file.Exist () ) then
		return;
	endif;
	if ( Response = undefined ) then
		answer = prepareResponse ();
	else
		answer = Response;
	endif;
	writer = new TextWriter ( path );
	answer.Messages = FlushServerMessages ();
	writer.Write ( Conversion.ToJSON ( answer, false ) );
#endif

endprocedure

function FlushServerMessages () export

	if ( MCPRequestProcessing ) then
		messages = new Structure ();
		try
			messages.Insert ( "application_messages", App.GetActiveWindow ().GetUserMessageTexts () );
		except
		endtry;
		if ( TesterServerMessages <> undefined ) then
			runtimeMessages = new Array ();
			for each msg in TesterServerMessages do
				runtimeMessages.Add ( new Structure ( "Severity, Message, File, Line, Column",
					messageType ( msg.Type ), msg.Text, msg.File, msg.Line, msg.Column ) );
			enddo;
			messages.Insert ( "runtime_messages", runtimeMessages );
		endif;
	else
		list = new ValueList ();
		list.LoadValues ( TesterServerMessages );
		messages = messages.UnloadValues ();
	endif;
	TesterServerMessages = undefined;
	return messages;

endfunction

function messageType ( Type )

	if ( Type = Enum.MessageTypesInfo () ) then
		return "Information";
	elsif ( Type = Enum.MessageTypesError () ) then
		return "Error";
	elsif ( Type = Enum.MessageTypesWarning () ) then
		return "Warning";
	elsif ( Type = Enum.MessageTypesHint () ) then
		return "Hint";
	elsif ( Type = Enum.MessageTypesPopup () ) then
		return "Popup";
	elsif ( Type = Enum.MessageTypesPopupWarning () ) then
		return "Popup Warning";
	else
		return "Undefined";
	endif;

endfunction

procedure AddMessage ( Text, Type = undefined, Scenario = undefined, Line = 1,
		Column = 1 ) export

	if ( Scenario = undefined ) then
		file = undefined;
	else
		file = scenarioFile ( Scenario );
		if ( file = undefined ) then
			return;
		endif;
	endif;
	if ( TesterServerMessages = undefined ) then
		TesterServerMessages = new Array ();
	endif;
	messageType = ? ( Type = undefined, Enum.MessageTypesPopup (), Type );
	p = new Structure ( "Text, Type, File, Line, Column", Text, messageType, file, Line, Column );
	TesterServerMessages.Add ( p );

endprocedure

function scenarioFile ( Scenario )

	if ( TypeOf ( Scenario ) = Type ( "String" ) ) then
		return Scenario;
	endif;
	error = "";
	file = RepositoryFiles.ScenarioFile ( Scenario, error );
	if ( file = undefined ) then
		AddMessage ( error, Enum.MessageTypesPopupWarning () );
	else
		return file + RepositoryFiles.BSLFile ();
	endif;

endfunction

procedure FetchChanges () export

	if ( FoldersWatchdog = undefined ) then
		return;
	endif;
	for each folder in FoldersWatchdog do
		try
			changes = folder.Value.Lib.GetChanges ();
		except
			Message ( folder.Value.Lib.Problem () );
			continue;
		endtry;
		data = WatcherSrv.ExtractIDs ( changes, folder.Key );
		for each file in data.Changes.File do
			proceedChanging ( file );
		enddo;
		for each file in data.New.File do
			proceedCreating ( file, false );
			proceedChanging ( file );
		enddo;
	enddo;

endprocedure
