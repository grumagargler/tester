
procedure OnWrite ( Cancel )
	
	if ( DataExchange.Load ) then
		return;
	endif;
	if ( not Local ) then
		Exchange.RecordChanges ( Ref );	
	endif; 
	
endprocedure