&atclient
var Reference;
&atclient
var ReferenceCode;
&atclient
var Buitin;
&atclient
var AssistantRow;
&atclient
var NavigationLink;

// *****************************************
// *********** Form events

&atserver
procedure OnCreateAtServer ( Cancel, StandardProcessing )
	
	loadParams ();
	setQuery ();
	filterList ();
	
endprocedure

&atserver
procedure loadParams ()
	
	ControlName = Parameters.ControlName;
	TypeFilter = Parameters.ControlType;
	Picking = Parameters.Picking;
	
endprocedure 

&atserver
procedure setQuery ()
	
	if ( CurrentLanguage () = Metadata.Languages.Russian ) then
		callMethod = "Вызвать";
	else
		callMethod = "Call";
	endif; 
	callMethod = """" + callMethod + " ( " + """""""" + " + Catalog.Path + """""" );""";
	s = "
	|select Catalog.Ref as Ref, Catalog.Description as Description, Catalog.Body as Body,
	|	Catalog.Explanation as Explanation, Catalog.Help as Help, Catalog.Code as Code, Usage.Date as Date,
	|	Catalog.Button as Button, Catalog.CommandBar as CommandBar, Catalog.CommandInterface as CommandInterface,
	|	Catalog.ContextMenu as ContextMenu, Catalog.Decoration as Decoration, Catalog.Field as Field,
	|	Catalog.Form as Form, Catalog.GroupType as GroupType, Catalog.InterfaceButton as InterfaceButton,
	|	Catalog.InterfaceGroup as InterfaceGroup, Catalog.Table as Table, Catalog.Window as Window,
	|	case when Catalog.Ref = value ( Catalog.Assistant.EmptyRef ) then 0 else 1 end as Image
	|from (
	|	select Catalog.Ref as Ref, Catalog.Description as Description, Catalog.Body as Body,
	|		Catalog.Explanation as Explanation, """" as Help, Catalog.Code as Code,
	|		0 as Button, 0 as CommandBar, 0 as CommandInterface, 0 as ContextMenu, 0 as Decoration,
	|		0 as Field, 0 as Form, 0 as GroupType, 0 as InterfaceButton, 0 as InterfaceGroup, 0 as Table, 0 as Window
	|	from Catalog.Assistant as Catalog
	|	where not Catalog.DeletionMark
	|	union all
	|	" + getBuiltin () + "
	|	) as Catalog
	|	//
	|	// Usage
	|	//
	|	left join InformationRegister.Usage as Usage
	|	on Usage.User = &User
	|	and Usage.Reference = 0
	|	and Usage.Code = Catalog.Code
	|union all
	|select Catalog.Ref, " + callMethod + ", " + callMethod + ", """", """", Catalog.Code, Usage.Date,
	|	0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1
	|from Catalog.Scenarios as Catalog
	|	//
	|	// Usage
	|	//
	|	left join InformationRegister.Usage as Usage
	|	on Usage.User = &User
	|	and Usage.Reference = 1
	|	and Usage.Code = Catalog.Code
	|where not Catalog.DeletionMark
	|and Catalog.Application in ( value ( Catalog.Applications.EmptyRef ), &Application )
	|and Catalog.Type = value ( Enum.Scenarios.Method )
	|";
	List.QueryText = s;
	DC.SetParameter ( List, "User", SessionParameters.User );
	DC.SetParameter ( List, "Application", Parameters.Application );
	
endprocedure 

&atserver
function getBuiltin ()
	
	parts = new Array ();
	t = Catalogs.Assistant.GetTemplate ( "Builtin" );
	for i = 2 to t.TableHeight do
		selection = new Array ();
		for j = 1 to t.TableWidth do
			cell = t.Area ( i, j, i, j );
			selection.Add ( ? ( j > 5, ? ( cell.Parameter = undefined, 0, 1 ), """" + cell.Text + """" ) );
		enddo; 
		parts.Add ( "select value ( Catalog.Assistant.EmptyRef ), " + StrConcat ( selection, "," ) );
	enddo; 
	return StrConcat ( parts, " union all " );
	
endfunction 

&atserver
procedure filterList ()
	
	filterByType ();
	if ( not Picking ) then
		return;
	endif; 
	DC.ChangeFilter ( List, "Ref", Catalogs.Assistant.EmptyRef (), true );
	
endprocedure 

&atserver
procedure filterByType ()
	
	if ( not LastFilter.IsEmpty () ) then
		DC.DeleteFilter ( List, getColumn ( LastFilter ) );
	endif; 
	if ( not TypeFilter.IsEmpty () ) then
		DC.ChangeFilter ( List, getColumn ( TypeFilter ), 1, true );
	endif; 
	LastFilter = TypeFilter;
	
endprocedure 

&atserver
function getColumn ( Control )
	
	column = Conversion.EnumToName ( Control );
	if ( column = "Group" ) then
		column = column + "Type";
	endif; 
	return column;
	
endfunction 

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
procedure OnOpen ( Cancel )
	
	startListener ();
	
endprocedure

&atclient
procedure startListener ()
	
	AttachIdleHandler ( "listener", 0.1, true );
	
endprocedure 

&atclient
procedure listener ()
	
	if ( AssistantRow <> Items.List.CurrentData ) then
		readRow ();
		if ( AssistantRow = undefined ) then
			showExplanation ();
		else
			if ( Buitin ) then
				helpOnline ();
			else
				showExplanation ();
			endif; 
		endif; 
	endif; 
	startListener ();

endprocedure 

&atclient
procedure readRow ()
	
	AssistantRow = Items.List.CurrentData;
	if ( AssistantRow = undefined ) then
		return;
	endif; 
	ReferenceCode = AssistantRow.Code;
	ref = AssistantRow.Ref;
	type = TypeOf ( ref );
	if ( type = Type ( "CatalogRef.Assistant" ) ) then
		Reference = 0;
		Buitin = ref.IsEmpty ();
	else
		Reference = 1;
		Buitin = false;
	endif;
	
endprocedure

&atclient
procedure showExplanation ()
	
	Items.HelpPages.CurrentPage = Items.UserHelpPage;
	HTML = "";
	
endprocedure 

&atclient
procedure helpOnline ()
	
	Items.HelpPages.CurrentPage = Items.BuiltinHelpPage;
	HTML = OnlineHelp.Href ( getLink () );
				
endprocedure

&atclient
function getLink ()
	
	return ? ( AssistantRow = undefined, "", Lower ( AssistantRow.Help ) );
	
endfunction 

// *****************************************
// *********** List

&atclient
procedure Create ( Command )
	
	openElement ( true );
	
endprocedure

&atclient
procedure openElement ( CreateNew )
	
	tableRow = Items.List.CurrentData;
	ref = ? ( tableRow = undefined or CreateNew, PredefinedValue ( "Catalog.Assistant.EmptyRef" ), tableRow.Ref );
	edit = not CreateNew;
	if ( edit
		and ref.IsEmpty () ) then
		Output.AssistantBuiltin ();
	else
		p = new Structure ( "Key", ref );
		OpenForm ( form ( ref ), p, ThisObject, , , , new NotifyDescription ( "HintCreated", ThisObject ) );
	endif; 
	
endprocedure 

&atclient
function form ( Ref )
	
	if ( TypeOf ( Ref ) = Type ( "CatalogRef.Scenarios" ) ) then
		return "Catalog.Scenarios.ObjectForm";
	else
		return "Catalog.Assistant.ObjectForm";
	endif; 
	
endfunction 

&atclient
procedure HintCreated ( Result, Params ) export
	
	Items.List.Refresh ();
	
endprocedure 

&atclient
procedure Edit ( Command )
	
	openElement ( false );
	
endprocedure

&atclient
procedure ListValueChoice ( Item, Value, StandardProcessing )
	
	StandardProcessing = false;
	readRow ();
	if ( Buitin ) then
		openParams ();
	else
		notifySelection ();
	endif; 

endprocedure

&atclient
procedure openParams ()
	
	data = Items.List.CurrentData;
	if ( data.Help = "CheckTable"
		and ControlName <> "" ) then
		p = new Structure ( "Method, Table, Form", data.Description, ControlName, Parameters.Form );
		form = "Catalog.Assistant.Form.CheckTable"
	else
		p = new Structure ( "Method, ControlName, Picking, Help", data.Description, ControlName, Picking, getLink () );
		form = "Catalog.Assistant.Form.Params";
	endif;
	OpenForm ( form, p, ThisObject, , , , new NotifyDescription ( "AssistantParams", ThisObject ) );

endprocedure 

&atclient
procedure AssistantParams ( Details, Params ) export
	
	if ( Details = undefined ) then
		return;
	endif; 
	notifyOwner ( Details );	
	
endprocedure 

&atclient
procedure notifyOwner ( Params )
	
	updateUsage ( Reference, ReferenceCode );
	NotifyChoice ( Params );

endprocedure 

&atservernocontext
procedure updateUsage ( val Reference, val Code )
	
	r = InformationRegisters.Usage.CreateRecordManager ();
	r.User = SessionParameters.User;
	r.Reference = Reference;
	r.Code = Code;
	r.Date = CurrentSessionDate ();
	r.Write ();
	
endprocedure 

&atclient
procedure notifySelection ()
	
	data = Items.List.CurrentData;
	value = data.Body;
	if ( IsBlankString ( value ) ) then
		value = data.Description;
	endif;
	notifyOwner ( value );
		
endprocedure 

// *****************************************
// *********** HTML

&atclient
procedure HTMLDocumentComplete ( Item )
	
	if ( Framework.VersionLess ( "8.3.14" ) ) then
		return;
	endif;
	newLink = getLink ();
	if ( newLink = NavigationLink ) then
		return;
	endif;
	NavigationLink = newLink;
	Item.Document.location.hash = "#" + newLink;

endprocedure
