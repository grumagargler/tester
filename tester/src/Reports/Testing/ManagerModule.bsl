#if ( server or thickclientordinaryapplication or externalconnection ) then

function Events () export
	
	p = Reporter.Events ();
	p.OnDetail = true;
	p.OnCompose = true;
	p.AfterOutput = true;
	return p;
	
endfunction 

procedure OnDetail ( Menu, StandardMenu, UseMainAction, Filters ) export
	
	UseMainAction = true;
	filters = GetFromTempStorage ( Filters );
	info = moduleInfo ( filters );
	if ( info <> undefined ) then
		Reporter.DisableMenu ( StandardMenu );
		Reporter.AddCommand ( Menu, Enum.ReportCommandsOpenModule (), info );
	endif;

endprocedure

function moduleInfo ( Filters ) export
	
	line = getValue ( "ModuleLine", Filters );
	if ( line <> undefined ) then
		scenario = getValue ( "ErrorScenario", Filters );
		error = getValue ( "ErrorsRef", Filters );
		return new Structure ( "Scenario, Line, Error", scenario, line, error );
	endif;

endfunction

function getValue ( Name, Filters )
	
	for each item in Filters do
		if ( item.Name = Name ) then
			return item.Item.Value;
		endif;
	enddo;
	
endfunction

#endif
