function JobRecord () export
	
	p = new Structure ();
	p.Insert ( "Scenario" );
	p.Insert ( "PinApplication" );
	p.Insert ( "PinVersion" );
	p.Insert ( "CloseAllAfter", true );
	p.Insert ( "Disconnect", true );
	return p;
	
endfunction
