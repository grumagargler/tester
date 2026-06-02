
// *****************************************
// *********** Form events

&atserver
procedure OnCreateAtServer ( Cancel, StandardProcessing )
	
	loadParams ();
	setFilter ();
	
endprocedure

&atserver
procedure loadParams ()
	
	ScenarioFilter = Parameters.Scenario;
	
endprocedure 

&atserver
procedure setFilter ()
	
	if ( ScenarioFilter = undefined ) then
		CreatorFilter = SessionParameters.User;
		filterByCreator ();
	else
		filterByScenario ();
	endif;
	
endprocedure 

&atserver
procedure filterByCreator ()
	
	DC.ChangeFilter ( List, "Creator", CreatorFilter, not CreatorFilter.IsEmpty () );
	
endprocedure

&atserver
procedure filterByScenario ()
	
	DC.ChangeFilter ( List, "Scenario", ScenarioFilter, not ScenarioFilter.IsEmpty () );
	
endprocedure

// *****************************************
// *********** Group Form

&atclient
procedure Refresh(Command)
	
	Items.List.Refresh ();
	Items.Agents.Refresh ();
	
endprocedure

&atclient
procedure CreatorFilterOnChange ( Item )
	
	filterByCreator ();
	
endprocedure

&atclient
procedure ScenarioFilterOnChange ( Item )
	
	filterByScenario ();
	
endprocedure

&atclient
procedure AgentFilterOnChange ( Item )
	
	filterByAgent ();
	
endprocedure

&atserver
procedure filterByAgent ()
	
	DC.ChangeFilter ( List, "Agent", AgentFilter, not AgentFilter.IsEmpty () );
	
endprocedure

&atclient
procedure ModeFilterOnChange ( Item )
	
	filterByMode ();
	
endprocedure

&atserver
procedure filterByMode ()
	
	DC.ChangeFilter ( List, "Mode", ModeFilter, not ModeFilter.IsEmpty () );
	
endprocedure

// *****************************************
// *********** List

&atclient
procedure ListSelection ( Item, SelectedRow, Field, StandardProcessing )
	
	if ( Field.Name = "Job" ) then
		StandardProcessing = false;
		ShowValue ( , Item.CurrentData.Job );
	endif;
	
endprocedure

&atservernocontext
procedure ListOnGetDataAtServer ( ItemName, Settings, Rows )
	
	for each item in Rows do
		data = item.Value.Data;
		end = ? ( data.Status = Enums.JobStatuses.Running, CurrentUniversalDateInMilliseconds (), data.Finish );
		data.Duration = Conversion.PeriodToDuration ( data.Start, end );
	enddo;
	
endprocedure
