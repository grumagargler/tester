
function AccessDenies () export
	
	SetPrivilegedMode ( true );
	return DF.Pick ( SessionParameters.User, "AccessDenied" );
	
endfunction 

procedure Init () export
	
	SetPrivilegedMode ( true );
	name = Output.UserAdmin ();
	user = Catalogs.Users.FindByDescription ( name, true );
	if ( user.IsEmpty () ) then
		user = Catalogs.Users.CreateItem ();
		user.Email = "user@domain.com";
		user.FirstName = name;
		user.Description = name;
		user.Code = "ADM";
		user.Language = CurrentLanguage ().Name;
		user.TimeZone = TimeZone ();
		user.ApplicationsAccess = Enums.Access.Undefined;
	else
		user = user.GetObject ();
	endif;
	if ( user.Rights.Find ( "Administrator", "RoleName" ) = undefined ) then
		right = user.Rights.Add ();
		right.RoleName = "Administrator";
	endif;
	user.Write ();
	SetPrivilegedMode ( false );
	
endprocedure 

function CanEditScenarios () export
	
	return AccessRight ( "Edit", Metadata.Catalogs.Scenarios );
	
endfunction 

procedure SaveSettings ( ObjectKey, SettingsKey = undefined, Settings ) export
	
	if ( AccessRight ( "SaveUserData", Metadata ) ) then
		CommonSettingsStorage.Save ( ObjectKey, SettingsKey, Settings );
	endif; 
	
endprocedure

function Admin () export
	
	return IsInRole ( "Administrator" );
	
endfunction 
