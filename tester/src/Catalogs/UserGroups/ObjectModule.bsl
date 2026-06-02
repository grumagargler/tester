var ObjectRef;

procedure BeforeWrite ( Cancel )
	
	if ( DataExchange.Load ) then
		return;
	endif; 
	makeUsersAndGroups ();
	
endprocedure

procedure makeUsersAndGroups ()
	
	selectedUsers = undefined;
	if ( not AdditionalProperties.Property ( "SelectedUsers", selectedUsers ) ) then
		return;
	endif; 
	recordset = InformationRegisters.UsersAndGroups.CreateRecordSet ();
	if ( IsNew () ) then
		SetNewObjectRef ( Catalogs.UserGroups.GetRef ( new UUID () ) );
		ObjectRef = GetNewObjectRef ();
	else
		ObjectRef = Ref;
	endif; 
	recordset.Filter.UserGroup.Set ( ObjectRef );
	for each row in selectedUsers do
		movement = recordset.Add ();
		movement.UserGroup = ObjectRef;
		movement.User = row.User;
	enddo; 
	recordset.Write ();
	
endprocedure 

procedure OnWrite ( Cancel )
	
	if ( DataExchange.Load ) then
		return;
	endif; 
	SetPrivilegedMode ( true );
	if ( LoginsSrv.LastAdministrator () ) then
		Cancel = true;
		return;
	endif; 
	setRights ();
	SetPrivilegedMode ( false );

endprocedure

procedure setRights ()
	
	userNames = getUserNames ();
	for each userName in userNames do
		user = InfoBaseUsers.FindByName ( userName );
		if ( user = undefined ) then
			continue;
		endif; 
		LoginsSrv.SetRights ( user );
		user.Write ();
	enddo; 
	
endprocedure 

function getUserNames ()
	
	s = "
	|select UsersAndGroups.User.Description as UserName
	|from InformationRegister.UsersAndGroups as UsersAndGroups
	|where UsersAndGroups.UserGroup = &Ref
	|";
	q = new Query ( s );
	q.SetParameter ( "Ref", Ref );
	return q.Execute ().Unload ().UnloadColumn ( "UserName" );
	
endfunction 
