procedure FormGetProcessing ( FormType, Parameters, SelectedForm, AdditionalInformation, StandardProcessing )
	
	if ( newScenario ( FormType, Parameters ) ) then
		SelectedForm = "New";
		StandardProcessing = false;
	endif;
	
endprocedure

function newScenario ( Type, Parameters )
	
	return Type = "ObjectForm"
	and not Parameters.Property ( "Key" )
	and not Parameters.Property ( "CopyingValue" );
	
endfunction

procedure PresentationFieldsGetProcessing ( Fields, StandardProcessing )
	
	Fields.Add ( "Path" );
	StandardProcessing = false;
	
endprocedure

procedure PresentationGetProcessing ( Data, Presentation, StandardProcessing )
	
	StandardProcessing = false;
	Presentation = Data.Path;
	
endprocedure

procedure Rollback ( Scenario, Version ) export
	
	obj = Scenario.GetObject ();
	source = Version.GetObject ();
	FillPropertyValues ( obj, source, , "Owner, Parent, Code" );
	obj.Areas.Load ( source.Areas.Unload () );
	obj.Template = new ValueStorage ( source.Template.Get () );
	obj.Parent = FindByCode ( source.Folder );
	obj.AdditionalProperties.Insert ( "Restored", true );
	obj.Write ();
	
endprocedure 

procedure RemoveAsMain ( Scenario ) export
	
	SetPrivilegedMode ( true );
	for each user in getScenarioUsers ( Scenario ) do
		r = InformationRegisters.Scenarios.CreateRecordManager ();
		r.User = user;
		r.Delete ();
	enddo; 
	SetPrivilegedMode ( false );
	
endprocedure

function Locked ( Scenario ) export
	
	user = InformationRegisters.Editing.Get ( new Structure ( "Scenario", Scenario ) ).User;
	if ( user = SessionParameters.User ) then
		return false;
	elsif ( user.IsEmpty () ) then
		Output.ScenarioNotLocked ( new Structure ( "Scenario", Scenario ), , Scenario );
	else
		Output.LockError ( new Structure ( "Scenario, User", Scenario, user ), , Scenario );
	endif; 
	return true;
	
endfunction

function getScenarioUsers ( Scenario )
	
	s = "
	|select Scenarios.User as User
	|from InformationRegister.Scenarios as Scenarios
	|where Scenarios.Scenario = &Scenario
	|";
	q = new Query ( s );
	q.SetParameter ( "Scenario", Scenario );
	return q.Execute ().Unload ().UnloadColumn ( "User" );
	
endfunction 

function ChangeChildren ( Parent, OldPath, NewPath, OldApp, NewApp, SavedLocally ) export
	
	changePath = ( OldPath <> NewPath )
	and not pathAlreadyChanged ( Parent, NewPath );
	changeApp = ( OldApp <> NewApp and not NewApp.IsEmpty () )
	and not appAlreadyChanged ( Parent, NewApp );
	if ( not ( changePath or changeApp ) ) then
		return true;
	endif;
	replacer = 1 + StrLen ( OldPath );
	for each child in getChildren ( Parent ) do
		baby = child.Ref;
		happenedLocally = SavedLocally and ( child.Application = OldApp );
		if ( not happenedLocally and Locked ( baby ) ) then
			return false;
		endif;
		obj = baby.GetObject ();
		obj.DataExchange.Load = true;
		if ( changePath ) then
			obj.Path = NewPath + Mid ( child.Path, replacer );
		endif;
		if ( changeApp ) then
			obj.Application = NewApp;
		endif;
		obj.Write ();		
		ExchangePlans.Repositories.Sync ( baby, obj.Application, happenedLocally );
		obj.FullExchange ();
	enddo;
	return true;
		
endfunction

