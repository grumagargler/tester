function MobileClient () export
	
	return isClient ( "MobileClient" );
	
endfunction

function isClient ( Type )
	
	return GetFunctionalOption ( Type, new Structure ( "Session", SessionParameters.Session ) );
	
endfunction

function WebClient () export
	
	return isClient ( "WebClient" );
	
endfunction

function LinuxClient () export
	
	return DF.Pick ( SessionParameters.Session, "Linux" );
	
endfunction
