var Log export;
var Lang export;
var SmartMode export;
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

endprocedure 

procedure fillDictionary ()
	
	Dictionary = new Map ();
	Dictionary [ "Connect" ] = ? ( Lang = "en", "Connect", "Подключить" );
	Dictionary [ "search" ] = ? ( Lang = "en", "search", "поиск" );
	Dictionary [ "RowGotoDirection" ] = ? ( Lang = "en", "RowGotoDirection", "НаправлениеПереходаКСтроке" );
	Dictionary [ "Up" ] = ? ( Lang = "en", "Up", "Вверх" );
	Dictionary [ "Down" ] = ? ( Lang = "en", "Down", "Вниз" );
	Dictionary [ "new" ] = ? ( Lang = "en", "new", "новый" );
	Dictionary [ "Map" ] = ? ( Lang = "en", "Map", "Соответствие" );
	Dictionary [ "WaitForDropDownListGeneration" ] = ? ( Lang = "en", "WaitForDropListGeneration", "ОжидатьФормированияВыпадающегоСписка" );
	Dictionary [ "true" ] = ? ( Lang = "en", "true", "истина" );
	Dictionary [ "false" ] = ? ( Lang = "en", "false", "ложь" );
	Dictionary [ "MainWindow" ] = ? ( Lang = "en", "MainWindow", "ГлавноеОкно" );
	Dictionary [ "GetObject" ] = ? ( Lang = "en", "GetObject", "ПолучитьОбъект" );
	Dictionary [ "GetCommandInterface" ] = ? ( Lang = "en", "GetCommandInterface", "ПолучитьКомандныйИнтерфейс" );
	Dictionary [ "App" ] = ? ( Lang = "en", "App", "Приложение" );
	Dictionary [ "activate" ] = ? ( Lang = "en", "Activate", "Активизировать" );
	Dictionary [ "inputText" ] = ? ( Lang = "en", "InputText", "ВвестиТекст" );
	Dictionary [ "click" ] = ? ( Lang = "en", "Click", "Нажать" );
	Dictionary [ "clear" ] = ? ( Lang = "en", "Clear", "Очистить" );
	Dictionary [ "create" ] = ? ( Lang = "en", "Create", "Создать" );
	Dictionary [ "cancel" ] = ? ( Lang = "en", "CancelEdit", "ОтменитьРедактирование" );
	Dictionary [ "open" ] = ? ( Lang = "en", "Open", "Открыть" );
	Dictionary [ "startChoosing" ] = ? ( Lang = "en", "StartChoosing", "Выбрать" );
	Dictionary [ "startChoosingFromChoiceList" ] = ? ( Lang = "en", "StartChoosingFromChoiceList", "ВыбратьИзСпискаВыбора" );
	Dictionary [ "executeChoiceFromChoiceList" ] = ? ( Lang = "en", "ExecuteChoiceFromChoiceList", "ВыполнитьВыборИзСпискаВыбора" );
	Dictionary [ "executeChoiceFromMenu" ] = ? ( Lang = "en", "ExecuteChoiceFromMenu", "ВыполнитьВыборИзМеню" );
	Dictionary [ "executeChoiceFromList" ] = ? ( Lang = "en", "ExecuteChoiceFromList", "ВыполнитьВыборИзСписка" );
	Dictionary [ "openDropList" ] = ? ( Lang = "en", "OpenDropList", "ОткрытьВыпадающийСписок" );
	Dictionary [ "closeDropList" ] = ? ( Lang = "en", "CloseDropList", "ЗакрытьВыпадающийСписок" );
	Dictionary [ "executeChoiceFromDropList" ] = ? ( Lang = "en", "ExecuteChoiceFromDropList", "ВыполнитьВыборИзВыпадающегоСписка" );
	Dictionary [ "increaseValue" ] = ? ( Lang = "en", "IncreaseValue", "УвеличитьЗначение" );
	Dictionary [ "decreaseValue" ] = ? ( Lang = "en", "DecreaseValue", "УменьшитьЗначение" );
	Dictionary [ "setCheck" ] = ? ( Lang = "en", "SetCheck", "УстановитьОтметку" );
	Dictionary [ "selectOption" ] = ? ( Lang = "en", "SelectOption", "ВыбратьВариант" );
	Dictionary [ "gotoValue" ] = ? ( Lang = "en", "GotoValue", "ПерейтиКЗначению" );
	Dictionary [ "gotoNextMonth" ] = ? ( Lang = "en", "GotoNextMonth", "ПерейтиНаМесяцВперед" );
	Dictionary [ "gotoPreviousMonth" ] = ? ( Lang = "en", "GotoPreviousMonth", "ПерейтиНаМесяцНазад" );
	Dictionary [ "gotoNextYear" ] = ? ( Lang = "en", "GotoNextYear", "ПерейтиНаГодВперед" );
	Dictionary [ "gotoPreviousYear" ] = ? ( Lang = "en", "GotoPreviousYear", "ПерейтиНаГодНазад" );
	Dictionary [ "gotoDate" ] = ? ( Lang = "en", "GoToDate", "ПерейтиКДате" );
	Dictionary [ "setCurrentArea" ] = ? ( Lang = "en", "SetCurrentArea", "УстановитьТекущуюОбласть" );
	Dictionary [ "beginEditingCurrentArea" ] = ? ( Lang = "en", "BeginEditCurrentArea", "НачатьРедактированиеТекущейОбласти" );
	Dictionary [ "finishEditingCurrentArea" ] = ? ( Lang = "en", "EndEditCurrentArea", "ЗакончитьРедактированиеТекущейОбласти" );
	Dictionary [ "gotoNextItem" ] = ? ( Lang = "en", "GotoNextItem", "ПерейтиКСледующемуЭлементу" );
	Dictionary [ "gotoPreviousItem" ] = ? ( Lang = "en", "GotoPreviousItem", "ПерейтиКПредыдущемуЭлементу" );
	Dictionary [ "goOneLevelUp" ] = ? ( Lang = "en", "GoOneLevelUp", "ПерейтиНаУровеньВверх" );
	Dictionary [ "goOneLevelDown" ] = ? ( Lang = "en", "GoOneLevelDown", "ПерейтиНаУровеньВниз" );
	Dictionary [ "gotoNextRow" ] = ? ( Lang = "en", "GotoNextRow", "ПерейтиКСледующейСтроке" );
	Dictionary [ "gotoPreviousRow" ] = ? ( Lang = "en", "GotoPreviousRow", "ПерейтиКПредыдущейСтроке" );
	Dictionary [ "gotoFirstRow" ] = ? ( Lang = "en", "GotoFirstRow", "ПерейтиКПервойСтроке" );
	Dictionary [ "gotoLastRow" ] = ? ( Lang = "en", "GotoLastRow", "ПерейтиКПоследнейСтроке" );
	Dictionary [ "gotoRow" ] = ? ( Lang = "en", "GotoRow", "ПерейтиКСтроке" );
	Dictionary [ "setOrder" ] = ? ( Lang = "en", "SetOrder", "УстановитьПорядок" );
	Dictionary [ "choose" ] = ? ( Lang = "en", "Choose", "Выбрать" );
	Dictionary [ "selectAllRows" ] = ? ( Lang = "en", "SelectAllRows", "ВыделитьВсеСтроки" );
	Dictionary [ "changeRow" ] = ? ( Lang = "en", "ChangeRow", "ИзменитьСтроку" );
	Dictionary [ "endEditRow" ] = ? ( Lang = "en", "EndEditRow", "ЗакончитьРедактированиеСтроки" );
	Dictionary [ "addRow" ] = ? ( Lang = "en", "AddRow", "ДобавитьСтроку" );
	Dictionary [ "deleteRow" ] = ? ( Lang = "en", "DeleteRow", "УдалитьСтроку" );
	Dictionary [ "switchRowDeleteMark" ] = ? ( Lang = "en", "SwitchRowDeleteMark", "ПереключитьПометкуУдаленияСтроки" );
	Dictionary [ "expand" ] = ? ( Lang = "en", "Expand", "Развернуть" );
	Dictionary [ "collapse" ] = ? ( Lang = "en", "Collapse", "Свернуть" );
	Dictionary [ "close" ] = ? ( Lang = "en", "Close", "Закрыть" );
	Dictionary [ "chooseUserMessage" ] = ? ( Lang = "en", "ChooseUserMessage", "ВыбратьСообщениеПользователю" );
	Dictionary [ "closeUserMessagesPanel" ] = ? ( Lang = "en", "CloseUserMessagesPanel", "ЗакрытьПанельСообщенийПользователю" );
	Dictionary [ "gotoStartPage" ] = ? ( Lang = "en", "GotoStartPage", "ПерейтиКНачальнойСтранице" );
	Dictionary [ "gotoNextWindow" ] = ? ( Lang = "en", "GotoNextWindow", "ПерейтиКСледующемуОкну" );
	Dictionary [ "gotoPreviousWindow" ] = ? ( Lang = "en", "GotoPreviousWindow", "ПерейтиКПредыдущемуОкну" );
	Dictionary [ "executeCommand" ] = ? ( Lang = "en", "ExecureCommand", "ВыполнитьКоманду" );
	Dictionary [ "ClientApplicationWindow" ] = ? ( Lang = "en", "ClientWindow", "ОкноПриложения" );
	Dictionary [ "Form" ] = ? ( Lang = "en", "Form", "Форма" );
	Dictionary [ "FormField" ] = ? ( Lang = "en", "Field", "Поле" );
	Dictionary [ "FormButton" ] = ? ( Lang = "en", "Button", "Кнопка" );
	Dictionary [ "FormGroup" ] = ? ( Lang = "en", "Group", "Группа" );
	Dictionary [ "FormTable" ] = ? ( Lang = "en", "Table", "Таблица" );
	Dictionary [ "FormDecoration" ] = ? ( Lang = "en", "Decoration", "Декорация" );
	Dictionary [ "CommandInterface" ] = ? ( Lang = "en", "CommandInterface", "КомандныйИнтерфейс" );
	Dictionary [ "CommandInterfaceGroup" ] = ? ( Lang = "en", "CommandInterfaceGroup", "ГруппаКомандногоИнтерфейса" );
	Dictionary [ "CommandInterfaceButton" ] = ? ( Lang = "en", "CommandInterfaceButton", "КнопкаКомандногоИнтерфейса" );
	Dictionary [ "setFileDialogResult" ] = ? ( Lang = "en", "SetFileDialogResult", "РезультатОткрытияФайла" );
	Dictionary [ "GetCurrentItem" ] = ? ( Lang = "en", "GetCurrentItem", "ПолучитьТекущийЭлемент" );
	Dictionary [ "if" ] = ? ( Lang = "en", "if", "если" );
	Dictionary [ "then" ] = ? ( Lang = "en", "then", "тогда" );
	Dictionary [ "endif" ] = ? ( Lang = "en", "endif", "конецесли" );
	Dictionary [ "not" ] = ? ( Lang = "en", "not", "не" );
	Dictionary [ "DropListIsOpen" ] = ? ( Lang = "en", "DropListIsOpen", "ВыпадающийСписокОткрыт" );
	Dictionary [ "InputFieldType" ] = ? ( Lang = "en", "FormFieldType.InputField", "ВидПоляФормы.ПолеВвода" );
	Dictionary [ "Expanded" ] = ? ( Lang = "en", "Expanded", "Развернут" );
	Dictionary [ "Type" ] = ? ( Lang = "en", "Type", "Вид" );
	Dictionary [ "clickFormattedStringHyperlink" ] = ? ( Lang = "en", "ClickFormattedStringHyperlink", "НажатьНаГиперссылкуВФорматированнойСтроке" );

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
			addRow ( translate ( "Connect" ) + " ();" );
		endif; 
		return;
	endif;
	obj = TopDescriptor.Var;
	method = obj + "." + translate ( Node );
	if ( Node = "gotoRow" ) then
		if ( NodeComplete ) then
			direction = Attributes [ "direction" ];
			if ( direction = undefined ) then
				addRow ( method + " ( " + translate ( "search" ) + " );" );
			else
				addRow ( method + " ( " + translate ( "search" ) + ", " + translate ( "RowGotoDirection" ) + "." + translate ( Title ( direction ) ) + " );" );
			endif; 
		else
			addRow ( translate ( "search" ) + " = " + translate ( "new" ) + " " + translate ( "Map" ) + " ();" );
		endif; 
	elsif ( Node = "expand" ) then
		applyRowTree ( obj, method, true );
	elsif ( Node = "collapse" ) then
		applyRowTree ( obj, method, false );
	else
		if ( NodeComplete ) then
			return;
		endif;
		if ( Node = "inputText" ) then
			addRow ( method + " ( " + wrapAttribute ( "text" ) + " );" );
		elsif ( Node = "closeDropList" ) then
			applyCloseDropList ( obj, method );
		elsif ( Node = "executeChoiceFromChoiceList"
			or Node = "executeChoiceFromDropList" ) then
			applyExecuteChoiceFromDropList ( obj, method );
		elsif ( Node = "executeChoiceFromMenu"
			or Node = "executeChoiceFromList"
			or Node = "selectOption" ) then
			addRow ( method + " ( " + wrapAttribute ( "presentation" ) + " );" );
		elsif ( Node = "gotoValue" ) then
			addRow ( method + " ( " + wrapAttribute ( "value" ) + " );" );
		elsif ( Node = "gotoDate" ) then
			addRow ( method + " ( " + wrapAttribute ( "date" ) + " );" );
		elsif ( Node = "setCurrentArea" ) then
			addRow ( method + " ( " + wrapAttribute ( "area" ) + " );" );
		elsif ( Node = "finishEditingCurrentArea" ) then
			addRow ( method + " ( " + translate ( Attributes [ "cancel" ] ) + " );" );
		elsif ( Node = "gotoNextRow"
			or Node = "gotoPreviousRow"
			or Node = "gotoFirstRow"
			or Node = "gotoLastRow" ) then
			addRow ( method + " ( " + translate ( Attributes [ "switchSelection" ] ) + " );" );
		elsif ( Node = "setOrder" ) then
			addRow ( method + " ( " + wrapAttribute ( "columnTitle" ) + " );" );
		elsif ( Node = "endEditRow" ) then
			addRow ( method + " ( " + translate ( Attributes [ "cancel" ] ) + " );" );
		elsif ( Node = "chooseUserMessage" ) then
			addRow ( method + " ( " + wrapAttribute ( "messageText" ) + " );" );
		elsif ( Node = "executeCommand" ) then
			addRow ( method + " ( " + wrapAttribute ( "url" ) + " );" );
		elsif ( Node = "clickFormattedStringHyperlink" ) then
			addRow ( method + " ( " + wrapAttribute ( "title" ) + " );" );
		else
			addRow ( method + " ();" );
		endif; 
	endif;

