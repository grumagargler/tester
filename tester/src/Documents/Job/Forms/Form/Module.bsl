&atclient
var TableRow;
&atclient
var ConfirmationTaken;
&atclient
var LockedScenarios;

// *****************************************
// *********** Form events

&atserver
procedure OnReadAtServer ( CurrentObject )
	
	setAgentStatus ( ThisObject );
	readSchedule ();
	readInfo ();
	readErrors ();
	Appearance.Apply ( ThisObject );
	
endprocedure

&atclientatservernocontext
procedure setAgentStatus ( Form )
	
	object = Form.Object;
	Form.AgentStatus = getStatus ( object.Agent, object.Computer );
	Appearance.Apply ( Form );
	
endprocedure

&atservernocontext
function getStatus ( val Agent, val Computer )
	
	s = "
	|select top 1 AgentStatuses.Status as Status
	|from InformationRegister.AgentStatuses as AgentStatuses
	|where AgentStatuses.Session in (
	|	select top 1 Sessions.Ref as Ref
	|	from Catalog.Sessions as Sessions
	|	where not Sessions.DeletionMark
	|	and Sessions.User = &Agent
	|	and Sessions.Computer = &Computer
	|)
	|";
	q = new Query ( s );
	q.SetParameter ( "Agent", Agent );
	q.SetParameter ( "Computer", Computer );
	table = q.Execute ().Unload ();
	return ? ( table.Count () = 0, undefined, table [ 0 ].Status );
	
endfunction 

&atserver
procedure readSchedule ()
	
	if ( Object.Mode = Enums.Running.Schedule ) then
		Schedule = Conversion.JSONToObject ( Object.Schedule, Type ( "JobSchedule" ) );
	endif;
	
endprocedure

&atserver
procedure readInfo ()
	
	r = InformationRegisters.AgentJobs.CreateRecordManager ();
	r.Job = Object.Ref;
	r.Read ();
	ValueToFormAttribute ( r, "JobInfo" );
	DC.SetParameter ( JobsLog, "Ref", Object.Ref );
	
endprocedure

&atserver
procedure readErrors ()
	
	s = "
	|select count ( Log.Status ) as Count
	|from InformationRegister.Log as Log
	|where Log.Job = &Ref
	|and Log.Level = 0
	|and Log.Status = value ( Enum.Statuses.Fault )
	|";
	q = new Query ( s );
	q.SetParameter ( "Ref", Object.Ref );
	ErrorsCount = q.Execute ().Unload ().Total ( "Count" );
	
endprocedure

&atserver
procedure OnCreateAtServer ( Cancel, StandardProcessing )
	
	if ( Object.Ref.IsEmpty () ) then
		DocumentForm.Init ( Object );
		loadParams ();
		initNew ();
	else
		WindowOpeningMode = FormWindowOpeningMode.Independent;
	endif;
	readAppearance ();
	Appearance.Apply ( ThisObject );
	
endprocedure

