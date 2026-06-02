
&atclient
procedure CommandProcessing ( Scenarios, ExecuteParameters )
	
	saveAll ();
	p = new Structure ( "Scenarios", Scenarios );
	OpenForm ( "Document.Job.ObjectForm", p, ExecuteParameters.Source, ExecuteParameters.Uniqueness, ExecuteParameters.Window, ExecuteParameters.URL );
	
endprocedure

&atclient
procedure saveAll ()
	
	Notify ( Enum.MessageSaveAll () );
	
endprocedure 
