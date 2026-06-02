
&atclient
procedure CommandProcessing ( CommandParameter, CommandExecuteParameters )
	
	OpenForm ( "Catalog.Applications.ChoiceForm", , , , , , new NotifyDescription ( "ApplicationSelection", ThisObject ) );

endprocedure

&atclient
procedure ApplicationSelection ( Application, Params ) export
	
	if ( Application = undefined ) then
		return;
	endif; 
	Environment.ChangeApplication ( Application );
	
endprocedure 
