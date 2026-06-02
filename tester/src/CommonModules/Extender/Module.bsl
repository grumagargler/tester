&atclient
procedure Connect ( ClearErrors = true, Port = undefined, Computer = undefined ) export
	
	Test.ConnectClient ( ClearErrors, Port, Computer );
	
endprocedure 

&atclient
procedure Подключить ( ClearErrors = true, Port = undefined, Computer = undefined ) export
	
	Connect ( ClearErrors, Port, Computer );
	
endprocedure 

&atclient
procedure Disconnect ( Close = false ) export
	
	Test.DisconnectClient ( Close );
	
endprocedure 

&atclient
procedure Отключить ( Close = false ) export
	
	Disconnect ( Close );
	
endprocedure 

&atclient
procedure CloseAll () export
	
	Test.CheckConnection ();
	Forms.CloseWindows ();
	Forms.ResetBaseline ();
	
endprocedure 

&atclient
procedure ЗакрытьВсе () export
	
	CloseAll ();
	
endprocedure 

&atclient
procedure ЗакрытьВсё () export
	
	CloseAll ();
	
endprocedure 

&atclient
function Get ( Name, Source = undefined, Type = undefined ) export
	
	Test.CheckConnection ();
	return Fields.GetControl ( Name, Forms.FindSource ( Source ), Type ).Field;
	
endfunction

&atclient
function FindForm ( Name ) export
	
	Test.CheckConnection ();
	return Forms.SearchForm ( Name );
	
endfunction 

&atclient
function НайтиФорму ( Name ) export
	
	return FindForm ( Name );
	
endfunction 

&atclient
function Получить ( Name, Source = undefined, Type = undefined ) export
	
	return Get ( Name, Source, Type );
	
endfunction

&atclient
function Clear ( Name, Source = undefined, Type = undefined ) export
	
	Test.CheckConnection ();
	target = Forms.FindSource ( Source );
	for each item in Conversion.StringToArray ( Name ) do
		data = Fields.ClearControl ( item, target, Type );
	enddo; 
	return data.Field;
	
endfunction 

&atclient
function Очистить ( Name, Source = undefined, Type = undefined ) export
	
	return Clear ( Name, Source, Type );
	
endfunction 

&atclient
function Fetch ( Name, Source = undefined, Type = undefined ) export
	
	return callFetch ( Name, Source, Type, "Fetch" );

endfunction

&atclient
function callFetch ( Name, Source = undefined, Type = undefined, FunctionName )

	Test.CheckConnection ();
	testParameter ( "1", Name, "String, TestedFormField", FunctionName );
	return Fields.FetchValue ( Name, Forms.FindSource ( Source ), Type );
	
endfunction

&atclient
procedure testParameter ( Parameter, Value, Types, FunctionName )

	parameterType = TypeOf ( Value );
	for each name in Conversion.StringToArray ( Types ) do
		if ( parameterType = Type ( name ) ) then
			return;
		endif;
	enddo;
	raise Output.WrongParameterType ( new Structure ( "Parameter, Function",
		Parameter, FunctionName ) );

endprocedure


&atclient
function Взять ( Name, Source = undefined, Type = undefined ) export
	
	return callFetch ( Name, Source, Type, "Взять" );
	
endfunction

&atclient
function Set ( Name, Value, Source = undefined, Type = undefined ) export
	
	Test.CheckConnection ();
	return Fields.SetValue ( Name, Value, Forms.FindSource ( Source ), Type );
	
endfunction 

&atclient
function Установить ( Name, Value, Source = undefined, Type = undefined ) export
	
	return Set ( Name, Value, Source, Type );
	
endfunction 

&atclient
function Put ( Name, Value, Source = undefined, Type = undefined, TestValue = false ) export
	
	Test.CheckConnection ();
	return Fields.SetValue ( Name, Value, Forms.FindSource ( Source ), Type, true, TestValue );
	
endfunction 

&atclient
function Ввести ( Name, Value, Source = undefined, Type = undefined, TestValue = false ) export
	
	return Put ( Name, Value, Source, Type, TestValue );
	
endfunction 

&atclient
procedure Pick ( Name, Value, Source = undefined, Type = undefined ) export
	
	Test.CheckConnection ();
	Fields.Select ( Name, Value, Forms.FindSource ( Source ), Type );

endprocedure 

&atclient
procedure Подобрать ( Name, Value, Source = undefined, Type = undefined ) export
	
	Pick ( Name, Value, Source, Type );

