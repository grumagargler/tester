&atclient
var TableRow;
&atclient
var RowStart;
&atclient
var RowEnd;
&atclient
var ColumnStart;
&atclient
var ColumnEnd;
&atclient
var SelectionStart;
&atclient
var SelectionEnd;
&atclient
var FieldsRow;
&atclient
var FieldsMap;
&atclient
var TestedForm;
&atclient
var OldParent;

// *****************************************
// *********** Form events

&atserver
procedure OnReadAtServer ( CurrentObject )

	readMyself ( CurrentObject );

endprocedure

&atserver
procedure readMyself ( CurrentObject )

	iHook ();
	initTags ();
	readStatus ();
	restoreTemplate ( CurrentObject );
	Appearance.Apply ( ThisObject );

endprocedure

&atserver
procedure iHook ()

	WebHook = Constants.Webhook.Get () = Object.Ref;

endprocedure

&atserver
procedure initTags ()

	initTagsList ();
	initTagsFilter ();

endprocedure

&atserver
procedure initTagsList ()

	set = Items.TagsList.ChoiceList;
	tags = readTags ();
	if ( tags = undefined ) then
		set.Clear ();
	else
		insertTag ( tags, set );
	endif;

endprocedure

&atserver
function readTags ()

	tag = Object.Tag;
	if ( tag.IsEmpty () ) then
		return undefined;
	endif;
	s = "
	|select Tags.Tag.Description as Tag
	|from Catalog.TagKeys.Tags as Tags
	|where Tags.Ref = &Key
	|and not Tags.Tag.DeletionMark
	|";
	q = new Query ( s );
	q.SetParameter ( "Key", tag );
	return q.Execute ().Unload ().UnloadColumn ( "Tag" );

endfunction

&atclientatservernocontext
procedure insertTag ( Tag, List )

	if ( TypeOf ( Tag ) = Type ( "Array" ) ) then
		List.LoadValues ( Tag );
	else
		List.Add ( Tag );
	endif;
	List.SortByValue ();

endprocedure

&atserver
procedure initTagsFilter ()

	tags = getTagClassifier ();
	for each row in tags do
		tag = row.Ref;
		item = TagsFilter.FindByValue ( tag );
		if ( item = undefined ) then
			TagsFilter.Add ( tag, row.Description );
		endif;
	enddo;
	TagsFilter.SortByPresentation ();

endprocedure

&atserver
function getTagClassifier ()

	s = "
		|select Tags.Ref as Ref, Tags.Description as Description
		|from Catalog.Tags as Tags
		|where not Tags.DeletionMark
		|";
	q = new Query ( s );
	return q.Execute ().Unload ();

endfunction

&atserver
procedure readStatus ()

	Locked = false;
	LockedBy = undefined;
	if ( Object.Ref.IsEmpty () ) then
		Locked = true;
		return;
	endif;
	info = InformationRegisters.Editing.Get ( new Structure ( "Scenario", Object.Ref ) );
	if ( info.User.IsEmpty () ) then
		return;
	endif;
	user = info.User;
	if ( user = SessionParameters.User ) then
		Locked = true;
	else
		LockedBy = "" + user + ", " + info.Date;
	endif;

endprocedure

&atserver
procedure restoreTemplate ( Scenario )

	TabDoc = Scenario.Template.Get ();
	TemplateChanged = Object.Ref.IsEmpty ();
	entitleTemplate ( ThisObject );
	AreasStorage = "";
	markAreas ();

endprocedure

&atclientatservernocontext
procedure entitleTemplate ( Form )

	items = Form.Items;
	tabDoc = Form.TabDoc;
	caption = Output.TemplateCaption ();
	if ( 0 < ( tabDoc.TableWidth + tabDoc.TableHeight ) ) then
		caption = caption + " *";
	endif;
	items.PageTemplate.Title = caption;

endprocedure

&atserver
procedure markAreas ( val List = undefined )

	noline = new Line ( SpreadsheetDocumentCellLineType.None );
	redLine = new Line ( SpreadsheetDocumentCellLineType.LargeDashed, 3 );
	redColor = new Color ( 255, 0, 0 );
	savedAreas = getSavedAreas ();
	if ( List = undefined ) then
		set = Object.Areas.Unload ( , "Name" ).UnloadColumn ( "Name" );
	else
		set = List;
	endif;
	for each name in set do
		savedAreas [ name ] = TabDoc.GetArea ( Name );
		area = TabDoc.Area ( name );
		area.TopBorder = noline;
		area.LeftBorder = noline;
		area.RightBorder = noline;
		area.BottomBorder = noline;
		area.Outline ( redLine, redLine, redLine, redLine );
		area.BorderColor = redColor;
	enddo;
	saveAreas ( savedAreas );

endprocedure

&atserver
function getSavedAreas ()

	if ( AreasStorage = "" ) then
		return new Map ();
	else
		return GetFromTempStorage ( AreasStorage );
	endif;

endfunction

&atserver
procedure saveAreas ( Areas )

	AreasStorage = PutToTempStorage ( Areas, UUID );

endprocedure

&atserver
procedure OnCreateAtServer ( Cancel, StandardProcessing )

	if ( Object.Ref.IsEmpty () ) then
		if ( not Parameters.CopyingValue.IsEmpty () ) then
			restoreTemplate ( Parameters.CopyingValue );
		endif;
		ScenarioForm.Init ( ThisObject );
		readStatus ();
		initTags ();
	endif;
	initEditor ();
	bindWorkplace ();
	setView ();
	setFilters ();
	showFilters ( ThisObject );
	readAppearance ();

endprocedure

