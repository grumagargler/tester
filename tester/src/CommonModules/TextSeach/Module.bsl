procedure Update () export
	
	if ( FullTextSearch.GetFullTextSearchMode () = FullTextMode.Disable
		or FullTextSearch.IndexTrue () ) then
		return;
	endif;
	FullTextSearch.UpdateIndex ( false, true );
	
endprocedure 

procedure Merge () export
	
	if ( FullTextSearch.GetFullTextSearchMode () = FullTextMode.Disable ) then
		return;
	endif; 
	FullTextSearch.UpdateIndex ( true );
	
endprocedure
