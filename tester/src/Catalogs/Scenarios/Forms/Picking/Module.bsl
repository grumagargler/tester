&atclient
var ControlPosition;
&atclient
var FieldsMap;

// *****************************************
// *********** Form events

&atserver
procedure OnCreateAtServer ( Cancel, StandardProcessing )
	
	loadParams ();
	applyParams ();
	initList ();
	ScenarioForm.InitPort ( Items.Port );
	filterByMetadata ();
	readAppearance ();
	Appearance.Apply ( ThisObject );
	
endprocedure

&atserver
procedure readAppearance ()

	rules = new Array ();
	rules.Add ( "
	|OfflineInfo Connect show not Connected;
	|OnlineInfo Disconnect show Connected;
	|ListUpdateList ListSelectForm ListSync ListContextMenuUpdateList ListContextMenuSelectForm ListContextMenuSync enable Connected;
	|Port enable not Connected
	|" );
	Appearance.Read ( ThisObject, rules );

endprocedure

&atserver
procedure loadParams ()
	
	MetadataFilter = Catalogs.Metadata.Ref ( Parameters.Form );
	
endprocedure 

&atserver
procedure applyParams ()
	
	if ( Parameters.SelectOnly ) then
		Items.Pages.PagesRepresentation = FormPagesRepresentation.None;
		Items.GroupScript.Visible = false;
	endif; 
	
endprocedure 

&atserver
procedure initList ()
	
	DC.SetParameter ( List, "User", SessionParameters.User );
	DC.SetParameter ( List, "Application", Parameters.Application );
	
endprocedure 

&atserver
procedure filterByMetadata ()
	
	DC.ChangeFilter ( List, "Metadata", MetadataFilter, not MetadataFilter.IsEmpty () );
	
endprocedure 

&atserver
procedure OnLoadDataFromSettingsAtServer ( Settings )
	
	filterByType ();
	
endprocedure

&atserver
procedure filterByType ()
	
	DC.ChangeFilter ( List, "Type", TypeFilter, not TypeFilter.IsEmpty () );
	
endprocedure 

&atclient
procedure OnOpen ( Cancel )
	
	init ();
	syncItem ();
	
endprocedure

&atclient
procedure init ()
	
	Port = AppData.Port;
	flagConnected ();
	
endprocedure

&atclient
procedure flagConnected ()
	
	Connected = AppData.Connected;
	Appearance.Apply ( ThisObject, "Connected" );
	
endprocedure

&atclient
procedure syncItem ()
	
	if ( FieldsMap = undefined ) then
		fill ();
	endif; 
	try
		item = CurrentSource.GetCurrentItem ();
	except
		return;
	endtry;
	for each field in FieldsMap do
		if ( field.Value = item ) then
			//@skip-warning
			Items.List.CurrentRow = positionKey ( field.Key, SessionApplication, MetadataFilter );
			break;
		endif; 
	enddo; 
	
endprocedure 

&atservernocontext
function positionKey ( val Position, val Application, val Meta )
	
	p = new Structure ( "User, Application, Metadata, Position" );
	p.User = SessionParameters.User;
	p.Application = Application;
	p.Metadata = Meta;
	p.Position = Position;
	return InformationRegisters.Controls.CreateRecordKey ( p );
	
endfunction 

// *****************************************
// *********** Group Form

&atclient
procedure SelectForm ( Command )
	
	if ( not Connected ) then
		if ( not attach ( Port, true ) ) then
			return;
		endif; 
	endif;
	ShowChooseFromMenu ( new NotifyDescription ( "FormSelected", ThisObject ), findForms (), Items.ListCommands );
	
endprocedure

&atclient
function attach ( ToPort = undefined, Silently )
	
	if ( Silently ) then
		try
			Test.Attach ( ToPort );
			attached = true;
		except
			attached = false;
		endtry;
	else
		Test.Attach ( ToPort );
		attached = true;
	endif;
	flagConnected ();
	return attached;
	
endfunction

&atclient
function findForms ()

	set = new ValueList ();
	objects = App.FindObjects ( Type ( "TestedForm" ) );
	for each form in objects do
		set.Add ( form, form.TitleText );
	enddo; 
	return set;
	
endfunction 

&atclient
procedure FormSelected ( Form, Params ) export
	
	if ( Form <> undefined ) then
		fill ( form.Value );
	endif; 
	
endprocedure 

&atclient
procedure TypeFilterOnChange ( Item )
	
	filterByType ();
	activateList ();
	
endprocedure

&atclient
procedure activateList ()
	
	CurrentItem = Items.List;
	
endprocedure 

&atclient
procedure UpdateList ( Command )
	
	fill ();
	
endprocedure

&atclient
procedure fill ( Form = undefined )
	
	if ( not Connected ) then
		if ( not attach ( Port, true ) ) then
			return;
		endif; 
	endif;
	fillControls ( Form );
	store ();
	withActiveForm ();

endprocedure 

&atclient
procedure fillControls ( Form )
	
	Controls.Clear ();
	ControlPosition = 0;
	FieldsMap = new Map ();
	if ( Form = undefined ) then
		objects = App.GetActiveWindow ().FindObjects ();
	else
		objects = Form.FindObjects ();
		addControl ( Form );
	endif; 
	for each field in objects do
		addControl ( field );
	enddo; 
	
endprocedure 

&atclient
procedure addControl ( Field )
	
	row = Controls.Add ();
	FillPropertyValues ( row, Field );
	row.Position = ControlPosition;
	type = ScenarioForm.FieldType ( Field );
	row.Type = type;
	if ( row.Name = "" ) then
		row.Name = "<" + ? ( row.FormName = "", type, row.FormName ) + ">";
	endif;
	if ( type = PredefinedValue ( "Enum.Controls.Form" ) ) then
		caption = row.TitleText;
		SelectedForm = caption;
		if ( row.FormName = "" ) then
			row.FormName = "SystemDialog_" + caption;
		endif;
	endif; 
	FieldsMap [ ControlPosition ] = Field; // TestedField cannot be used as a key
	ControlPosition = ControlPosition + 1;
	
endprocedure 

&atserver
procedure store ()
	
	MetadataFilter = storeMetadata ();
	filterByMetadata ();
	
endprocedure 

&atserver
function storeMetadata ()
	
	user = SessionParameters.User;
	application = Parameters.Application;
	currentMeta = undefined;
	currentForm = "";
	recordset = undefined;
	for each row in Controls do
		name = row.FormName;
		if ( name <> currentForm ) then
			if ( name <> "" ) then
				currentForm = name;
				currentMeta = Catalogs.Metadata.Ref ( name );
				commitRecordset ( recordset );
				recordset = newRecordset ( currentMeta );
			endif; 
		endif; 
		if ( currentMeta = undefined ) then
			continue;
		endif; 
		r = recordset.Add ();
		r.User = user;
		r.Application = application;
		r.Metadata = currentMeta;
		r.TitleText = row.TitleText;
		r.Type = row.Type;
		r.Name = row.Name;
		r.FormName = name;
		r.Position = row.Position;
	enddo; 
	commitRecordset ( recordset );
	return currentMeta;
	
endfunction

&atserver
procedure commitRecordset ( Recordset )
	
	if ( Recordset <> undefined ) then
		Recordset.Write ();
	endif; 
				
endprocedure 

&atserver
function newRecordset ( Meta )
	
	r = InformationRegisters.Controls.CreateRecordSet ();
	r.Filter.User.Set ( SessionParameters.User );
	r.Filter.Application.Set ( Parameters.Application );
	r.Filter.Metadata.Set ( Meta );
	return r;
	
endfunction

&atclient
procedure withActiveForm ()
	
	#if ( ThinClient or ThickClientManagedApplication ) then
		if ( not Connected ) then
			return;
		endif;
		search = Controls.FindRows ( new Structure ( "Type", PredefinedValue ( "Enum.Controls.Form" ) ) );
		if ( search.Count () = 0 ) then
			name = Parameters.FormTitle;
		else
			name = search [ 0 ].TitleText;
		endif; 
		With ( name );
	#endif
	
endprocedure 

&atclient
procedure CompleteSelection ( Command )
	
	completePicking ();
	
endprocedure

&atclient
procedure completePicking ()
	
	if ( Parameters.SelectOnly ) then
		NotifyChoice ( selectedID () );
	else
		NotifyChoice ( ? ( Script = "", selectedID (), Script ) );
	endif;
		
endprocedure 

&atclient
function selectedID ()
	
	if ( tableRow () = undefined ) then
		return undefined;
	else
		name = ScenarioForm.ControlName ( Items.List, Items.ListName );
		return Conversion.Wrap ( name );
	endif;
	
endfunction 

&atclient
function tableRow ()
	
	return Items.List.CurrentData;
	
endfunction 

&atclient
procedure Sync ( Command )
	
	syncItem ();
	
endprocedure

&atclient
procedure ConnectClient ( Command )
	
	attach ( Port, false );
	fill ();
	activateList ();
	
endprocedure

&atclient
procedure DisconnectClient ( Command )
	
	Test.DisconnectClient ();
	flagConnected ();
	activateList ();
	
endprocedure

// *****************************************
// *********** List

&atclient
procedure ListSelection ( Item, SelectedRow, Field, StandardProcessing )
	
	StandardProcessing = false;
	if ( Parameters.SelectOnly ) then
		completePicking ();
	else
		ScenarioForm.OpenAssistant ( Items.List, Items.ListName, true, SelectedForm, Parameters.Application );
	endif; 
	
endprocedure

&atclient
procedure ListChoiceProcessing ( Item, SelectedValue, StandardProcessing )
	
	StandardProcessing = false;
	applyAction ( SelectedValue );
	
endprocedure

&atclient
procedure applyAction ( Action )
	
	if ( TypeOf ( Action ) = Type ( "String" ) ) then
		Script = Script + Action + Chars.LF;
	else
		error = not ScenarioForm.ApplyAction ( Action );
		if ( error ) then
			Script = Script + "//";
		endif; 
		Script = Script + Action.Expression + Chars.LF;
	endif;
	
endprocedure 
