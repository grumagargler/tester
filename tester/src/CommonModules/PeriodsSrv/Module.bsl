function GetCurrentSessionDate () export
	
	return CurrentSessionDate ();
	
endfunction 

function CurrentUserDate ( val User ) export
	
	return ToLocalTime ( CurrentUniversalDate (), DF.Pick ( User, "TimeZone" ) );
	
endfunction