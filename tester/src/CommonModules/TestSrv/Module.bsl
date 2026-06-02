function Data ( val Scenario ) export
	
	app = DF.Pick ( Scenario, "Application" );
	if ( app.IsEmpty () ) then
		app = EnvironmentSrv.GetApplication ();
	endif; 
	result = new Structure ( "Scenario, Application, Computer, Port, ClientID, Connected, Version,
	|ConnectedHost, ConnectedPort, SourcesDesigner, SourcesEDT" );
	info = getData ( app );
	FillPropertyValues ( result, info );
	result.Scenario = Scenario;
	result.Application = app;
	result.Connected = false;
	return result;
	
endfunction 

function getData ( App )
	
	s = "
	|select allowed Applications.Computer as Computer, Applications.ClientID as ClientID,
	|	isnull ( Ports.Port, Applications.Port ) as Port,
	|	isnull ( Sources.Designer, """" ) as SourcesDesigner,
	|	isnull ( Sources.EDT, """" ) as SourcesEDT
	|from ";
	if ( App.IsEmpty () ) then
		s = s + "( select value ( Catalog.Applications.EmptyRef ) as Ref, """" as Computer, 0 as Port, """" as ClientID )";
	else
		s = s + "Catalog.Applications";
	endif;
	s = s + " as Applications
	|	//
	|	// Sessions
	|	//
	|	left join Catalog.Sessions as Sessions
	|	on Sessions.Ref = &Session
	|	//
	|	// Ports
	|	//
	|	left join InformationRegister.Ports as Ports
	|	on Ports.Application = Applications.Ref
	|	and Ports.Session = &Session
	|	//
	|	// Sources
	|	//
	|	left join InformationRegister.Sources as Sources
	|	on Sources.Session = &Session
	|	and Sources.Application = &App
	|where Applications.Ref = &App
	|";
	q = new Query ( s );
	q.SetParameter ( "App", App );
	q.SetParameter ( "Session", SessionParameters.Session );
	return q.Execute ().Unload () [ 0 ];
	
endfunction

function SessionDate () export
	
	return CurrentSessionDate ();
	
endfunction 

function Version ( val Expression ) export
	
	operation = decompose ( Expression );
	if ( operation = undefined ) then
		raise Output.ExpressionError ();
	endif; 
	info = versionsData ( operation );
	if ( info.Current = undefined ) then
		raise Output.CurrentVersionUndefined ();
	elsif ( info.Compared = undefined ) then
		raise Output.VersionNotFound ( new Structure ( "Version", operation.Version ) );
	endif; 
	return Eval ( "info.Current " + operation.Operator + " info.Compared" );

endfunction 

function decompose ( Expression )
	
	pattern = "([^<>=]+)(>|<|=|<>|>=|<=)([^<>=]+)"; // "Application = 1.2.3.4"
	matches = Regexp.Select ( Expression, pattern );
	if ( matches.Count () = 0 ) then
		return undefined;
	endif; 
	result = new Structure ();
	match = matches [ 0 ].Groups;
	result.Insert ( "Application", TrimAll ( match [ 0 ] ) );
	result.Insert ( "Operator", TrimAll ( match [ 1 ] ) );
	result.Insert ( "Version", TrimAll ( match [ 2 ] ) );
	return result;
	
endfunction 

function versionsData ( Operation )
	
	q = new Query ();
	filter = filterByVersion ( q, Operation );
	q.Text = "
	|// Current Version
	|select allowed 0 as Priority, Versions.Version.Date as Date
	|from InformationRegister.ApplicationVersions.SliceLast ( , User = &User
	|	and Application in ( select top 1 Ref from Catalog.Applications where Description = &Application ) ) Versions
	|union all
	|select 1, Versions.Date
	|from (
	|	select top 1 1, Versions.Date
	|	from Catalog.ApplicationVersions as Versions
	|	where Versions.Owner.Description = &Application
	|	order by Versions.Date desc
	|	) as Versions
	|order by Priority
	|;
	|// Comparison
	|select allowed top 1 Versions.Date as Date
	|from Catalog.ApplicationVersions as Versions
	|where Versions.Owner.Description = &Application
	|" + ? ( Operation.Operator = "=", " and Versions.Description = &Version", "" ) + "
	|" + filter + "
	|order by Date desc
	|";
	q.SetParameter ( "User", SessionParameters.User );
	q.SetParameter ( "Application", Operation.Application );
	q.SetParameter ( "Version", Operation.Version );
	data = q.ExecuteBatch ();
	current = data [ 0 ].Unload ();
	compared = data [ 1 ].Unload ();
	result = new Structure ();
	result.Insert ( "Current", ? ( current.Count () = 0, undefined, current [ 0 ].Date ) );
	result.Insert ( "Compared", ? ( compared.Count () = 0, undefined, compared [ 0 ].Date ) );
	return result;
	
endfunction 

function filterByVersion ( Q, Operation )
	
	pattern = "\d+";
	parts = StrSplit ( Operation.Version, "." );
	i = 0;
	filter = new Array ();
	for i = 1 to parts.Count () do
		part = parts [ i - 1 ];
		matches = Regexp.Select ( part, pattern );
		if ( matches.Count () = 0 ) then
			break;
		endif; 
		try
			x = Number ( matches [ 0 ].Value );
		except
			break;
		endtry;
		if ( i = 1 ) then
			filter.Add ( "Versions.Major = &P1" );
		elsif ( i = 2 ) then
			filter.Add ( "Versions.Minor = &P2" );
		elsif ( i = 3 ) then
			filter.Add ( "Versions.Version = &P3" );
		elsif ( i = 4 ) then
			filter.Add ( "Versions.Build = &P4" );
		endif; 
		q.SetParameter ( "P" + i, x );
	enddo; 
	return ? ( filter.Count () = 0, "", " and " + StrConcat ( filter, " and " ) );
	
endfunction 

function GetVersion ( val Version, val Application ) export
	
	ref = findVersion ( Version, Application );
	if ( ref = undefined ) then
		raise Output.VersionNotFound ( new Structure ( "Version", Version ) );
	endif;
	return ref;
	
endfunction

function findVersion ( Version, Application )
	
	s = "
	|select top 1 allowed Versions.Ref as Ref
	|from Catalog.ApplicationVersions as Versions
	|where Versions.Owner.Description = &Application
	|and Versions.Description like &Version
	|and not Versions.Ref.DeletionMark
	|order by Versions.Major desc, Versions.Minor desc, Versions.Version desc, Versions.Build desc
	|";
	q = new Query ( s );
	q.SetParameter ( "Application", Application );
	q.SetParameter ( "Version", Version );
	table = q.Execute ().Unload ();
	return ? ( table.Count () = 0, undefined, table [ 0 ].Ref );
	
endfunction
