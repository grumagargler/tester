
&atclient
procedure CommandProcessing ( Jobs, ExecuteParameters )
	
	openReport ( Jobs, ExecuteParameters );
	
endprocedure

&atclient
procedure openReport ( Jobs, ExecuteParameters )
	
	parameter = Jobs [ 0 ];
	p = ReportsSystem.GetParams ( "Protocol" );
	p.Filters = new Array ();
	filter = DC.CreateFilter ( "Job" );
	if ( Jobs.Count () = 1 ) then
		filter.ComparisonType = DataCompositionComparisonType.Equal;
		filter.RightValue = parameter;
	else
		filter.ComparisonType = DataCompositionComparisonType.InList;
		filter.RightValue = new ValueList ();
		filter.RightValue.LoadValues ( Jobs );
	endif; 
	p.Filters.Add ( filter );
	p.GenerateOnOpen = true;
	ReportsSystem.Open ( p, ExecuteParameters.Source, true, ExecuteParameters.Window );
	
endprocedure 
