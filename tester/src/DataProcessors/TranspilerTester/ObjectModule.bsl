var Log export;
var Lang export;
var AlreadyConnected export;
var Script;
var Reader;
var Node;
var LastNode;
var NodeComplete;
var NodeMethod;
var Program;
var Stack;
var Attributes;
var Descriptor;
var TopDescriptor;
var StackIndex;
var Dictionary;
var NameIndicator;
var CheckFinishEditingCurrentArea;
var CurrentForm;
var FormTables;

function Perform () export
	
	init ();
	build ();
	complete ();
	return Script;
	
endfunction

procedure init ()

	Program = new Array ();
	Reader = new XMLReader ();
	Stack = new Array ();
	StackIndex = -1;
	TopDescriptor = undefined;
	Reader.SetString ( Log );
	fillDictionary ();
	NameIndicator = ScenarioForm.NamePrefix ( Lang );
	CheckFinishEditingCurrentArea = false;
	CurrentForm = undefined;
	FormTables = new Map ();

endprocedure 

procedure fillDictionary ()
	
	Dictionary = new Map ();
	Dictionary [ "search" ] = ? ( Lang = "en", "search", "поиск" );
	Dictionary [ "RowGotoDirection" ] = ? ( Lang = "en", "RowGotoDirection", "НаправлениеПереходаКСтроке" );
	Dictionary [ "Up" ] = ? ( Lang = "en", "Up", "Вверх" );
	Dictionary [ "Down" ] = ? ( Lang = "en", "Down", "Вниз" );
	Dictionary [ "new" ] = ? ( Lang = "en", "new", "новый" );
	Dictionary [ "Map" ] = ? ( Lang = "en", "Map", "Соответствие" );
	Dictionary [ "WaitForDropDownListGeneration" ] = ? ( Lang = "en", "WaitForDropListGeneration", "ОжидатьФормированияВыпадающегоСписка" );
	Dictionary [ "true" ] = ? ( Lang = "en", "true", "истина" );
	Dictionary [ "false" ] = ? ( Lang = "en", "false", "ложь" );
	Dictionary [ "GetCommandInterface" ] = ? ( Lang = "en", "GetCommandInterface", "ПолучитьКомандныйИнтерфейс" );
	Dictionary [ "create" ] = ? ( Lang = "en", "Create", "Создать" );
	Dictionary [ "cancel" ] = ? ( Lang = "en", "CancelEdit", "ОтменитьРедактирование" );
	Dictionary [ "open" ] = ? ( Lang = "en", "Open", "Открыть" );
	Dictionary [ "executeChoiceFromMenu" ] = ? ( Lang = "en", "ExecuteChoiceFromMenu", "ВыполнитьВыборИзМеню" );
	Dictionary [ "executeChoiceFromList" ] = ? ( Lang = "en", "ExecuteChoiceFromList", "ВыполнитьВыборИзСписка" );
	Dictionary [ "increaseValue" ] = ? ( Lang = "en", "IncreaseValue", "УвеличитьЗначение" );
	Dictionary [ "decreaseValue" ] = ? ( Lang = "en", "DecreaseValue", "УменьшитьЗначение" );
	Dictionary [ "setCheck" ] = ? ( Lang = "en", "SetCheck", "УстановитьОтметку" );
	Dictionary [ "gotoNextItem" ] = ? ( Lang = "en", "GotoNextItem", "ПерейтиКСледующемуЭлементу" );
	Dictionary [ "gotoValue" ] = ? ( Lang = "en", "GotoValue", "ПерейтиКЗначению" );
	Dictionary [ "gotoNextMonth" ] = ? ( Lang = "en", "GotoNextMonth", "ПерейтиНаМесяцВперед" );
	Dictionary [ "gotoPreviousMonth" ] = ? ( Lang = "en", "GotoPreviousMonth", "ПерейтиНаМесяцНазад" );
	Dictionary [ "gotoNextYear" ] = ? ( Lang = "en", "GotoNextYear", "ПерейтиНаГодВперед" );
	Dictionary [ "gotoPreviousYear" ] = ? ( Lang = "en", "GotoPreviousYear", "ПерейтиНаГодНазад" );
	Dictionary [ "gotoDate" ] = ? ( Lang = "en", "GoToDate", "ПерейтиКДате" );
	Dictionary [ "beginEditingCurrentArea" ] = ? ( Lang = "en", "BeginEditCurrentArea", "НачатьРедактированиеТекущейОбласти" );
	Dictionary [ "gotoPreviousItem" ] = ? ( Lang = "en", "GotoPreviousItem", "ПерейтиКПредыдущемуЭлементу" );
	Dictionary [ "goOneLevelUp" ] = ? ( Lang = "en", "GoOneLevelUp", "ПерейтиНаУровеньВверх" );
	Dictionary [ "goOneLevelDown" ] = ? ( Lang = "en", "GoOneLevelDown", "ПерейтиНаУровеньВниз" );
	Dictionary [ "gotoNextRow" ] = ? ( Lang = "en", "GotoNextRow", "ПерейтиКСледующейСтроке" );
	Dictionary [ "gotoPreviousRow" ] = ? ( Lang = "en", "GotoPreviousRow", "ПерейтиКПредыдущейСтроке" );
	Dictionary [ "gotoFirstRow" ] = ? ( Lang = "en", "GotoFirstRow", "ПерейтиКПервойСтроке" );
	Dictionary [ "gotoLastRow" ] = ? ( Lang = "en", "GotoLastRow", "ПерейтиКПоследнейСтроке" );
	Dictionary [ "gotoRow" ] = ? ( Lang = "en", "GotoRow", "ПерейтиКСтроке" );
	Dictionary [ "setOrder" ] = ? ( Lang = "en", "SetOrder", "УстановитьПорядок" );
	Dictionary [ "selectAllRows" ] = ? ( Lang = "en", "SelectAllRows", "ВыделитьВсеСтроки" );
	Dictionary [ "changeRow" ] = ? ( Lang = "en", "ChangeRow", "ИзменитьСтроку" );
	Dictionary [ "endEditRow" ] = ? ( Lang = "en", "EndEditRow", "ЗакончитьРедактированиеСтроки" );
	Dictionary [ "addRow" ] = ? ( Lang = "en", "AddRow", "ДобавитьСтроку" );
	Dictionary [ "deleteRow" ] = ? ( Lang = "en", "DeleteRow", "УдалитьСтроку" );
	Dictionary [ "switchRowDeleteMark" ] = ? ( Lang = "en", "SwitchRowDeleteMark", "ПереключитьПометкуУдаленияСтроки" );
	Dictionary [ "expand" ] = ? ( Lang = "en", "Expand", "Развернуть" );
	Dictionary [ "collapse" ] = ? ( Lang = "en", "Collapse", "Свернуть" );
	Dictionary [ "chooseUserMessage" ] = ? ( Lang = "en", "ChooseUserMessage", "ВыбратьСообщениеПользователю" );
	Dictionary [ "closeUserMessagesPanel" ] = ? ( Lang = "en", "CloseUserMessagesPanel", "ЗакрытьПанельСообщенийПользователю" );
	Dictionary [ "gotoStartPage" ] = ? ( Lang = "en", "GotoStartPage", "ПерейтиКНачальнойСтранице" );
	Dictionary [ "gotoNextWindow" ] = ? ( Lang = "en", "GotoNextWindow", "ПерейтиКСледующемуОкну" );
	Dictionary [ "gotoPreviousWindow" ] = ? ( Lang = "en", "GotoPreviousWindow", "ПерейтиКПредыдущемуОкну" );
	Dictionary [ "executeCommand" ] = ? ( Lang = "en", "ExecureCommand", "ВыполнитьКоманду" );
	Dictionary [ "setFileDialogResult" ] = ? ( Lang = "en", "SetFileDialogResult", "РезультатОткрытияФайла" );
	Dictionary [ "getCurrentItem" ] = ? ( Lang = "en", "GetCurrentItem", "ПолучитьТекущийЭлемент" );
	Dictionary [ "clickFormattedStringHyperlink" ] = ? ( Lang = "en", "ClickFormattedStringHyperlink", "НажатьНаГиперссылкуВФорматированнойСтроке" );
	Dictionary [ "choose" ] = ? ( Lang = "en", "Choose", "Выбрать" );
	// There are Tester Methods. We can't use Catalogs.Assistant.Templates.Builtin
	// because template language defined for user session and can't be changed on-fly
	Dictionary [ "App" ] = ? ( Lang = "en", "App", "Приложение" );
	Dictionary [ "MainWindow" ] = ? ( Lang = "en", "MainWindow", "ГлавноеОкно" );
	Dictionary [ "Connect" ] = ? ( Lang = "en", "Connect", "Подключить" );
	Dictionary [ "With" ] = ? ( Lang = "en", "With", "Здесь" );
	Dictionary [ "Get" ] = ? ( Lang = "en", "Get", "Получить" );
	Dictionary [ "CurrentSource" ] = ? ( Lang = "en", "CurrentSource", "ТекущийОбъект" );
	Dictionary [ "Date" ] = ? ( Lang = "en", "Date", "Дата" );
	Dictionary [ "Set" ] = ? ( Lang = "en", "Set", "Установить" );
	Dictionary [ "Next" ] = ? ( Lang = "en", "Next", "Далее" );
	Dictionary [ "Choose" ] = ? ( Lang = "en", "Choose", "Выбрать" );
	Dictionary [ "OpenMenu" ] = ? ( Lang = "en", "OpenMenu", "Меню" );
	Dictionary [ "Close" ] = ? ( Lang = "en", "Close", "Закрыть" );
	Dictionary [ "Click" ] = ? ( Lang = "en", "Click", "Нажать" );
	Dictionary [ "Clear" ] = ? ( Lang = "en", "Clear", "Очистить" );
	Dictionary [ "Activate" ] = ? ( Lang = "en", "Activate", "Фокус" );
	Dictionary [ "Pick" ] = ? ( Lang = "en", "Pick", "Подобрать" );
	// Supplementary names
	Dictionary [ "table" ] = ? ( Lang = "en", "Table", "Таблица" );
	Dictionary [ "TableType" ] = ? ( Lang = "en", "Table", "Таблица" );

