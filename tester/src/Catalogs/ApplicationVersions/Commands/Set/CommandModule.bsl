
&atclient
procedure CommandProcessing ( Version, CommandExecuteParameters )
	
	Output.SetCurrentVersion ( ThisObject, Version, new Structure ( "Version", Version ) );
	
endprocedure

&atclient
procedure SetCurrentVersion ( Answer, Version ) export
	
	if ( Answer = DialogReturnCode.No ) then
		return;
	endif; 
	Environment.ApplyVersion ( Version );
	
endprocedure 
