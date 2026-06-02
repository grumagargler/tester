// *****************************************
// *********** Form events

&atserver
procedure OnReadAtServer ( CurrentObject )
	
	RightsTree.FillRights ( ThisObject );
	fillUserGroups ();
	fillActualRights ();
	Appearance.Apply ( ThisObject );
	
endprocedure

&atserver
procedure fillUserGroups ()
	
	s = "
	|select UserGroups.Ref as UserGroup,";
	if ( Object.Ref.IsEmpty () ) then
		s = s + "case when UserGroups.Ref = value ( Catalog.UserGroups.Users ) then true else false end as Use";
	else
		s = s + "case when SelectedGroups.UserGroup is null then false else true end as Use";
	endif; 
	s = s + "
	|from Catalog.UserGroups as UserGroups
	|	//
	|	// SelectedGroups
	|	//
	|	left join InformationRegister.UsersAndGroups as SelectedGroups
	|	on SelectedGroups.UserGroup = UserGroups.Ref
	|	and SelectedGroups.User = &Ref
	|where not UserGroups.DeletionMark
	|order by UserGroups.Description
	|";
	q = new Query ( s );
	q.SetParameter ( "Ref", Object.Ref );
	Tables.UserGroups.Load ( q.Execute ().Unload () );
	
endprocedure 

&atserver
procedure fillActualRights ()
	
	env = RightsTree.GetEnv ( ThisObject );
	RightsTree.PrepareRightsTable ( env );
	getSelectedRights ( env );
	addRolesToArray ( env );
	fillRightsByGroups ( env, Tables.UserGroups.Unload () );
	RightsTree.FillRightsTable ( env );
	RightsTree.SetCheckboxesForGroups ( Env.RightsTable.Rows );
	deleteUnusedRows ( Env.RightsTable.Rows );
	ValueToFormAttribute ( Env.RightsTable, "ActualAccess" );
	
endprocedure

&atserver
procedure getSelectedRights ( Env )
	
	Env.Insert ( "SelectedRights", new Array () );
	
endprocedure 

&atserver
procedure addRolesToArray ( Env )
	
	rightsValueTree = FormDataToValue ( Env.Form.Rights, Type ( "ValueTree" ) );
	list = Env.SelectedRights;
	for each groupRow in rightsValueTree.Rows do
		if ( groupRow.Use = 0 ) then
			continue;
		endif;
		for each row in groupRow.Rows do
			if ( row.Use = 1 ) then
				list.Add ( row.roleName );
			endif;
		enddo;
	enddo;	
		
endprocedure

&atserver
procedure deleteUnusedRows ( Groups )
	
	count = Groups.Count();
	for i = 1 to count do
		row = Groups [ count - i ];
		if ( row.use = 0 ) then
			Groups.Delete ( row );
		else
			deleteUnusedRows ( row.rows );
		endif;
	enddo; 
	
endprocedure

&atserver
procedure fillRightsByGroups ( Env, Groups );
	
	usedGroups = getUsedGroups ( Groups );
	groupRoles = getRolesByGroups ( usedGroups );
	list = Env.SelectedRights;
	for each role in groupRoles do
		if ( not RightsTree.InRole( Env, role ) ) then
			list.Add ( role );
		endif;
	enddo;
	
endprocedure

&atserver
function getUsedGroups ( Groups )
	
	usedGroupsArray = new array;
	usedGroups = Groups.FindRows ( new Structure ( "Use", true ) );
	for each usedGroup in usedGroups do
		usedGroupsArray.Add ( usedGroup.UserGroup );
	enddo;
	return usedGroupsArray;
	
endfunction

&atserver
function getRolesByGroups ( Groups )
	
	q = new Query ( "select RoleName as RoleName from Catalog.UserGroups.Rights where Ref in ( &Groups )" );
	q.SetParameter ( "Groups", Groups );
	return q.Execute ().Unload ().UnloadColumn ( "RoleName" );
	
endfunction