endprocedure 

procedure addRow ( Code )
	
	Program.Add ( Code );

endprocedure 

function wrapAttribute ( Name )
	
	return Conversion.Wrap ( Attributes [ Name ] );
	
endfunction 

function translate ( Text )
	
	result = Dictionary [ Text ];
	return ? ( result = undefined, Text, result );
	
endfunction 

procedure applyRowTree ( Obj, Method, Expand )
	
	if ( NodeComplete ) then
		currentRow = ( Node = LastNode );
		if ( SmartMode ) then
			if ( not currentRow ) then
				addRow ( Obj + "." + translate ( "gotoRow" ) + " ( " + translate ( "search" ) + " );" );
			endif; 
			condition = ? ( Expand, translate ( "not" ) + " ", "" );
			addRow ( translate ( "if" ) + " ( " + condition + Obj + "." + translate ( "Expanded" ) + " () ) " + translate ( "then" ) );
			addRow ( Chars.Tab + method + " ();" );
			addRow ( translate ( "endif" ) + ";" );
		else
			if ( currentRow ) then
				addRow ( method + " ();" );
			else
				addRow ( method + " ( " + translate ( "search" ) + " );" );
			endif; 
		endif; 
	else
		addRow ( translate ( "search" ) + " = " + translate ( "new" ) + " " + translate ( "Map" ) + " ();" );
	endif; 
	
