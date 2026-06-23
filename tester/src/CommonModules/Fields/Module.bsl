function Focus ( Name, Source = undefined, Type = undefined ) export

	place = Source;
	parts = StrSplit ( encode ( Name ), "/" );
	tableType = Type ( "TestedFormTable" );
	rowWasLocated = ( tableType = TypeOf ( Source ) );
	for each part in parts do
		part = decode ( part );
		data = findField ( TrimAll ( part ), place, Type );
		field = data.Field;
		area = data.Area;
		placeIsTable = TypeOf ( place ) = tableType;
		rowWasLocated = rowWasLocated or placeIsTable;
		if ( placeIsTable
			and place.GetSelectedRows ().Count () = 0 ) then
			place.GotoFirstRow ( false );
		endif;
		if ( TypeOf ( data.Field ) = Type ( "TestedFormField" ) ) then
			fieldType = field.Type;
			if ( fieldType = FormFieldType.InputField ) then
				dropListOpened = field.DropListIsOpen ();
			endif;
		endif;
		if ( currentItem ( data.Parent ) <> field ) then
			field.Activate ();
		endif;
		if ( dropListOpened <> undefined
			and not dropListOpened ) then
			// I close the drop-down list to prevent GetActiveWindowControls from fetching
			// history and non-deterministic data. The AI Agent should intentionally
			// open the list if it needs it.
			try
				field.CloseDropList ();
			except
			endtry;
		endif;
		if ( area <> undefined ) then
			if ( fieldType = FormFieldType.SpreadsheetDocumentField ) then
				field.SetCurrentArea ( area );
			elsif ( not rowWasLocated
				and fieldType <> FormFieldType.LabelField ) then
				locateRow ( ? ( place = undefined, tableOfColumn ( field ), place ), area );
			endif;
		endif;
		place = field;
	enddo;
	return data;

endfunction

function tableOfColumn ( Control )

	type = TypeOf ( Control );
	if ( type = Type ( "TestedFormField" )
		or type = Type ( "TestedFormGroup" ) ) then
		parent = Control.GetParent ();
		if ( TypeOf ( parent ) = Type ( "TestedFormTable" ) ) then
			return parent;
		else
			return tableOfColumn ( parent );
		endif;
	endif;
	return undefined;

endfunction

function currentItem ( val Control )

	while ( true ) do
		type = TypeOf ( Control );
		if ( type = Type ( "TestedForm" ) ) then
			try
				return Control.GetCurrentItem ();
			except
				return undefined;
			endtry;
		elsif ( type = Type ( "TestedClientApplicationWindow" ) ) then
			objects = Control.GetChildObjects ();
			if ( objects.Count () = 0 ) then
				break;
			else
				Control = objects [ 0 ];
			endif;
		elsif ( Control = undefined ) then
			break;
		else
			Control = Control.GetParent ();
		endif;
	enddo;
	return undefined;

endfunction

function encode ( Name )

	return StrReplace ( Name, "\/", "27E9292F" );

endfunction

function decode ( Name )

	return StrReplace ( Name, "27E9292F", "/" );

endfunction

function findField ( Name, Source = undefined, Type = undefined )

	result = new Structure ( "Name, Field, Area, Parent", Name );
	window = ? ( Source = undefined, CurrentSource, Source );
	if ( window = undefined ) then
		window = With ();
	endif;
	table = TypeOf ( window ) = Type ( "TestedFormTable" );
	fieldType = getFieldType ( Type );
	cell = cellInfo ( Name );
	if ( isID ( Name ) ) then
		if ( cell = undefined ) then
			field = window.GetObject ( fieldType, , Mid ( Name, 2 ) );
			if ( not table ) then
				implicitTable = tableOfColumn ( field );
				if ( implicitTable <> undefined ) then
					return findField ( Name, implicitTable );
				endif;
			endif;
			result.Field = field;
		else
			if ( table ) then
				locateRow ( window, cell.Area );
			endif;
			field = window.GetObject ( fieldType, , Mid ( cell.Field, 2 ) );
			if ( not table ) then
				implicitTable = tableOfColumn ( field );
				if ( implicitTable <> undefined ) then
					return findField ( Name, implicitTable );
				endif;
			endif;
			result.Field = field;
			result.Area = cell.Area;
		endif;
	else
		if ( cell = undefined ) then
			objects = window.FindObjects ( fieldType, Name );
		else
			if ( table ) then
				locateRow ( window, cell.Area );
			endif;
			objects = window.FindObjects ( fieldType, cell.Field );
			result.Area = cell.Area;
		endif;
		count = objects.Count ();
		if ( count = 0 ) then
			try
				result = findField ( "!" + Name, Source, Type );
				return result;
			except
			endtry;
			s = Name + ? ( Type = undefined, "", " (" + Type + ")" );
			raise Output.FieldNotFound ( new Structure ( "Field", s ) );
		else
			if ( count > 1 ) then
				showObjects ( Name, objects );
			endif;
			result.Field = objects [ 0 ];
		endif;
	endif;
	result.Parent = window;
	return result;

endfunction

function isID ( Name )

	return ( StrStartsWith ( Name, "#" )
		or StrStartsWith ( Name, "!" ) )
		and StrLen ( Name ) <> 1;

endfunction

function cellInfo ( Name )

	result = undefined;
	i = StrFind ( Name, "[" );
	if ( i > 0 ) then
		j = StrFind ( Name, "]", , i );
		if ( j > 0 ) then
			result = new Structure ();
			result.Insert ( "Field", TrimR ( Left ( Name, i - 1 ) ) );
			result.Insert ( "Area", TrimAll ( Mid ( Name, i + 1, j - i - 1 ) ) );
		endif;
	endif;
	return result;

endfunction

procedure locateRow ( Table, Row )

#if ( ThinClient or ThickClientManagedApplication ) then
	editing = Table.CurrentModeIsEdit ();
	if ( editing ) then
		Table.EndEditRow ();
	else
		Table.Activate ();
	endif;
	try
		// This navigation is "just in case".
		// We do not care if first row is aready activated
		Table.GotoFirstRow ( false );
	except
	endtry;
	column = SpecialFields.LineNo;
	field = Table.FindObject ( , column );
	if ( field = undefined
		or not field.CurrentVisible () ) then
		for i = 1 to Number ( Row ) - 1 do
			Table.GotoNextRow ( false );
		enddo;
	else
		search = new Map ();
		search.Insert ( column, Row );
		Table.GotoRow ( search, RowGotoDirection.Down );
	endif;
	if ( editing ) then
		Table.ChangeRow ();
	endif;
#endif

endprocedure

function Retrieve ( Name, Source = undefined, Type = undefined ) export

	place = Source;
	parts = StrSplit ( encode ( Name ), "/" );
	for each part in parts do
		part = decode ( part );
		data = findField ( TrimAll ( part ), place, Type );
		place = data.Field;
	enddo;
	return data;

