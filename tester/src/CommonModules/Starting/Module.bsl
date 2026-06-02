function Allowed () export
	
	if ( Logins.AccessDenies () ) then
		Output.AccessDenied ( ThisObject, , , "Quit" );
		return false;
	endif; 
	return true;
	
endfunction

procedure Quit ( Params ) export
	
	Terminate ();
	
endprocedure 
