// *****************************************
// *********** Form events

&atserver
procedure OnCreateAtServer ( Cancel, StandardProcessing )
	
	if ( Object.Ref.IsEmpty () ) then
		ScenarioForm.Init ( ThisObject );
	endif; 
	
endprocedure

&atclient
procedure BeforeWrite ( Cancel, WriteParameters )
	
	if ( not ScenarioForm.SaveParents ( Object, undefined ) ) then
		Cancel = true;
	endif;
	
endprocedure

&atclient
procedure AfterWrite ( WriteParameters )
	
	ScenarioForm.RereadParents ( Object, undefined );
	ref = Object.Ref;
	if ( Main ) then
		Environment.ChangeScenario ( ref );
	endif;
	RepositoryFiles.Sync ();
	type = Object.Type;
	if ( type = PredefinedValue ( "Enum.Scenarios.Scenario" )
		or type = PredefinedValue ( "Enum.Scenarios.Method" ) ) then
		OpenForm ( "Catalog.Scenarios.ObjectForm", new Structure ( "Key", ref ) );
	endif;

endprocedure

// *****************************************
// *********** Group Form

&atclient
procedure DescriptionOnChange ( Item )
	
	Object.Description = TrimAll ( Object.Description );
	
endprocedure