endfunction

procedure showObjects ( Field, Objects )

	types = new Array ();
	types.Add ( Type ( "TestedFormDecoration" ) );
	types.Add ( Type ( "TestedFormField" ) );
	types.Add ( Type ( "TestedFormGroup" ) );
	types.Add ( Type ( "TestedFormButton" ) );
	types.Add ( Type ( "TestedFormItemAddition" ) );
	places = new Array ();
	for each obj in Objects do
		objType = TypeOf ( obj );
		info = "" + objType;
		if ( types.Find ( objType ) <> undefined ) then
			info = info + " / " + obj.Type;
		endif;
		places.Add ( Output.NameAndType ( new Structure ( "Name, Type", obj.Name, info ) ) );
	enddo;
	s = StrConcat ( places, ", " );
	s = s + ". " + Output.AvoidAmbiguity ();
	p = new Structure ();
	p.Insert ( "Field", Field );
	p.Insert ( "Places", s );
	warning = Output.ManyPlaces ( p );
	Runtime.ShowWarning ( warning );

endprocedure

function getFieldType ( Type )

	if ( Type = undefined ) then
		return undefined;
	elsif ( Type = "Field"
		or Type = "Поле" ) then
		return Type ( "TestedFormField" );
	elsif ( Type = "Group"
		or Type = "Группа" ) then
		return Type ( "TestedFormGroup" );
	elsif ( Type = "Button"
		or Type = "Кнопка" ) then
		return Type ( "TestedFormButton" );
	elsif ( Type = "Table"
		or Type = "Таблица" ) then
		return Type ( "TestedFormTable" );
	elsif ( Type = "Decoration"
		or Type = "Декорация" ) then
		return Type ( "TestedFormDecoration" );
	endif;

endfunction

function FetchValue ( Field, Source = undefined, Type = undefined ) export

	if ( TypeOf ( Field ) = Type ( "String" ) ) then
		data = Fields.Retrieve ( Field, Source, Type );
		element = data.Field;
		area = data.Area;
		parent = data.Parent;
	else
		element = Field;
		area = undefined;
		parent = undefined;
	endif;
	tableType = Type ( "TestedFormTable" );
	if ( TypeOf ( Source ) = tableType ) then
		element.Activate ();
		if ( area <> undefined ) then
			locateRow ( Source, area );
		endif;
		return RemoveSeachingTags ( Source.GetCellText () );
	else
		elementType = element.Type;
		if ( elementType = FormFieldType.SpreadsheetDocumentField ) then
			return element.GetAreaText ( ? ( area = undefined, element.GetCurrentAreaAddress (), area ) );
		else
			if ( TypeOf ( parent ) = tableType ) then
				return RemoveSeachingTags ( parent.GetCellText ( element.Name ) );
			else
				return getDisplayedText ( element, undefined );
			endif;
		endif;
	endif;

endfunction

function RemoveSeachingTags ( Text ) export

	return Regexp.Replace ( Text, "<[^>]*>", "" );

endfunction

function getDisplayedText ( Control, ClientField )

	data = "";
	type = Control.Type;
	if ( type = FormFieldType.InputField ) then
		if ( ClientField = undefined ) then
			try
				data = Control.GetDisplayedText ();
			except
			endtry;
		else
			data = ? ( IsBlankString ( ClientField.EditText ), ClientField.FieldValue, ClientField.EditText );
		endif;
	elsif ( type = FormFieldType.CheckBoxField ) then
		try
			data = Boolean ( Control.GetDataPresentation () );
		except
			try
				data = Control.GetDisplayedText ();
			except
			endtry;
		endtry;
	elsif ( type = FormFieldType.RadioButtonField
		or type = FormFieldType.LabelField ) then
		try
			data = Control.GetDisplayedText ();
		except
		endtry;
	else
		try
			data = Control.GetDataPresentation ();
		except
		endtry;
	endif;
	return data;

endfunction

procedure CheckValue ( Field, Value, Source = undefined, Type = undefined ) export

	if ( TypeOf ( Source ) = Type ( "TestedFormTable" ) ) then
		// Bug workaroud for 8.3.7.1901: The method EndEditRow should be executed,
		// otherwise, system will be adding rows into the Table infinitely
		try
			Source.EndEditRow ();
		except
		endtry;
	endif;
	result = Fields.FetchValue ( Field, Source, Type );
	if ( TableProcessor.ValuesEqual ( result, Value ) ) then
		return;
	endif;
	p = new Structure ();
	if ( TypeOf ( CurrentSource ) = Type ( "TestedForm" ) ) then
		form = CurrentSource.FormName;
		title = CurrentSource.TitleText;
	else
		form = "<...>";
		title = "<...>";
	endif;
	p.Insert ( "Form", form );
	p.Insert ( "Title", title );
	name = ? ( TypeOf ( Field ) = Type ( "String" ), Field, Field.TitleText );
	p.Insert ( "Field", name );
	p.Insert ( "Value", Value );
	p.Insert ( "Result", result );
	Runtime.ThrowError ( Output.CheckError ( p ), Debug );

endprocedure

procedure CheckTableContent ( Table, Params, Options, Source ) export

	TableProcessor.CompareFieldAndTable ( Table, Params, Options, Source );

endprocedure

procedure CheckAppearance ( Name, Value, Flag = true, Source = undefined, Type = undefined ) export

	field = Fields.Retrieve ( Name, Source, Type ).Field;
	if ( Value = "Visible"
		or Value = "Видимость" ) then
		state = field.CurrentVisible ();
	elsif ( Value = "Enable"
		or Value = "Доступность" ) then
		state = field.CurrentEnable ();
	elsif ( Value = "ReadOnly"
		or Value = "ТолькоЧтение" ) then
		state = field.CurrentReadOnly ();
	else
		p = new Structure ();
		p.Insert ( "Value", Value );
		Runtime.ThrowError ( Output.CheckAppearanceIncorrect ( p ), Debug );
		return;
	endif;
	if ( state = Flag ) then
		return;
	endif;
	p = new Structure ();
	p.Insert ( "Field", Name );
	p.Insert ( "Value", Value );
	p.Insert ( "Flag", Flag );
	p.Insert ( "State", state );
	Runtime.ThrowError ( Output.CheckAppearanceError ( p ), Debug );

endprocedure

