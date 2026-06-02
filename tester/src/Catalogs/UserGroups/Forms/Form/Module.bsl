&atclient
var IsNew;

// *****************************************
// *********** Form events

&atserver
procedure OnReadAtServer ( CurrentObject )
	
	RightsRelations = RightsTree.FillRights ( ThisObject );
	RightsConfirmed = true;
	fillUsers ();
	
endprocedure

&atserver
procedure fillUsers ()
	
	s = "
	|select UsersAndGroups.User as User
	|from InformationRegister.UsersAndGroups as UsersAndGroups
	|where UsersAndGroups.UserGroup = &Ref
	|order by UsersAndGroups.User.Description
	|";
	q = new Query ( s );
	q.SetParameter ( "Ref", Object.Ref );
	Tables.Users.Load ( q.Execute ().Unload () );
	
endprocedure 

&atserver
procedure OnCreateAtServer ( Cancel, StandardProcessing )
	
	if ( Object.Ref.IsEmpty () ) then
		RightsRelations = RightsTree.FillRights ( ThisObject );
		RightsConfirmed = true;
	endif; 
	
endprocedure

&atclient
procedure OnOpen ( Cancel )
	
	IsNew = Object.Ref.IsEmpty ();
	
endprocedure

&atserver
procedure FillCheckProcessingAtServer ( Cancel, CheckedAttributes )
	
	if ( not checkRights () ) then
		Cancel = true;
	endif; 
	
endprocedure

&atserver
function checkRights ()
	
	if ( not RightsConfirmed ) then
		Output.ConfirmAccessRights ( , "RightsChanges", , "" );
		return false;
	endif;	
	error = not RightsTree.FillCheck ( ThisObject );
	if ( error ) then
		Output.SelectAccessRights ( , "Rights", , "" );
	endif; 
	return not error;
	
endfunction 

&atserver
procedure BeforeWriteAtServer ( Cancel, CurrentObject, WriteParameters )
	
	RightsTree.SaveSeletedRights ( ThisObject, CurrentObject );
	getUsersTable ();
	setProperties ( CurrentObject );
	
endprocedure

&atserver
procedure setProperties ( CurrentObject )
	
	CurrentObject.AdditionalProperties.Insert ( "SelectedUsers", getUsersTable () );
	
endprocedure 

&atserver
function getUsersTable ()
	
	selectedUsers = Tables.Users.Unload ();
	selectedUsers.GroupBy ( "User" );
	return selectedUsers;
	
endfunction

&atclient
procedure AfterWrite ( WriteParameters )
	
	if ( IsNew ) then
		Notify ( Enum.MessageUserGroupCreated () );
		IsNew = false;
	endif; 
	Notify ( Enum.MessageUserGroupModified () );
	
endprocedure

// *****************************************
// *********** Group Rights

&atclient
procedure MarkAllRights ( Command )
	
	RightsTree.MarkAll ( Rights );
	
endprocedure

&atclient
procedure UnmarkAllRights ( Command )
	
	RightsTree.UnmarkAll ( Rights );
	
endprocedure

&atclient
procedure ConfirmRights ( Command )
	
	RightsConfirmed = true;
	RightsTree.HideConfirmation ( ThisObject );	
	
endprocedure

&atclient
procedure RevertRights ( Command )	
	
	RightsConfirmed = true;
	RightsTree.RevertRights ( ThisObject );
	
endprocedure

&atclient
procedure Help ( Command )
	
	Output.RightsConfirmation ();
	
endprocedure

&atclient
procedure RightsBeforeAddRow ( Item, Cancel, Clone, Parent, Folder )
	
	Cancel = true;
	
endprocedure

&atclient
procedure RightsBeforeDeleteRow ( Item, Cancel )
	
	Cancel = true;
	
endprocedure

&atclient
procedure RightsUseOnChange ( Item )
	
	if ( RightsTree.UseChanged ( ThisObject ) ) then
		showChanges ();	
		RightsTree.Expand ( ThisObject );
	endif;
	
endprocedure

&atserver
procedure showChanges ()
	
	RightsConfirmed = false;
	RightsTree.FillChanges ( ThisObject );
	RightsTree.ShowConfirmation ( ThisObject );
	
endprocedure