endprocedure 

procedure applyCloseDropList ( Obj, Method )
	
	if ( SmartMode ) then
		addRow ( translate ( "if" ) + " ( " + Obj + "." + translate ( "DropListIsOpen" ) + " () ) " + translate ( "then" ) );
		addRow ( Chars.Tab + method + " ();" );
		addRow ( translate ( "endif" ) + ";" );
	else
		addRow ( method + " ();" );
	endif; 

endprocedure 

procedure applyExecuteChoiceFromDropList ( Obj, Method )
	
	if ( SmartMode ) then
		if ( LastNode = "closeDropList" ) then
			addRow ( Obj + "." + translate ( "openDropList" ) + " ();" );
		endif; 
		addRow ( translate ( "if" ) + " ( " + Obj + "." + translate ( "Type" ) + " = " + translate ( "InputFieldType" ) + " )" + translate ( "then" ) );
		addRow ( Chars.Tab + Obj + "." + translate ( "WaitForDropDownListGeneration" ) + " ();" );
		addRow ( translate ( "endif" ) + ";" );
		value = Attributes [ "presentation" ];
		if ( SmartMode
			and Node = "executeChoiceFromDropList"
			and value = "" ) then
			addRow ( Obj + "." + translate ( "startChoosing" ) + " ();" );
		else
			addRow ( Method + " ( " + Conversion.Wrap ( value ) + " );" );
		endif; 
	else
		addRow ( method + " ();" );
	endif; 