procedure CheckSpreadsheet ( Name, Source = undefined, Type = undefined, Template = undefined ) export

	if ( Template = undefined ) then
		stack = Debug.Stack [ Debug.Level ];
		spreadsheet = RuntimeSrv.GetSpreadsheet ( stack.Module, stack.IsVersion );
		if ( spreadsheet = undefined ) then
			raise Output.TemplateEmpty ();
		endif;
	else
		spreadsheet = Template;
	endif;
	result = Fields.Retrieve ( Name, Source, Type ).Field;
	areas = Collections.DeserializeTable ( spreadsheet.Areas );
	tabDoc = spreadsheet.Template;
	for each range in areas do
		for j = range.Up to range.Bottom do
			for i = range.Left to range.Right do
				area = getArea ( j, i );
				original = tabDoc.Area ( area ).Text;
				actual = result.GetAreaText ( area );
				if ( not equal ( original, actual ) ) then
					p = new Structure ( "Area, Original, Actual", area, original, actual );
					raise Output.AreaComparisonError ( p );
				endif;
			enddo;
		enddo;
	enddo;

endprocedure

function getArea ( R, C )

	return "R" + Format ( R, "NG=" ) + "C" + Format ( C, "NG=" );

endfunction

function equal ( Original, Actual )

	if ( Original = "{*}" ) then
		return not IsBlankString ( Actual );
	elsif ( StrStartsWith ( Original, "{" )
		and StrEndsWith ( Original, "}" ) ) then
		s = TrimAll ( Original );
		s = Mid ( s, 2, StrLen ( s ) - 2 );
		s = Output.Sformat ( s, __ );
		asterisk = StrFind ( s, "*" );
		if ( asterisk = 0 ) then
			return s = Actual;
		elsif ( asterisk = 1 ) then
			return StrEndsWith ( Actual, Mid ( s, asterisk + 1 ) );
		else
			return StrStartsWith ( Actual, Left ( s, asterisk - 1 ) );
		endif;
	else
		return Lower ( Original ) = Lower ( Actual );
	endif;

endfunction

function GetControl ( Name, Source = undefined, Type = undefined ) export

	data = Fields.Retrieve ( Name, Source, Type );
	field = data.Field;
	area = data.Area;
	if ( data.Area <> undefined ) then
		if ( field.Type = FormFieldType.SpreadsheetDocumentField ) then
			field.SetCurrentArea ( area );
			data.Field = field.GetCurrentAreaField ();
		else
			table = data.Parent;
			if ( table = undefined ) then
				locateRow ( Source, area );
			else
				locateRow ( table, area );
			endif;
		endif;
	endif;
	return data;

endfunction

function SetValue ( Name, Value, Source = undefined, Type = undefined, ChooseValue = false, TestSelection = false ) export

	data = Fields.Focus ( Name, Source, Type );
	field = data.Field;
	fieldType = field.Type;
	if ( fieldType = FormFieldType.RadioButtonField ) then
		field.SelectOption ( Value );
	elsif ( fieldType = FormFieldType.TrackBarField ) then
		field.GotoValue ( Value );
	else
		stringValue = String ( Value );
		if ( fieldType = FormFieldType.SpreadsheetDocumentField ) then
			field.BeginEditCurrentArea ();
			putValue ( data, stringValue, ChooseValue, TestSelection );
			field.EndEditCurrentArea ();
		elsif ( fieldType = FormFieldType.InputField ) then
			table = editRow ( data, Source );
			putValue ( data, stringValue, ChooseValue, TestSelection );
			finishEditing ( table );
		elsif ( fieldType = FormFieldType.FormattedDocumentField ) then
			if ( Framework.VersionLess ( "8.3.13" ) ) then
				field.InputHTML ( Value );
			else
				field.InputDocumentHTML ( Value );
			endif;
		elsif ( fieldType = FormFieldType.CheckBoxField ) then
			table = editRow ( data, Source );
			currentValue = Boolean ( field.GetDataPresentation () );
			if ( currentValue <> Boolean ( Value ) ) then
				field.SetCheck ();
			endif;
			finishEditing ( table );
		else
			field.InputText ( Value );
			if ( fieldType = FormItemAdditionType.SearchStringRepresentation ) then
				Pause ( TesterDynamicListSearchWaitTime );
			endif;
		endif;
	endif;
	return field;

endfunction

procedure putValue ( FieldData, Value, ChooseValue, TestSelection )

	field = FieldData.Field;
	try
		field.InputText ( Value );
	except
		error = ErrorProcessing.BriefErrorDescription ( ErrorInfo () );
		readonly = field.CurrentReadOnly ();
		raise error + ? ( StrEndsWith ( error, "." ), " ", ". " )
			+ ? ( readonly, Output.FieldIsReadOnly (), Output.SetValueFailed () );
	endtry;
	if ( ChooseValue ) then
		try
			opened = field.WaitForDropListGeneration ();
		except
			opened = false;
		endtry;
		if ( opened ) then
			if ( field.DropListIsOpen () ) then
				field.ExecuteChoiceFromChoiceList ( 0 );
				if ( TestSelection ) then
					fieldName = FieldData.Name;
					newValue = Fields.FetchValue ( fieldName, FieldData.Parent );
					if ( Lower ( newValue ) <> Lower ( Value ) ) then
						Fields.ClearControl ( fieldName );
						raise Output.WrongFieldValue ( new Structure ( "NewValue", newValue ) );
					endif;
				endif;
			endif;
		endif;
	endif;

endprocedure

function editRow ( FieldData, Source )

	tableType = Type ( "TestedFormTable" );
	if ( TypeOf ( FieldData.Parent ) = tableType ) then
		table = FieldData.Parent;
	elsif ( TypeOf ( Source ) = tableType ) then
		table = Source;
	else
		return undefined;
	endif;
	if ( table.CurrentModeIsEdit () ) then
		return undefined;
	endif;
	table.ChangeRow ();
	return table;

endfunction

procedure finishEditing ( Table )

	if ( Table <> undefined and Table.CurrentModeIsEdit () ) then
		Table.EndEditRow ();
	endif;

endprocedure

function StartChoosing ( Name, Source = undefined, Type = undefined ) export

	data = Fields.Focus ( Name, Source, Type );
	field = data.Field;
	if ( TypeOf ( field ) = Type ( "TestedFormTable" ) ) then
		field.Choose ();
	else
		fieldType = field.Type;
		if ( fieldType = FormFieldType.SpreadsheetDocumentField ) then
			field.BeginEditCurrentArea ();
		else
			editRow ( data, Source );
		endif;
		field.StartChoosing ();
	endif;
	return field;

endfunction

function ClearControl ( Name, Source = undefined, Type = undefined ) export

	data = Fields.GetControl ( Name, Source, Type );
	field = data.Field;
	field.Activate ();
	table = editRow ( data, Source );
	if ( data.Field.Type = FormItemAdditionType.ViewStatusRepresentation ) then
		field = data.Field;
		i = field.GetViewStatusItemTexts ().Count ();
		while ( i > 0 ) do
			i = i - 1;
			field.DeleteViewStatusItem ( i );
		enddo;
	else
		field.Clear ();
	endif;
	finishEditing ( table );
	return data;

endfunction

