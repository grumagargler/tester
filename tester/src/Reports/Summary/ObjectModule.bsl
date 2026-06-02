var Params export;

procedure OnCompose () export
	
	adjustFilter ();
	
endprocedure

procedure adjustFilter ()
	
	settings = Params.Settings;
	job = DC.FindFilter ( settings, "Job" );
	if ( job = undefined
		or not job.Use ) then
		return;
	endif;
	user = DC.FindFilter ( settings, "User" );
	if ( user.Use ) then
		user.Use = false;
		DC.FindFilter ( Params.Composer, "User" ).Use = false;
	endif;
	filter = DC.FindParameter ( settings, "Period" );
	if ( filter.Use ) then
		filter.Use = false;
		DC.FindParameter ( Params.Composer, "Period" ).Use = false;
	endif;
	
endprocedure