endprocedure 

&atclient
function Activate ( Name, Source = undefined, Type = undefined ) export
	
	Test.CheckConnection ();
	return Fields.Focus ( Name, Forms.FindSource ( Source ), Type ).Field;
	
endfunction

&atclient
function Фокус ( Name, Source = undefined, Type = undefined ) export
	
	return Activate ( Name, Source, Type );
	
endfunction

&atclient
function Click ( Name, Source = undefined, Type = undefined ) export
	
	Test.CheckConnection ();
	return Fields.ClickField ( Name, Source, Type );
	
endfunction

&atclient
function Нажать ( Name, Source = undefined, Type = undefined ) export
	
	return Click ( Name, Source, Type );
	
endfunction

&atclient
function Call ( Scenario, Params = undefined, Application = undefined ) export
	
	return Runtime.Perform ( Scenario, Params, Application, false );
	
endfunction

&atclient
function Вызвать ( Scenario, Params = undefined, Application = undefined ) export
	
	return Call ( Scenario, Params, Application );
	
endfunction

&atclient
function Run ( Scenario, Params = undefined, Application = undefined ) export
	
	return Runtime.Perform ( Scenario, Params, Application, true );
	
endfunction

&atclient
function Позвать ( Scenario, Params = undefined, Application = undefined ) export
	
	return Run ( Scenario, Params, Application );
	
endfunction

&atclient
procedure OpenMenu ( Path ) export
	
	Test.CheckConnection ();
	Forms.ClickMenu ( Path );
	Forms.ResetBaseline ();
	
endprocedure 

&atclient
procedure Меню ( Path ) export
	
	OpenMenu ( Path );
	
endprocedure 

&atclient
function With ( Name = undefined, Activate = true ) export
	
	Test.CheckConnection ();
	current = Forms.SetCurrent ( Name, Activate );
	Forms.ResetBaseline ( false );
	return current;

endfunction

&atclient
function Здесь ( Name = undefined, Activate = true ) export
	
	return With ( Name, Activate );

endfunction

&atclient
function Choose ( Name, Source = undefined, Type = undefined ) export
	
	Test.CheckConnection ();
	return Fields.StartChoosing ( Name, Source, Type );
	
endfunction

&atclient
function Выбрать ( Name, Source = undefined, Type = undefined ) export
	
	return Choose ( Name, Source, Type );
	
endfunction 

&atclient
procedure Check ( Name, Value, Source = undefined, Type = undefined ) export
	
	Test.CheckConnection ();
	Fields.CheckValue ( Name, Value, Forms.FindSource ( Source ), Type );
	
endprocedure 

&atclient
procedure Проверить ( Name, Value, Source = undefined, Type = undefined ) export
	
	Check ( Name, Value, Source, Type );
	
endprocedure 

&atclient
procedure CheckTable ( Table, Params = undefined, Options = undefined, Source = undefined ) export
	
	Test.CheckConnection ();
	Fields.CheckTableContent ( Table, Params, Options, Forms.FindSource ( Source ) );
	
endprocedure 

&atclient
procedure ПроверитьТаблицу ( Table, Params = undefined, Options = undefined, Source = undefined ) export
	
	CheckTable ( Table, Params, Options, Source );
	
endprocedure 

&atclient
procedure CheckState ( Name, Value, Flag = true, Source = undefined, Type = undefined ) export
	
	Test.CheckConnection ();
	parts = StrSplit ( Name, "," );
	for each part in parts do
		Fields.CheckAppearance ( TrimAll ( part ), Value, Flag, Forms.FindSource ( Source ), Type );
	enddo; 
		
endprocedure 

&atclient
procedure ПроверитьСтатус ( Name, Value, Flag = true, Source = undefined, Type = undefined ) export
	
	CheckState ( Name, Value, Flag, Source, Type );
		
endprocedure 

&atclient
procedure CheckTemplate ( Name, Source = undefined, Type = undefined, Template = undefined ) export
	
	Test.CheckConnection ();
	Fields.CheckSpreadsheet ( Name, Forms.FindSource ( Source ), Type, Template );
		
endprocedure 

&atclient
procedure ПроверитьШаблон ( Name, Source = undefined, Type = undefined, Template = undefined ) export
	
	CheckTemplate ( Name, Source, Type, Template );
		
endprocedure 