procedure NextField () export

	type = TypeOf ( CurrentSource );
	if ( type = Type ( "TestedForm" )
		or type = Type ( "TestedFormTable" ) ) then
		CurrentSource.GotoNextItem ();
	else
		raise Output.WrongNextUse ();
	endif;

endprocedure

procedure Select ( Name, Value, Source = undefined, Type = undefined ) export

	data = Fields.Focus ( Name, Source, Type );
	field = data.Field;
	table = editRow ( data, Source );
	if ( not field.DropListIsOpen () ) then
		field.OpenDropList ();
	endif;
	field.ExecuteChoiceFromChoiceList ( Value );
	finishEditing ( table );

endprocedure

function ClickField ( Name, Source = undefined, Type = undefined ) export

	if ( TypeOf ( Source ) = Type ( "TestedWindowCommandInterface" ) ) then
		data = Fields.Retrieve ( Name, Source, Type );
		field = data.Field;
	else
		data = Fields.Focus ( Name, Forms.FindSource ( Source ), Type );
		field = data.Field;
	endif;
	type = TypeOf ( field );
	if ( type = Type ( "TestedFormField" ) ) then
		fieldType = field.Type;
		if ( fieldType = FormFieldType.CheckBoxField ) then
			field.SetCheck ();
		elsif ( fieldType = FormFieldType.LabelField ) then
			try
				field.ClickFormattedStringHyperlink ( getPosition ( data.Area ) );
			except
				try
					field.Click ();
				except
					raise Output.UnableToClick ( new Structure ( "Field", Name ) );
				endtry;
			endtry;
		else
			field.Click ();
		endif;
	elsif ( type = Type ( "TestedFormDecoration" ) ) then
		try
			field.ClickFormattedStringHyperlink ( getPosition ( data.Area ) );
		except
			field.Click ();
		endtry;
	elsif ( type = Type ( "TestedFormGroup" ) ) then
		try
			field.Expand ();
		except
			try
				field.Collapse ();
			except
			endtry;
		endtry;
	elsif ( type = Type ( "TestedFormButton" ) ) then
		try
			field.Click ();
		except
			// Some buttons are enabled but not actually accessible (FormCancelSearch, for example).
			// So, for such buttons we suppress error. Why? Because the AI agent sees that the button is
			// enabled and can legitimately click it
			if ( not controlEnabled ( field ) ) then
				raise;
			endif;
		endtry;
	else
		field.Click ();
	endif;
	return field;

endfunction

function controlEnabled ( val Control )

	enabled = Control.CurrentEnable ();
	if ( TypeOf ( Control ) = Type ( "TestedForm" ) ) then
		return enabled;
	else
		return enabled
			and Control.CurrentVisible ()
			and controlEnabled ( Control.GetParent () );
	endif;

endfunction

function getPosition ( Area )

	if ( Area = undefined ) then
		return 0;
	endif;
	try
		position = Number ( Area );
		return position - 1;
	except
		return Area;
	endtry;

endfunction

procedure ShowValueInInputField ( Name, Source = undefined ) export

	data = Fields.Focus ( Name, Source, Type ( "TestedFormField" ) );
	field = data.Field;
	if ( field.Type <> FormFieldType.InputField ) then
		raise Output.FailedToOpenValue ();
	else
		table = editRow ( data, Source );
		field.Open ();
		finishEditing ( table );
	endif;

endprocedure

function FetchSpreadsheetContent ( Field, Source = undefined ) export

	controlType = Type ( "TestedFormField" );
	if ( TypeOf ( Field ) = Type ( "String" ) ) then
		control = Fields.Retrieve ( Field, Source, controlType ).Field;
	else
		control = Field;
	endif;
	if ( TypeOf ( control ) <> controlType
		or control.Type <> FormFieldType.SpreadsheetDocumentField ) then
		raise Output.SpreadsheetNotFound ();
	endif;
	return fetchSpreadsheet ( control );

endfunction

function fetchSpreadsheet ( Field )

	#if ( not WebClient ) then
		mxl = GetTempFileName ( "mxl" );
		xlsx = GetTempFileName ( "xlsx" );
		App.SetFileDialogResult ( true, mxl );
		Field.WriteContentToFile ();
		waiting = Enum.ConstantsSavingXMLWaitTime ();
		while ( true ) do
			try
				binaryData = new BinaryData ( mxl );
				break;
			except
				if ( waiting > 0 ) then
					Test.PauseExecution ( 1 );
					waiting = waiting - 1;
				else
					raise;
				endif;
			endtry;
		enddo;
		data = FieldsSrv.XLSXData ( binaryData );
		data.Write ( xlsx );
		DeleteFilesAsync ( mxl );
		return xlsx;
	#endif

endfunction

function FetchTableContent ( Field, Source = undefined ) export

	control = getTable ( Field, Source );
	control.GotoFirstRow ();
	control.SelectAllRows ();
	rows = control.GetSelectedRows ();
	selected = rows.Count ();
	if ( selected = 0 ) then
		return new Array ();
	elsif ( selected > Enum.ConstantsTableContentLimit () ) then
		raise Output.TableIsTooBig ();
	else
		return tableData ( control, rows );
	endif;

endfunction

function getTable ( Field, Source )

	controlType = Type ( "TestedFormTable" );
	if ( TypeOf ( Field ) = Type ( "String" ) ) then
		control = Fields.Retrieve ( Field, Source, controlType ).Field;
	else
		control = Field;
	endif;
	if ( TypeOf ( control ) <> controlType ) then
		raise Output.TableNotFound ();
	endif;
	if ( control.CurrentModeIsEdit () ) then
		control.EndEditRow ();
	endif;
	return control;

endfunction

function tableData ( Control, Rows )

	table = new Array ();
	columns = getColumns ( Control.GetChildObjects () );
	selected = Rows.Count ();
	selectAllAllowed = ( selected > 1 );
	if ( selectAllAllowed ) then
		for each row in Rows do
			addToTable ( table, row, columns );
		enddo;
	else
		limit = Enum.ConstantsTableContentLimit ();
		while ( true ) do
			Rows = Control.GetSelectedRows ();
			if ( Rows.Count () = 0 ) then
				break;
			endif;
			addToTable ( table, Rows [ 0 ], columns );
			try
				Control.GotoNextRow ();
			except
				break;
			endtry;
			if ( limit = 0 ) then
				raise Output.TableIsTooBig ();
			endif;
			limit = limit - 1;
		enddo;
		Control.GotoFirstRow ();
	endif;
	return table;

endfunction

function getColumns ( Objects )

	columns = new Array ();
	for each item in Objects do
		type = TypeOf ( item );
		if ( type = Type ( "TestedFormField" ) ) then
			columns.Add ( new Structure ( "Name, Title", item.Name, item.TitleText ) );
		elsif ( type = Type ( "TestedFormGroup" ) ) then
			for each column in getColumns ( item.GetChildObjects () ) do
				columns.Add ( column );
			enddo;
		endif;
	enddo;
	return columns;

