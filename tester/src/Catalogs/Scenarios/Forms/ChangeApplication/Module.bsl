&atserver
var AllScenarios export;
&atserver
var WorkingScope export;

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
	
	var changed, locked, alreadyLocked, errors;
	
	change ( changed, locked, alreadyLocked, errors );
	broadcast ( changed );
	RepositoryFiles.Sync ();
	Close ( new Structure ( "AlreadyLocked, Errors", alreadyLocked, errors ) );
	
endprocedure

&atserver
procedure change ( Changed, Locked, AlreadyLocked, Errors )
	
	fetchScenarios ();
	LockingForm.Lock ( AllScenarios, Locked, AlreadyLocked );
	modify ( AlreadyLocked, Errors );
	Changed = WorkingScope;
	
endprocedure

&atserver
procedure fetchScenarios ()
	
	data = LockingForm.FetchScenarios ( ThisObject );
	AllScenarios = data [ 0 ].Unload ();
	WorkingScope = data [ 1 ].Unload ().UnloadColumn ( "Ref" );
	
endprocedure 

&atserver
procedure modify ( AlreadyLocked, Errors )
	
	errorsList = new Array ();
	notMine = notMine ( AlreadyLocked );
	for each row in AllScenarios do
		scenario = row.Ref;
		if ( notMine [ scenario ] <> undefined ) then
			continue;
		endif; 
		current = DF.Pick ( scenario, "Application" );
		if ( current = Application ) then
			continue;
		endif;
		obj = scenario.GetObject ();
		obj.Application = Application;
		try
			obj.Write ();
		except
			error = ErrorDescription ();
			errorsList.Add ( new Structure ( "Scenario, Error", scenario, error ) );
			continue;
		endtry;
	enddo; 
	Errors = ? ( errorsList.Count () = 0, undefined, errorsList );
	
endprocedure

&atserver
function notMine ( AlreadyLocked )
	
	set = new Map ();
	if ( AlreadyLocked <> undefined ) then
		for each item in AlreadyLocked do
			set [ item.Scenario ] = true;
		enddo; 
	endif; 
	return set;
	
endfunction 

&atclient
procedure broadcast ( Changed )
	
	Notify ( Enum.MessageApplicationChanged (), Changed );
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