&atserver
procedure readAppearance ()

	rules = new Array ();
	rules.Add ( "
	|LastCreator show filled ( Object.Ref );
	|LockedBy show not Locked and filled ( LockedBy );
	|CatalogScenariosLock show not Locked and empty ( LockedBy );
	|Script TabDoc Description Parent Application Memo Code Type TagsList Access Severity Users lock not Locked;
	|ScriptContextMenuAssist TabDocContextMenuCheckArea TabDocContextMenuRemoveArea
	|	TabDocContextMenuClearAreas TabDocContextMenuClearTabDoc
	|	TabDocContextMenuUseTemplate Assist StartRecording Convert
	|	Comment Uncomment InsertID WriteAndClose FormWrite PickAction ScriptContextMenuPickAction
	|	ScriptContextMenuFormatTable FormatTable ScriptContextMenuAddBreakpoint AddTag enable Locked;
	|DeletionWarning show Object.DeletionMark;
	|PageFields show filled ( Object.Ref ) and TestedMode;
	|FormCatalogScenariosRun RunExternally show TestedMode;
	|Restart show not TestedMode;
	|GroupOptions show ShowOptions;
	|Users enable Object.Access;
	|ShowScenarios show HidePanel;
	|HideScenarios hide HidePanel;
	|ScenariosPanel hide HidePanel;
	|SyncTree ActivateTree ScriptContextMenuSyncTree FindMain ScriptContextMenuFindMain ScriptContextMenuActivateDefinition enable not HidePanel;
	|GroupHook show WebHook;
	|Script show not AdvancedEditor;
	|Editor show AdvancedEditor
	|" );
		Appearance.Read ( ThisObject, rules );

endprocedure

&atserver
procedure initEditor ()

	AdvancedEditor = Framework.AdvancedEditor ();
	TesterVersion = StrReplace ( Metadata.Version, ".", "_" );
	EditorStorage = PutToTempStorage ( Catalogs.Scenarios.GetTemplate ( "Editor" ), UUID );
	if ( EnvironmentSrv.WebClient () ) then
		Editor = Catalogs.Scenarios.GetTemplate ( "EditorWeb" ).GetText ();
	endif;

endprocedure

&atserver
procedure bindWorkplace ()

	params = new Array ();
	params.Add ( new ChoiceParameter ( "Filter.Owner", SessionParameters.User ) );
	Items.WorkplaceFilter.ChoiceParameters = new FixedArray ( params );

endprocedure

&atserver
procedure setView ()

	control = Items.List;
	if ( StatusFilter = 0 and IsBlankString ( SearchString )
		and not tagsFiltered () ) then
		control.Representation = TableRepresentation.Tree;
	else
		control.Representation = TableRepresentation.List;
	endif;
	showPath = StatusFilter <> 0;
	Items.ListDescription.Visible = not showPath;
	Items.ListFullDescription.Visible = showPath;

endprocedure

&atserver
function tagsFiltered ()

	for each item in TagsFilter do
		if ( item.Check ) then
			return true;
		endif;
	enddo;
	return false;

endfunction

&atserver
procedure setFilters ()

	DC.SetParameter ( List, "User", SessionParameters.User );
	ApplicationFilter = EnvironmentSrv.GetApplication ();
	WorkplaceFilter = CommonSettingsStorage.Load ( Enum.SettingsWorkplaceFilter () );
	applicationFixed ( ThisObject );
	filterByApplication ();
	filterByWorkplace ();
	filterByDeletion ();

endprocedure

&atclientatservernocontext
function applicationFixed ( Form )

	object = Form.Object;
	application = object.Application;
	if ( Form.ApplicationFilter <> application and not application.IsEmpty () ) then
		Form.ApplicationFilter = application;
		return true;
	else
		return false;
	endif;

endfunction

&atserver
procedure filterByApplication ()

	if ( ApplicationFilter.IsEmpty () ) then
		DC.ChangeFilter ( List, "Application", undefined, false );
	else
		filter = new Array ();
		filter.Add ( Catalogs.Applications.EmptyRef () );
		filter.Add ( ApplicationFilter );
		DC.ChangeFilter ( List, "Application", filter, true, DataCompositionComparisonType.InList );
	endif;

endprocedure

&atserver
procedure filterByWorkplace ()

	show = DC.FindParameter ( List, "Show" );
	hide = DC.FindParameter ( List, "Hide" );
	show.Use = false;
	hide.Use = false;
	if ( WorkplaceFilter.IsEmpty () ) then
		return;
	endif;
	set = WorkplaceFilter.Scenarios.UnloadColumn ( "Scenario" );
	if ( WorkplaceFilter.Exclude ) then
		hide.Use = true;
		hide.Value = set;
	else
		show.Use = true;
		show.Value = set;
	endif;

endprocedure

&atserver
procedure filterByDeletion ()

	if ( DeletionFilter ) then
		DC.DeleteFilter ( List, "DeletionMark" );
	else
		DC.ChangeFilter ( List, "DeletionMark", false, true );
	endif;

endprocedure

&atclientatservernocontext
procedure showFilters ( Form )

	label = Form.Items.ShowOptionsLabel;
	if ( Form.ShowOptions ) then
		label.Title = Output.OptionsLabelHide ();
	else
		parts = new Array ();
		value = Form.ApplicationFilter;
		if ( not value.IsEmpty () ) then
			parts.Add ( value );
		endif;
		value = Form.WorkplaceFilter;
		if ( not value.IsEmpty () ) then
			parts.Add ( value );
		endif;
		value = Form.StatusFilter;
		if ( value = 1 ) then
			parts.Add ( Output.LockedLabel () );
		elsif ( value = 2 ) then
			parts.Add ( Output.UnlockedLabel () );
		endif;
		value = selectedTags ( Form );
		if ( value <> "" ) then
			parts.Add ( Output.TagsFilter () + ": " + value );
		endif;
		if ( parts.Count () = 0 ) then
			label.Title = Output.OptionsLabelShow ();
		else
			label.Title = Output.FilterLabelShow () + StrConcat ( parts, " | " );
		endif;
	endif;

endprocedure

&atclientatservernocontext
function selectedTags ( Form )

	set = new Array ();
	for each item in Form.TagsFilter do
		if ( item.Check ) then
			set.Add ( item.Presentation );
		endif;
	enddo;
	return StrConcat ( set, ", " );

endfunction

&atclient
procedure OnOpen ( Cancel )

	saveOldParent ();
	ScenariosPanel.Push ( ThisObject );
	initProperties ();
	Appearance.Apply ( ThisObject );
	setTitle ();
	if ( AdvancedEditor ) then
		deployEditor ();
	else
		syncScenario ();
		AttachIdleHandler ( "activateEditor", 0.1, true );
	endif;

endprocedure

&atclient
async procedure deployEditor ()

#if not WebClient then
	path = await TempFilesDirAsync () + "testerEditor" + PathSeparator + TesterVersion;
	Editor = path + Pathseparator + "index.html";
	folder = new File ( path );
	extracted = await folder.ExistsAsync ();
	if ( not extracted ) then
		template = GetFromTempStorage ( EditorStorage );
		zip = new ZipFileReader ( template.OpenStreamForRead () );
		zip.ExtractAll ( path );
	endif;
	Editor = path + PathSeparator + "index.html";
#endif
	addToQueue ( "initEngine" );
	addToQueue ( "updateEditorAsync" );
	addToQueue ( "resetMetadata" );
	addToQueue ( "activateEditor" );

endprocedure

&atclient
procedure addToQueue ( Method, Parameter = undefined )

	Queue.Add ( Parameter, Method );
	proceedQueue ();

endprocedure

&atclient
procedure proceedQueue () export

	try
		engine = engine ();
	except
		AttachIdleHandler ( "proceedQueue", 0.1, true );
		return;
	endtry;
	lambda = Queue [ 0 ];
	LambdaParameter = lambda.Value;
	result = eval ( lambda.Presentation + "()" );
	LambdaParameter = undefined;
	Queue.Delete ( 0 );
	if ( Queue.Count () > 0 ) then
		AttachIdleHandler ( "proceedQueue", 0.1, true );
	endif;

endprocedure

&atclient
function updateEditorAsync ()

	engine = engine ();
	engine.setContent ( Object.Script );
	engine.setReadOnly ( not Locked );
	return undefined;

endfunction

&atclient
procedure saveOldParent ()

	OldParent = Object.Parent;

endprocedure

&atclient
procedure initProperties ()

	if ( TestManager = true ) then
		TestedMode = true;
	else
		TestedMode = false;
	endif;

endprocedure

&atserver
procedure loadScenario ( val Scenario )

	exists = ( Scenario <> undefined );
	if ( exists ) then
		obj = Scenario.GetObject ();
	else
		obj = Catalogs.Scenarios.CreateItem ();
		FillPropertyValues ( obj, Object, "Parent, Application, Type, Creator" );
	endif;
	ValueToFormAttribute ( obj, "Object" );
	if ( exists ) then
		restoreTemplate ( obj );
	endif;
	readStatus ();
	Appearance.Apply ( ThisObject );

endprocedure

&atclient
procedure syncScenario ()

	Items.List.CurrentRow = Object.Ref;

endprocedure

&atclient
function activateEditor () export

	CurrentItem = ? ( AdvancedEditor, Items.Editor, Items.Script );
	return undefined;

endfunction

&atclient
procedure setTitle ()

	ref = Object.Ref;
	if ( ref.IsEmpty () ) then
		Title = Output.NewScenario ();
	else
		Title = ? ( ref = SessionScenario, "►", "" ) + Object.Path;
	endif;

endprocedure

&atclient
procedure NotificationProcessing ( EventName, Parameter, Source )

	if ( EventName = Enum.MessageSaveAll () ) then
		if ( Locked ) then
			if ( isModified () ) then
				saveScenario ();
			endif;
		endif;
	elsif ( EventName = Enum.MessageLocked ()
		or EventName = Enum.MessageApplicationChanged ()
		or EventName = Enum.MessageReload () ) then
		if ( Parameter.Find ( Object.Ref ) <> undefined ) then
			reloadScenario ();
		endif;
	elsif ( EventName = Enum.MessageStored () ) then
		if ( Parameter.Find ( Object.Ref ) <> undefined ) then
			unlockScenario ();
		endif;
	elsif ( EventName = Enum.MessageSave () ) then
		if ( Locked and Parameter.Find ( Object.Ref ) <> undefined ) then
			if ( isModified () ) then
				saveScenario ();
			endif;
		endif;
	elsif ( EventName = Enum.MessageActivateError ()
		or EventName = Enum.MessageDebugger () ) then
		if ( Source = Object.Ref ) then
			activateEditor ();
			activateRow ( Parameter );
		endif;
	elsif ( EventName = Enum.MessageMainScenarioChanged () ) then
		setTitle ();
	elsif ( EventName = Enum.MessageRunExternally ()
		and Parameter = Object.Ref ) then
		AttachIdleHandler ( "runExternally", 1, true );
	endif;

endprocedure

&atclient
procedure runExternally () export

	RunScenarios.Go ( Object.Ref, false );

endprocedure

&atclient
function isModified ()

	if ( not AdvancedEditor ) then
		// Modified flag will not appear unless editor box looses focus
		field = Items.Script;
		if ( CurrentItem = field ) then
			CurrentItem = Items.Description;
			CurrentItem = field;
		endif;
	endif;
	return Modified;

endfunction

&atclient
procedure saveScenario ()

	if ( not AdvancedEditor ) then
		Write ();
	else
		addToQueue ( "Write" );
	endif;

endprocedure

&atclient
procedure reloadScenario ()

	reload ();
	setTitle ();
	if ( AdvancedEditor ) then
		addToQueue ( "updateEditorAsync" );
	endif;

endprocedure

&atserver
procedure reload ()

	if ( Object.Ref.IsEmpty () ) then
		return;
	endif;
	obj = Object.Ref.GetObject ();
	obj.Unlock ();
	ValueToFormAttribute ( obj, "Object" );
	Modified = false;
	readStatus ();
	restoreTemplate ( obj );
	applicationFixed ( ThisObject );
	filterByApplication ();
	showFilters ( ThisObject );
	Appearance.Apply ( ThisObject );

endprocedure

&atclient
procedure unlockScenario ()

	unlock ();
	if ( AdvancedEditor ) then
		addToQueue ( "updateEditorAsync" );
	endif;

endprocedure

&atserver
procedure unlock ()

	readStatus ();
	if ( not Locked ) then
		UnlockFormDataForEdit ();
	endif;
	Appearance.Apply ( ThisObject, "Locked" );

endprocedure

&atclient
procedure activateRow ( Line )

	endOfLine = StrLen ( StrGetLine ( Object.Script, Line ) ) + 1;
	if ( not AdvancedEditor ) then
		Items.Script.SetTextSelectionBounds ( Line, 1, Line, endOfLine );
	else
		addToQueue ( "activateRowAsync", new Structure ( "Line, EndOfLine", Line, endOfLine ) );
	endif;

endprocedure

&atclient
function activateRowAsync ()

	line = LambdaParameter.Line;
	engine ().setSelection ( line, 1, line, LambdaParameter.endOfLine );
	return undefined;

endfunction

&atclient
procedure ChoiceProcessing ( SelectedValue, ChoiceSource )

	if ( TypeOf ( SelectedValue ) = Type ( "String" ) ) then
		applyAssistant ( SelectedValue, false, false );
	endif;

endprocedure

&atclient
procedure applyAssistant ( Replacement, Picking, Comment )

	if ( not AdvancedEditor ) then
		multiline = StrLineCount ( Replacement ) > 1;
		if ( multiline ) then
			getSelection ();
			if ( ColumnStart = 1 ) then
				text = Replacement;
			else
				text = Chars.LF + Replacement;
			endif;
		else
			text = Replacement;
		endif;
		if ( Picking ) then
			text = text + Chars.LF;
		endif;
		if ( Comment ) then
			text = "//" + text;
		endif;
		Items.Script.SelectedText = text;
	else
		addToQueue ( "applyAssistantAsync", new Structure ( "Replacement, Picking, Comment",
			Replacement, Picking, Comment ) );
	endif;

endprocedure

&atclient
function applyAssistantAsync ()

	replacement = LambdaParameter.Replacement;
	multiline = StrLineCount ( replacement ) > 1;
	if ( multiline ) then
		getSelection ();
		if ( ColumnStart = 1 ) then
			text = replacement;
		else
			text = Chars.LF + replacement;
		endif;
	else
		text = replacement;
	endif;
	if ( LambdaParameter.Picking ) then
		text = text + Chars.LF;
	endif;
	if ( LambdaParameter.Comment ) then
		text = "//" + text;
	endif;
	engine ().selectedText ( text );
	return undefined;

endfunction

&atclient
procedure NewWriteProcessing ( NewObject, Source, StandardProcessing )

	type = TypeOf ( NewObject );
	if ( type = Type ( "CatalogRef.Tags" ) ) then
		insertTag ( String ( NewObject ), Items.TagsList.ChoiceList );
		initTagsFilter ();
	endif;

endprocedure

&atserver
procedure FillCheckProcessingAtServer ( Cancel, CheckedAttributes )

	if ( not ScenarioForm.CheckName ( Object.Description ) ) then
		Output.ScenarioIDError ( , "Description" );
		Cancel = true;
	endif;

endprocedure

&atclient
procedure BeforeWrite ( Cancel, WriteParameters )

	if ( ScenarioForm.SaveParents ( Object, OldParent ) ) then
		if ( AdvancedEditor ) then
			uploadScript ();
		endif;
	else
		Cancel = true;
	endif;

endprocedure

&atserver
procedure BeforeWriteAtServer ( Cancel, CurrentObject, WriteParameters )

	saveTags ( CurrentObject );
	if ( TemplateChanged ) then
		prepareTempale ();
		saveTemplate ( CurrentObject );
	endif;

endprocedure

&atserver
procedure saveTags ( CurrentObject )

	CurrentObject.Tag = Catalogs.TagKeys.Pick ( Items.TagsList.ChoiceList.UnloadValues () );

endprocedure

&atserver
procedure prepareTempale ()

	begin = undefined;
	end = undefined;
	marker = getMarker ();
	while ( true ) do
		begin = TabDoc.FindText ( "{", end );
		if ( begin = undefined ) then
			break;
		endif;
		end = begin;
		if ( isTemplate ( begin.Text ) ) then
			begin.TextColor = marker;
		endif;
	enddo;

endprocedure

&atclientatservernocontext
function getMarker ()

	return new Color ( 255, 0, 255 );

endfunction

&atclientatservernocontext
function isTemplate ( Text )

	s = TrimAll ( Text );
	return StrStartsWith ( s, "{" ) and StrEndsWith ( s, "}" );

endfunction

&atserver
procedure saveTemplate ( CurrentObject )

	restoreAreas ();
	CurrentObject.Template = new ValueStorage ( TabDoc );
	CurrentObject.Spreadsheet = ( TabDoc.TableHeight + TabDoc.TableWidth ) > 0;
	TemplateChanged = false;

endprocedure

&atserver
procedure AfterWriteAtServer ( CurrentObject, WriteParameters )

	markAreas ();
	if ( tagsFiltered () ) then
		filterByTag ();
	endif;
	Appearance.Apply ( ThisObject, "Object.Ref" );

endprocedure

&atclient
procedure AfterWrite ( WriteParameters )

	ScenarioForm.RereadParents ( Object, OldParent );
	saveOldParent ();
	setTitle ();
	ScenariosPanel.Push ( ThisObject );
	RepositoryFiles.Sync ();
	if ( not AdvancedEditor ) then
		resetCursor ();
	else
		AttachIdleHandler ( "activateEditor", 0.1, true );
	endif;

endprocedure

&atclient
procedure resetCursor ()

	// Bug workaround: the following actions try to avoid
	// undefined behaviour of cursor position in Text Editor
	OldCurrentItem = CurrentItem;
	CurrentItem = Items.Description;
	CurrentItem = OldCurrentItem;

endprocedure

&atclient
procedure OnClose ( Exit )

	ScenariosPanel.Pop ( Object.Ref );

endprocedure

&atclient
procedure RereadScenario ( Command )

	Reread ();

endprocedure

&atclient
procedure Reread () export

	rereadMyself ();
	saveOldParent ();
	if ( AdvancedEditor ) then
		addToQueue ( "updateEditorAsync" );
	endif;
	setTitle ();
	Modified = false;

endprocedure

&atserver
procedure rereadMyself ()

	obj = Object.Ref.GetObject ();
	ValueToFormAttribute ( obj, "Object" );
	readMyself ( obj );

endprocedure

// *****************************************
// *********** Group Form

&atclient
procedure Restart ( Command )

	OpenForm ( "Catalog.Scenarios.Form.Restart" );

endprocedure

&atclient
procedure RunSelected ( Command )

	if ( not AdvancedEditor ) then
		runCode ();
	else
		addToQueue ( "runCodeAsync" );
	endif;
	activateEditor ();

endprocedure

&atclient
procedure runCode ()

	getSelection ();
	ModuleCode = getBlock ();
	Test.Exec ( Object.Ref,, ModuleCode,, SelectionStart );

endprocedure

&atclient
procedure getSelection ()

	if ( not AdvancedEditor ) then
		Items.Script.GetTextSelectionBounds ( RowStart, ColumnStart, RowEnd, ColumnEnd );
	else
		info = engine ().getSelection ();
		RowStart = info.startLineNumber;
		RowEnd = info.endLineNumber;
		ColumnStart = info.startColumn;
		ColumnEnd = info.endColumn;
	endif;
	SelectionStart = RowStart;
	SelectionEnd = RowEnd;
	if ( ColumnStart = ColumnEnd and ColumnStart = 1 ) then
		SelectionEnd = Max ( SelectionStart, SelectionEnd - 1 );
	endif;

endprocedure

&atclient
function getBlock ()

	text = Object.Script;
	rows = new Array ();
	for i = SelectionStart to SelectionEnd do
		rows.Add ( StrGetLine ( text, i ) );
	enddo;
	return StrConcat ( rows, Chars.LF );

endfunction

&atclient
function runCodeAsync ()

	uploadScript ();
	runCode ();
	return undefined;

endfunction

&atclient
procedure Comment ( Command )

	commentScript ();
	activateEditor ();

endprocedure

&atclient
procedure commentScript ()

	if ( not AdvancedEditor ) then
		getSelection ();
		insertComments ();
		restoreSelection ();
	else
		addToQueue ( "commentScriptAsync" );
	endif;

endprocedure

&atclient
procedure insertComments ()

	text = Object.Script;
	rows = new Array ();
	for i = SelectionStart to SelectionEnd do
		row = StrGetLine ( text, i );
		rows.Add ( "//" + row );
	enddo;
	replaceSelection ( rows );

endprocedure

&atclient
procedure replaceSelection ( Rows )

	control = Items.Script;
	control.SetTextSelectionBounds ( SelectionStart, 1, SelectionEnd, 1
		+StrLen ( StrGetLine ( Object.Script, SelectionEnd ) ) );
	control.SelectedText = StrConcat ( rows, Chars.LF );

endprocedure

&atclient
procedure restoreSelection ()

	control = Items.Script;
	control.SetTextSelectionBounds ( RowStart, ColumnStart, RowEnd, ColumnEnd );

endprocedure

&atclient
function commentScriptAsync ()

	engine ().addComment ();
	return undefined;


endfunction

&atclient
procedure Uncomment ( Command )

	if ( not AdvancedEditor ) then
		uncommentScript ();
		activateEditor ();
	else
		addToQueue ( "uncommentScriptAsync" );
	endif;

endprocedure

&atclient
function uncommentScriptAsync ()

	engine ().removeComment ();
	return undefined;

endfunction

&atclient
procedure uncommentScript ()

	getSelection ();
	removeComments ();
	restoreSelection ();

endprocedure

&atclient
procedure removeComments ()

	text = Object.Script;
	rows = new Array ();
	for i = SelectionStart to SelectionEnd do
		row = StrGetLine ( text, i );
		if ( Lexer.IsComment ( row ) ) then
			rows.Add ( Mid ( row, 3 ) );
		else
			rows.Add ( row );
		endif;
	enddo;
	replaceSelection ( rows );

endprocedure

&atclient
procedure GotoDefinition ( Command )

	openSubScenario ();
	activateEditor ();

endprocedure

&atclient
procedure openSubScenario ()

	scenario = getScenario ();
	if ( scenario = undefined ) then
		return;
	endif;
	OpenForm ( "Catalog.Scenarios.ObjectForm", new Structure ( "Key", scenario ), Items.List );

endprocedure

&atclient
function getScenario ()

	getSelection ();
	s = StrGetLine ( Object.Script, RowStart );
	return findScenario ( s, Object.Application, ? ( Object.Tree, Object.Ref, Object.Parent ) );

endfunction

&atservernocontext
function findScenario ( val Row, val Application, val Parent )

	variants = new Array ();
	variants.Add ( getSignature ( "call|вызвать", 1, 3 ) );
	variants.Add ( getSignature ( "run|позвать", 1, 3, Parent ) );
	variants.Add ( getSignature ( "test.start", 1, 2 ) );
	variants.Add ( getSignature ( "callserver|вызватьсервер ", 2, 4 ) );
	variants.Add ( getSignature ( "runserver|позватьсервер ", 2, 4, Parent ) );
	for each variant in variants do
		p = extractParams ( variant, Row );
		if ( p <> undefined ) then
			return RuntimeSrv.FindScenario ( p.Scenario, Application, p.Application, variant.Parent, true );
		endif;
	enddo;

endfunction

&atservernocontext
function getSignature ( Names, Scenario, Application, Parent = undefined )

	return new Structure ( "Names, Scenario, Application, Parent", Names, Scenario, Application, Parent );

endfunction

&atservernocontext
function extractParams ( Variant, Row )

	params = getParams ( Variant.Names, Row );
	if ( params = undefined ) then
		return undefined;
	endif;
	count = params.Count ();
	i = Variant.Scenario;
	if ( count < i ) then
		return undefined;
	endif;
	scenario = params [ i - 1 ];
	i = Variant.Application;
	app = ? ( count < i, undefined, params [ i - 1 ] );
	return new Structure ( "Scenario, Application", scenario, app );

endfunction

&atservernocontext
function getParams ( Functions, Row )

	pattern = "(" + Functions + ")(\(| +\()(.+)\)";
	matches = Regexp.Select ( Row, pattern );
	if ( matches.Count () = 0 ) then
		return undefined;
	endif;
	params = StrSplit ( matches [ 0 ].Groups [ 2 ], "," );
	for i = 0 to params.UBound () do
		params [ i ] = TrimAll ( StrReplace ( params [ i ], """", "" ) );
	enddo;
	return ? ( params.Count () = 0, undefined, params );

endfunction

&atclient
procedure FindDefinition ( Command )

	scenario = getScenario ();
	if ( scenario = undefined ) then
		return;
	endif;
	Items.List.CurrentRow = scenario;
	activateList ();

endprocedure

&atclient
procedure ActivateTree ( Command )

	activateList ();

endprocedure

&atclient
procedure activateList ()

	CurrentItem = Items.List;

endprocedure

&atclient
procedure NewScenario ( Command )

	// Bug workaround 8.3.8.2088:
	// I have to create special command because standard form command disables F5 shortcut
	OpenForm ( "Catalog.Scenarios.ObjectForm" );

endprocedure

&atclient
procedure SyncTree ( Command )

	if ( not AdvancedEditor ) then
		synchronizeTree ();
	else
		addToQueue ( "synchronizeTree" );
	endif;

endprocedure

&atclient
function synchronizeTree ()

	if ( Object.Ref.IsEmpty () ) then
		saveScenario ();
	endif;
	applicationChanged = applicationFixed ( ThisObject );
	searchUsed = SearchString <> "";
	if ( applicationChanged or searchUsed ) then
		resetFilters ( applicationChanged, searchUsed );
	endif;
	syncScenario ();
	activateList ();
	return undefined;

endfunction

&atserver
procedure resetFilters ( val Application, val Search )

	if ( Application ) then
		filterByApplication ();
		showFilters ( ThisObject );
	endif;
	if ( Search ) then
		SearchString = "";
		applySearch ();
	endif;

endprocedure

&atclient
procedure CheckSyntax ( Command )

	if ( not AdvancedEditor ) then
		checkCode ();
		activateEditor ();
	else
		addToQueue ( "checkCodeAsync" );
	endif;

endprocedure

&atclient
procedure checkCode ()

	Test.CheckSyntax ( Object.Script );

endprocedure

&atclient
function checkCodeAsync ()

	uploadScript ();
	checkCode ();
	return undefined;

endfunction

&atclient
procedure uploadScript ()

	Object.Script = engine ().getText ();

endprocedure

&atclient
procedure Assist ( Command )

	openAssistant ();

endprocedure

&atclient
procedure openAssistant ()

	Test.AttachApplication ( Object.Ref );
	OpenForm ( "Catalog.Assistant.ChoiceForm",, ThisObject );

endprocedure

&atclient
procedure DescriptionOnChange ( Item )

	Object.Description = TrimAll ( Object.Description );

endprocedure

&atclient
procedure InsertID ( Command )

	insertIdentifier ();

endprocedure

&atclient
procedure insertIdentifier ()

	if ( not AdvancedEditor ) then
		Items.Script.SelectedText = TestingID ();
	else
		addToQueue ( "insertIdentifierAsync" );
	endif;

endprocedure

&atclient
function insertIdentifierAsync ()

	engine ().selectedText ( TestingID () );
	return undefined;

endfunction

&atclient
procedure StartRecording ( Command )

	if ( SessionScenario.IsEmpty () ) then
		Output.SetupMainScenario ( ThisObject, Object.Ref );
	else
		openRecording ();
	endif;

endprocedure

&atclient
procedure Convert ( Command )

	openConversion ();

endprocedure

&atclient
procedure openConversion ()

	OpenForm ( "Catalog.Scenarios.Form.Convert",,,,,, new NotifyDescription ( "Converting", ThisObject ) );

endprocedure

&atclient
procedure SetupMainScenario ( Answer, Scenario ) export

	if ( Answer = DialogReturnCode.No ) then
		return;
	endif;
	Environment.ChangeScenario ( Scenario );
	openRecording ();

endprocedure

&atclient
procedure openRecording ()

	OpenForm ( "Catalog.Scenarios.Form.Record",, ThisObject,,,, new NotifyDescription ( "Converting", ThisObject ) );

endprocedure

&atclient
procedure Converting ( Data, Params ) export

	if ( Data = undefined ) then
		return;
	endif;
	Log = Data.Log;
	if ( not AdvancedEditor ) then
		Items.Script.SelectedText = transpile ( Data, Object.Script );
	else
		addToQueue ( "setRecorderScriptAsync", Data );
	endif;

endprocedure

&atclient
function setRecorderScriptAsync ()

	uploadScript ();
	engine ().selectedText ( transpile ( LambdaParameter, Object.Script ) );
	return undefined;

endfunction

&atservernocontext
function transpile ( val Data, val Script )

	mode = Data.Mode;
	if ( mode = Enums.Recording.Tester ) then
		return DataProcessors.TranspilerTester.Perform ( Data.Log, Data.Lang, findConnect ( Script ) );
	else
		return DataProcessors.TranspilerRaw.Perform ( Data.Log, Data.Lang, mode = Enums.Recording.Smart, findConnect ( Script ) );
	endif;

endfunction

&atservernocontext
function findConnect ( Script )

	pattern = "(^|\s+)(connect\W|подключить\W)";
	return Regexp.Test ( Script, pattern );

endfunction

&atclient
procedure PickAction ( Command )

	ScenarioForm.Picking ( ThisObject, false );

endprocedure

&atclient
procedure FormatTable ( Command )

	if ( not AdvancedEditor ) then
		alignTable ();
	else
		addToQueue ( "alignTableAsync" );
	endif;

endprocedure

&atclient
procedure alignTable ()

	getSelection ();
	evalRange = SelectionStart = SelectionEnd;
	table = extractSelection ( evalRange );
	text = TableProcessor.Formatting ( table.Text, table.Indent );
	if ( not AdvancedEditor ) then
		control = Items.Script;
		if ( evalRange ) then
			control.SetTextSelectionBounds ( table.Start, 1, table.Finish + 1, 1 );
			control.SelectedText = text + Chars.LF;
			restoreSelection ();
		else
			control.SelectedText = text + ? ( ColumnEnd = 1, Chars.LF, "" );
		endif;
	else
		control = engine ();
		if ( evalRange ) then
			control.setSelection ( table.Start, 1, table.Finish + 1, 1 );
			control.selectedText ( text + Chars.LF );
		else
			control.selectedText ( text + ? ( ColumnEnd = 1, Chars.LF, "" ) );
		endif;
	endif;

endprocedure

&atclient
function alignTableAsync ()

	uploadScript ();
	alignTable ();
	return undefined;

endfunction

&atclient
function extractSelection ( EvalRange )

	rows = new Array ();
	indent = undefined;
	if ( EvalRange ) then
		start = evalTableStart ();
		finish = evalTableEnd ();
	else
		start = SelectionStart;
		finish = SelectionEnd;
	endif;
	script = Object.Script;
	for i = start to finish do
		s = StrGetLine ( script, i );
		data = extractTablePart ( s, 2 );
		if ( data = undefined ) then
			continue;
		endif;
		indent = data.Indent;
		rows.Add ( data.Text );
	enddo;
	return new Structure ( "Text, Indent, Start, Finish", StrConcat ( rows, Chars.LF ), indent, start, finish );

endfunction

&atclient
function evalTableStart ()

	script = Object.Script;
	i = SelectionStart;
	while ( i > 0 ) do
		s = StrGetLine ( script, i );
		if ( extractTablePart ( s, 1 ) ) then
			return i + 1;
		elsif ( extractTablePart ( s, 2 ) = undefined
			and not extractTablePart ( s, 3 ) ) then
			break;
		endif;
		i = i - 1;
	enddo;
	raise Output.TableDefinitionNotFound ();

endfunction

&atclient
function extractTablePart ( Row, Part )

	result = new Structure ( "Indent, Text" );
	if ( Part = 1 ) then
		// Definition begins
		// = "text
		// ( "text
		pattern = "((=(\s+)?"")|(\((\s+)?""))(.+)?";
		return Regexp.Test ( Row, pattern );
	elsif ( Part = 2 ) then
		// Header or Row
		// | text
		pattern = "^(\s+)?\|(.+)?";
		matches = Regexp.Select ( Row, pattern );
		if ( matches.Count () = 0 ) then
			return undefined;
		else
			match = matches [ 0 ];
			result.Indent = match.Groups [ 0 ];
			result.Text = match.Groups [ 1 ];
		endif;
	else
		// Definition ends
		// | text";
		// | text" )
		pattern = "(^(\s+)?\|)""(\s+)?(\)|;)";
		return Regexp.Test ( Row, pattern );
	endif;
	return result;

endfunction

&atclient
function evalTableEnd ()

	script = Object.Script;
	eof = StrLineCount ( script );
	for i = SelectionStart to eof do
		s = StrGetLine ( script, i );
		if ( extractTablePart ( s, 3 ) ) then
			return i - 1;
		elsif ( not extractTablePart ( s, 1 )
			and extractTablePart ( s, 2 ) = undefined ) then
			break;
		endif;
	enddo;
	raise Output.TableDefinitionNotFound ();

endfunction

&atclient
procedure AddBreakpoint ( Command )

	if ( not AdvancedEditor ) then
		insertDebugger ();
	else
		addToQueue ( "insertDebugger" );
	endif;

endprocedure

&atclient
function insertDebugger ()

	label = Output.DebuggerLabel () + Chars.LF;
	if ( not AdvancedEditor ) then
		Items.Script.SelectedText = label;
	else
		engine ().selectedText ( label );
	endif;
	return undefined;

endfunction

&atclient
procedure ShowScenarios ( Command )

	togglePanel ();

endprocedure

&atclient
procedure togglePanel ()

	HidePanel = not HidePanel;
	Appearance.Apply ( ThisObject, "HidePanel" );

endprocedure

// *****************************************
// *********** Group Filters
&atclient
procedure QuickFilterStartChoice ( Item, ChoiceData, StandardProcessing )

	StandardProcessing = false;

endprocedure

&atclient
procedure QuickFilterClearing ( Item, StandardProcessing )

	resetSearch ();
	activateList ();

endprocedure

&atclient
procedure resetSearch ()

	SearchString = "";
	filterScenario ();

endprocedure

&atclient
procedure filterScenario () export

	applySearch ();
	OldScenario = undefined;

endprocedure

&atserver
procedure applySearch ()

	setView ();
	refs = FullSearch.Refs ( SearchString, Enums.Search.Scenarios );
	DC.ChangeFilter ( List, "Ref", refs, not IsBlankString ( SearchString ), DataCompositionComparisonType.InList );

endprocedure

&atclient
procedure QuickFilterEditTextChange ( Item, Text, StandardProcessing )

	DetachIdleHandler ( "filterScenario" );
	SearchString = Text;
	AttachIdleHandler ( "filterScenario", 0.4, true );

endprocedure

&atclient
procedure ShowOptionsLabelClick ( Item )

	ShowOptions = not ShowOptions;
	Appearance.Apply ( ThisObject, "ShowOptions" );
	showFilters ( ThisObject );

endprocedure

&atclient
procedure ApplicationFilterOnChange ( Item )

	filterByApplication ();
	activateList ();

endprocedure

&atclient
procedure WorkplaceFilterOnChange ( Item )

	applyWorkplace ();

endprocedure

&atserver
procedure applyWorkplace ()

	Logins.SaveSettings ( Enum.SettingsWorkplaceFilter (),, WorkplaceFilter );
	filterByWorkplace ();

endprocedure

&atclient
procedure StatusFilterOnChange ( Item )

	applyStatusFilter ();
	activateList ();

endprocedure

&atserver
procedure applyStatusFilter ()

	setView ();
	filterByStatus ();

endprocedure

&atserver
procedure filterByStatus ()

	if ( StatusFilter = 2 ) then
		DC.ChangeFilter ( List, "Locked", 1, true, DataCompositionComparisonType.NotEqual );
	else
		DC.ChangeFilter ( List, "Locked", StatusFilter, StatusFilter <> 0 );
	endif;

endprocedure

&atclient
procedure DeletionFilterOnChange ( Item )

	filterByDeletion ();

endprocedure

&atclient
procedure TagsFilterOnChange ( Item )

	applyTagsFilter ();

endprocedure

&atserver
procedure applyTagsFilter ()

	setView ();
	filterByTag ();

endprocedure

&atserver
procedure filterByTag ()

	tags = gatherTags ();
	DC.ChangeFilter ( List, "Tag", gatherKeys ( Tags ), tags.Count () > 0, DataCompositionComparisonType.InList );

endprocedure

&atserver
function gatherTags ()

	set = new Array ();
	for each item in TagsFilter do
		if ( item.Check ) then
			set.Add ( item.Value );
		endif;
	enddo;
	return set;

endfunction

&atserver
function gatherKeys ( Tags )

	if ( Tags.Count () = 0 ) then
		result = new Array ();
	else
		s = "
			|select Keys.Ref as Ref
			|from Catalog.Tags as Tags
			|	//
			|	// Tags
			|	//
			|	left join (
			|		select Keys.Ref as Ref, Tags.Ref as Tag, case when Keys.Tag = Tags.Ref then 1 else 0 end as Selected
			|		from Catalog.TagKeys.Tags as Keys, Catalog.Tags as Tags
			|		where not Keys.Ref.DeletionMark
			|	) as Keys
			|	on Keys.Tag = Tags.Ref
			|where Tags.Ref in ( &Tags )
			|group by Keys.Ref
			|having sum ( Keys.Selected ) = &TagsCount
			|";
		q = new Query ( s );
		q.SetParameter ( "Tags", Tags );
		q.SetParameter ( "TagsCount", Tags.Count () );
		result = q.Execute ().Unload ().UnloadColumn ( "Ref" );
	endif;
	return result;

endfunction

&atclient
procedure TagsFilterBeforeRowChange ( Item, Cancel )

	if ( Item.CurrentItem.Name = "TagsFilterValue" ) then
		Cancel = true;
		toggleTagsFilter ();
	endif;

endprocedure

&atclient
procedure toggleTagsFilter ()

	row = Items.TagsFilter.CurrentData;
	// The code does not work in 8.3.11.2924:
	// row.Check = not row.Check;
	//
	// Workaround is used:
	TagsFilter.FindByValue ( row.Value ).Check = not row.Check;
	applyTagsFilter ();

endprocedure

// *****************************************
// *********** Group List

&atclient
procedure SetCurrent ( Command )

	Environment.ChangeApplication ( ApplicationFilter );

endprocedure

&atclient
procedure OpenHere ( Command )

	if ( not AdvancedEditor ) then
		applyScenario ( TableRow.Ref );
	else
		addToQueue ( "applyScenarioAsync", TableRow.Ref );
	endif;

endprocedure

&atclient
procedure applyScenario ( Scenario )

	if ( Scenario = Object.Ref ) then
		return;
	endif;
	if ( isModified () ) then
		saveScenario ();
	endif;
	ScenariosPanel.Pop ( Object.Ref );
	loadScenario ( Scenario );
	if ( AdvancedEditor ) then
		updateEditorAsync ();
	endif;
	ScenariosPanel.Push ( ThisObject );
	setTitle ();
	activateEditor ();

endprocedure

&atclient
function applyScenarioAsync ()

	applyScenario ( LambdaParameter );
	return undefined;

endfunction

&atclient
procedure FindMain ( Command )

	findHead ();

endprocedure

&atclient
procedure findHead ()

	if ( SessionScenario.IsEmpty () ) then
		Output.MainScenarioUndefined ();
	else
		Items.List.CurrentRow = SessionScenario;
		activateList ();
	endif;

endprocedure

&atclient
procedure RefreshList ( Command )

	Items.List.Refresh ();

endprocedure

&atclient
procedure ListOnActivateRow ( Item )

	TableRow = Item.CurrentData;
	AttachIdleHandler ( "showCode", 0.1, true );

endprocedure

&atclient
procedure showCode () export

	if ( TableRow = undefined ) then
		CodePreview = "";
		return;
	endif;
	if ( TableRow.Ref = OldScenario ) then
		return;
	endif;
	OldScenario = TableRow.Ref;
	CodePreview = preview ( OldScenario, adjustText ( Items.QuickFilter.EditText ) );

endprocedure

&atclientatservernocontext
function adjustText ( Text )

	if ( IsBlankString ( Text ) ) then
		return "";
	endif;
	parts = Conversion.StringToArray ( Lower ( Text ), " " );
	s = "";
	for each part in parts do
		if ( part = "" ) then
			continue;
		endif;
		s = s + " " + part;
	enddo;
	return Mid ( s, 2 );

endfunction

&atservernocontext
function preview ( val Scenario, val Highlighting ) export

	return "
		|<html>
		|<head>
		|<style>" + styles() + "</style>
		|<script type=""text/javascript"">" + scripts() + "</script>
		|</head>
		|<body onload=""highlightWord('" + Highlighting + "')"">
		|<pre>" + body(Scenario) + "</pre>
		|</body>
		|</html>";

endfunction

&atservernocontext
function styles ()

	s = "
		|.yellow{
		|	background-color:yellow;
		|	color:black;
		|}
		|";
	return s;

endfunction

&atservernocontext
function scripts ()

	s = "
		|function highlightWord(searchString) {
		|	if ( searchString == '' ) return;
		|	var nodes = textNodesUnder(document.body);
		|	var words = searchString.split(' ');
		|	for (var i in nodes) {
		|		highlightWords(nodes[i], words);
		|	}
		|}
		|function textNodesUnder(node) {
		|	var all = [];
		|	for (node = node.firstChild; node; node = node.nextSibling) {
		|		if (node.nodeType == 3) all.push(node);
		|		else all = all.concat(textNodesUnder(node));
		|	}
		|	return all;
		|}
		|function highlightWords(n, words) {
		|	for (var i in words) {
		|		var word = words[i].toLowerCase ();
		|		for (var j; (j = n.nodeValue.toLowerCase().indexOf(word, j)) > -1; n = after) {
		|			var after = n.splitText(j + word.length);
		|			var highlighted = n.splitText(j);
		|			var span = document.createElement('span');
		|			span.className = 'yellow';
		|			span.appendChild(highlighted);
		|			after.parentNode.insertBefore(span, after);
		|		}
		|	}
		|}
		|";
	return s;

endfunction

&atservernocontext
function body ( val Scenario )

	body = DF.Pick ( Scenario, "Script" );
	return Conversion.XMLToStandard ( body );

endfunction

&atclient
procedure ListSelection ( Item, SelectedRow, Field, StandardProcessing )

	if ( hierarchy () ) then
		StandardProcessing = false;
		processHierarchy ();
	endif;

endprocedure

&atclient
function hierarchy ()

	type = TableRow.Type;
	return TableRow.Tree and ( type = PredefinedValue ( "Enum.Scenarios.Folder" )
		or type = PredefinedValue ( "Enum.Scenarios.Library" ) );

endfunction

&atclient
procedure processHierarchy ()

	tree = Items.List;
	row = tree.CurrentRow;
	if ( tree.Expanded ( row ) ) then
		tree.Collapse ( row );
	else
		tree.Expand ( row );
	endif;

endprocedure

&atclient
procedure ListDrag ( Item, DragParameters, StandardProcessing, Row, Field )

	ScenarioForm.ListDrag ( ThisObject, DragParameters, StandardProcessing, Row );

endprocedure

// *****************************************
// *********** Table FieldsTable

&atclient
procedure FetchFields ( Command )

	fill ( false );
	expandTree ();

endprocedure

&atclient
procedure fill ( ActiveOnly )

	scenario = Object.Ref;
	Test.AttachApplication ( scenario );
	Test.ConnectClient ( false );
	initTree ();
	source = ? ( ActiveOnly, App.GetActiveWindow (), App );
	fillTree ( FieldsTable.GetItems (), source.GetChildObjects () );

endprocedure

&atclient
procedure initTree ()

	rows = FieldsTable.GetItems ();
	rows.Clear ();
	FieldsMap = new Map ();
	TestedForm = undefined;

endprocedure

&atclient
procedure fillTree ( Rows, Objects )

	form = PredefinedValue ( "Enum.Controls.Form" );
	for each obj in Objects do
		try
			next = obj.GetChildObjects (); // For some particular forms, testmanager gets error
		except
			continue;
		endtry;
		row = Rows.Add ();
		FillPropertyValues ( row, obj );
		type = ScenarioForm.FieldType ( obj );
		row.Type = type;
		row.Picture = ScenarioForm.GetPicture ( type );
		if ( row.Name = "" ) then
			row.Name = "<" + ? ( row.FormName = "", type, row.FormName ) + ">";
		endif;
		id = row.GetID ();
		FieldsMap [ id ] = obj; // TestedField cannot be used as a key
		if ( next.Count () > 0 ) then
			fillTree ( row.GetItems (), next );
		endif;
		if ( type = form ) then
			TestedForm = obj;
		endif;
	enddo;

endprocedure

&atclient
procedure FetchActive ( Command )

	fill ( true );
	expandTree ();

endprocedure

&atclient
procedure Sync ( Command )

	syncItem ();

endprocedure

&atclient
procedure syncItem ()

	if ( TestedForm = undefined ) then
		return;
	endif;
	try
		item = TestedForm.GetCurrentItem ();
	except
		return;
	endtry;
	for each field in FieldsMap do
		if ( field.Value = item ) then
			Items.FieldsTable.CurrentRow = field.Key;
			break;
		endif;
	enddo;

endprocedure

&atclient
procedure Expand ( Command )

	expandTree ();

endprocedure

&atclient
procedure expandTree ()

	tree = Items.FieldsTable;
	rows = FieldsTable.GetItems ();
	for each row in rows do
		tree.Expand ( row.GetID (), true );
	enddo;

endprocedure

&atclient
procedure Collapse ( Command )

	collapseTree ( FieldsTable.GetItems () );

endprocedure

&atclient
procedure collapseTree ( Rows )

	tree = Items.FieldsTable;
	for each row in rows do
		next = row.GetItems ();
		if ( next.Count () > 0 ) then
			collapseTree ( next );
		endif;
		tree.Collapse ( row.GetID () );
	enddo;

endprocedure

&atclient
procedure ExpressionOnChange ( Item )

	calcResult ();

endprocedure

&atclient
procedure calcResult ()

	if ( FieldsRow = undefined or IsBlankString ( Expression ) ) then
		ExpressionResult = "";
	else
		try
			ExpressionResult = Eval ( "FieldsMap [ FieldsRow.GetID () ]." + Expression );
		except
			ExpressionResult = ErrorProcessing.BriefErrorDescription ( ErrorInfo () );
		endtry;
	endif;

endprocedure

&atclient
procedure ExpressionStartChoice ( Item, ChoiceData, StandardProcessing )

	StandardProcessing = false;
	calcResult ();

endprocedure

&atclient
procedure FieldsTableOnActivateRow ( Item )

	FieldsRow = Item.CurrentData;
	AttachIdleHandler ( "activateItem", 0.1, true );

endprocedure

&atclient
procedure activateItem () export

	if ( App = undefined or FieldsRow = undefined ) then
		return;
	endif;
	field = FieldsMap [ FieldsRow.GetID () ];
	if ( field <> undefined ) then
		try
			field.Activate ();
		except
		endtry;
	endif;

endprocedure

&atclient
procedure FieldsTableSelection ( Item, SelectedRow, Field, StandardProcessing )

	StandardProcessing = false;
	ScenarioForm.OpenAssistant ( Items.FieldsTable, Items.FieldsTableName, true,
		tableForm (), Object.Application );

endprocedure

&atclient
function tableForm ()

	row = FieldsRow;
	form = PredefinedValue ( "Enum.Controls.Form" );
	while ( true ) do
		row = row.GetParent ();
		if ( row = undefined ) then
			return "";
		elsif ( row.Type = form ) then
			return row.TitleText;
		endif;
	enddo;

endfunction

&atclient
procedure FieldsTableChoiceProcessing ( Item, SelectedValue, StandardProcessing )

	StandardProcessing = false;
	applyAction ( SelectedValue );

endprocedure

&atclient
procedure applyAction ( Action )

	withActiveForm ();
	if ( TypeOf ( Action ) = Type ( "String" ) ) then
		applyAssistant ( Action, true, false );
	else
		error = not ScenarioForm.ApplyAction ( Action );
		applyAssistant ( Action.Expression, true, error );
	endif;

endprocedure

&atclient
procedure withActiveForm ()

#if ( ThinClient or ThickClientManagedApplication ) then
	form = PredefinedValue ( "Enum.Controls.Form" );
	row = FieldsRow;
	while ( row <> undefined ) do
		if ( row.Type = form ) then
			With ( row.TitleText );
			return;
		endif;
		row = row.GetParent ();
	enddo;
#endif

endprocedure

// *****************************************
// *********** Group Template

&atclient
procedure TabDocOnChange ( Item )

	TemplateChanged = true;
	entitleTemplate ( ThisObject );
	restoreAreas ();
	markAreas ();

endprocedure

&atclient
procedure UseTemplate ( Command )

	openReplacement ();

endprocedure

&atclient
procedure openReplacement ()

	if ( isPicture ( TabDoc.CurrentArea ) ) then
		return;
	endif;
	text = TabDoc.CurrentArea.Text;
	if ( IsBlankString ( text ) ) then
		return;
	endif;
	p = new Structure ( "Text", text );
	OpenForm ( "Catalog.Scenarios.Form.Template", p, Items.TabDoc,,,, new NotifyDescription ( "ApplyTemplate", ThisObject, text ) );

endprocedure

&atclient
function isPicture ( Area )

	try
		//@skip-warning
		text = Area.Text;
	except
		return true;
	endtry;
	return false;

endfunction

&atclient
procedure ApplyTemplate ( Result, Text ) export

	if ( Result = undefined ) then
		return;
	endif;
	template = Result.Template;
	if ( Lower ( template ) = Lower ( Text ) ) then
		return;
	endif;
	Modified = true;
	TemplateChanged = true;
	marker = ? ( isTemplate ( template ), getMarker (), undefined );
	if ( Result.Everywhere ) then
		while ( true ) do
			area = TabDoc.FindText ( Text,,,, true,, true );
			if ( area = undefined ) then
				break;
			endif;
			replaceValue ( area, template, marker );
		enddo;
	else
		replaceValue ( TabDoc.CurrentArea, template, marker );
	endif;

endprocedure

&atclient
procedure replaceValue ( Area, Text, Marker )

	Area.Text = Text;
	if ( Marker <> undefined ) then
		Area.TextColor = Marker;
	endif;

endprocedure

&atclient
procedure CheckArea ( Command )

	attachAreas ();

endprocedure

&atclient
procedure attachAreas ()

	names = new Array ();
	for each area in TabDoc.SelectedAreas do
		if ( isPicture ( area ) ) then
			continue;
		endif;
		name = area.Name;
		areas = Object.Areas.FindRows ( new Structure ( "Name", name ) );
		if ( areas.Count () = 0 ) then
			names.Add ( name );
			row = Object.Areas.Add ();
			row.Name = name;
			row.Top = area.Top;
			row.Left = Max ( area.Left, 1 );
			row.Bottom = area.Bottom;
			row.Right = ? ( area.Right = 0, TabDoc.TableWidth, area.Right );
		endif;
	enddo;
	if ( names.Count () > 0 ) then
		markAreas ( names );
	endif;

endprocedure

&atclient
procedure ClearAreas ( Command )

	restoreAreas ();
	Object.Areas.Clear ();

endprocedure

&atserver
procedure restoreAreas ( Name = undefined )

	savedAreas = getSavedAreas ();
	if ( savedAreas.Count () = 0 ) then
		return;
	endif;
	if ( Name = undefined ) then
		for each area in savedAreas do
			unmarkArea ( area.Value, area.Key );
		enddo;
		savedAreas.Clear ();
		saveAreas ( savedAreas );
	else
		unmarkArea ( savedAreas [ Name ], Name );
		savedAreas.Delete ( Name );
		saveAreas ( savedAreas );
	endif;

endprocedure

&atserver
procedure unmarkArea ( Source, Name )

	receiver = TabDoc.Area ( Name );
	for i = 1 to source.TableHeight do
		for j = 1 to source.TableWidth do
			x = receiver.Top + i - 1;
			y = receiver.Left + j - 1;
			sourceCell = source.Area ( i, j, i, j );
			receiverCell = TabDoc.Area ( x, y, x, y );
			receiverCell.TopBorder = sourceCell.TopBorder;
			receiverCell.LeftBorder = sourceCell.LeftBorder;
			receiverCell.RightBorder = sourceCell.RightBorder;
			receiverCell.BottomBorder = sourceCell.BottomBorder;
			receiverCell.BorderColor = sourceCell.BorderColor;
		enddo;
	enddo;

endprocedure

&atclient
procedure RemoveArea ( Command )

	detachAreas ();

endprocedure

&atclient
procedure detachAreas ()

	areas = Object.Areas;
	for each area in TabDoc.SelectedAreas do
		if ( isPicture ( area ) ) then
			continue;
		endif;
		for i = area.Top to area.Bottom do
			for j = area.Left to area.Right do
				k = areas.Count ();
				while ( k > 0 ) do
					k = k - 1;
					row = areas [ k ];
					if ( row.Top <= i and i <= row.Bottom and row.Left <= j
						and j <= row.Right ) then
						restoreAreas ( row.Name );
						areas.Delete ( k );
					endif;
				enddo;
			enddo;
		enddo;
	enddo;

endprocedure

&atclient
procedure ClearTabDoc ( Command )

	deleteTabDoc ();
	TemplateChanged = true;
	entitleTemplate ( ThisObject );

endprocedure

&atserver
procedure deleteTabDoc ()

	Object.Areas.Clear ();
	TabDoc.Clear ();

endprocedure

// *****************************************
// *********** Tags

&atclient
procedure AddTag ( Command )

	selectTag ();

endprocedure

&atclient
procedure selectTag ()

	callback = new NotifyDescription ( "TagSelected", ThisObject );
	tags = getTags ( Items.TagsList.ChoiceList.UnloadValues () );
	menu = tags.Count ();
	if ( menu = 0 ) then
		Output.TagsListEmpty ();
		return;
	elsif ( menu > 15 ) then
		ShowChooseFromList ( callback, tags );
	else
		ShowChooseFromMenu ( callback, tags );
	endif;

endprocedure

&atservernocontext
function getTags ( val SelectedTags )

	s = "
		|select Tags.Description as Description
		|from Catalog.Tags as Tags
		|where not Tags.DeletionMark
		|and Tags.Description not in ( &Tags )
		|order by Description
		|";
	q = new Query ( s );
	q.SetParameter ( "Tags", SelectedTags );
	tags = q.Execute ().Unload ().UnloadColumn ( "Description" );
	list = new ValueList ();
	list.LoadValues ( tags );
	if ( AccessRight ( "Edit", Metadata.Catalogs.Tags ) ) then
		list.Add ( , Output.NewTag (),, PictureLib.CreateListItem );
	endif;
	return list;

endfunction

&atclient
procedure newTag ()

	callback = new NotifyDescription ( "TagCreated", ThisObject );
	OpenForm ( "Catalog.Tags.ObjectForm",, ThisObject,,,, callback );

endprocedure

&atclient
procedure TagCreated ( Tag, Params ) export

	// For backward compatibility with versions < 8.3.11
	//@skip-warning
	noerrorshere = true;

endprocedure

&atclient
procedure TagSelected ( Tag, Params ) export

	if ( Tag = undefined ) then
		return;
	endif;
	value = Tag.Value;
	if ( value = undefined ) then
		newTag ();
	else
		insertTag ( value, Items.TagsList.ChoiceList );
	endif;

endprocedure

&atclient
procedure TagsListOnChange ( Item )

	Output.TagRemovingConfirmation ( ThisObject );

endprocedure

&atclient
procedure TagRemovingConfirmation ( Answer, Params ) export

	if ( Answer = DialogReturnCode.Yes ) then
		removeTag ();
	endif;
	TagsList = "";

endprocedure

&atclient
procedure removeTag ()

	set = Items.TagsList.ChoiceList;
	set.Delete ( set.FindByValue ( TagsList ) );

endprocedure

// *****************************************
// *********** Access

&atclient
procedure AccessOnChange ( Item )

	applyAccess ();

endprocedure

&atclient
procedure applyAccess ()

	if ( Object.Access ) then
		defaultAccess ();
	else
		Object.Users.Clear ();
	endif;
	Appearance.Apply ( ThisObject, "Object.Access" );

endprocedure

&atclient
procedure defaultAccess ()

	table = Object.Users;
	if ( table.Count () <> 0 ) then
		return;
	endif;
	creator = Object.Creator;
	row = table.Add ();
	row.User = creator;
	user = EnvironmentSrv.User ();
	if ( user <> creator ) then
		row = table.Add ();
		row.User = user;
	endif;

endprocedure

// *****************************************
// *********** Editor

&atclient
function initEngine ()

	engine = engine ();
	info = new SystemInfo ();
	engine.init ( info.AppVersion );
	engine.minimap ( false );
	engine.disableContextMenu (); // Context menu doesn't work properly on Linux
	engine.setOption ( "disableContextQueryConstructor", true );
	engine.setOption ( "autoResizeEditorLayout", true );
	engine.setOption ( "renderQueryDelimiters", true );
	engine.setOption ( "generateModificationEvent", true );
	engine.setOption ( "generateDefinitionEvent", true );
	engine.setOption ( "disableDefinitionMessage", true );
	engine.hideScrollX ();
	engine.hideScrollY ();
	return undefined;

endfunction

&atclient
function engine ()

	view = Items.Editor.Document.defaultView;
	view.getCurrentLine ();
	return view;

endfunction

&atclient
function resetMetadata ()

	engine ().clearMetadata ();
	//refreshCommonModules();

endfunction

&atclient
procedure EditorOnClick ( Item, EventData, StandardProcessing )

	if ( Locked ) then
		proceedEditorEvent ( EventData.Event.eventData1C );
	endif;

endprocedure

&atclient
procedure proceedEditorEvent ( Event )

	if ( Event = undefined ) then
		return;
	endif;
	id = Event.event;
	if ( id = "EVENT_CONTENT_CHANGED" ) then
		Modified = true;
	elsif ( id = "EVENT_ON_LINK_CLICK" ) then
		if ( StrFind ( Event.params.href, "e1cib" ) ) then
			GotoURL ( Event.params.href );
		endif;
	elsif ( id = "EVENT_GET_DEFINITION" ) then
		openSubScenario ();
	endif;

endprocedure