endprocedure 

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
	
	variable = Descriptor.Var;
	if ( Node = "Field" ) then
		addRow ( translate ( "search" ) + " [ " + wrapAttribute ( "title" ) + " ] = " + wrapAttribute ( "cellText" ) + ";" );
		return;
	endif;
	expression = variable + " = " + TopDescriptor.Var + ".";
	if ( Node = "ClientApplicationWindow" ) then
		main = Attributes [ "isMain" ];
		if ( main <> undefined
			and main = "true" ) then
			addRow ( variable + " = " + translate ( "MainWindow" ) + ";" );
		else
			addRow ( expression + translate ( "GetObject" ) + " ( , " + wrapAttribute ( "caption" ) + " );" );
		endif;
	elsif ( Node = "CommandInterface" ) then
		addRow ( expression + translate ( "GetCommandInterface" ) + " ();" );
	elsif ( Node = "FormField"
		and Attributes.Count () = 0 ) then
		addRow ( variable + " = " + translate ( "Form" ) + "." + translate ( "GetCurrentItem" ) + " ();" );
	else
		addRow ( expression + translate ( "GetObject" ) + " " + getObjectParams () + ";" );
	endif;
	
endprocedure 

function getObjectParams ()
	
	list = new Array ();
	list.Add ();
	list.Add ( Attributes [ "title" ] );
	list.Add ( Attributes [ "name" ] );
	params = paramsToString ( list );
	return ? ( params = "", "()", "( " + params + " )" );
	
