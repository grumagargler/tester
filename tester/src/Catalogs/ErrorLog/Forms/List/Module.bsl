&atclient
var ListRow;

// *****************************************
// *********** Form events

&atserver
procedure OnCreateAtServer ( Cancel, StandardProcessing )
	
	loadParams ();
	setFilter ();
	readAppearance ();
	Appearance.Apply ( ThisObject );
	
endprocedure

&atserver
procedure readAppearance ()

	rules = new Array ();
	rules.Add ( "
	|User show empty ( UserFilter );
	|Job show empty ( JobFilter );
	|Severity show empty ( SeverityFilter );
	|Area show empty ( AreaFilter )
	|" );
	Appearance.Read ( ThisObject, rules );

endprocedure

&atserver
procedure loadParams ()
	
	ScenarioFilter = Parameters.Scenario;
	JobFilter = Parameters.Job;
	
endprocedure 

&atserver
procedure setFilter ()
	
	defaultFilter = true;
	if ( not JobFilter.IsEmpty () ) then
		defaultFilter = false;
		filterByJob ();
	endif;
	if ( ScenarioFilter <> undefined ) then
		defaultFilter = false;
		filterByScenario ();
	endif;
	if ( Parameters.CurrentRow <> undefined ) then
		defaultFilter = false;
	endif;
	if ( defaultFilter ) then
		UserFilter = SessionParameters.User;
		filterByUser ();
	endif;
	
endprocedure 

&atserver
procedure filterByJob ()
	
	DC.ChangeFilter ( List, "Job", JobFilter, not JobFilter.IsEmpty () );
	
endprocedure 

&atserver
procedure filterByUser ()
	
	DC.ChangeFilter ( List, "User", UserFilter, not UserFilter.IsEmpty () );
	
endprocedure 

&atserver
procedure filterByScenario ()
	
	filter = ScenarioFilter <> undefined;
	if ( filter ) then
		DC.SetParameter ( List, "Scenario", ScenarioFilter, ScenarioFilter <> undefined );
	else
		DC.SetParameter ( List, "Scenario", undefined, false );
	endif;
	
endprocedure 

// *****************************************
// *********** Group Form

&atclient
procedure ClearLog ( Command )
	
	Output.ClearLogConfirmation ( ThisObject );
	
endprocedure

&atclient
procedure ClearLogConfirmation ( Answer, Params ) export
	
	if ( Answer = DialogReturnCode.No ) then
		return;
	endif; 
	clearErrors ();
	Items.List.Refresh ();
	
endprocedure 

&atserver
procedure clearErrors ()
	
	data = getRecords ();
	SetPrivilegedMode ( true );
	BeginTransaction ();
	selection = data.Log.Select ();
	while ( selection.Next () ) do
		r = InformationRegisters.Log.CreateRecordManager ();
		FillPropertyValues ( r, selection );
		r.Delete ();
	enddo; 
	selection = data.ErrorLog.Select ();
	while ( selection.Next () ) do
		selection.Ref.GetObject ().Delete ();
	enddo; 
	CommitTransaction ();
	
endprocedure 

&atserver
function getRecords ()
	
	s = "
	|select allowed ErrorLog.Ref as Ref
	|into ErrorLog
	|from Catalog.ErrorLog as ErrorLog
	|;
	|select ErrorLog.Ref as Ref
	|from ErrorLog as ErrorLog
	|;
	|select Log.Period as Period, Log.Session as Session, Log.Scenario as Scenario
	|from InformationRegister.Log as Log
	|where Log.Error in ( select Ref from ErrorLog )
	|";
	q = new Query ( s );
	data = q.ExecuteBatch ();
	result = new Structure ();
	result.Insert ( "ErrorLog", data [ 1 ] );
	result.Insert ( "Log", data [ 2 ] );
	return result;
	
endfunction 

&atclient
procedure UserFilterOnChange ( Item )
	
	applyUserFilter ();
	
endprocedure

&atserver
procedure applyUserFilter ()
	
	if ( not UserFilter.IsEmpty () ) then
		JobFilter = undefined;
		filterByJob ();
		Appearance.Apply ( ThisObject, "JobFilter" );
	endif;
	filterByUser ();
	Appearance.Apply ( ThisObject, "UserFilter" );

endprocedure

&atclient
procedure ScenarioFilterOnChange ( Item )
	
	filterByScenario ();
	
endprocedure

&atclient
procedure JobFilterOnChange ( Item )
	
	applyJobFilter ();
	
endprocedure

&atserver
procedure applyJobFilter ()
	
	if ( not JobFilter.IsEmpty () ) then
		UserFilter = undefined;
		filterByUser ();
		Appearance.Apply ( ThisObject, "UserFilter" );
	endif;
	filterByJob ();
	Appearance.Apply ( ThisObject, "JobFilter" );

endprocedure

&atclient
procedure SeverityFilterOnChange ( Item )
	
	filterBySeverity ();
	
endprocedure

&atserver
procedure filterBySeverity ()
	
	DC.ChangeFilter ( List, "Severity", SeverityFilter, not SeverityFilter.IsEmpty () );
	Appearance.Apply ( ThisObject, "SeverityFilter" );
	
endprocedure 

&atclient
procedure AreaFilterOnChange ( Item )
	
	filterByArea ();
	
endprocedure

&atserver
procedure filterByArea ()
	
	DC.ChangeFilter ( List, "Area", AreaFilter, not AreaFilter.IsEmpty () );
	Appearance.Apply ( ThisObject, "AreaFilter" );
	
endprocedure 

// *****************************************
// *********** List

&atclient
procedure ListOnActivateRow ( Item )
	
	ListRow = Item.CurrentData;
	AttachIdleHandler ( "fill", 0.1, true );
	
endprocedure

&atclient
procedure fill () export
	
	if ( ListRow = undefined ) then
		Screenshot = "";
		Stack.Clear ();
	else
		if ( ListRow.Ref = OldRecord ) then
			return;
		endif; 
		OldRecord = ListRow.Ref;
		updateInfo ();
	endif; 
	displayInfo ();
	
endprocedure 

&atserver
procedure updateInfo ()
	
	ErrorLogForm.UpdateStack ( OldRecord, Stack );
	updateScreenshot ();
	
endprocedure 

&atserver
procedure updateScreenshot ()
	
	if ( DF.Pick ( OldRecord, "ScreenshotExists" ) ) then
		Screenshot = GetURL ( OldRecord, "Screenshot" );
	else
		Screenshot = "";
	endif; 

endprocedure 

&atclient
procedure displayInfo ()
	
	if ( Screenshot = "" ) then
		if ( ListRow = undefined ) then
			Items.Pages.CurrentPage = Items.UndefinedPage;
		else
			Items.Pages.CurrentPage = Items.InfoPage;
		endif; 
	else
		Items.Pages.CurrentPage = Items.ScreenshotPage;
	endif; 
	
endprocedure 

&atclient
procedure ListSelection ( Item, SelectedRow, Field, StandardProcessing )
	
	StandardProcessing = false;
	if ( Field.Name = "Job" ) then
		ShowValue ( , ListRow.Job );
	else
		ShowValue ( , ListRow.Ref );
	endif;
	
endprocedure

// *****************************************
// *********** Table Stack

&atclient
procedure StackSelection ( Item, SelectedRow, Field, StandardProcessing )
	
	StandardProcessing = false;
	data = Item.CurrentData;
	ScenarioForm.GotoLine ( data.Ref, data.Row, ListRow.Ref );
	
endprocedure

// *****************************************
// *********** Screenshot Field

&atclient
procedure ScreenshotClick ( Item, StandardProcessing )
	
	StandardProcessing = false;
	showPicture ();
	
endprocedure

&atclient
procedure showPicture ()
	
	if ( Screenshot = "" ) then
		return;
	endif; 
	p = new Structure ();
	p.Insert ( "Title", OldRecord );
	p.Insert ( "URL", Screenshot );
	OpenForm ( "CommonForm.Screenshot", p );
	
endprocedure 