function pathAlreadyChanged ( Parent, ParentPath )
	
	s = "
	|select top 1 1
	|from Catalog.Scenarios as Scenarios
	|where Scenarios.Parent = &Parent
	|and Scenarios.Path like &Path
	|";
	q = new Query ( s );
	q.SetParameter ( "Parent", Parent );
	q.SetParameter ( "Path", ParentPath + ".%" );
	return not q.Execute ().IsEmpty ();

endfunction

function appAlreadyChanged ( Parent, Application )
	
	s = "
	|select top 1 1
	|from Catalog.Scenarios as Scenarios
	|where Scenarios.Ref in hierarchy ( &Parent )
	|and Scenarios.Ref <> &Parent
	|and Scenarios.Application <> &Application
	|";
	q = new Query ( s );
	q.SetParameter ( "Parent", Parent );
	q.SetParameter ( "Application", Application );
	return q.Execute ().IsEmpty ();

endfunction

function getChildren ( Scenario )
	
	s = "
	|select Scenarios.Ref as Ref, Scenarios.Path as Path, Scenarios.Application as Application
	|from Catalog.Scenarios as Scenarios
	|where Scenarios.Ref in hierarchy ( &Parent )
	|and Scenarios.Ref <> &Parent
	|";
	q = new Query ( s );
	q.SetParameter ( "Parent", Scenario.Ref );
	return q.Execute ().Unload ();
	
endfunction

procedure SetPath ( Object ) export
	
	ancestor = Object.Parent;
	if ( ancestor.IsEmpty () ) then
		Object.Path = Object.Description;
	else
		Object.Path = DF.Pick ( ancestor, "Path" ) + "." + Object.Description;
	endif; 
	
endprocedure 

procedure RemoveFile ( Scenario, Application, Path, Tree, AlreadyRemoved ) export
	
	SetPrivilegedMode ( true );
	uid = Scenario.UUID ();
	for each repo in getRepos ( Application, AlreadyRemoved ) do
		r = InformationRegisters.Removing.CreateRecordManager ();
		r.Repository = repo;
		r.ID = uid;
		r.Path = Path;
		r.Tree = Tree;
		r.Write ();
	enddo; 
	SetPrivilegedMode ( false );
	
endprocedure 

function getRepos ( Application, ExceptMe )
	
	s = "
	|select Repositories.Ref as Ref
	|from ExchangePlan.Repositories as Repositories
	|where not Repositories.DeletionMark
	|and not Repositories.ThisNode
	|and Repositories.Application = &Application";
	if ( ExceptMe ) then
		s = s + "
		|and Repositories.Session <> &Session
		|";
	endif;
	q = new Query ( s );
	q.SetParameter ( "Session", SessionParameters.Session );
	q.SetParameter ( "Application", Application );
	return q.Execute ().Unload ().UnloadColumn ( "Ref" );
	
endfunction

function ApplicationsInside ( CommonFolder, ExceptApplication ) export
	
	s = "
	|select distinct Scenarios.Application as Ref
	|from Catalog.Scenarios as Scenarios
	|where not Scenarios.DeletionMark
	|and Scenarios.Ref in hierarchy ( &Folder )
	|and Scenarios.Application <> &Except
	|";
	q = new Query ( s );
	q.SetParameter ( "Folder", CommonFolder );
	q.SetParameter ( "Except", ExceptApplication );
	return q.Execute ().Unload ().UnloadColumn ( "Ref" );
	
endfunction

function DeleteChildren ( Parent, RepoApplication ) export
	
	for each child in getVictims ( Parent, RepoApplication ) do
		baby = child.Ref;
		happenedLocally = child.Application = RepoApplication;
		if ( not happenedLocally and Locked ( baby ) ) then
			return false;
		endif;
		obj = baby.GetObject ();
		obj.DataExchange.Load = true;
		obj.DeletionMark = true;
		obj.Write ();		
		ExchangePlans.Repositories.Sync ( baby, obj.Application, happenedLocally );
		obj.FullExchange ();
	enddo;
	return true;
		
endfunction