endfunction

procedure addToTable ( Table, Row, Columns )

	data = new Structure ();
	for each column in Columns do
		data.Insert ( column.Name, new Structure ( "Title, Value", column.Title, cellValue ( Row [ column.Title ] ) ) );
	enddo;
	Table.Add ( data );

endprocedure

function cellValue ( Value )

	data = RemoveSeachingTags ( StrConcat ( StrSplit ( Value, Char ( 160 ) + Char ( 8239 ) + Char ( 8195 ) + Char ( 8194 ) ) ) );
	if ( LatestSeparatorsInfo <> undefined ) then
		data = toNumber ( data );
	endif;
	return data;

endfunction

function GetWindowControls () export

	formType = Type ( "TestedForm" );
	window = App.GetActiveWindow ();
	controls = window.GetChildObjects ();
	for each element in controls do
		if ( TypeOf ( element ) = formType ) then
			form = element;
			break;
		endif;
	enddo;
	if ( form = undefined ) then
		return undefined;
	endif;
	context = prepareContext ( window, form );
	applyMetadata ( context );
	elements = new Array ();
	prepareElements ( elements, controls, context, false );
	LastActiveWindowControls = Conversion.ToJSON ( elements, false );
	return new Structure ( "ActiveForm, Elements", form,
		? ( elements.Count () = 1, elements [ 0 ], elements ) );

endfunction

function prepareContext ( Window, Form )

	context = new Structure (
		"FormName, CurrentControl, CurrentControlEditingText, CurrentDropList, ClientControls, "
		"Language, Metadata, SourcesFolder",
		Form.FormName );
	currentControl = getCurrentControl ( Form );
	if ( currentControl <> undefined ) then
		context.CurrentControl = currentControl;
		dropList = false;
		type = typeOfControl ( currentControl );
		if ( type = FormFieldType.InputField ) then
			try
				context.CurrentControlEditingText = currentControl.GetDisplayedText ();
			except
			endtry;
			try
				dropList = currentControl.DropListIsOpen ();
			except
			endtry;
		endif;
		context.CurrentDropList = ? ( dropList, currentControl, undefined );
	endif;
	path = AppData.SourcesEDT;
	if ( path = "" ) then
		path = AppData.SourcesDesigner;
	endif;
	if ( path <> "" ) then
		context.SourcesFolder = path;
	endif;
	clientContext = clientContext ( context, Window.Caption );
	if ( clientContext = undefined ) then
		context.Language = CurrentLanguage ();
		LatestSeparatorsInfo = FieldsSrv.Separators ();
	else
		context.Language = clientContext.Language;
		context.ClientControls = clientContext.Items;
		LatestSeparatorsInfo = clientContext.separators;
	endif;
	context.Metadata = getMetadata ( context );
	return context;

endfunction

function getCurrentControl ( Form )

	try
		// There are tricky windows (Type selection) which will
		// throw an exception in this case
		control = Form.GetCurrentItem ();
	except
		return undefined;
	endtry;
	if ( TypeOf ( control ) = Type ( "TestedFormTable" ) ) then
		try
			control = control.GetCurrentItem ();
		except
		endtry;
	endif;
	return control;

endfunction

function typeOfControl ( Control )

	type = TypeOf ( Control );
	if ( type = Type ( "TestedFormField" )
		or type = Type ( "TestedFormGroup" )
		or type = Type ( "TestedFormButton" )
		or type = Type ( "TestedFormDecoration" )
		or type = Type ( "TestedFormItemAddition" ) ) then
		return Control.Type;
	endif;

endfunction

function clientContext ( Context, FormCaption )

	profile = clientProfile ();
	if ( profile = undefined ) then
		return undefined;
	endif;
	formName = Context.FormName;
	sources = Context.SourcesFolder;
	if ( sources <> undefined ) then
		try
			dataPaths = ExternalMeta.GetFormDataPaths ( sources, formName );
		except
			RuntimeSrv.LogException ( "ExternalMeta", ExternalMeta.Problem (), "Warning" );
		endtry;
	endif;
	result = callClient ( "getControls", new Structure (
		"Caption, Form, DataPaths", FormCaption, formName, dataPaths ),
		profile );
	if ( result.success ) then
		content = result.content;
		return new Structure ( "Items, Language, Separators",
			content.items, content.language, content.separators );
	endif;

endfunction

function clientProfile ()

	address = StrSplit ( TesterAgentConnectionString, ":" );
	if ( address.Count () = 2 ) then
		return address;
	endif;

endfunction

function callClient ( Command, Parameters, Profile = undefined )

	if ( Profile = undefined ) then
		address = clientProfile ();
		if ( address = undefined ) then
			return undefined;
		endif;
	else
		address = Profile;
	endif;
	connection = new HTTPConnection ( address [ 0 ], Number ( address [ 1 ] ) );
	request = new HTTPRequest ();
	p = new Structure ( "command, parameters", Command, Parameters );
	request.SetBodyFromString ( Conversion.ToJSON ( p ) );
	response = connection.Post ( request );
	return Conversion.FromJson ( response.GetBodyAsString () );

endfunction

procedure applyMetadata ( Context )

	meta = Context.Metadata;
	clientControls = Context.ClientControls;
	if ( meta = undefined or clientControls = undefined ) then
		return;
	endif;
	sources = new Array ();
	sources.Add ( meta.fields );
	for each table in meta.tables do
		sources.Add ( table.Value );
	enddo;
	control = undefined;
	for each set in sources do
		for each field in set do
			name = field.Key;
			value = field.Value;
			if ( clientControls.Property ( name, control ) ) then
				if ( IsBlankString ( control.ToolTip )
					and not IsBlankString ( value.tooltip ) ) then
					control.Tooltip = value.tooltip;
				endif;
				if ( not IsBlankString ( value.type ) ) then
					control.Insert ( "DataType", value.type );
				endif;
			endif;
		enddo;
	enddo;
	clientControls.Insert ( Enum.ConstantsEntityInfoMark (), meta.explanation );

endprocedure

function getMetadata ( Context )

	sources = Context.SourcesFolder;
	if ( sources = undefined ) then
		return undefined;
	endif;
	try
		return Conversion.FromJSON (
			ExternalMeta.GetFormInfo ( sources, Context.FormName, Context.Language )
		);
	except
		RuntimeSrv.LogException ( "ExternalMeta", ExternalMeta.Problem (), "Warning" );
	endtry;

endfunction

