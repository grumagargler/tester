
&atclient
function IsOpen ( Scenario, FoundWindow = undefined ) export
	
	if ( Scenario.IsEmpty () ) then
		return false;
	endif; 
	windows = GetWindows ();
	for each FoundWindow in windows do
		if ( FoundWindow.StartPage ) then
			for each content in FoundWindow.Content do
				if ( findScenario ( content, Scenario ) ) then
					return true;
				endif; 
			enddo; 
		else
			if ( findScenario ( FoundWindow.GetContent (), Scenario ) ) then
				return true;
			endif;
		endif; 
	enddo; 
	return false;
	
endfunction 

&atclient
function findScenario ( Form, Scenario )
	
	return TypeOf ( Form ) = Type ( Enum.FrameworkManagedForm () )
	and StrFind ( "Catalog.Scenarios.Form.Form, Catalog.Versions.Form.Form", Form.FormName ) > 0
	and Form.Parameters.Key = Scenario;
	
endfunction 

&atclient
function GetPicture ( Type ) export
	
	if ( Type = PredefinedValue ( "Enum.Controls.Window" ) ) then
		return 0;
	elsif ( Type = PredefinedValue ( "Enum.Controls.CommandInterface" ) ) then
		return 0;
	elsif ( Type = PredefinedValue ( "Enum.Controls.InterfaceGroup" ) ) then
		return 7;
	elsif ( Type = PredefinedValue ( "Enum.Controls.InterfaceButton" ) ) then
		return 6;
	elsif ( Type = PredefinedValue ( "Enum.Controls.Form" ) ) then
		return 0;
	elsif ( Type = PredefinedValue ( "Enum.Controls.Field" ) ) then
		return 3;
	elsif ( Type = PredefinedValue ( "Enum.Controls.Group" ) ) then
		return 7;
	elsif ( Type = PredefinedValue ( "Enum.Controls.ContextMenu" ) ) then
		return 4;
	elsif ( Type = PredefinedValue ( "Enum.Controls.CommandBar" ) ) then
		return 5;
	elsif ( Type = PredefinedValue ( "Enum.Controls.Button" ) ) then
		return 6;
	elsif ( Type = PredefinedValue ( "Enum.Controls.Table" ) ) then
		return 2;
	elsif ( Type = PredefinedValue ( "Enum.Controls.Decoration" ) ) then
		return 1;
	else
		return 3;
	endif; 
	
endfunction 

&atclient
function FieldType ( Field, Stringify = false ) export
	
	type = TypeOf ( Field );
	if ( type = Type ( "TestedClientApplicationWindow" ) ) then
		return ? ( Stringify, "Window", PredefinedValue ( "Enum.Controls.Window" ) );
	elsif ( type = Type ( "TestedWindowCommandInterface" ) ) then
		return ? ( Stringify, "CommandInterface", PredefinedValue ( "Enum.Controls.CommandInterface" ) );
	elsif ( type = Type ( "TestedCommandInterfaceGroup" ) ) then
			return ? ( Stringify, "InterfaceGroup", PredefinedValue ( "Enum.Controls.InterfaceGroup" ) );
	elsif ( type = Type ( "TestedCommandInterfaceButton" ) ) then
			return ? ( Stringify, "InterfaceButton", PredefinedValue ( "Enum.Controls.InterfaceButton" ) );
	elsif ( type = Type ( "TestedForm" ) ) then
		return ? ( Stringify, "Form", PredefinedValue ( "Enum.Controls.Form" ) );
	elsif ( type = Type ( "TestedFormField" ) ) then
		return ? ( Stringify, "Field", PredefinedValue ( "Enum.Controls.Field" ) );
	elsif ( type = Type ( "TestedFormGroup" ) ) then
		fieldType = Field.Type;
		if ( fieldType = FormGroupType.ContextMenu ) then
			return ? ( Stringify, "ContextMenu", PredefinedValue ( "Enum.Controls.ContextMenu" ) );
		elsif ( fieldType = undefined
			or fieldType = FormGroupType.CommandBar ) then
			return ? ( Stringify, "CommandBar", PredefinedValue ( "Enum.Controls.CommandBar" ) );
		else
			return ? ( Stringify, "Group", PredefinedValue ( "Enum.Controls.Group" ) );
		endif; 
	elsif ( type = Type ( "TestedFormButton" ) ) then
		return ? ( Stringify, "Button", PredefinedValue ( "Enum.Controls.Button" ) );
	elsif ( type = Type ( "TestedFormTable" ) ) then
		return ? ( Stringify, "Table", PredefinedValue ( "Enum.Controls.Table" ) );
	elsif ( type = Type ( "TestedFormDecoration" ) ) then
		return ? ( Stringify, "Decoration", PredefinedValue ( "Enum.Controls.Decoration" ) );
	else
		return ? ( Stringify, "Field", PredefinedValue ( "Enum.Controls.Field" ) );
	endif; 
	
endfunction 

