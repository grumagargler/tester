
procedure SessionParametersSetting ( Params )
	
	if ( Params = undefined ) then
		return;
	endif; 
	for each parameter in Params do
		if ( parameter = "User" ) then
			setUser ();
		elsif ( parameter = "Session" ) then
			setSession ();
		elsif ( parameter = "Connection" ) then
			setConnection ();
		elsif ( parameter = "ApplicationsAccess" ) then
			setApplicationsAccess ();
		elsif ( parameter = "ApplicationsList" ) then
			setApplicationsList ();
		endif;
	enddo; 
	
endprocedure

procedure setUser ()
	
	currentUser = Catalogs.Users.FindByDescription ( UserName (), true );
	SessionParameters.User = currentUser;
	
endprocedure 

procedure setSession ()
	
	EnvironmentSrv.SetSession ( ComputerName () );
	
endprocedure 

procedure setConnection ()
	
	EnvironmentSrv.SetConnection ( false, false, false, false );
	
endprocedure 

procedure setApplicationsAccess ()
	
	SessionParameters.ApplicationsAccess = DF.Pick ( SessionParameters.User, "ApplicationsAccess" );
	
endprocedure 

procedure setApplicationsList ()
	
	s = "
	|select distinct Access.Application as Application
	|from Catalog.Users.Applications as Access
	|where Access.Ref = &User
	|";
	q = new Query ( s );
	q.SetParameter ( "User", SessionParameters.User );
	SessionParameters.ApplicationsList = new FixedArray ( q.Execute ().Unload ().UnloadColumn ( "Application" ) );
	
endprocedure 

function module ()
	
	return CoreExtension;
	
endfunction