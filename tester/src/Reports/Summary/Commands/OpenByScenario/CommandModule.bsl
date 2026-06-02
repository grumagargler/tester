
&atclient
procedure CommandProcessing ( References, ExecuteParameters )
	
	openReport ( References, ExecuteParameters );
	
endprocedure

&atclient
procedure openReport ( References, ExecuteParameters )
	
	parameter = References [ 0 ];
	p = ReportsSystem.GetParams ( "Summary" );
	filters = new Array ();
	if ( TypeOf ( parameter ) = Type ( "DocumentRef.Job" ) ) then
		filters.Add ( DC.CreateFilter ( "Job", References ) );
		data = jobsData ( References );
		filters.Add ( DC.CreateFilter ( "Application", data.Applications ) );
		filters.Add ( DC.CreateFilter ( "Session", data.Sessions ) );
		filters.Add ( DC.CreateFilter ( "User", data.Users ) );
	else
		filter = DC.CreateFilter ( "Scenario" );
		if ( References.Count () = 1 ) then
			filter.ComparisonType = ? ( DF.Pick ( parameter, "Tree" ), DataCompositionComparisonType.InHierarchy, DataCompositionComparisonType.Equal );
			filter.RightValue = parameter;
		else
			filter.ComparisonType = DataCompositionComparisonType.InListByHierarchy;
			filter.RightValue = new ValueList ();
			filter.RightValue.LoadValues ( References );
		endif; 
		filters.Add ( filter );
	endif;
	p.Filters = filters;
	p.GenerateOnOpen = true;
	ReportsSystem.Open ( p, ExecuteParameters.Source, true, ExecuteParameters.Window );
	
endprocedure 

&atserver
function jobsData ( val References )
	
	s = "
	|// Sessions
	|select distinct Jobs.Session as Session
	|from InformationRegister.AgentJobs as Jobs
	|where Jobs.Job in ( &Jobs )
	|;
	|// Applications
	|select distinct Scenarios.Application as Application
	|from Document.Job.Scenarios as Scenarios
	|where Scenarios.Ref in ( &Jobs )
	|;
	|// Users
	|select distinct Jobs.Agent as Agent
	|from Document.Job as Jobs
	|where Jobs.Ref in ( &Jobs )
	|";
	q = new Query ( s );
	q.SetParameter ( "Jobs", References );
	data = q.ExecuteBatch ();
	result = new Structure ( "Sessions, Applications, Users" );
	result.Sessions = data [ 0 ].Unload ().UnloadColumn ( "Session" );;
	result.Applications = data [ 1 ].Unload ().UnloadColumn ( "Application" );
	result.Users = data [ 2 ].Unload ().UnloadColumn ( "Agent" );
	return result;
	
endfunction