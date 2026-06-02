function StatusPresentation ( Status, Encountered ) export
	
	if ( Encountered > 1 ) then
		return String ( Status ) + " (" + Encountered + ")";
	else
		return String ( Status );
	endif; 
	
endfunction 