procedure prepareElements ( Elements, Objects, Context, TableItems )

	// What is CurrentDropList for?
	// As soon as a drop-down list is opened in a field, all input fields will report
	// that a drop-down list is opened. So, we have to determine first which field actually
	// has a drop-down list opened
	for each control in Objects do
		try
			next = new Array ( control.GetChildObjects () ); // For some particular forms, testmanager gets error
		except
			continue;
		endtry;
		if ( isInvisible ( control, Context ) ) then
			continue;
		endif;
		element = controlToElement ( control, Context, TableItems );
		Elements.Add ( element );
		if ( next.Count () > 0 ) then
			element.Insert ( "Items", new Array () );
			prepareElements ( element.Items, next, Context, TypeOf ( control ) = Type ( "TestedFormTable" ) );
			if ( element.Items.Count () = 0 ) then
				element.Delete ( "Items" );
			endif;
		endif;
	enddo;

endprocedure

function isInvisible ( Control, Context )

	type = TypeOf ( Control );
	if ( type = Type ( "TestedFormField" )
		or type = Type ( "TestedFormItemAddition" )
		or type = Type ( "TestedFormButton" )
		or type = Type ( "TestedFormDecoration" )
		or type = Type ( "TestedFormGroup" )
		or type = Type ( "TestedFormTable" ) ) then
		// There are some weird controls (such as type selector) which don't
		// have implementation of basic testing methods
		name = Control.Name;
		clientControls = Context.ClientControls;
		if ( clientControls <> undefined and clientControls.Property ( name ) ) then
			item = clientControls [ name ];
			disabledForUser = Context.Metadata <> undefined
				and Context.Metadata.InvisibleFields.Find ( name ) <> undefined;
			return disabledForUser or item.Visible = false or item.Enabled = false;
		else
			try
				return not ( Control.CurrentVisible () and Control.CurrentEnable () );
			except
			endtry;
		endif;
	endif;
	return false;

endfunction

function controlToElement ( Control, Context, ColumnDescription )

	type = TypeOf ( Control );
	if ( type = Type ( "TestedClientApplicationWindow" ) ) then
		element = new Structure ( "Caption, HomePage, IsMain, URL, Type" );
		FillPropertyValues ( element, Control );
	else
		clientControls = Context.ClientControls;
		element = new Structure ( "ID, TitleText, Type" );
		FillPropertyValues ( element, Control );
		if ( type = Type ( "TestedCommandInterfaceButton" ) ) then
			element.Insert ( "URL", Control.URL );
		elsif ( type = Type ( "TestedForm" ) ) then
			formElement ( element, Context );
		else
			element.ID = Control.Name;
			injectTooltip ( Control, element, Context );
			if ( type = Type ( "TestedFormButton" ) ) then
				try
					// Select Type dialog is weird and breaks the documented execution
					if ( controlChecked ( Control, clientControls ) ) then
						element.Insert ( "PressedOrChecked", true );
					endif;
				except
				endtry;
			elsif ( type = Type ( "TestedFormGroup" ) ) then
				groupElement ( Control, element, Context );
			elsif ( type = Type ( "TestedFormDecoration" ) ) then
				if ( clientControls = undefined ) then
					element.Insert ( "DecorationType", String ( Control.Type ) );
				endif;
			elsif ( type = Type ( "TestedFormField" ) ) then
				fieldElement ( Control, element, Context, ColumnDescription );
			elsif ( type = Type ( "TestedFormTable" ) ) then
				tableElement ( Control, element, Context );
			elsif ( type = Type ( "TestedFormItemAddition" )
				and Control.Type = FormItemAdditionType.SearchStringRepresentation ) then
					element.Insert ( "SearchString", true );
			endif;
			removeTitleText ( element, clientControls );
		endif;
	endif;
	injectType ( element, Control, clientControls );
	return element;

endfunction

function controlChecked ( Control, ClientControls )

	name = Control.Name;
	if ( ClientControls <> undefined and ClientControls.Property ( name ) ) then
		return ClientControls [ name ].Check = true;
	else
		return Control.CurrentCheck ();
	endif;

endfunction

procedure formElement ( Element, Context )

	var info;
	Element.ID = Context.FormName;
	clientControls = Context.ClientControls;
	if ( clientControls <> undefined
		and clientControls.Property ( Enum.ConstantsEntityInfoMark (), info ) ) then
		Element.Insert ( "EntityShortDescription", info );
	endif;
	control = Context.CurrentControl;
	if ( control <> undefined ) then
		info = new Structure ( "ID, Title", control.Name, control.TitleText );
		if ( Context.CurrentControlEditingText <> undefined ) then
			info.Insert ( "EditingText", Context.CurrentControlEditingText );
		endif;
		Element.Insert ( "CurrentControl", info );
	endif;

endprocedure

procedure injectTooltip ( Control, Element, Context )

	tooltip = getTooltip ( Control, Context );
	if ( not IsBlankString ( tooltip )
		and Lower ( Element.TitleText ) <> Lower ( tooltip ) ) then
		Element.Insert ( "ToolTip", tooltip );
	endif;

endprocedure

function getTooltip ( Control, Context )

	name = Control.Name;
	clientControls = Context.ClientControls;
	if ( clientControls <> undefined and clientControls.Property ( name ) ) then
		tooltip = clientControls [ name ].Tooltip;
	else
		valueKey = AppName + "#" + Context.FormName + "#" + name;
		if ( CachedControlTooltips [ valueKey ] <> undefined ) then
			return CachedControlTooltips [ valueKey ];
		endif;
		try
			// Even though GetToolTipText is supposed to work for TestedFormField,
			// it is not true for certain controls, such as the type selector
			tooltip = Control.GetToolTipText ();
		except
			return "";
		endtry;
	endif;
	if ( Lower ( name ) = Lower ( StrReplace ( tooltip, " ", "" ) ) ) then
		return "";
	endif;
	CachedControlTooltips [ valueKey ] = tooltip;
	return tooltip;

endfunction

procedure groupElement ( Control, Element, Context )

	clientControls = Context.ClientControls;
	if ( clientControls = undefined ) then
		element.Insert ( "GroupType", String ( Control.Type ) );
		return;
	endif;
	name = Control.Name;
	item = clientControls [ name ];
	if ( item.Collapsible ) then
		element.Insert ( "GroupType", Output.CollapsibleGroup () );
		// Looks like bug in 1C 8.3.27, `CurrentOpened` forks in opposite way
		groupIsClosed = Control.CurrentOpened ();
		if ( groupIsClosed ) then
			element.Insert ( "SystemHint", Output.CollapsibleGroupSystemHint (
				new Structure ( "Name", name ) ) );
		endif;
	endif;
	if ( item.CurrentTab <> undefined ) then
		element.Insert ( "CurrentVisibleTab", item.CurrentTab );
	endif;

endprocedure

