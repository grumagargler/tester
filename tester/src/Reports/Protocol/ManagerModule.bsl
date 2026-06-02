
function Events () export
	
	params = Reporter.Events ();
	params.OnDetail = true;
	params.OnCompose = true;
	return params;
	
endfunction 

procedure OnDetail ( Menu, StandardMenu, UseMainAction, Filters ) export
	
	UseMainAction = true;

endprocedure