&atclient
procedure CheckErrors () export
	
	Test.CheckConnection ();
	Forms.ThrowErrors ();
	
endprocedure 

&atclient
procedure ПроверитьОшибки () export
	
	CheckErrors (); 
	
endprocedure 

&atclient
function GetMessages () export
	
	Test.CheckConnection ();
	return Runtime.GetErrors ();
	
endfunction

&atclient
function ПолучитьСообщения () export
	
	return GetMessages ();
	
endfunction

&atclient
function FindMessages ( Template ) export
	
	Test.CheckConnection ();
	return Runtime.FindErrors ( Template );
	
endfunction

&atclient
function НайтиСообщения ( Template ) export
	
	return FindMessages ( Template );
	
endfunction

&atclient
procedure Stop ( Reason = undefined ) export
	
	if ( Reason = undefined ) then
		raise Output.StopMessage ();
	else
		raise String ( Reason );
	endif; 
	
endprocedure 

&atclient
procedure Стоп ( Reason = undefined ) export
	
	Stop ( Reason );
	
endprocedure 

&atclient
procedure Close ( Form = undefined ) export
	
	Test.CheckConnection ();
	Forms.CloseForm ( Form );
	Forms.ResetBaseline ();
	
endprocedure 

&atclient
procedure Закрыть ( Form = undefined ) export
	
	Close ( Form );
	
endprocedure 

&atclient
function Waiting ( Name, Timeout = 3, Type = undefined ) export
	
	Test.CheckConnection ();
	return Forms.Wait ( Name, Timeout, Type );
	
endfunction 

&atclient
function Дождаться ( Name, Timeout = 3, Type = undefined ) export
	
	return Waiting ( Name, Timeout, Type );
	
endfunction 

&atclient
function GetWindow ( Form = undefined ) export
	
	Test.CheckConnection ();
	return Forms.GetFrame ( Form );
	
endfunction 

&atclient
function ПолучитьОкно ( Form = undefined ) export
	
	return GetWindow ( Form );
	
endfunction 

&atclient
function GetLinks ( Form = undefined ) export
	
	Test.CheckConnection ();
	return Forms.GetFrame ( Form ).GetCommandInterface ();
	
endfunction 

&atclient
function ПолучитьСсылки ( Form = undefined ) export
	
	return GetLinks ( Form );
	
endfunction 

&atclient
procedure Pause ( Seconds ) export
	
	Test.PauseExecution ( Seconds );

endprocedure

&atclient
procedure Пауза ( Seconds ) export
	
	Pause ( Seconds ); 

endprocedure

&atclient
function CurrentTab ( Name, Source = undefined, Type = undefined ) export
	
	Test.CheckConnection ();
	tab = Fields.GetControl ( Name, Forms.FindSource ( Source ), Type ).Field;
	return tab.GetCurrentPage ();
	
endfunction

&atclient
function ТекущаяВкладка ( Name, Source = undefined, Type = undefined ) export
	
	return CurrentTab ( Name, Source, Type );
	
endfunction

&atclient
procedure Next () export
	
	Test.CheckConnection ();
	Fields.NextField ();
	
endprocedure 

&atclient
procedure Далее () export
	
	Next ();
	
endprocedure 
         
&atclient
function GotoRow ( Table, Column, Value, FromStart = true, Source = undefined ) export
	
	Test.CheckConnection ();
	return Fields.NavigateToRow ( Table, Column, Value, FromStart, Source );
	
endfunction
         
&atclient
function КСтроке ( Table, Column, Value, FromStart = true, Source = undefined ) export
	
	return GotoRow ( Table, Column, Value, FromStart, Source );
	
endfunction

&atclient
function Commando ( Action, Activate = true ) export
	
	Test.CheckConnection ();
	Forms.DoCommand ( Action );
	if ( Activate ) then
		Forms.ResetBaseline ();
		return Forms.SetCurrent ( undefined, Activate );
	endif;

endfunction

&atclient
function Коммандос ( Action, Activate = true ) export
	
	return Commando ( Action, Activate );
	
endfunction 

&atclient
procedure LogError ( Text ) export
	
	Runtime.WriteError ( Text );
	
endprocedure 

&atclient
procedure ЗаписатьОшибку ( Text ) export
	
	LogError ( Text );
	
endprocedure 

&atclient
function MyVersion ( Expression ) export
	
	return TestSrv.Version ( Expression );
	
endfunction 

