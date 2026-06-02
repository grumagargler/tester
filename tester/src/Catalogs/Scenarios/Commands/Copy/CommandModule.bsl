
&atclient
procedure CommandProcessing ( Scenarios, ExecuteParameters )
	
	p = new NotifyDescription ( "TargetSelected", ThisObject, Scenarios );
	OpenForm ( "Catalog.Scenarios.ChoiceForm", , , , , , p );
	
endprocedure

&atclient
procedure TargetSelected ( Target, Scenarios ) export
	
	if ( Target = undefined ) then
		return;
	endif;
	if ( not Target.IsEmpty () ) then
		ScenariosPanel.Save ( Target );
	endif;
	ScenarioForm.CopyMove ( Scenarios, Target, true );
	
endprocedure