endprocedure 

procedure build ()
	
	while ( read () ) do
		if ( NodeComplete ) then
			if ( NodeMethod ) then
				callMethod ();
			endif; 
			pop ();
		else
			push ();
			if ( NodeMethod ) then
				callMethod ();
			else
				defineVar ();
			endif; 
		endif; 
	enddo; 
	
endprocedure 

function read ()
	
	taken = Reader.Read ();
	if ( taken ) then
		LastNode = Node;
		Node = Reader.Name;
		NodeComplete = ( Reader.NodeType = XMLNodeType.EndElement );
		NodeMethod = isMethod ();
	endif; 
	return taken;
	
endfunction 

function isMethod ()
	
	k = Left ( Node, 1 );
	return k = Lower ( k );
	
endfunction 

procedure callMethod ()
	
	if ( Node = "uilog" ) then
		if ( not NodeComplete
			and not AlreadyConnected ) then
			addCall ( translate ( "Connect" ) );
		endif; 
		return;
	endif;
	if ( CheckFinishEditingCurrentArea
		and not NodeComplete ) then
		userCommitCellEditing = Node = "finishEditingCurrentArea"
		and Attributes [ "cancel" ] = "false";
		if ( not userCommitCellEditing ) then
			rollback ();
		endif;
		CheckFinishEditingCurrentArea = false;
	endif;
	if ( Node = "gotoRow" ) then
		applyGotoRow ();
	elsif ( Node = "expand" ) then
		applyExpand ( true );
	elsif ( Node = "collapse" ) then
		applyExpand ( false );
	else
		if ( NodeComplete ) then
			return;
		endif;
		if ( Node = "inputText"
			or Node = "selectOption"
			or Node = "executeChoiceFromChoiceList"
			or Node = "executeChoiceFromDropList" ) then
			applyValue ();
		elsif ( Node = "executeChoiceFromMenu"
			or Node = "executeChoiceFromList" ) then
			addCall ( translate ( "CurrentSource" ) + "." + translate ( Node ), wrapAttribute ( "presentation" ) );
		elsif ( Node = "clear" ) then
			addCall ( translate ( "Clear" ), fieldID () );
		elsif ( Node = "gotoValue" ) then
			addCall ( buildMethod (), Attributes [ "presentation" ] );
		elsif ( Node = "gotoDate" ) then
			addCall ( buildMethod (), translate ( "Date" ) + " ( """ + XMLValue ( Type ( "Date" ), Attributes [ "date" ] ) + """ )" );
		elsif ( Node = "setCurrentArea" ) then
			addCall ( translate ( "Activate" ), """" + NameIndicator + TopDescriptor.Attributes [ "name" ] + " [ " + Attributes [ "area" ] + " ]""" );
		elsif ( Node = "beginEditingCurrentArea" ) then
			addCall ( translate ( "Get" ) + " ( " + fieldID ( , "FormField" ) + " )." + translate ( Node ) );
		elsif ( Node = "startChoosing"
			or Node = "startChoosingFromChoiceList" ) then
			table = getTable ();
			addCall ( translate ( "Choose" ), fieldID (), ? ( table = undefined, undefined, getTableName ( table ) ) );
		elsif ( Node = "addRow" ) then
			addCall ( TopDescriptor.Attributes [ "name" ] + "." + translate ( Node ) );
		elsif ( Node = "gotoNextItem" ) then
			applyGotoNextItem ();
		elsif ( Node = "gotoNextRow"
			or Node = "gotoPreviousRow"
			or Node = "gotoFirstRow"
			or Node = "gotoLastRow" ) then
			addCall ( buildMethod (), translate ( Attributes [ "switchSelection" ] ) );
		elsif ( Node = "setOrder" ) then
			addCall ( buildMethod (), wrapAttribute ( "columnTitle" ) );
		elsif ( Node = "endEditRow" ) then
			applyEndEditRow ();
		elsif ( Node = "chooseUserMessage" ) then
			addCall ( buildMethod (), wrapAttribute ( "messageText" ) );
		elsif ( Node = "executeCommand" ) then
			addCall ( buildMethod (), wrapAttribute ( "url" ) );
		elsif ( Node = "clickFormattedStringHyperlink" ) then
			addCall ( buildMethod (), wrapAttribute ( "title" ) );
		elsif ( Node = "activate" ) then
			applyActivate ();
		elsif ( Node = "click" ) then
			applyClick ();
		elsif ( Node = "close" ) then
			addCall ( translate ( "Close" ), """" + TopDescriptor.Attributes [ "caption" ] + """" );
		elsif ( Node <> "openDropList"
			and Node <> "closeDropList"
			and Node <> "finishEditingCurrentArea" ) then
			addCall ( buildMethod () );
		endif; 
	endif;

endprocedure 

procedure rollback ( HowMany = 1 )
	
	i = HowMany;
	j = Program.UBound ();
	while ( i >= 1 ) do
		Program.Delete ( j );
		j = j - 1;
		i = i - 1;
	enddo;

endprocedure

procedure addCall ( Method, P1 = undefined, P2 = undefined, P3 = undefined, Comment = "" )
	
	params = new Array ();
	skipped = 0;
	if ( P1 = undefined ) then
		skipped = skipped + 1;
	else 
		params.Add ( P1 );
	endif;
	if ( P2 = undefined ) then
		skipped = skipped + 1;
	else
		addSkipped ( params, skipped );
		params.Add ( ", " + P2 );
		skipped = 0;
	endif;
	if ( P3 = undefined ) then
		skipped = skipped + 1;
	else
		addSkipped ( params, skipped );
		params.Add ( ", " + P3 );
		skipped = 0;
	endif;
	code = new Array ();
	code.Add ( Method );
	if ( skipped = 3 ) then
		code.Add ( " ();" );
	else
		code.Add ( " ( " );
		code.Add ( StrConcat ( params ) );
		code.Add ( " );" );
	endif;
	Program.Add ( StrConcat ( code ) + ? ( Comment = "", "", " // " + Comment ) );
	if ( TopDescriptor <> undefined ) then
		TopDescriptor.Nodes.Add ( Descriptor );
	endif;

endprocedure

procedure addSkipped ( Code, Skipped )

	for i = 1 to Skipped do
		Code.Add ( "," );
	enddo;
	
endprocedure

function buildMethod ()
	
	method = translate ( Node );
	if ( TopDescriptor.Name = "ClientApplicationWindow"
		and TopDescriptor.Attributes [ "isMain" ] = "true" ) then
		return translate ( "MainWindow" ) + "." + method;
	else
		if ( TopDescriptor.Name = "FormTable" ) then
			return getTableName ( TopDescriptor ) + "." + method;
		else
			return translate ( "Get" ) + " ( " + fieldID () + " )." + method;
		endif;
	endif;

endfunction 

function getTableName ( Table )

	name = Table.Attributes [ "name" ];
	return ? ( name = undefined, translate ( "table" ), name );
	
endfunction

procedure addDefinition ( Left, Right )
	
	code = new Array ();
	code.Add ( Left );
	code.Add ( " = " );
	code.Add ( Right + ";" );
	Program.Add ( StrConcat ( code ) );
	TopDescriptor.Nodes.Add ( Descriptor );

endprocedure 

function wrapAttribute ( Name )
	
	return Conversion.Wrap ( Attributes [ Name ] );
	
endfunction 

function translate ( Text )
	
	result = Dictionary [ Text ];
	return ? ( result = undefined, Text, result );
	
endfunction

function fieldID ( Quote = true, Parent = undefined )
	
	if ( Parent = undefined ) then
		nodeAbove = TopDescriptor;
	else
		nodeAbove = parentNode ( "FormField", "name" );
	endif;
	if ( nodeAbove = undefined ) then
		return translate ( "App" );
	else
		idAndTitle = nodeAbove.Attributes;
		value = idAndTitle [ "name" ];
		if ( value = undefined ) then
			value = idAndTitle [ "title" ];
			name = ? ( value = undefined, "", value );
		else
			name = NameIndicator + value;
		endif;
		return ? ( Quote, """"  + name + """", name );
	endif;
	
endfunction

function parentNode ( Name, Attribute = undefined, AttributeValue = undefined )
	
	set = ? ( AttributeValue = undefined, undefined, Conversion.StringToArray ( AttributeValue ) );
	justNode = Attribute = undefined;
	i = StackIndex;
	while ( i >= 0 ) do
		entry = Stack [ i ];
		if ( entry.Name = Name ) then
			if ( justNode ) then
				return entry;
			endif;
			value = entry.Attributes [ Attribute ];
			found = ( set = undefined and value <> undefined )
			or ( set <> undefined and set.Find ( value ) <> undefined ); 
			if ( found ) then
				return entry;
			endif;
		endif; 
		i = i - 1;
	enddo; 
	return undefined;

endfunction

procedure applyGotoRow ()

	if ( NodeComplete ) then
		if ( Node = LastNode ) then
			rollback ();
		else
			direction = Attributes [ "direction" ];
			method = getTableName ( getTable () ) + "." + translate ( Node );
			if ( direction = undefined
				or direction = "down" ) then
				addCall ( method, translate ( "search" ) );
			else
				addCall ( method, translate ( "search" ), translate ( "RowGotoDirection" ) + "." + translate ( Title ( direction ) ) );
			endif;
		endif;
	else
		fetchSearch ();
	endif; 

endprocedure

procedure fetchSearch ()
	
	addDefinition ( translate ( "search" ), translate ( "new" ) + " " + translate ( "Map" ) + " ()" );
	
endprocedure 

procedure applyEndEditRow ()
	
	cancel = Attributes [ "cancel" ];
	if ( cancel = "true" ) then
		if ( nodeHas ( TopDescriptor.Nodes, "addRow", 0 ) ) then
			rollback ();
		else
			method = translate ( "deleteRow" );
			table = getTable ();
			if ( table = undefined ) then
				addCall ( translate ( "Get" ) + " ( " + fieldID () + " )." + method );
			else
				addCall ( getTableName ( table ) + "." + method );
			endif;
		endif;
	endif;
	
endprocedure

procedure applyWith ( Title, Activate = undefined )
	
	if ( CurrentForm <> undefined
		and ( CurrentForm = Title
			or CurrentForm + " *" = Title ) ) then
		return;
	endif;
	CurrentForm = Title;
	FormTables = new Map ();
	addLineBreak ();
	addCall ( translate ( "With" ), """" + CurrentForm + """", Activate );
	
endprocedure

procedure addLineBreak ()

	Program.Add ( Chars.CR );
	
endprocedure

procedure applyActivate ()
	
	name = TopDescriptor.Name; 
	if ( name = "Form" ) then
		if ( TopDescriptor.Nodes.Count () = 0 ) then
			applyWith ( TopDescriptor.Attributes [ "title" ], translate ( "true" ) );
		endif;
	elsif ( name = "FormGroup" ) then
		addCall ( translate ( "Activate" ), fieldID (), , , TopDescriptor.Attributes [ "title" ] );
	endif;
	
endprocedure

procedure applyClick ()

	if ( TopDescriptor.Name = "CommandInterfaceButton" ) then
		parent = parentNode ( "ClientApplicationWindow", "isMain", "true" );
		if ( parent = undefined ) then
			parent = parentNode ( "ClientApplicationWindow" );
			if ( parent <> undefined ) then
				form = parent.Attributes [ "caption" ];
				source = ? ( CurrentForm = form, undefined, " """ + form + """ " ); 
				addCall ( translate ( "Click" ), """" + TopDescriptor.Attributes [ "title" ] + """", translate ( "GetLinks" ) + " (" + source + ")" );
			endif;
		else
			i = StackIndex;
			menu = new Array ();
			entry = undefined;
			while ( entry <> parent  ) do
				entry = Stack [ i ];
				path = entry.Attributes [ "title" ];
				if ( path <> undefined ) then
					menu.Insert ( 0, path );
				endif;
				i = i - 1;
			enddo;
			addCall ( translate ( "OpenMenu" ), """" + StrConcat ( menu, " / " ) + """" );
		endif;
	else
		addCall ( translate ( "Click" ), fieldID () );
	endif;

endprocedure

procedure applyExpand ( Expand )
	
	if ( TopDescriptor.Name = "FormGroup" ) then
		if ( NodeComplete ) then
			addCall ( buildmethod () );
		endif;
	else
		if ( NodeComplete ) then
			if ( Node = LastNode ) then
				rollback ();
				search = undefined;
			else
				search = translate ( "search" ); 
			endif;
			addCall ( getTableName ( getTable () ) + "." + translate ( Node ), search );
		else
			fetchSearch ();
		endif; 
	endif;
	
endprocedure

procedure applyValue ()
	
	if ( Node = "executeChoiceFromChoiceList"
		or Node = "executeChoiceFromDropList" ) then
		if ( nodeHas ( TopDescriptor.Nodes, "startChoosing", 0 )
			or nodeHas ( TopDescriptor.Nodes, "startChoosingFromChoiceList", 0 ) ) then
			rollback ();
		endif;
		action = "Pick";
		value = wrapAttribute ( "presentation" );
	elsif ( Node = "selectOption" ) then
		action = "Set";
		value = wrapAttribute ( "presentation" );
	else
		action = "Set";
		value = wrapAttribute ( "text" );
	endif;
	if ( TopDescriptor.Name = "FormField"
		and TopDescriptor.Attributes.Count () = 0 ) then
		methods = Stack [ StackIndex - 2 ].Nodes;
		last = methods.UBound ();
		if ( methods [ last ].Name = "beginEditingCurrentArea"
			and methods [ last - 1 ].Name = "setCurrentArea") then
			rollback ( 2 );
			area = methods [ last - 1 ];
			addCall ( translate ( action ), """" + fieldID ( false, "FormField" ) + " [ " + area.Attributes [ "area" ] + " ]""", value );
			CheckFinishEditingCurrentArea = true;
			return;
		endif; 
	endif;
	table = getTable ();
	if ( table = undefined ) then
		tableName = undefined;
	else
		tableName = getTableName ( table );
		nodes = table.Nodes;
		if ( nodeHas ( nodes, "changeRow", 0 ) ) then
			rollback ();
			if ( nodeHas ( nodes, "choose", 1 ) ) then
				rollback ();
			endif;
		endif;
	endif;
	addCall ( translate ( action ), fieldID ( , "FormField" ), value, tableName );
	
endprocedure

function getTable ()

	table = parentNode ( "FormTable", "name" );
	if ( table = undefined ) then
		table = parentNode ( "FormTable" ); // System table without testclient support mechanism
	endif;
	return table;

endfunction

procedure applyGotoNextItem ()

	if ( TopDescriptor.Name = "FormTable" ) then
		if ( not nodeHas ( TopDescriptor.Nodes, "gotoNextItem" ) ) then
			method = getTableName ( TopDescriptor ) + "." + translate ( "endEditRow" );
			addCall ( method, translate ( "false" ) );
		endif;
	else
		addCall ( translate ( "Next" ) );
	endif;
	
endprocedure 

function nodeHas ( Nodes, Method, StackBack = undefined )
	
	if ( StackBack = undefined ) then
		for each item in Nodes do
			if ( item.Name = Method ) then
				return true;
			endif;
		enddo;
		return false;
	else
		i = Nodes.UBound () - StackBack;
		if ( i < 0 ) then
			return false;
		else
			return Nodes [ i ].Name = Method;
		endif;
	endif;
	
endfunction

procedure pop ()
	
	Stack.Delete ( StackIndex );
	StackIndex = StackIndex - 1;
	if ( StackIndex >= 0 ) then
		Descriptor = Stack [ StackIndex ];
		Attributes = Descriptor.Attributes;
		if ( StackIndex > 0 ) then
			TopDescriptor = Stack [ StackIndex - 1 ];
		endif; 
	endif;
	
endprocedure 

procedure defineVar ()
	
	if ( Node = "Field" ) then
		addDefinition ( translate ( "search" ) + " [ " + wrapAttribute ( "title" ) + " ]", wrapAttribute ( "cellText" ) );
	elsif ( Node = "Form" ) then
		applyWith ( Attributes [ "title" ] );
	elsif ( Node = "FormTable" ) then
		applyFormTable ();
	endif;
	
endprocedure

procedure applyFormTable ()

	name = Attributes [ "name" ];
	if ( name = undefined ) then
		nameDefined = false;
		name = translate ( "table" );
	else
		nameDefined = true;
	endif;
	if ( FormTables [ name ] <> undefined ) then
		return;
	endif;
	FormTables [ name ] = true;
	if ( nameDefined ) then
		addDefinition ( name, translate ( "Get" ) + " ( """ + NameIndicator + name + """ )" );
	else
		addDefinition ( name, translate ( "Get" ) + " ( """", , """ + translate ( "TableType" ) + """ )" );
	endif;
	
endprocedure

procedure push ()
	
	Attributes = new Map ();
	if ( Reader.AttributeCount () > 0 ) then
		while ( Reader.ReadAttribute () ) do
			Attributes.Insert ( Reader.Name, Reader.Value );
		enddo; 
	endif; 
	if ( StackIndex >= 0 ) then
		TopDescriptor = Stack [ StackIndex ];
	endif; 
	Descriptor = new Structure ( "Name, Attributes, Nodes", Node, Attributes, new Array () );
	Stack.Add ( Descriptor );
	StackIndex = StackIndex + 1;
	
endprocedure 

procedure complete ()
	
	Program.Add ( "" );
	Script = StrConcat ( Program, Chars.LF );
	
endprocedure 