&atserver
procedure readAppearance ()

	rules = new Array ();
	rules.Add ( "
	|Job show filled ( Object.Job ) and Object.Mode = Enum.Running.Now;
	|Scenarios show ( empty ( Object.Ref ) or Object.Mode = Enum.Running.Schedule );
	|FormWriteAndClose show
	|( empty ( Object.Ref ) or Object.Mode = Enum.Running.Schedule )
	|and not Object.DeletionMark;
	|FormDelete show filled ( Object.Ref ) and not Object.DeletionMark;
	|Schedule IgnoreCompletion enable Object.Mode = Enum.Running.Schedule and not Object.DeletionMark;
	|Statistics JobsLog show filled ( Object.Ref ) and Object.Mode = Enum.Running.Now;
	|Info show
	|filled ( Object.Ref )
	|and Object.Mode = Enum.Running.Now
	|and not Object.DeletionMark;
	|Removed show Object.DeletionMark;
	|Agent Computer Mode1 Mode2 Scenarios Number lock filled ( Object.Ref );
	|ErrorLog show JobInfo.Status = Enum.JobStatuses.Fault;
	|JobsLogRefresh show inlist ( JobInfo.Status, Enum.Running.EmptyRef, Enum.JobStatuses.Pending, Enum.JobStatuses.Running ) and Object.Mode = Enum.Running.Now;
	|Memo lock
	|( Object.DeletionMark
	|	or ( Object.Mode = Enum.Running.Now and filled ( Object.Ref ) ) );
	|AgentStatus
	|" );
	Appearance.Read ( ThisObject, rules );

endprocedure

&atserver
procedure loadParams ()
	
	if ( Parameters.Scenarios = undefined ) then
		return;
	endif;
	list = getScenarios ();
	Object.Scenarios.Load ( list );
	
endprocedure

&atserver
function getScenarios ()
	
	s = "
	|select allowed Scenarios.Ref as Scenario,
	|	case when Scenarios.Application = value ( Catalog.Applications.EmptyRef ) then &Application else Scenarios.Application end as Application
	|from Catalog.Scenarios as Scenarios
	|where Scenarios.Ref in hierarchy ( &Scenarios )
	|and not Scenarios.DeletionMark
	|and Scenarios.Type = value ( Enum.Scenarios.Scenario )
	|order by Scenarios.Path
	|";
	q = new Query ( s );
	q.SetParameter ( "Scenarios", Parameters.Scenarios );
	q.SetParameter ( "Application", EnvironmentSrv.GetApplication () );
	return q.Execute ().Unload ();
	
endfunction

&atserver
procedure initNew ()
	
	if ( Object.Schedule = "" ) then
		initSchedule ();
	else
		readSchedule ();
	endif;
	if ( not Object.Agent.IsEmpty () ) then
		setAgentStatus ( ThisObject );
	endif;
	
endprocedure

&atserver
procedure initSchedule ()
	
	Schedule = new JobSchedule ();
	Schedule.BeginDate = BegOfDay ( CurrentSessionDate () + 86400 );
	Schedule.DaysRepeatPeriod = 1;
	
endprocedure

&atserver
procedure BeforeLoadDataFromSettingsAtServer ( Settings )
	
	if ( not Object.Agent.IsEmpty ()
		or not Object.Ref.IsEmpty () ) then
		Settings.Clear ();
	endif;
	
endprocedure

&atserver
procedure OnLoadDataFromSettingsAtServer ( Settings )
	
	if ( not Object.Agent.IsEmpty () ) then
		setAgentStatus ( ThisObject );
	endif;
	
endprocedure

&atclient
procedure BeforeWrite ( Cancel, WriteParameters )
	
	if ( not CheckFilling () ) then
		Cancel = true;
		return;
	endif;
	if ( confirmationRequired () ) then
		Cancel = true;
		askUser ();
	endif;
	storeSchedule ();
	
endprocedure

&atclient
function confirmationRequired ()
	
	if ( ConfirmationTaken
		or not Object.Ref.IsEmpty () ) then
		return false;
	endif;
	LockedScenarios = editingScenarios ();
	return LockedScenarios.Count () > 0;
	
endfunction

&atserver
function editingScenarios ()
	
	s = "
	|select allowed distinct Editing.Scenario as Scenario
	|from InformationRegister.Editing as Editing
	|	//
	|	// Actual Versions
	|	//
	|	left join Catalog.Versions as Versions
	|	on Versions.Scenario = Editing.Scenario
	|	and Versions.Changed = Editing.Scenario.Changed
	|where Editing.Scenario in ( &Scenarios )
	|and Editing.User <> &Agent
	|and Editing.User = &Me
	|and Versions.Code is null
	|order by Editing.Scenario.Path
	|";
	q = new Query ( s );
	q.SetParameter ( "Scenarios", Object.Scenarios.Unload ( , "Scenario" ).UnloadColumn ( "Scenario" ) );
	q.SetParameter ( "Agent", Object.Agent );
	q.SetParameter ( "Me", SessionParameters.User );
	return q.Execute ().Unload ().UnloadColumn ( "Scenario" );
	
endfunction

&atclient
procedure askUser ()
	
	p = new Structure ( "Scenarios, JobPreparing", LockedScenarios, true );
	callback = new NotifyDescription ( "StoreFormClosed", ThisObject );
	OpenForm ( "Catalog.Scenarios.Form.Store", p, ThisObject, true, , , callback );
	
endprocedure

&atclient
procedure StoreFormClosed ( Result, Params ) export
	
	ConfirmationTaken = true;
	Write ();
	Close ();
	
endprocedure

&atclient
procedure storeSchedule ()
	
	if ( Object.Mode = PredefinedValue ( "Enum.Running.Schedule" ) ) then
		Object.Schedule = Conversion.ObjectToJSON ( Schedule );
	endif;
	
endprocedure

// *****************************************
// *********** Group Form

&atclient
procedure ModeOnChange ( Item )
	
	Appearance.Apply ( ThisObject, "Object.Mode" );

endprocedure

&atclient
procedure ScheduleClick ( Item, StandardProcessing )
	
	StandardProcessing = false;
	showSchedule ();
	
endprocedure

&atclient
procedure showSchedule ()
	
	#if ( not MobileClient ) then
		dialog = new ScheduledJobDialog ( Schedule );
		dialog.Show ( new NotifyDescription ( "ScheduleDefined", ThisObject ) );
	#endif
	
endprocedure

&atclient
procedure ScheduleDefined ( Data, Params ) export
	
	if ( Data = undefined ) then
		return;
	endif;
	Schedule = Data;
	
endprocedure

&atclient
procedure Delete ( Command )

	Output.DeleteJob ( ThisObject );
	
endprocedure

&atclient
procedure DeleteJob ( Answer, Params ) export
	
	if ( Answer = DialogReturnCode.No ) then
		return;
	endif;
	Object.DeletionMark = true;
	Write ();
	Close ();
	
endprocedure

&atclient
procedure AgentChoiceProcessing ( Item, SelectedValue, StandardProcessing )
	
	if ( TypeOf ( SelectedValue ) = Type ( "Structure" ) ) then
		StandardProcessing = false;
		applyAgent ( SelectedValue );
	endif;
	
endprocedure

&atclient
procedure applyAgent ( Data )
	
	Object.Agent = Data.Agent;
	Object.Computer = Data.Computer;
	setAgentStatus ( ThisObject );
	
endprocedure

&atclient
procedure AgentOnChange ( Item )
	
	setAgentStatus ( ThisObject );
	
endprocedure

// *****************************************
// *********** Scenarios

&atclient
procedure ScenariosOnActivateRow ( Item )
	
	TableRow = Item.CurrentData;
	
endprocedure

&atclient
procedure ScenariosScenarioOnChange ( Item )
	
	setApplication ();
	
endprocedure

&atclient
procedure setApplication ()
	
	value = DF.Pick ( TableRow.Scenario, "Application" );
	if ( value.IsEmpty () ) then
		value = EnvironmentSrv.GetApplication ();
	endif;
	TableRow.Application = value;
	
endprocedure

// *****************************************
// *********** Jobs

&atclient
procedure JobsLogOnActivateRow ( Item )
	
	TableRow = Item.CurrentData;
	
endprocedure

&atclient
procedure JobsLogSelection ( Item, SelectedRow, Field, StandardProcessing )
	
	if ( Field.Name = "JobsLogScenario" ) then
		showMenu ();
	endif;
	
endprocedure

&atclient
procedure showMenu ()
	
	menu = new ValueList ();
	status = TableRow.Status;
	if ( status = PredefinedValue ( "Enum.Statuses.Fault" ) ) then
		menu.Add ( 1, Output.OpenErrorsLog (), , PictureLib.Warning );
		menu.Add ( 2, Output.OpenError () + TableRow.Error );
	endif;
	menu.Add ( 3, Output.OpenLog (), , PictureLib.EventLog );
	menu.Add ( 4, Output.OpenScenario (), , PictureLib.Change );
	ShowChooseFromMenu ( new NotifyDescription ( "ActionSelected", ThisObject ), menu );

endprocedure

&atclient
procedure ActionSelected ( Menu, Params ) export
	
	if ( Menu = undefined ) then
		return;
	endif;
	value = Menu.Value;
	if ( value = 1 ) then
		openLog ( true );
	elsif ( value = 2 ) then
		ShowValue ( , TableRow.Error );
	elsif ( value = 3 ) then
		openLog ();
	elsif ( value = 4 ) then
		ShowValue ( , findScenario ( Object.Ref, jobScenario (), TableRow.LineNumber ) );
	endif;
	
endprocedure

&atclient
function jobScenario ()
	
	return Object.Scenarios [ TableRow.LineNumber - 1 ].Scenario;
	
endfunction

&atclient
procedure openLog ( OnlyErrors = false )
	
	job = Object.Ref;
	scenario = findScenario ( job, jobScenario (), TableRow.LineNumber );
	if ( scenario = undefined ) then
		return;
	endif;
	params = new Structure ( "Scenario, Job", scenario, job );
	if ( OnlyErrors ) then
		OpenForm ( "Catalog.ErrorLog.ListForm", params );
	else
		OpenForm ( "InformationRegister.Log.ListForm", params );
	endif;
	
endprocedure

&atservernocontext
function findScenario ( val Job, val Scenario, val Row )
	
	s = "
	|select top 1 Log.Scenario as Scenario
	|from InformationRegister.Log as Log
	|where Log.Job = &Job
	|and Log.Row = &Row
	|and Log.Level = 0
	|and &Scenario in ( Log.Scenario.Scenario, Log.Scenario )
	|";
	q = new Query ( s );
	q.SetParameter ( "Job", Job );
	q.SetParameter ( "Row", Row );
	q.SetParameter ( "Scenario", Scenario );
	table = q.Execute ().Unload ();
	return ? ( table.Count () = 0, undefined, table [ 0 ].Scenario );
	
endfunction

// *****************************************
// *********** Variables Initialization

ConfirmationTaken = false;
