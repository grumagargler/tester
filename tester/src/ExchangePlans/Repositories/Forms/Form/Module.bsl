// *****************************************
// *********** Form events
&atserver
procedure OnCreateAtServer(Cancel, StandardProcessing)

	if (Object.Ref.IsEmpty()) then
		fillNew();
	endif;

endprocedure

&atserver
procedure fillNew()

	if (not Parameters.CopyingValue.IsEmpty()) then
		return;
	endif;
	if (Object.Session.IsEmpty()) then
		Object.Session = SessionParameters.Session;
	endif;
	if (Object.Application.IsEmpty()) then
		Object.Application = EnvironmentSrv.GetApplication();
	endif;
	setNode();
	InitFolder = true;

endprocedure

&atserver
procedure setNode()

	session = Object.Session;
	if (session.IsEmpty()) then
		return;
	endif;
	data = nodeData();
	Object.Code = TrimR(data.ApplicationCode) + TrimR(data.UserCode)
		+ Conversion.CodeToNumber(data.SessionCode);
	Object.Description = data.ApplicationName + ": " + data.UserName + " ("
		+ session + ")";

endprocedure

&atserver
function nodeData()

	result = new Structure("SessionCode, UserName, UserCode, ApplicationName, ApplicationCode");
	q = new Query();
	q.SetParameter("Session", Object.Session);
	application = Object.Application;
	q.SetParameter("Application", application);
	s = "select Sessions.Code as SessionCode, Sessions.User.Code as UserCode,
		|	Sessions.User.Description as UserName
		|from Catalog.Sessions as Sessions
		|where Sessions.Ref = &Session";
	if (application.IsEmpty()) then
		q.Text = s;
		FillPropertyValues(result, Conversion.RowToStructure(q.Execute().Unload()));
		result.ApplicationCode = Output.CommonApplicationCode();
		result.ApplicationName = Output.CommonApplicationName();
	else
		s = s + ";
			|select Applications.Code as ApplicationCode, Applications.Description as ApplicationName
			|from Catalog.Applications as Applications
			|where Applications.Ref = &Application";
		q.Text = s;
		data = q.ExecuteBatch();
		FillPropertyValues(result, Conversion.RowToStructure(data[0].Unload()));
		FillPropertyValues(result, Conversion.RowToStructure(data[1].Unload()));
	endif;
	return result;

endfunction

&atserver
procedure FillCheckProcessingAtServer(Cancel, CheckedAttributes)

	if (not checkFolder()) then
		Cancel = true;
		return;
	endif;

endprocedure

