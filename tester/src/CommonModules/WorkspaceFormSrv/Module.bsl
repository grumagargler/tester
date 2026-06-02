function GetFolders ( val Workspace ) export

	s = "select Workspaces.Workspace as Workspace
	|from Catalog.Workspaces as Workspaces
	|where Workspaces.Ref = &Workspace
	|;
	|select Repositories.Folder as Folder,
	|	case Repositories.Application when value ( Catalog.Applications.EmptyRef ) then &Common
	|		else Repositories.Application.Code
	|	end as Name
	|from ExchangePlan.Repositories as Repositories
	|	//
	|	// Filter by workspace
	|	//
	|	join Catalog.Workspaces.Applications as Applications
	|	on Applications.Ref = &Workspace
	|	and Applications.Ref.Computer = Repositories.Session.Computer
	|	and Applications.Ref.Owner = Repositories.Session.User
	|	and Applications.Application = Repositories.Application
	|where not Repositories.DeletionMark
	|order by Applications.LineNumber";
	q = new Query ( s );
	q.SetParameter ( "Workspace", Workspace );
	q.SetParameter ( "Common", Output.CommonApplicationCode () );
	data = q.ExecuteBatch ();
	result = new Structure ( "Path, Folders" );
	result.Path = data [ 0 ].Unload () [ 0 ].Workspace;
	result.Folders = Collections.Serialize ( data [ 1 ].Unload () );
	return result;

endfunction

function ScenarioContext ( val Scenario ) export
	
	application = DF.Pick ( Scenario, "Application" );
	return workspaceData ( application );
	
endfunction

function workspaceData ( Application )
	
	s = "// VSCode
	|select Sessions.Computer.VSCode as VSCode
	|from Catalog.Sessions as Sessions
	|where Sessions.Ref = &Session
	|;
	|// Workspaces
	|select Applications.Ref.Workspace as Workspace
	|from Catalog.Workspaces.Applications as Applications
	|where not Applications.Ref.DeletionMark
	|and Applications.Ref.Computer = &Computer
	|and Applications.Ref.Owner = &User
	|and Applications.Application = &Application
	|order by Applications.Ref.Description";
	q = new Query ( s );
	q.SetParameter ( "User", SessionParameters.User );
	q.SetParameter ( "Computer", SessionData.Computer () );
	q.SetParameter ( "Application", Application );
	q.SetParameter ( "Session", SessionParameters.Session );
	data = q.ExecuteBatch ();
	result = new Structure ( "Application, VSCode, Workspaces" );
	result.Application = Application;
	result.VSCode = data [ 0 ].Unload () [ 0 ].VSCode; 
	result.Workspaces = data [ 1 ].Unload ().UnloadColumn ( "Workspace" );
	return result;
	
endfunction