function getVictims ( Scenario, Application )
	
	s = "
	|select Scenarios.Ref as Ref, Scenarios.Application as Application
	|from Catalog.Scenarios as Scenarios
	|where not Scenarios.DeletionMark
	|and Scenarios.Ref in hierarchy ( &Parent )
	|and Scenarios.Ref <> &Parent
	|";
	if ( ValueIsFilled ( Application ) ) then
		s = s + "and Scenarios.Application = &Application";
	endif;
	q = new Query ( s );
	q.SetParameter ( "Parent", Scenario.Ref );
	q.SetParameter ( "Application", Application );
	return q.Execute ().Unload ();
	
endfunction

procedure SetSorting ( Object ) export
	
	objectType = Object.Type;
	if ( objectType = Enums.Scenarios.Library ) then
		Object.Sorting = 0;
	elsif ( objectType = Enums.Scenarios.Folder ) then
		Object.Sorting = 1;
	elsif ( objectType = Enums.Scenarios.Scenario ) then
		Object.Sorting = 2;
	elsif ( objectType = Enums.Scenarios.Method ) then
		Object.Sorting = 3;
	endif;
	
endprocedure 

function CheckDoubles ( Object ) export
	
	if ( doubleExists ( Object ) ) then
		Output.ScenarioAlreadyExists ( new Structure ( "Name", Object.Path ), "Description", Object.Ref );
		return false;
	else
		return true;
	endif; 
	
endfunction 

function doubleExists ( Object )
	
	s = "
	|select top 1 1
	|from Catalog.Scenarios as Scenarios
	|where Scenarios.Ref <> &Ref
	|and Scenarios.Application in ( &Application, value ( Catalog.Applications.EmptyRef ) )
	|and Scenarios.Path = &Path
	|";
	q = new Query ( s );
	q.SetParameter ( "Ref", Object.Ref );
	q.SetParameter ( "Application", Object.Application );
	q.SetParameter ( "Path", Object.Path );
	return not q.Execute ().IsEmpty ();
	
endfunction 

procedure UpdateFiles ( Object ) export
	
	path = RepositoryFiles.ScenarioFile ( Object );
	if ( path = undefined ) then
		return;
	endif;
	r = InformationRegisters.Files.CreateRecordManager ();
	session = SessionParameters.Session;
	r.Session = session;
	application = Object.Application;
	r.Application = application;
	file = path + RepositoryFiles.BSLFile ();
	r.ID = CoreLibrary.GetStringHash ( file, false );
	r.Content = CoreLibrary.GetStringHash ( TrimAll ( Object.Script ), false );
	r.File = file;
	r.Write ();
	r = InformationRegisters.Files.CreateRecordManager ();
	r.Session = SessionParameters.Session;
	r.Application = Object.Application;
	file = path + RepositoryFiles.JSONFile ();
	r.ID = CoreLibrary.GetStringHash ( file, false );
	r.Content = CoreLibrary.GetStringHash ( TrimAll ( GetProperties ( Object ) ), false );
	r.File = file;
	r.Write ();

endprocedure

function GetProperties ( Scenario ) export

	properties = new Structure ( "Version, Type, Tree, Severity, Creator, LastCreator, Memo, Tags" );
	properties.Version = Enum.ConstantsFormatVersion ();
	properties.Tree = Scenario.Tree;
	properties.Type = Conversion.EnumToName (  Scenario.Type );
	properties.Severity = Scenario.Severity;
	properties.Creator = Scenario.Creator;
	properties.LastCreator = Scenario.LastCreator;
	properties.Memo = Scenario.Memo;
	properties.Tags = getTags ( Scenario );
	return Conversion.ToJSON ( properties );
	
endfunction

function getTags ( Scenario )

	s = "select Tags.Tag.Description as Tag
	|from Catalog.TagKeys.Tags as Tags
	|where Tags.Ref = &Key";
	q = new Query ( s );
	q.SetParameter ( "Key", Scenario.Tag );
	return q.Execute ().Unload ().UnloadColumn ( "Tag" );
	
endfunction


