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
	|Scenario show empty ( ScenarioFilter );
	|Job show empty ( JobFilter );
	|Severity show empty ( SeverityFilter )
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
	
	DC.ChangeFilter ( List, "Scenario", ScenarioFilter, ScenarioFilter <> undefined );
	Appearance.Apply ( ThisObject, "ScenarioFilter" );
	
endprocedure 

// *****************************************
// *********** Group Form

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
procedure SeverityFilterOnChange ( Item )
	
	filterBySeverity ();
	
endprocedure

&atserver
procedure filterBySeverity ()
	
	DC.ChangeFilter ( List, "Severity", SeverityFilter, not SeverityFilter.IsEmpty () );
	Appearance.Apply ( ThisObject, "SeverityFilter" );
	
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
procedure ListSelection ( Item, SelectedRow, Field, StandardProcessing )
	
	if ( openError ( Field )
		or showError ()
		or openJob ( Field ) ) then
		StandardProcessing = false;
	endif; 
	
endprocedure

&atclient
function openError ( Field )
	
	if ( Field.Name = "Error" ) then
		ShowValue ( , Items.List.CurrentData.Error );
		return true;
	endif; 
	return false;
	
endfunction 

&atclient
function showError ()
	
	error = Items.List.CurrentData.Error;
	if ( error.IsEmpty ()
		or not DF.Pick ( error, "ScreenshotExists" ) ) then
		return false;
	else
		p = new Structure ();
		p.Insert ( "Title", error );
		p.Insert ( "URL", GetURL ( error, "Screenshot" ) );
		OpenForm ( "CommonForm.Screenshot", p );
		return true;
	endif; 
	
endfunction

&atclient
function openJob ( Field )
	
	if ( Field.Name = "Job" ) then
		ShowValue ( , Items.List.CurrentData.Job );
		return true;
	endif; 
	return false;
	
endfunction 