&atserver
procedure OnCreateAtServer ( Cancel, StandardProcessing )
	
	setAdministrator ();
	fillTimeZones ();
	if ( Object.Ref.IsEmpty () ) then
		setCurrentTimeZone ();
		fillUserGroups ();
		RightsTree.FillRights ( ThisObject );
		fillActualRights ();
	endif; 
	readAppearance ();
	Appearance.Apply ( ThisObject );
		
endprocedure

&atserver
procedure readAppearance ()

	rules = new Array ();
	rules.Add ( "
	|Password PasswordConfirmation enable SetNewPassword;
	|Applications enable inlist ( Object.ApplicationsAccess, Enum.Access.Allow, Enum.Access.Forbid );
	|RightsEditRights enable Administrator;
	|Managers enable Object.Agent
	|" );
	Appearance.Read ( ThisObject, rules );

endprocedure

&atserver
procedure setAdministrator ()
	
	Administrator = IsInRole ( "Administrator" );
	
endprocedure 

&atserver
procedure fillTimeZones ()
	
	timeZones = GetAvailableTimeZones ();
	for each timeZone in timeZones do
		Items.TimeZone.ChoiceList.Add ( timeZone, timeZone + " (" + TimeZonePresentation ( timeZone ) + ")" );
	enddo; 
	
endprocedure 

&atserver
procedure setCurrentTimeZone ()
	
	currentTimeZone = GetInfoBaseTimeZone ();
	Object.TimeZone = ? ( currentTimeZone = undefined, TimeZone (), currentTimeZone );
	
endprocedure 

&atclient
procedure NotificationProcessing ( EventName, Parameter, Source )
	
	if ( EventName = Enum.MessageUserGroupCreated () ) then
		fillAccess ();
		expandTree ();
	elsif (	EventName = Enum.MessageUserGroupModified () ) then
		fillActualRights ();
		expandTree ();
	elsif ( EventName = Enum.MessageUserRightsChanged () ) then
		updateRights ( Parameter );
		expandTree ();
	endif; 
	
endprocedure

&atserver
procedure fillAccess ()
	
	fillUserGroups ();
	fillActualRights ();
	
endprocedure

&atserver
procedure updateRights ( val Address ) export
	
	table = GetFromTempStorage ( Address );
	ValueToFormData ( table, Rights );
	RightsTree.FillChanges ( ThisObject );
	fillActualRights ();
	
endprocedure

&atclient
procedure expandTree ()
	
	RightsTree.Expand ( ThisObject, "ActualAccess" );

endprocedure 

&atserver
procedure FillCheckProcessingAtServer ( Cancel, CheckedAttributes )
	
	if ( not checkUsersName () ) then
		Cancel = true;
	endif; 
	if ( not checkRights () ) then
		Cancel = true;
	endif; 
	
endprocedure

&atserver
function checkUsersName ()
	
	user = Catalogs.Users.FindByDescription ( Object.Description, true );
	error = not user.IsEmpty () and ( user <> Object.Ref );
	if ( error ) then
		Output.UserNameAlreadyExists ( , "Description" );
	endif; 
	return not error;
	
endfunction 

&atserver
function checkRights ()
	
	groupsSelected = Tables.UserGroups.FindRows ( new Structure ( "Use", true ) ).Count () > 0;
	if ( groupsSelected ) then
		return true;	
	else
		error = not RightsTree.FillCheck ( ThisObject );
		if ( error ) then
			if ( Tables.UserGroups.Count () = 0 ) then
				Output.SelectAccessRights ( , "Rights", , "" );
			else
				Output.SelectUsersGroup ( , "Tables.UserGroups", , "" );
			endif; 
		endif; 
		return not error;
	endif;
	
endfunction 

&atserver
procedure BeforeWriteAtServer ( Cancel, CurrentObject, WriteParameters )
	
	setProperties ( CurrentObject );
	serializeRights ( CurrentObject );
	
endprocedure

&atserver
procedure setProperties ( CurrentObject )
	
	p = CurrentObject.AdditionalProperties;
	if ( SetNewPassword ) then
		p.Insert ( "Password", Password );
	endif; 
	p.Insert ( "UserGroups", Tables.UserGroups.Unload () );
	
endprocedure 

&atserver
procedure serializeRights ( CurrentObject )
	
	RightsAugmented = false;
	RightsTree.SaveSeletedRights ( ThisObject, CurrentObject );
	if ( Object.Agent ) then
		role = Metadata.Roles.JobsUse.Name;
		table = CurrentObject.Rights;
		if ( table.Find ( role ) = undefined ) then
			RightsAugmented = true;
			row = table.Add ();
			row.RoleName = role;
		endif;
	endif;
	
endprocedure

&atserver
procedure AfterWriteAtServer ( CurrentObject, WriteParameters )
	
	if ( RightsAugmented ) then
		RightsTree.FillRights ( ThisObject );
		fillActualRights ();
	endif;
	
endprocedure

&atclient
procedure AfterWrite ( WriteParameters )
	
	if ( RightsAugmented ) then
		expandTree ();
	endif;
	
endprocedure

// *****************************************
// *********** Page User

&atclient
procedure DescriptionOnChange ( Item )
	
	adjustLogin ();
	setFirstName ();
	Object.Code = Conversion.NameToCode ( Object.Description, 3 );
	
endprocedure

&atclient
procedure adjustLogin ()
	
	Object.Description = TrimAll ( Object.Description );
	
endprocedure 

&atclient
procedure setFirstName ()
	
	Object.FirstName = Object.Description;
	
endprocedure 

&atclient
procedure SetNewPasswordOnChange ( Item )
	
	Appearance.Apply ( ThisObject, "SetNewPassword" );
	
endprocedure

// *****************************************
// *********** Page Rights

&atclient
procedure MarkAllGroups ( Command )
	
	markRows ( true );
	fillActualRights ();
	expandTree ();
	
endprocedure

procedure markRows ( Check )
	
	for each item in Tables.UserGroups do
		item.Use = Check;
	enddo; 
	
endprocedure

&atclient
procedure UnmarkAllGroups ( Command )
	
	markRows ( false );
	fillActualRights ();
	expandTree ();
	
endprocedure

&atclient
procedure UsersGroupsBeforeAddRow ( Item, Cancel, Clone, Parent, Folder )
	
	Cancel = true;
	
endprocedure

&atclient
procedure UsersGroupsBeforeDeleteRow ( Item, Cancel )
	
	Cancel = true;
	
endprocedure

&atclient
procedure UsersGroupsSelection ( Item, SelectedRow, Field, StandardProcessing )
	
	openSeletedUserGroup ( Item );
	
endprocedure

&atclient
procedure openSeletedUserGroup ( Item )
	
	ShowValue ( , Item.CurrentData.UserGroup );
	
endprocedure 

&atclient
procedure EditRights ( Command )
	
	openEditor ();
	
endprocedure

&atclient
procedure openEditor ()
	
	p = new Structure ();
	p.Insert ( "UserRights", storeRights () );
	OpenForm ( "Catalog.Users.Form.Rights", p, ThisObject );
	
endprocedure 

&atserver
function storeRights ()
	
	return PutToTempStorage ( FormDataToValue ( Rights, Type ( "ValueTree" ) ) );

endfunction
	
&atclient
procedure UsersGroupsUseOnChange ( Item )
	
	fillActualRights ();
	expandTree ();
	
endprocedure

// *****************************************
// *********** Page Applications

&atclient
procedure ApplicationAccessOnChange ( Item )
	
	adjustAccess ( "Applications" );
	Appearance.Apply ( ThisObject, "Object.ApplicationsAccess" );
	
endprocedure

&atclient
procedure adjustAccess ( Class )
	
	if ( Class = "Applications" ) then
		access = Object.ApplicationsAccess;
		table = Object.Applications;
	endif; 
	if ( access = PredefinedValue ( "Enum.Access.Undefined" ) ) then
		table.Clear ();
	endif;
	
endprocedure 

// *****************************************
// *********** Page Agent

&atclient
procedure AgentOnChange ( Item )
	
	applyAgent ();
	
endprocedure

&atclient
procedure applyAgent ()
	
	if ( not Object.Agent ) then
		Object.Managers.Clear ();
	endif; 
	Appearance.Apply ( ThisObject, "Object.Agent" );
	
endprocedure 
