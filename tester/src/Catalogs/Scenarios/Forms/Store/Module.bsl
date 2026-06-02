&atserver
var Stored;

// *****************************************
// *********** Form events

&atserver
procedure OnCreateAtServer ( Cancel, StandardProcessing )
	
	loadParams ();
	LockingForm.LoadScenarios ( ThisObject );
	readAppearance ();
	Appearance.Apply ( ThisObject );
	
endprocedure

&atserver
procedure readAppearance ()

	rules = new Array ();
	rules.Add ( "
	|FormContinue Warning show JobPreparing;
	|FormClose show not JobPreparing
	|" );
	Appearance.Read ( ThisObject, rules );

endprocedure

&atserver
procedure loadParams ()
	
	JobPreparing = Parameters.JobPreparing;
	Memo = Parameters.Memo;
	
endprocedure

// *****************************************
// *********** Group Form

&atclient
procedure OnOpen ( Cancel )
	
	if ( silentMode () ) then
		Cancel = true;
		beginStoring ();
	endif;
	
endprocedure

&atclient
function silentMode ()
	
	return Parameters.Silent;
	
endfunction

&atclient
procedure beginStoring ()
	
	AllScenarios = fetchScenarios ();
	Notify ( Enum.MessageSave (), AllScenarios );
	if ( silentMode ()
		or checkSyntax () ) then
		startStoring ();
	else
		Output.ContinueStoring ( ThisObject );
	endif;

endprocedure

&atserver
function fetchScenarios ()
	
	return new FixedArray ( LockingForm.FetchScenarios ( ThisObject ).UnloadColumn ( "Ref" ) );
	
endfunction

&atclient
function checkSyntax ()

	ok = true;
	target = FormOwner.UUID;
	for each scenario in AllScenarios do
		error = Runtime.CheckSyntax ( DF.Pick ( scenario, "Script" ), scenario );
		if ( error <> undefined ) then
			ok = false;
			Output.SyntaxError ( target, new Structure ( "Error", error ), , scenario );
		endif;
	enddo;
	return ok;

endfunction

&atclient
procedure startStoring ()

	stored = store ();
	broadcast ( stored );
	Close ();

endprocedure 

&atserver
function store ()
	
	BeginTransaction ();
	LockingForm.LockEditing ( scenariosTable () );
	userScenarios ();
	if ( not KeepLocked ) then
		unlockScenarios ();
	endif; 
	createVersions ();
	CommitTransaction ();
	return Stored;
	
endfunction

&atserver
function scenariosTable ()
	
	table = new ValueTable ();
	table.Columns.Add ( "Ref", new TypeDescription ( "CatalogRef.Scenarios" ) );
	for each scenario in AllScenarios do
		row = table.Add ();
		row.Ref = scenario;
	enddo; 
	return table;
	
endfunction 

&atserver
procedure userScenarios ()
	
	s = "
	|select Editing.Scenario as Scenario
	|from InformationRegister.Editing as Editing
	|where Editing.Scenario in ( &Scenarios )
	|and Editing.User = &User
	|";
	q = new Query ( s );
	q.SetParameter ( "User", SessionParameters.User );
	q.SetParameter ( "Scenarios", AllScenarios );
	Stored = q.Execute ().Unload ().UnloadColumn ( "Scenario" );

endprocedure

&atserver
procedure unlockScenarios ()
	
	for each scenario in Stored do
		r = InformationRegisters.Editing.CreateRecordManager ();
		r.Scenario = scenario;
		r.Delete ();
	enddo; 
	
endprocedure

&atserver
procedure createVersions ()
	
	for each scenario in Stored do
		Catalogs.Versions.Create ( scenario, Memo );
	enddo; 

endprocedure 

&atclient
procedure broadcast ( Scenarios )
	
	Notify ( Enum.MessageStored (), Scenarios );
	NotifyChanged ( Type ( "CatalogRef.Scenarios" ) );
	
endprocedure 

&atclient
procedure OK ( Command )
	
	beginStoring ();
	
endprocedure

&atclient
procedure ContinueStoring ( Answer, Params ) export
	
	if ( Answer = DialogReturnCode.No ) then
		Close ();
		return;
	endif;
	startStoring ();
	
endprocedure

// *****************************************
// *********** Table List

&atclient
procedure ListBeforeAddRow ( Item, Cancel, Clone, Parent, Folder, Parameter )
	
	Cancel = true;
	
endprocedure

&atclient
procedure ListBeforeDeleteRow ( Item, Cancel )
	
	Cancel = true;
	
endprocedure