&atclient
function МояВерсия ( Expression ) export
	
	return MyVersion ( Expression );
	
endfunction 

&atclient
procedure DebugStart () export
	
	Debugger.Toggle ( true );
	
endprocedure 

&atclient
procedure ОтладкаСтарт () export
	
	DebugStart ();
	
endprocedure 

&atclient
function EnvironmentExists ( ID ) export
	
	return Environment.FindByID ( ID );
	
endfunction 

&atclient
function СозданоОкружение ( ID ) export
	
	return EnvironmentExists ( ID );
	
endfunction 

&atclient
function EnvironmentData ( ID ) export
	
	return Environment.GetData ( ID );
	
endfunction 

&atclient
function ДанныеОкружения ( ID ) export
	
	return EnvironmentData ( ID );
	
endfunction 

&atclient
procedure RegisterEnvironment ( ID, Data = undefined ) export
	
	Environment.Register ( ID, Data );
	
endprocedure 

&atclient
procedure СохранитьОкружение ( ID, Data = undefined ) export
	
	RegisterEnvironment ( ID, Data );
	
endprocedure 

&atclient
function Screenshot ( Pattern = "", Compressed = undefined ) export
	
	return Forms.Shoot ( Pattern, Compressed );
	
endfunction 

&atclient
function Снимок ( Pattern = "", Compressed = undefined ) export
	
	return Screenshot ( Pattern, Compressed );
	
endfunction 

&atclient
procedure VStudio ( Text ) export
	
	Forms.BroadcastMessage ( Text );
	
endprocedure

&atclient
procedure ВСтудию ( Text ) export
	
	VStudio ( Text );
	
endprocedure

&atclient
procedure PinApplication ( Name ) export
	
	Environment.ChangeApplication ( Name );
	
endprocedure

&atclient
procedure УстановитьПриложение ( Name ) export
	
	PinApplication ( Name );
	
endprocedure

&atclient
procedure SetVersion ( Version, Application = undefined ) export
	
	Environment.SetApplicationVersion ( Version, Application );
	
endprocedure 

&atclient
procedure УстановитьВерсию ( Version, Application = undefined ) export
	
	SetVersion ( Version, Application );
	
endprocedure 

function ParametersSpace () export
	
	return ParametersService;
	
endfunction

function ЗонаПараметров () export
	
	return ParametersService;
	
endfunction

procedure NewJob ( Agent, Scenario, Application = undefined, Parameters = undefined, Computer = undefined,
	Memo = undefined, Schedule = undefined, Parent = undefined ) export
	
	TesterAgent.CreateJob ( Agent, Scenario, Application, Parameters, Computer, Memo, Schedule, Parent );
	
endprocedure

procedure СоздатьЗадание ( Agent, Scenario, Application = undefined, Parameters = undefined, Computer = undefined,
	Memo = undefined, Schedule = undefined, Parent = undefined ) export
	
	NewJob ( Agent, Scenario, Application, Parameters, Computer, Memo, Schedule, Parent );
	
endprocedure

&atclient
procedure GotoConsole () export
	
	Test.GotoSystemConsole ();

endprocedure

&atclient
procedure ПерейтиВКонсоль () export
	
	GotoConsole (); 

endprocedure

function Assert ( Value, Details = "" ) export 
	
	#if ( Server ) then
		obj = DataProcessors.Assertions.Create ();
	#else
		obj = GetForm ( "DataProcessor.Assertions.Form" );
	#endif
	obj.That ( Value, Details );	
	return obj;
	
endfunction

function Заявить ( Value, Details = "" ) export
	
	return Assert ( Value, Details );
	
endfunction

&atclient
procedure RecorderStart () export
	
	Debugger.Recording ( true );
	
endprocedure

&atclient
procedure ХронографСтарт () export
	
	RecorderStart ();
	
endprocedure

&atclient
procedure RecorderStop () export
	
	Debugger.Recording ( false );
	
endprocedure

&atclient
procedure ХронографСтоп () export
	
	RecorderStop ();
	
endprocedure

procedure RecorderClean ( Scenario = undefined, DateTo = undefined, Session = undefined ) export
	
	Maintenance.CleanTimelapse ( Session, Scenario, DateTo );
	
endprocedure

procedure ХронографОчистить ( Scenario = undefined, DateTo = undefined, Session = undefined ) export
	
	RecorderClean ( Session, Scenario, DateTo );
	
endprocedure

