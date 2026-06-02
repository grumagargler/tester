
&atclient
procedure CommandProcessing ( References, ExecuteParameters )
	
	openReport ( References, ExecuteParameters );
	
endprocedure

&atclient
procedure openReport ( References, ExecuteParameters )
	
	parameter = References [ 0 ];
	p = ReportsSystem.GetParams ( "JobsSummary" );
	filters = new Array ();
	if ( TypeOf ( parameter ) = Type ( "DocumentRef.Job" ) ) then
		parent = DF.Pick ( parameter, "Job" );
		filters.Add ( DC.CreateFilter ( "Job", ? ( parent.IsEmpty (), References, parent ) ) );
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