endfunction 

function paramsToString ( Params )
	
	i = Params.Ubound ();
	while ( i >= 0 ) do
		if ( ValueIsFilled ( Params [ i ] ) ) then
			break;
		endif; 
		Params.Delete ( i );
		i = i - 1;
	enddo; 
	for i = 0 to Params.Ubound () do
		p = Params [ i ];
		if ( ValueIsFilled ( p ) ) then
			Params [ i ] = Conversion.Wrap ( p );
		endif; 
	enddo; 
	return StrConcat ( Params, ", " );
	
endfunction 

procedure push ()
	
	attributes = new Map ();
	if ( Reader.AttributeCount () > 0 ) then
		while ( Reader.ReadAttribute () ) do
			attributes.Insert ( Reader.Name, Reader.Value );
		enddo; 
	endif; 
	if ( StackIndex >= 0 ) then
		TopDescriptor = Stack [ StackIndex ];
	endif; 
	Descriptor = new Structure ( "Name, Attributes, Var", Node, attributes, getVar () );
	Stack.Add ( Descriptor );
	StackIndex = StackIndex + 1;
	
endprocedure 

function getVar ()
	
	i = StackIndex;
	if ( i = -1 ) then
		return translate ( "App" );
	else
		suffix = 0;
		while ( i >= 0 ) do
			entry = Stack [ i ];
			if ( entry.Name = Node ) then
				suffix = suffix + 1;
			endif; 
			i = i - 1;
		enddo; 
		return translate ( Node ) + Format ( suffix, "NG=" );
	endif; 

endfunction 

procedure complete ()
	
	addRow ( "" );
	Script = StrConcat ( Program, Chars.LF );
	
endprocedure 
