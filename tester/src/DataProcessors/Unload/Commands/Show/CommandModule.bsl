
&atclient
procedure CommandProcessing ( CommandParameter, CommandExecuteParameters )
	
	Notify ( Enum.MessageSaveAll () );
	OpenForm ( "DataProcessor.Unload.Form", , CommandExecuteParameters.Source, CommandExecuteParameters.Uniqueness, CommandExecuteParameters.Window, CommandExecuteParameters.URL );
	
endprocedure
