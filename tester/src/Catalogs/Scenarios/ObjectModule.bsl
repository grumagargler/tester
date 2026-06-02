var IsNew;
var OldParent;
var OldApplication;
var OldDeletionMark;
var OldTree;
var OldPath;

procedure FillCheckProcessing ( Cancel, CheckedAttributes )
	
	checkAccess ( CheckedAttributes );
	
endprocedure

procedure checkAccess ( CheckedAttributes )
	
	if ( Access ) then
		CheckedAttributes.Add ( "Users" );
	endif; 
	
endprocedure 

procedure BeforeWrite ( Cancel )
	
	if ( DataExchange.Load ) then
		return;
	endif; 
	IsNew = IsNew ();
	if ( not IsNew and Catalogs.Scenarios.Locked ( Ref ) ) then
		Cancel = true;
		return;
	endif;
	Catalogs.Scenarios.SetPath ( ThisObject );
	if ( not option ( "Restored" ) ) then
		stamp ();
		fixApplication ();
	endif;
	if ( not Catalogs.Scenarios.CheckDoubles ( ThisObject ) ) then
		Cancel = true;
		return;
	endif; 
	setTree ();
	fixType ();
	Catalogs.Scenarios.SetSorting ( ThisObject );
	getLastProps ();
	if ( not changeParents () ) then
		Cancel = true;
		return;
	endif;
	if ( IsNew ) then
		return;
	endif;
	if ( Tree ) then
		Catalogs.Scenarios.ChangeChildren ( Ref, OldPath, Path, OldApplication, Application, false );
	endif;
	deleteFile = OldPath <> Path or OldTree <> Tree or OldApplication <> Application; 
	if ( deleteFile ) then
		removeFiles ();
	endif; 
	if ( DeletionMark ) then
		Catalogs.Scenarios.RemoveAsMain ( Ref );
	endif; 
	Catalogs.Scenarios.UpdateFiles ( ThisObject );
	
endprocedure

procedure removeFiles ()
	
	Catalogs.Scenarios.RemoveFile ( Ref, OldApplication, OldPath, OldTree, false );
	renamedCommonFolder = Tree and Application.IsEmpty (); 
	if ( renamedCommonFolder ) then
		for each reference in Catalogs.Scenarios.ApplicationsInside ( Ref, Application ) do
			ExchangePlans.Repositories.Sync ( Ref, reference, false );
			Catalogs.Scenarios.RemoveFile ( Ref, reference, OldPath, true, false );
		enddo;
	endif;
	
endprocedure

function option ( Name )
	
	return AdditionalProperties.Property ( Name )
	and AdditionalProperties [ Name ];
	
endfunction 

procedure stamp ()
	
	Changed = CurrentUniversalDate ();
	LastCreator = SessionParameters.User;
	
endprocedure

procedure fixApplication ()
	
	if ( Parent.IsEmpty () ) then
		return;
	endif;
	parentApp = DF.Pick ( Parent, "Application" );
	if ( parentApp.IsEmpty ()
		or parentApp = Application ) then
		return;
	endif; 
	Application = parentApp;
	
endprocedure 

procedure setTree ()
	
	Tree = ( Type = Enums.Scenarios.Folder ) or ( not IsNew and hasChildren ( Ref ) );
	
endprocedure 

function hasChildren ( Scenario )
	
	s = "
	|select top 1 1
	|from Catalog.Scenarios as Scenarios
	|where Scenarios.Parent = &Parent
	|and Scenarios.Ref <> &Ref
	|and not Scenarios.DeletionMark
	|";
	q = new Query ( s );
	q.SetParameter ( "Parent", Scenario );
	q.SetParameter ( "Ref", Ref );
	SetPrivilegedMode ( true );
	return not q.Execute ().IsEmpty ();
	
endfunction 

procedure fixType ()
	
	if ( Tree
		and Type = Enums.Scenarios.Scenario ) then
		Type = Enums.Scenarios.Folder;
	endif; 
	
endprocedure 

procedure getLastProps ()
	
	OldParent = Ref.Parent;
	OldApplication = Ref.Application;
	OldDeletionMark = Ref.DeletionMark;
	OldTree = Ref.Tree;
	OldPath = Ref.Path;
	
endprocedure

function changeParents ()
	
	if ( Parent = OldParent ) then
		return true;
	endif;
	stillParent = OldParent.IsEmpty () or isFolder ( OldParent ) or hasChildren ( OldParent );
	if ( not stillParent ) then
		if ( not makeScenario ( OldParent, false ) ) then
			return false;
		endif;
	endif;
	isParent = Parent.IsEmpty () or DF.Pick ( Parent, "Tree" );
	if ( not isParent ) then
		if ( not makeScenario ( Parent, true ) ) then
			return false;
		endif;
	endif; 
	return true;
	
endfunction 

function isFolder ( Scenario )
	
	scenarioType = DF.Pick ( Scenario, "Type" );
	return scenarioType = Enums.Scenarios.Folder
	or scenarioType = Enums.Scenarios.Library;
	
endfunction

function makeScenario ( Scenario, AsParent )
	
	if ( Catalogs.Scenarios.Locked ( Scenario ) ) then
		return false;
	endif;
	obj = Scenario.GetObject ();
	parentApp = obj.Application; 
	Catalogs.Scenarios.RemoveFile ( Scenario, parentApp, obj.Path, obj.Tree, false );
	obj.Tree = AsParent;
	if ( AsParent
		and obj.Type = Enums.Scenarios.Scenario ) then
		obj.Type = Enums.Scenarios.Folder;
		Catalogs.Scenarios.SetSorting ( obj );
	endif;
	Catalogs.Scenarios.UpdateFiles ( obj );
	obj.DataExchange.Load = true;
	obj.Write ();
	obj.FullExchange ();
	ExchangePlans.Repositories.Sync ( Scenario, parentApp, false );
	return true;
	
endfunction 

procedure OnWrite ( Cancel )
	
	if ( DataExchange.Load ) then
		return;
	endif;
	FullExchange ();
	ExchangePlans.Repositories.Sync ( Ref, Application, false );
	if ( IsNew ) then
		InformationRegisters.Editing.Lock ( SessionParameters.User, Ref );
	else
		if ( Application <> OldApplication ) then
			ExchangePlans.Repositories.Sync ( Ref, OldApplication, false );
		endif;
		if ( DeletionMark <> OldDeletionMark ) then
			markVersions ( DeletionMark );
		endif;
	endif;
	
endprocedure

procedure FullExchange () export

	if ( not Local ) then
		Exchange.RecordChanges ( Ref );	
	endif; 

endprocedure

procedure markVersions ( Delete )
	
	selection = Catalogs.Versions.Select ( , , new Structure ( "Scenario", Ref ) );
	while ( selection.Next () ) do
		obj = selection.GetObject ();
		obj.SetDeletionMark ( Delete );
	enddo; 
	
endprocedure 

procedure BeforeDelete ( Cancel )
	
	Catalogs.Scenarios.RemoveFile ( Ref, Application, Path, Tree, true );
	
endprocedure
