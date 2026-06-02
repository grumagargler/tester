&atserver
procedure LoadScenarios ( Form ) export
	
	list = Form.List;
	for each scenario in getScenarios ( Form ) do
		row = list.Add ();
		FillPropertyValues ( row, scenario );
		row.Use = true;
	enddo; 
	
endprocedure 

&atserver
function getScenarios ( Form )
	
	s = "
	|select Scenarios.Ref as Ref, Scenarios.Path as Path,
	|	case when Scenarios.Spreadsheet then 4 else 0 end
	|	+
	|	case when Scenarios.Type = value ( Enum.Scenarios.Library ) then 0
	|		when Scenarios.Type = value ( Enum.Scenarios.Folder ) then 1
	|		when Scenarios.Type = value ( Enum.Scenarios.Method ) then 2
	|		else 3
	|	end as Picture
	|from Catalog.Scenarios as Scenarios
	|where Scenarios.Ref in ( &List )
	|order by Scenarios.Path
	|";
	q = new Query ( s );
	if ( Form.FormName = "Catalog.Scenarios.Form.Store"
		and Form.Parameters.Silent ) then
		q.SetParameter ( "List", lockedScenarios () );
	else
		q.SetParameter ( "List", Form.Parameters.Scenarios );
	endif;
	return q.Execute ().Unload ();
	
endfunction

&atserver
function lockedScenarios ()
	
	s = "
	|select Editing.Scenario as Scenario
	|from InformationRegister.Editing as Editing
	|where Editing.User = &Me";
	q = new Query ( s );
	q.SetParameter ( "Me", SessionParameters.User );
	return q.Execute ().Unload ().UnloadColumn ( "Scenario" );
	
endfunction

&atserver
function FetchScenarios ( Form ) export
	
	applicationChanging = ( Form.FormName = "Catalog.Scenarios.Form.ChangeApplication" );
	s = "
	|select allowed Scenarios.Ref as Ref
	|from Catalog.Scenarios as Scenarios
	|where Scenarios.Ref in " + ? ( Form.Deep, "hierarchy", "" ) + " ( &List )
	|";
	if ( applicationChanging ) then
		s = s + ";
		|select allowed Scenarios.Ref as Ref
		|from Catalog.Scenarios as Scenarios
		|where Scenarios.Ref in hierarchy ( &List )
		|";
	endif; 
	q = new Query ( s );
	scenarios = Form.List.Unload ( new Structure ( "Use", true ), "Ref" ).UnloadColumn ( "Ref" );
	q.SetParameter ( "List", scenarios );
	if ( applicationChanging ) then
		return q.ExecuteBatch ();
	else
		return q.Execute ().Unload ();
	endif; 
	
endfunction

&atserver
procedure Lock ( Scenarios, Locked, Errors ) export
	
	BeginTransaction ();
	LockingForm.LockEditing ( Scenarios );
	lockScenarios ( Scenarios, Locked, Errors );
	CommitTransaction ();
	
endprocedure 

&atserver
procedure LockEditing ( DataSource ) export
	
	lock = new DataLock ();
	item = lock.Add ( "InformationRegister.Editing" );
	item.Mode = DataLockMode.Exclusive;
	item.DataSource = DataSource;
	item.UseFromDataSource ( "Scenario", "Ref" );
	lock.Lock ();
	
endprocedure 

&atserver
procedure lockScenarios ( Scenarios, Locked, Errors )
	
	errorsList = new Array ();
	Locked = new Array ();
	me = SessionParameters.User;
	for each row in Scenarios do
		scenario = row.Ref;
		r = InformationRegisters.Editing.CreateRecordManager ();
		r.Scenario = scenario;
		r.Read ();
		if ( r.Selected () ) then
			user = r.User;
			if ( user = me ) then
				continue;
			else
				errorsList.Add ( new Structure ( "User, Scenario", user, scenario ) );
				continue;
			endif; 
		endif; 
		InformationRegisters.Editing.Lock ( me, scenario );
		Locked.Add ( scenario );
	enddo; 
	Errors = ? ( errorsList.Count () = 0, undefined, errorsList );

endprocedure