procedure fieldElement ( Control, Element, Context, ColumnDescription )

	clientControls = Context.ClientControls;
	controlName = Control.Name;
	if ( clientControls <> undefined and clientControls.Property ( controlName ) ) then
		clientField = clientControls [ controlName ];
	endif;
	type = Control.Type;
	dataType = undefined;
	if ( clientField = undefined ) then
		Element.Insert ( "FieldType", String ( type ) );
	endif;
	if ( clientField <> undefined
		and clientField.Property ( "DataType", dataType ) ) then
		Element.Insert ( "DataType", dataType );
	endif;
	if ( not ColumnDescription ) then
		if ( type = FormFieldType.SpreadsheetDocumentField ) then
			data = spreadsheetInfo ( Control );
		else
			data = getDisplayedText ( Control, clientField );
			if ( numericClientField ( clientField ) ) then
				data = toNumber ( data );
			elsif ( TypeOf ( data ) = Type ( "String" ) ) then
				data = CoreExtension.GetLibrary ( "Root" )
					.NormalizeNumber ( data, LatestSeparatorsInfo.Fractions, LatestSeparatorsInfo.Groups );
			endif;
		endif;
		if ( not IsBlankString ( data ) or type = FormFieldType.InputField ) then
			Element.Insert ( "Value", data );
		endif;
	endif;
	if ( clientField <> undefined ) then
		if ( clientField.ValueListInField = true ) then
			Element.Insert ( "AdditionalInfo",
					Output.ValuesListFieldHint ( new Structure ( "Name", "#" + controlName ) ) );
		endif;
		if ( clientField.ReadOnly = true ) then
			Element.Insert ( "ReadOnly", true );
		endif;
		hint = clientField.InputHint;
		if ( not IsBlankString ( hint ) ) then
			Element.Insert ( "InputHint", hint );
		endif;
		if ( clientField.WarningOnEdit ) then
			Element.Insert ( "WarningOnEdit", true );
			warning = clientField.WarningOnEditText;
			if ( not IsBlankString ( warning ) ) then
				Element.Insert ( "WarningOnEditText", warning );
			endif;
		endif;
	endif;
	if ( type = FormFieldType.InputField ) then
		metaInfo = undefined;
		if ( clientField <> undefined
			and clientField.ReadOnly <> true
			and Context.Metadata <> undefined
			and Context.Metadata.fields.Property ( controlName, metaInfo )
			and metaInfo.FillChecking = "ShowError" ) then
			Element.Insert ( "Mandatory", true );
		endif;
		if ( Control = Context.CurrentDropList ) then
			list = new Array ();
			dropList = Control.GetChoiceListPresentation ();
			index = 0;
			for each item in dropList do
				list.Add ( new Structure ( "Index, Value", index, item.DisplayedText ) );
				index = index + 1;
			enddo;
			Element.Insert ( "DropList", list );
		endif;
	elsif ( type = FormFieldType.RadioButtonField ) then
		Element.Insert ( "AvailableValues", Control.GetChoiceListPresentation () );
	elsif ( type = FormFieldType.TrackBarField
		and clientField <> undefined ) then
		Element.Insert ( "MinValue", clientField.MinValue );
		Element.Insert ( "MaxValue", clientField.MaxValue );
		Element.Insert ( "Step", clientField.Step );
	endif;

endprocedure

function isNumber ( String )

	return TypeOf ( String ) = Type ( "String" )
		and CoreExtension.GetLibrary ( "Root" ).IsNumber ( String );

endfunction

function spreadsheetInfo ( Control )

	rows = Control.GetDocumentDataAreaVerticalSize ();
	columns = Control.GetDocumentDataAreaHorizontalSize ();
	state = Control.GetStatePresentation ();
	info = new Structure ( "RowCount, ColumnCount, CurrentState", rows, columns, state );
	if ( ( rows + columns ) > 0 ) then
		info.Insert ( "Hint", Output.SpreadsheetControlHint ( new Structure ( "Name", "!" + Control.Name ) ) );
	endif;
	return info;

endfunction

procedure tableElement ( Control, Element, Context )

	var table;
	column = Control.GetCurrentItem ();
	if ( column <> undefined ) then
		info = new Structure ( "ID, Title", column.Name, column.TitleText );
		if ( column = Context.CurrentControl
			and Context.CurrentControlEditingText <> undefined ) then
			info.Insert ( "EditingText", Context.CurrentControlEditingText );
		endif;
		Element.Insert ( "CurrentColumn", info );
	endif;
	clientControls = Context.ClientControls;
	if ( clientControls = undefined
		or not clientControls.Property ( Control.Name, table ) ) then
		return;
	endif;
	if ( table.TableIsInChoiceMode = true ) then
		Element.Insert ( "TableIsInChoiceMode", true );
	endif;
	if ( table.Representation <> undefined ) then
		Element.Insert ( "TableRepresentation", table.Representation );
	endif;
	if ( table.AutoInsertNewRow and table.ChangeRowSet ) then
		Element.Insert ( "AutoAddNewRow", true );
	elsif ( not table.ChangeRowSet ) then
		Element.Insert ( "ChangeRowSet", false );
	endif;
	tableData = table.TableData;
	if ( tableData <> undefined ) then
		rows = tableData.Rows;
		if ( rows <> undefined ) then
			for each row in rows do
				adjustTableRow ( row, clientControls );
			enddo;
			Element.Insert ( "RowCount", rows.Count () );
			Element.Insert ( "Rows", rows );
		endif;
		if ( tableData.Info <> undefined ) then
			Element.Insert ( "RowsInfo", tableData.Info );
		endif;
	endif;
	currentRow = table.TableCurrentRow;
	if ( currentRow <> undefined ) then
		if ( tableData <> undefined and tableData.ValueTree ) then
			row = currentRow;
			while ( row <> undefined ) do
				adjustTableRow ( row.Data, ClientControls );
				row = row.Parent;
			enddo;
		else
			adjustTableRow ( currentRow, ClientControls );
		endif;
		Element.Insert ( "CurrentRowData", currentRow );
	endif;
	systemFields = table.TableCurrentRowSystemFields;
	if ( systemFields <> undefined ) then
		Element.Insert ( "CurrentRowSystemFields", systemFields );
	endif;
	currentParent = table.TableCurrentParent;
	if ( currentParent <> undefined ) then
		Element.Insert ( "CurrentRowParent", currentParent );
	endif;
	systemFields = table.TableCurrentParentSystemFields;
	if ( systemFields <> undefined ) then
		Element.Insert ( "CurrentRowParentSystemFields", systemFields );
	endif;

endprocedure

procedure adjustTableRow ( Row, ClientControls )

	var field;
	for each entry in row do
		if ( clientControls.Property ( entry.Key, field )
			and numericClientField ( field ) ) then
			row [ entry.Key ] = toNumber ( entry.Value );
		endif;
	enddo;

endprocedure

function numericClientField ( Field )

	var type;
	return Field <> undefined
		and Field.Property ( "DataType", type )
		and StrFind ( type, "Number(");

endfunction