&atclient
procedure Picking ( Owner, SelectOnly ) export
	
	Test.AttachApplication ( SessionScenario );
	p = new Structure ();
	p.Insert ( "SelectOnly", SelectOnly );
	p.Insert ( "Application", SessionApplication );
	form = getActiveForm ();
	if ( form <> undefined ) then
		p.Insert ( "Form", form.Name );
		p.Insert ( "FormTitle", form.Title );
	endif; 
	OpenForm ( "Catalog.Scenarios.Form.Picking", p, Owner );
	
endprocedure 

&atclient
function getActiveForm ()
	
	try
		Test.ConnectClient ( false );
	except
		return undefined;
	endtry;
	wnd = App.GetActiveWindow ();
	form = wnd.FindObject ( Type ( "TestedForm" ) );
	if ( form = undefined ) then
		return undefined;
	else
		return new Structure ( "Name, Title", form.FormName, form.TitleText );
	endif;
	
endfunction 

&atclient
procedure ExecuteExpression ( Expression ) export
	
	Execute ( Expression );
		
endprocedure 

&atclient
procedure OpenAssistant ( Table, NameColumn, Picking, Form, Application ) export
	
	name = ScenarioForm.ControlName ( Table, NameColumn );
	p = new Structure ( "ControlName, ControlType, Picking, Form, Application",
		name, Table.CurrentData.Type, Picking, Form, Application );
	OpenForm ( "Catalog.Assistant.ChoiceForm", p, Table );
	
endprocedure 

&atclient
function ControlName ( Table, NameColumn ) export
	
	row = Table.CurrentData;
	if ( row.Type = PredefinedValue ( "Enum.Controls.Form" ) ) then
		return row.TitleText;
	else
		perfix = ScenarioForm.NamePrefix ( CurrentLanguage () );
		return ? ( Table.CurrentItem = NameColumn, perfix + row.Name, row.TitleText );
	endif; 
	
endfunction

function NamePrefix ( Lang ) export

	return ? ( Lang = "ru", "!", "#" );
	
endfunction 

&atclient
function ApplyAction ( Action ) export
	
	expression = Action.Expression;
	error = false;
	if ( Action.Running ) then
		try
			ScenarioForm.ExecuteExpression ( expression );
		except
			ShowValue ( , ErrorDescription () );
			error = true;
		endtry;
	endif; 
	return not error;
	
endfunction 

&atserver
procedure Init ( Form ) export
	
	object = Form.Object;
	setCreator ( object );
	if ( Form.Parameters.CopyingValue.IsEmpty () ) then
		data = undefined;
		setParent ( object, data );
		setType ( object, data );
	endif;
	setApplication ( Form );

endprocedure 

&atserver
procedure setCreator ( Object )
	
	Object.Creator = SessionParameters.User;
	
endprocedure 

&atserver
procedure setParent ( Object, Data )
	
	Data = undefined;
	parent = Object.Parent;
	if ( parent.IsEmpty () ) then
		return;
	endif; 
	Data = DF.Values ( parent, "Type, Parent" );
	type = Data.Type;
	if ( type = Enums.Scenarios.Scenario ) then
		Object.Parent = Data.Parent;
	endif; 
	
endprocedure 

&atserver
procedure setType ( Object, ParentData )
	
	if ( ParentData = undefined ) then
		Object.Type = Enums.Scenarios.Scenario;
	else
		type = ParentData.Type;
		if ( type = Enums.Scenarios.Library
			or type = Enums.Scenarios.Method ) then
			Object.Type = Enums.Scenarios.Method;
		else
			Object.Type = Enums.Scenarios.Scenario;
		endif; 
	endif; 
	
endprocedure 

&atserver
procedure setApplication ( Form )
	
	value = undefined;
	object = Form.Object;
	if ( Form.Parameters.ChoiceParameters.Property ( "Application", value ) ) then
		if ( TypeOf ( value ) = Type ( "Array" ) ) then
			for each item in value do
				if ( not item.IsEmpty () ) then
					object.Application = item;
					return;
				endif; 
			enddo; 
		endif; 
	else
		parent = object.Parent;
		if ( not parent.IsEmpty () ) then
			object.Application = DF.Pick ( parent, "Application" );
		endif; 
		if ( object.Application.IsEmpty () ) then
			object.Application = EnvironmentSrv.GetApplication ();
		endif; 
	endif;

endprocedure 

&atclient
function SaveParents ( Object, OldParent ) export
	
	if ( wrongParent ( Object ) ) then
		return false;
	endif;
	for each parent in scenarioParents ( Object.Parent, OldParent ) do
		ScenariosPanel.Save ( parent );
	enddo;
	return true;
	
endfunction

&atclient
function wrongParent ( Object )
	
	ref = Object.Ref;
	if ( Object.Parent = ref
		and not ref.IsEmpty () ) then
		Output.WrongFolder ( , "Parent" );
		return true;
	endif;
	return false;
	
endfunction

&atclient
function scenarioParents ( CurrentParent, OldParent )
	
	parents = new Array ();
	if ( ValueIsFilled ( OldParent ) ) then
		parents.Add ( OldParent );
	endif;
	if ( OldParent <> CurrentParent
		and not CurrentParent.IsEmpty () ) then
		parents.Add ( CurrentParent );
	endif;
	return parents;
	
