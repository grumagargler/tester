
&atclient
procedure CommandProcessing ( Job, CommandExecuteParameters )
	
	p = new Structure ( "Job", Job );
	OpenForm ( "Catalog.ErrorLog.ListForm", p, CommandExecuteParameters.Source, true, CommandExecuteParameters.Window, CommandExecuteParameters.URL );
	
endprocedure
