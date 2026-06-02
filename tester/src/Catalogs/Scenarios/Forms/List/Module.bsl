&atclient
var TableRow;

// *****************************************
// *********** Form events

&atserver
procedure OnCreateAtServer ( Cancel, StandardProcessing )
	
	initTags ();
	bindWorkplace ();
	setView ();
	setFilters ();
	showFilters ( ThisObject );
	readAppearance ();
	Appearance.Apply ( ThisObject );
	
endprocedure

&atserver
procedure readAppearance ()

	rules = new Array ();
	rules.Add ( "
	|GroupOptions show ShowOptions;
	|Restart show not TestedMode;
	|ListContextMenuRun show TestedMode
	|" );
	Appearance.Read ( ThisObject, rules );

endprocedure

&atserver
procedure initTags ()
	
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
procedure bindWorkplace ()
	
	params = new Array ();
	params.Add ( new ChoiceParameter ( "Filter.Owner", SessionParameters.User ) );
	Items.WorkplaceFilter.ChoiceParameters = new FixedArray ( params );
	
endprocedure 

&atserver
procedure setView ()
	
	control = Items.List;
	if ( StatusFilter = 0
		and IsBlankString ( SearchString )
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
	filterByApplication ();
	filterByWorkplace ();
	filterByDeletion ();
	
endprocedure 

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
	
	initProperties ();
	Appearance.Apply ( ThisObject );
	
endprocedure

&atclient
procedure initProperties ()

	if ( TestManager = true ) then
		TestedMode = true;
	else
		TestedMode = false;
	endif;

endprocedure

&atclient
procedure NewWriteProcessing ( NewObject, Source, StandardProcessing )
	
	type = TypeOf ( NewObject );
	if ( type = Type ( "CatalogRef.Tags" ) ) then
		initTags ();
	endif; 
	
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
procedure activateList ()
	
	CurrentItem = Items.List;
	
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
	
	Logins.SaveSettings ( Enum.SettingsWorkplaceFilter (), , WorkplaceFilter );
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
procedure Restart(Command)

	OpenForm ( "Catalog.Scenarios.Form.Restart" );

endprocedure

&atclient
procedure RunScenario ( Command )
	
	RunScenarios.Go ( undefined, false );
	
endprocedure

&atclient
procedure SetCurrent ( Command )
	
	Environment.ChangeApplication ( ApplicationFilter );
	
endprocedure

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
	|<style>" + styles () + "</style>
	|<script type=""text/javascript"">" + scripts () + "</script>
	|</head>
	|<body onload=""highlightWord('" + Highlighting + "')"">
	|<pre>" + body ( Scenario ) + "</pre>
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
	return TableRow.Tree
	and ( type = PredefinedValue ( "Enum.Scenarios.Folder" )
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
