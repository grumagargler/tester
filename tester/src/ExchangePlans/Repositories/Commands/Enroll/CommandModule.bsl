
&atclient
procedure CommandProcessing ( Node, CommandExecuteParameters )
	
	if ( main ( Node ) ) then
		Output.EnrollmentError ();
	else
		Output.EnrollNode ( ThisObject, Node );
	endif; 
	
endprocedure

&atserver
function main ( val Node )
	
	name = Node.Metadata ().Name;
	return ExchangePlans [ name ].ThisNode () = Node;
	
endfunction 

&atclient
procedure EnrollNode ( Answer, Node ) export
	
	if ( Answer = DialogReturnCode.No ) then
		return;
	endif;
	enroll ( Node );
	Output.EnrollmentCompleted ();

endprocedure 

&atserver
procedure enroll ( val Node )
	
	ExchangePlans.Repositories.Reset ( Node );
	
endprocedure 