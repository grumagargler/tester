&atserver
var AllScenarios export;

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
	
	var locked, errors;
	
	lock ( locked, errors );
	broadcast ( locked );
	Close ( errors );
	
endprocedure

&atserver
procedure lock ( LockedScenarios, ErrorsList )
	
	AllScenarios = LockingForm.FetchScenarios ( ThisObject );
	LockingForm.Lock ( AllScenarios, LockedScenarios, ErrorsList );
	
endprocedure

&atclient
procedure broadcast ( Scenarios )
	
	Notify ( Enum.MessageLocked (), Scenarios );
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
