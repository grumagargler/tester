procedure Init () export
	
	OpenedScenarios = new Map ();
	
endprocedure 

procedure Push ( Form ) export
	
	ref = Form.Object.Ref;
	if ( ref.IsEmpty () ) then
		return;
	endif; 
	OpenedScenarios [ ref ] = Form;
	
endprocedure 

procedure Pop ( Scenario ) export
	
	form = OpenedScenarios [ Scenario ];
	if ( form = undefined ) then
		return;
	endif; 
	OpenedScenarios.Delete ( Scenario );
	
endprocedure 

function TryActivate ( Scenario ) export
	
	form = OpenedScenarios [ Scenario ];
	if ( form = undefined ) then
		return false;
	endif;
	form.Activate ();
	return true;
	
endfunction 

procedure Save ( Scenario ) export
	
	form = OpenedScenarios [ Scenario ];
	if ( form <> undefined
		and form.Modified ) then
		form.Write ();
	endif;
	
endprocedure

procedure Reread ( Scenario ) export
	
	form = OpenedScenarios [ Scenario ];
	if ( form <> undefined
		and not form.Modified ) then
		form.Reread ();
	endif;
	
endprocedure