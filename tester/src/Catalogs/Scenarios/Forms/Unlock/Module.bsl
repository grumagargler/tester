&atserver
var ActualScenarios;
&atserver
var LastVersions;

// *****************************************
// *********** Form events

&atserver
procedure OnCreateAtServer ( Cancel, StandardProcessing )
	
	LockingForm.LoadScenarios ( ThisObject );
	
endprocedure

// *****************************************
// *********** Group Form

&atclient
procedure OK ( Command )
	
	if ( nothing () ) then
		Close ();
	else
		Output.UnlockConfirmation ( ThisObject );
	endif; 
	
endprocedure

&atclient
function nothing ()
	
	for each row in List do
		if ( row.Use ) then
			return false;
		endif; 
	enddo; 
	return false;
	
endfunction 

&atclient
procedure UnlockConfirmation ( Answer, Params ) export
	
	if ( Answer = DialogReturnCode.No ) then
		return;
	endif; 
	restored = unlock ();
	broadcast ( restored );
	Close ();
	
endprocedure 

&atserver
function unlock ()
	
	table = LockingForm.FetchScenarios ( ThisObject );
	BeginTransaction ();
	LockingForm.LockEditing ( table );
	userScenarios ( table );
	restored = rollbackScenarios ();
	unlockScenarios ();
	CommitTransaction ();
	return restored;
	
endfunction

&atserver
procedure userScenarios ( Table )
	
	s = "
	|select Editing.Scenario as Scenario
	|into UserScenarios
	|from InformationRegister.Editing as Editing
	|where Editing.Scenario in ( &Scenarios )
	|and Editing.User = &User
	|index by Scenario
	|;
	|// Actual scenarios
	|select UserScenarios.Scenario as Scenario
	|from UserScenarios as UserScenarios
	|;
	|// Last versions
	|select Versions.Scenario as Scenario, Versions.Version as Version
	|from InformationRegister.Versions.SliceLast ( , Scenario in ( select Scenario from UserScenarios ) ) as Versions
	|";
	q = new Query ( s );
	q.SetParameter ( "User", SessionParameters.User );
	q.SetParameter ( "Scenarios", Table.UnloadColumn ( "Ref" ) );
	data = q.ExecuteBatch ();
	ActualScenarios  = data [ 1 ].Unload ().UnloadColumn ( "Scenario" );
	LastVersions  = data [ 2 ].Unload ();

endprocedure 

&atserver
function rollbackScenarios ()
	
	restored = new Array ();
	for each row in LastVersions do
		scenario = row.Scenario;
		Catalogs.Scenarios.Rollback ( scenario, row.Version );
		restored.Add ( scenario );
	enddo; 
	return restored;

endfunction

&atserver
procedure unlockScenarios ()
	
	for each scenario in ActualScenarios do
		r = InformationRegisters.Editing.CreateRecordManager ();
		r.Scenario = scenario;
		r.Delete ();
	enddo; 
	
endprocedure

&atclient
procedure broadcast ( Scenarios )
	
	Notify ( Enum.MessageReload (), Scenarios );
	NotifyChanged ( Type ( "CatalogRef.Scenarios" ) );
	
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
