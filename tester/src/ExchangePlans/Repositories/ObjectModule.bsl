procedure FillCheckProcessing ( Cancel, CheckedAttributes )
	
	checkFolder ( CheckedAttributes );
	
endprocedure

procedure checkFolder ( CheckedAttributes )
	
	if ( Mapping ) then
		CheckedAttributes.Add ( "Folder" );
	endif;
	
endprocedure