&atserver
function checkFolder()

	folder = Object.Folder;
	if (IsBlankString(folder)) then
		return true;
	endif;
	folders = getFolders();
	folder1 = Lower(Object.Folder);
	for each folder in folders do
		folder2 = Lower(folder.Folder);
		overlapped = (folder1 = folder2);
		if (overlapped) then
			Output.WrongRepoFolder1(new Structure("Folder1, Folder2", folder1, folder2), "Folder", , "Object");
			return false;
		endif;
		inside = (StrStartsWith(folder1, folder2)
			or StrStartsWith(folder2, folder1))
			and StrSplit(folder1, "/\").Count() <> StrSplit(folder2, "/\").Count();
		if (inside) then
			Output.WrongRepoFolder2(new Structure("Folder1, Folder2", folder1, folder2), "Folder", , "Object");
			return false;
		endif;
	enddo;
	return true;

endfunction

&atserver
function getFolders()

	s = "select allowed Repositories.Folder as Folder, Repositories.Application as Application
		|from ExchangePlan.Repositories as Repositories
		|where Repositories.Ref <> &Ref
		|and Repositories.Session = &Session
		|and Repositories.Folder not like """"
		|";
	q = new Query(s);
	q.SetParameter("Session", Object.Session);
	q.SetParameter("Ref", Object.Ref);
	return q.Execute().Unload();

endfunction

&atclient
procedure AfterWrite(WriteParameters)

	restartWatcher();
	if ( InitFolder
		or Object.Mapping ) then
		file = Object.Folder + GetPathSeparator () + RepositoryFiles.Gitignore ();
		LocalFiles.CheckExistence ( file, new NotifyDescription ( "GitignoreExists", ThisObject, file ) );
	endif;

endprocedure

&atclient
procedure restartWatcher()

	#if ( not WebClient ) then
	if (myRepositry(Object.Session)) then
		Watcher.Init();
	endif;
	#endif

endprocedure

&atservernocontext
function myRepositry(val Session)

	return Session = SessionParameters.Session;

endfunction

&atclient
procedure GitignoreExists ( Exists, File ) export
	
	#if ( not MobileClient ) then
		if ( not Exists ) then
			text = new TextDocument ();
			text.SetText ( RepositoryFiles.SystemFolder () + "/" );
			text.Write ( File );
		endif;
		createBSLSettings ();
	#endif
	
endprocedure

&atclient
procedure createBSLSettings ()
	
	settings = new Structure ();
	lang = CurrentLanguage ();
	settings.Insert ( "language", lang );
	settings.Insert ( "diagnosticLanguage", lang );
	diagnostics = new Structure ();
	// https://1c-syntax.github.io/bsl-language-server/diagnostics/
	diagnostics.Insert ( "computeTrigger", "onType" );
	p = new Structure ();
	p.Insert ( "CanonicalSpellingKeywords", false );
	p.Insert ( "IfElseIfEndsWithElse", false );
	p.Insert ( "UsingSynchronousCalls", false );
	p.Insert ( "BeginTransactionBeforeTryCatch", false );
	p.Insert ( "CommitTransactionOutsideTryCatch", false );
	p.Insert ( "DeprecatedMessage", false );
	p.Insert ( "MagicNumber", false );
	p.Insert ( "MethodSize", false );
	p.Insert ( "SpaceAtStartComment", false );
	p.Insert ( "TimeoutsInExternalResources", false );
	p.Insert ( "UnreachableCode", false );
	p.Insert ( "UsingFindElementByString", false );
	p.Insert ( "UsingHardcodeNetworkAddress", false );
	p.Insert ( "UsingHardcodePath", false );
	p.Insert ( "UsingHardcodeSecretInformation", false );
	p.Insert ( "UsingModalWindows", false );
	p.Insert ( "UsingObjectNotAvailableUnix", false );
	p.Insert ( "UsingSynchronousCalls", false );
	p.Insert ( "YoLetterUsage", false );
	p.Insert ( "MissingCodeTryCatchEx", false );
	p.Insert ( "CodeBlockBeforeSub", false );
	p.Insert ( "CommentedCode", false );
	p.Insert ( "DeprecatedCurrentDate", false );
	diagnostics.Insert ( "parameters", p );
	settings.Insert ( "diagnostics", diagnostics );
	file = Object.Folder + GetPathSeparator () + TesterWatcherBSLServerSettings;
	text = new TextDocument ();
	text.SetText ( Conversion.ToJSON ( settings ) );
	text.Write ( file, , Chars.LF );

endprocedure

// *****************************************
// *********** Group Form
&atclient
procedure SessionOnChange(Item)

	setNode();

endprocedure

&atclient
procedure ApplicationOnChange(Item)

	setNode();

endprocedure

&atclient
procedure FolderStartChoice(Item, ChoiceData, StandardProcessing)

	StandardProcessing = false;
	chooseFolder();

endprocedure

&atclient
procedure chooseFolder()

	dialog = new FileDialog(FileDialogMode.ChooseDirectory);
	dialog.Show(new NotifyDescription("selectFolder", ThisObject));

endprocedure

&atclient
procedure selectFolder(Folder, Params) export

	if (Folder = undefined) then
		return;
	endif;
	Object.Folder = Folder[0];

endprocedure

&atclient
procedure FolderOnChange(Item)

	adjustPath();

endprocedure

&atclient
procedure adjustPath()

	Object.Folder = FileSystem.RemoveSlash(Object.Folder);

endprocedure

