procedure Reset ( Node ) export
	
	SetPrivilegedMode ( true );
	set = Metadata.FindByType ( TypeOf ( Node ) ).Content;
	for each item in set do
		ExchangePlans.RecordChanges ( Node, item.Metadata );
	enddo;
	SetPrivilegedMode ( false );
	
endprocedure 

procedure Sync ( Scenario, Application, SavedLocally ) export

	SetPrivilegedMode ( true );
	nodes = getNodes ( Application, SavedLocally );
	ExchangePlans.RecordChanges ( nodes, Scenario );
	SetPrivilegedMode ( false );

endprocedure 

function getNodes ( Application, ExceptMe )
	
	s = "
	|select Repositories.Ref as Ref
	|from ExchangePlan.Repositories as Repositories
	|where not Repositories.DeletionMark
	|and Repositories.Application = &Application
	|and not Repositories.ThisNode
	|";
	if ( ExceptMe ) then
		s = s + "
		|and Repositories.Session <> &Session
		|";
	endif; 
	q = new Query ( s );
	q.SetParameter ( "Application", Application );
	q.SetParameter ( "Session", SessionParameters.Session );
	return q.Execute ().Unload ().UnloadColumn ( "Ref" );
	
endfunction

procedure MarkDeletion ( User ) export
	
	SetPrivilegedMode ( true );
	for each node in userNodes ( User ) do
		node.GetObject ().SetDeletionMark ( true );
	enddo; 
	SetPrivilegedMode ( false );
	
endprocedure 

function userNodes ( User )
	
	s = "
	|select Nodes.Ref as Ref
	|from ExchangePlan.Repositories as Nodes
	|where not Nodes.DeletionMark
	|and Nodes.Session.User = &User
	|";
	q = new Query ( s );
	q.SetParameter ( "User", User );
	return q.Execute ().Unload ().UnloadColumn ( "Ref" );
	
endfunction 
