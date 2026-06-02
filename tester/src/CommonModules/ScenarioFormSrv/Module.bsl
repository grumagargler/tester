function HierarchyList ( val Scenarios ) export
	
	s = "
	|select distinct allowed Scenarios.Ref as Ref
	|from Catalog.Scenarios as Scenarios
	|where Scenarios.Ref in hierarchy ( &Scenarios )
	|";
	q = new Query ( s );
	q.SetParameter ( "Scenarios", Scenarios );
	return q.Execute ().Unload ().UnloadColumn ( "Ref" );
	
endfunction

procedure CopyMove ( val Scenarios, val Folder, val Copying ) export
	
	if ( recursion ( Scenarios, Folder ) ) then
		raise Output.CopyingError ();
	endif;
	BeginTransaction ();
	for each scenario in Scenarios do
		if ( Copying ) then
			copyScenario ( scenario, Folder );
		else
			moveScenario ( scenario, Folder );
		endif;
	enddo;
	CommitTransaction ();
	
endprocedure

function recursion ( Scenarios, Folder )
	
	s = "
	|select top 1 1
	|from Catalog.Scenarios as Scenarios
	|where Scenarios.Ref in hierarchy ( &Scenarios )
	|and Scenarios.Ref = &Folder
	|union
	|select top 1 1
	|from Catalog.Scenarios as Scenarios
	|where Scenarios.Ref in ( &Scenarios )
	|and Scenarios.Parent = &Folder
	|";
	q = new Query ( s );
	q.SetParameter ( "Folder", ? ( Folder = undefined, Catalogs.Scenarios.EmptyRef (), Folder ) );
	q.SetParameter ( "Scenarios", Scenarios );
	SetPrivilegedMode ( true );
	return not q.Execute ().IsEmpty ();
	
endfunction

procedure copyScenario ( Scenario, Folder )
	
	obj = Scenario.GetObject ().Copy ();
	obj.Parent = Folder;
	obj.Creator = SessionParameters.User;
	obj.Write ();
	parent = obj.Ref;
	for each baby in children ( Scenario ) do
		copyScenario ( baby, parent );
	enddo;
	
endprocedure

function children ( Scenario )
	
	s = "
	|select allowed Scenarios.Ref as Ref
	|from Catalog.Scenarios as Scenarios
	|where Scenarios.Parent = &Scenario
	|";
	q = new Query ( s );
	q.SetParameter ( "Scenario", Scenario );
	return q.Execute ().Unload ().UnloadColumn ( "Ref" );
	
endfunction

procedure moveScenario ( Scenario, Folder )
	
	obj = Scenario.GetObject ();
	obj.Parent = Folder;
	obj.Write ();
	
endprocedure

function InheritApplication ( val Scenarios, val Target ) export
	
	application = DF.Pick ( Target, "Application" );
	if ( application.IsEmpty () ) then
		return undefined;
	endif;
	s = "
	|select top 1 1
	|from Catalog.Scenarios as Scenarios
	|where Scenarios.Ref in ( &Scenarios )
	|and Scenarios.Application <> &Application
	|";
	q = new Query ( s );
	q.SetParameter ( "Application", application );
	q.SetParameter ( "Scenarios", Scenarios );
	return ? ( q.Execute ().IsEmpty (), undefined, application );
	
endfunction