function toNumber ( Value )

	try
		return Conversion.LocalStringToNumber ( Value,
			LatestSeparatorsInfo.Fractions, LatestSeparatorsInfo.Groups
		);
	except
		return Value;
	endtry;

endfunction

procedure removeTitleText ( Element, ClientControls )

	var field;
	if ( ClientControls <> undefined
		and ClientControls.Property ( Element.ID, field )
		and field.Notitle ) then
		Element.Delete ( "TitleText" );
	endif;

endprocedure

procedure injectType ( Element, Control, ClientControls )

	var field, type;
	if ( ClientControls <> undefined ) then
		conrolType = TypeOf ( Control );
		if ( conrolType = Type ( "TestedClientApplicationWindow" ) ) then
			type = String ( Type ( "ClientApplicationWindow" ) );
		elsif ( conrolType = Type ( "TestedForm" ) ) then
			type = String ( Type ( "ClientApplicationForm" ) );
		elsif ( ClientControls.Property ( Element.ID, field ) ) then
			type = ? ( field.ControlType = undefined, field.Type, field.ControlType );
		else
			type = String ( Control );
		endif;
	endif;
	Element.Type = ? ( type = undefined, String ( Control ), type );

endprocedure

function FetchMainMenu () export

	menu = callClient ( "getMenu", undefined );
	fromCache = menu <> undefined and menu.success and menu.Property ( "content" );
	if ( fromCache ) then
		return menu.content;
	endif;
	interface = MainWindow.GetCommandInterface ();
	sections = interface.FindObject ( , "Sections panel" );
	if ( sections = undefined ) then
		sections = interface.FindObject ( , "Панель разделов" );
	endif;
	if ( sections = undefined ) then
		raise Output.SectionsPanelNotFound ();
	endif;
	sections = sections.GetChildObjects ();
	groupType = Type ( "TestedCommandInterfaceGroup" );
	commandInterface = new Array ();
	functionsMenu = new Array ();
	functionsMenu.Add ( "Functions menu" );
	functionsMenu.Add ( "Меню функций" );
	lastSection = undefined;
	for each section in sections do
		lastSection = section;
		section.Click ();
		menu = undefined;
		for each item in functionsMenu do
			menu = interface.FindObject ( , item );
			probablyWasOpened = ( menu = undefined );
			if ( probablyWasOpened ) then
				section.Click ();
				menu = interface.FindObject ( , item );
			endif;
			if ( menu <> undefined ) then
				break;
			endif;
		enddo;
		subsystemWithOneCommand = ( menu = undefined );
		if ( subsystemWithOneCommand ) then
			CloseAll ();
			continue;
		endif;
		subsystem = new Structure ( "Subsystem, Items", section.TitleText, new Array () );
		group = subsystem;
		commandInterface.Add ( group );
		commands = menu.GetChildObjects ();
		for each command in commands do
			try
				if ( Type ( command ) = groupType ) then
					submenu = new Structure ( "Group, Items", command.TitleText, new Array () );
					for each subcommand in command.GetChildObjects () do
						submenu.Items.Add ( new Structure ( "Item, URL", subcommand.TitleText, subcommand.URL ) );
					enddo;
				else
					submenu = new Structure ( "Item, URL", command.TitleText, command.URL );
				endif;
				subsystem.Items.Add ( submenu );
			except
				// suppress all types of dangled/broken links
			endtry;
		enddo;
	enddo;
	if ( lastSection <> undefined ) then
		lastSection.Click ();
	endif;
	callClient ( "keepMenu", commandInterface );
	return commandInterface;

endfunction

function NavigateToRow ( Table, Column, Value, FromStart, Source ) export

	if ( TypeOf ( Table ) = Type ( "TestedFormTable" ) ) then
		target = Table;
	else
		target = Fields.GetControl ( Table, Forms.FindSource ( Source ), "Table" ).Field;
	endif;
	finishEditing ( target );
	if ( FromStart ) then
		activateFirstRow ( target );
	endif;
	if ( isID ( Column ) ) then
		data = Fields.Retrieve ( Column, Source );
		columnTitle = data.Field.TitleText;
	else
		columnTitle = Column;
	endif;
	search = new Map ();
	search [ columnTitle ] = Value;
	try
		found = target.GotoRow ( search );
	except
		error = ErrorDescription ();
	endtry;
	if ( found = true ) then
		return true;
	else
		currentValue = Fetch ( Column, target );
		if ( value = currentValue ) then
			return true;
		endif;
	endif;
	if ( MCPRequestProcessing = true ) then
		activateFirstRow ( target );
		raise Output.CannotGotoRow ( new Structure ( "Value, Column, Table",
			Value, Column, Table ) );
	endif;
	tableIsEmpty = target.FindObject ( , columnTitle ) <> undefined;
	if ( tableIsEmpty ) then
		return false;
	else
		raise error;
	endif;

endfunction

procedure activateFirstRow ( Table )

	try
		Table.GotoFirstRow ( false );
	except
	endtry;

endprocedure

procedure NavigateToTableRow ( Table, Source, Row ) export

	if ( TypeOf ( Table ) = Type ( "TestedFormTable" ) ) then
		target = Table;
	else
		target = Fields.GetControl ( Table, Forms.FindSource ( Source ), "Table" ).Field;
	endif;
	finishEditing ( target );
	if ( Row = "First" ) then
		target.GotoFirstRow ( false );
	elsif ( Row = "Last" ) then
		target.GotoLastRow ( false );
	elsif ( Row = "Next" ) then
		try
			target.GotoNextRow ( false );
		except
			raise Output.GotoNextRowFailed ();
		endtry;
	elsif ( Row = "Previous" ) then
		try
			target.GotoPreviousRow ( false );
		except
			raise Output.GotoPreviousRowFailed ();
		endtry
	endif;

endprocedure

procedure SetTreeRow ( Table, Source, Closed ) export

	if ( TypeOf ( Table ) = Type ( "TestedFormTable" ) ) then
		target = Table;
	else
		target = Fields.GetControl ( Table, Forms.FindSource ( Source ), "Table" ).Field;
	endif;
	finishEditing ( target );
	expanded = target.Expanded ();
	if ( Closed and expanded ) then
		target.Collapse ();
	elsif ( not ( Closed or expanded ) ) then
		target.Expand ();
	endif;

endprocedure

procedure GotoTableLevel ( Table, Source, Direction ) export

	if ( TypeOf ( Table ) = Type ( "TestedFormTable" ) ) then
		target = Table;
	else
		target = Fields.GetControl ( Table, Forms.FindSource ( Source ), "Table" ).Field;
	endif;
	finishEditing ( target );
	if ( Direction = 1 ) then
		try
			target.GoOneLevelDown ();
		except
			raise Output.GoOneLevelDownFailed ();
		endtry;
	else
		try
			target.GoOneLevelUp ();
		except
			raise Output.GoOneLevelUpFailed ();
		endtry;
	endif;

endprocedure