endfunction

&atclient
procedure RereadParents ( Object, OldParent ) export
	
	for each parent in scenarioParents ( Object.Parent, OldParent ) do
		ScenariosPanel.Reread ( parent );
	enddo;

endprocedure

&atclient
procedure ListDrag ( Form, Params, StandardProcessing, Target ) export
	
	#if ( not MobileClient ) then
		if ( not draggingScenarios ( Params ) ) then
			return;
		endif;
		action = Params.Action;
		copying = ( action = DragAction.Copy );
		if ( action = DragAction.Move
			or copying ) then
			StandardProcessing = false;
			ScenarioForm.CopyMove ( Params.Value, Target, copying );
		endif;
	#endif

endprocedure

&atclient
function draggingScenarios ( Params )
	
	scenarios = Params.Value;
	return TypeOf ( scenarios ) = Type ( "Array" )
		or TypeOf ( scenarios [ 0 ] ) = Type ( "CatalogRef.Scenarios" );
	
endfunction

&atclient
procedure CopyMove ( Scenarios, Target, Copying ) export
	
	list = ScenarioFormSrv.HierarchyList ( Scenarios );
	if ( ValueIsFilled ( Target ) ) then
		folder = Target;
		list.Add ( folder );
	else
		folder = undefined;
	endif;
	for each scenario in list do
		ScenariosPanel.Save ( scenario );
	enddo;
	if ( Copying ) then
		if ( folder <> undefined ) then
			reread = new Array ();
			reread.Add ( Target );
		endif;
	else
		reread = list;
	endif;
	context = new Structure ( "Scenarios, Target, Copying, Reread", Scenarios, folder, Copying, reread );
	newApplication = ? ( folder = undefined, undefined, ScenarioFormSrv.InheritApplication ( Scenarios, folder ) );
	if ( newApplication = undefined ) then
		startCopyMove ( context );
	else
		Output.CopyMoveConfirmation ( ThisObject, context, new Structure ( "Application", newApplication ) );
	endif;

endprocedure

&atclient
procedure startCopyMove ( Context )
	
	copying = Context.Copying;
	target = Context.Target;
	ScenarioFormSrv.CopyMove ( Context.Scenarios, target, copying );
	reread = Context.Reread;
	if ( reread <> undefined ) then
		for each scenario in reread do
			ScenariosPanel.Reread ( scenario );
		enddo;
	endif;
	if ( target = undefined ) then
		NotifyChanged ( Type ( "CatalogRef.Scenarios" ) );
	else
		NotifyChanged ( target );
	endif;
	RepositoryFiles.Sync ();

endprocedure

&atclient
procedure CopyMoveConfirmation ( Answer, Context ) export
	
	if ( Answer = DialogReturnCode.No ) then
		return;
	endif;
	startCopyMove ( Context );
	
endprocedure

&atclient
procedure GotoLine ( Scenario, Line, Error ) export
	
	p = new Structure ( "Key", Scenario );
	if ( TypeOf ( Scenario ) = Type ( "CatalogRef.Versions" ) ) then
		form = GetForm ( "Catalog.Versions.ObjectForm", p );
	else
		form = GetForm ( "Catalog.Scenarios.ObjectForm", p );
	endif;
	form.Open ();
	Output.PutMessage ( Error, undefined, undefined, Error, , form.UUID );
	Notify ( Enum.MessageActivateError (), Line, Scenario );
	
endprocedure

&atserver
procedure InitPort ( Port ) export
	
	set = Port.ChoiceList;
	format = Metadata.Catalogs.Applications.Attributes.Port.Format;
	for each item in getApplications () do
		p = item.Port;
		set.Add ( p, item.Code + " | " + Format ( p, format ), , ? ( item.Main, PictureLib.Pin, undefined ) );
	enddo;
	
endprocedure

&atserver
function getApplications ()
	
	s = "
	|select allowed Applications.Code as Code,
	|	isnull ( Ports.Port, Applications.Port ) as Port,
	|	case when Applications.Ref = &Main then true else false end as Main
	|from Catalog.Applications as Applications
	|	//
	|	// Ports
	|	//
	|	left join InformationRegister.Ports as Ports
	|	on Ports.Application = Applications.Ref
	|	and Ports.Session = &Session
	|where not Applications.DeletionMark
	|and not Applications.IsFolder
	|order by Applications.Description
	|";
	q = new Query ( s );
	q.SetParameter ( "Main", EnvironmentSrv.GetApplication () );
	q.SetParameter ( "Session", SessionParameters.Session );
	return q.Execute ().Unload ();
	
endfunction

function CheckName ( Name ) export

	forbidden = "\ / : * ? "" < > | . ^ , $ # @ ` ~ & % ( ) { } - + =";
	description = Name;
	for each restriction in StrSplit ( forbidden, " " ) do
		if ( StrFind(description, restriction ) > 0 ) then
			return false;
		endif;
	enddo;
	return true;

endfunction