
procedure Init ( Object ) export
	
	setCreator ( Object );
	
endprocedure 

procedure setCreator ( Object )
	
	Object.Creator = SessionParameters.User;
	
endprocedure 
