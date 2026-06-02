var CurrentName;
var IsNew;

procedure FillCheckProcessing ( Cancel, CheckedAttributes )
	
	if ( IsFolder ) then
		return;
	endif; 
	checkApplicationsAccess ( CheckedAttributes );
	checkUsers ( CheckedAttributes );
	
endprocedure

procedure checkApplicationsAccess ( CheckedAttributes )
	
	if ( ApplicationsAccess = Enums.Access.Allow
		or ApplicationsAccess = Enums.Access.Forbid ) then
		CheckedAttributes.Add ( "Applications" );
	endif; 
	
endprocedure 

procedure checkUsers ( CheckedAttributes )
	
	if ( Agent ) then
		CheckedAttributes.Add ( "Users" );
	endif; 
	
endprocedure 

procedure BeforeWrite ( Cancel )

	if ( DataExchange.Load ) then
		return;
	endif; 
	if ( IsFolder ) then
		return;
	endif; 
	IsNew = IsNew ();
	getCurrentName ();
	setFullName ();
	if ( DeletionMark ) then
		ExchangePlans.Repositories.MarkDeletion ( Ref );
	endif; 
	
endprocedure

procedure getCurrentName ()
	
	if ( IsNew ) then
		CurrentName = Description;
	else
		CurrentName = DF.Pick ( Ref, "Description" );
	endif; 
	
endprocedure 

procedure setFullName ()
	
	FullName = FirstName + ? ( IsBlankString ( LastName ), "", " " + LastName );
	
endprocedure 

procedure OnWrite ( Cancel )
	
	if ( DataExchange.Load ) then
		return;
	endif; 
	if ( IsFolder ) then
		return;
	endif; 
	SetPrivilegedMode ( true );
	if ( DeletionMark ) then
		LoginsSrv.Remove ( CurrentName );
	else
		makeAccess ();
		makeProfile ();
	endif;
	if ( LoginsSrv.LastAdministrator () ) then
		Cancel = true;
		return;
	endif; 
	SetPrivilegedMode ( false );
	
endprocedure

procedure makeAccess ()
	
	usersGroups = undefined;
	if ( not AdditionalProperties.Property ( "UserGroups", usersGroups ) ) then
		return;
	endif; 
	recordset = InformationRegisters.UsersAndGroups.CreateRecordSet ();
	recordset.Filter.User.Set ( Ref );
	for each row in usersGroups do
		if ( not row.Use ) then
			continue;
		endif; 
		movement = recordset.Add ();
		movement.UserGroup = row.UserGroup;
		movement.User = Ref;
	enddo; 
	recordset.Write ();
	
endprocedure 

procedure makeProfile ()
	
	user = getIBUser ();
	setProfile ( user );
	LoginsSrv.SetRights ( user );
	user.Write ();
	
endprocedure 

function getIBUser ()
	
	user = InfoBaseUsers.FindByName ( CurrentName );
	if ( user = undefined ) then
		user = InfoBaseUsers.CreateUser ();
	endif;
	return user;
	
endfunction

procedure setProfile ( User )
	
	User.Name = Description;
	User.FullName = FullName;
	User.Language = Metadata.Languages.Find ( Language );
	password = undefined;
	if ( AdditionalProperties.Property ( "Password", password ) ) then
		User.Password = password;
	endif; 
	
endprocedure 
