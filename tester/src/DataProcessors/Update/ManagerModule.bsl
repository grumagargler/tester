
#if ( server or thickclientordinaryapplication or externalconnection ) then

procedure Run ( ID ) export
	
	DataProcessors.Update.Create ().Update ( ID );
	
endprocedure 

#endif