&atclient
procedure ProgressShow () export
	
	Debugger.EnableProgress ();
	
endprocedure

&atclient
procedure ПрогрессПоказать () export
	
	ProgressShow ();
	
endprocedure

&atclient
procedure ProgressHide () export
	
	Debugger.DisableProgress ();
	
endprocedure

&atclient
procedure ПрогрессСкрыть () export
	
	ProgressHide ();
	
endprocedure

&atclient
function SystemVariable ( Name ) export
	
	return Environment.GetVariable ( Name );
	
endfunction

&atclient
function ПеременнаяСреды ( Name ) export

	return SystemVariable ( Name );
	
endfunction

&atclient
procedure MaximizeWindow ( Pattern = "" ) export
	
	Forms.ToggleWindow ( Pattern, true );
	
endprocedure

&atclient
procedure МаксимизироватьОкно ( Pattern = "" ) export
	
	MaximizeWindow ( Pattern );
	
endprocedure

&atclient
procedure MinimizeWindow ( Pattern = "" ) export
	
	Forms.ToggleWindow ( Pattern, false );
	
endprocedure

&atclient
procedure МинимизироватьОкно ( Pattern = "" ) export
	
	MinimizeWindow ( Pattern );
	
endprocedure

&atclient
procedure StoreScenarios ( Memo = "" ) export

	p = new Structure ( "Silent, Memo", true, Memo );
	OpenForm ( "Catalog.Scenarios.Form.Store", p, , true );

endprocedure

&atclient
procedure ПоместитьСценарии ( Memo = "" ) export

	StoreScenarios ( Memo );

endprocedure

&atclient
procedure RunTest ( Scenario, Application = undefined, IgnoreLocking = false ) export
	
	Test.Start( Scenario, Application, IgnoreLocking );
	
endprocedure

&atclient
procedure ЗапуститьТест ( Scenario, Application = undefined, IgnoreLocking = false ) export
	
	RunTest ( Scenario, Application, IgnoreLocking );
	
endprocedure

&atclient
function TestingID () export
	
	return EnvironmentSrv.TestingID ();
	
endfunction

&atclient
function ИДОкружения () export
	
	return TestingID ();
	
endfunction

&atclient
function ПолучитьСодержимоеТаблицы ( Name, Source = undefined ) export
	
	return GetTableContent ( Name, Source );
	
endfunction

&atclient
function GetTableContent ( Name, Source = undefined ) export
	
	Test.CheckConnection ();
	return Fields.FetchTableContent ( Name, Forms.FindSource ( Source ) );
	
endfunction

&atclient
function ПолучитьСодержимоеТабличногоДокумента ( Name, Source = undefined ) export
	
	return GetSpreadsheetContent ( Name, Source );
	
endfunction

&atclient
function GetSpreadsheetContent ( Name, Source = undefined ) export
	
	Test.CheckConnection ();
	return Fields.FetchSpreadsheetContent ( Name, Forms.FindSource ( Source ) );
	
endfunction

&atclient
function GetActiveWindowControls () export
	
	Test.CheckConnection ();
	data = Fields.GetWindowControls ();
	return ? ( data = undefined, undefined, data.Elements );
	
endfunction

&atclient
function ПолучитьЭлементыАктивногоОкна () export
	
	return GetActiveWindowControls ();
	
endfunction

&atclient
function GetActiveWindowChanges () export
	
	Test.CheckConnection ();
	return Forms.GetChanges ();
	
endfunction

&atclient
function ПолучитьИзмененияОкна () export
	
	return GetActiveWindowChanges ();
	
endfunction

&atclient
function GetMainMenu () export
	
	Test.CheckConnection ();
	return Fields.FetchMainMenu ();
	
endfunction

&atclient
function ПолучитьГлавноеМеню () export
	
	return GetMainMenu ();
	
endfunction

&atclient
function EnterValue ( Name, Value ) export

	Test.CheckConnection ();
	return Fields.SetValue ( Name, Value, , , true, true );

endfunction

&atclient
function ВнестиЗначение ( Name, Value ) export

	return EnterValue ( Name, Value );

endfunction

#if ( not webclient ) then

&atclient
function GetScreenshot () export

	data = Screenshot ();
	file = GetTempFileName ( "png" );
	data.Write ( file );
	return file;

endfunction

&atclient
function ПолучитьСнимок () export

	return GetScreenshot ();

endfunction

#endif
