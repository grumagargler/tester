
&atclient
procedure CommandProcessing ( Scenario, ExecuteParameters )

	p = New Structure ( "Scenario", Scenario );
	OpenForm ( "Document.Job.ListForm", p, ExecuteParameters.Source, ExecuteParameters.Uniqueness, ExecuteParameters.Window, ExecuteParameters.URL );
	
endprocedure
