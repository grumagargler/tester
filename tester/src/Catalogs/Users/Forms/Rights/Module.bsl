// *****************************************
// *********** Form events

&atserver
procedure OnCreateAtServer ( Cancel, StandardProcessing )
	
	loadParams ();
	RightsRelations = RightsTree.GetRelations ();
	
endprocedure

&atserver
procedure loadParams ()
	
	table = GetFromTempStorage ( Parameters.UserRights );
	ValueToFormData ( table, Rights );
	
endprocedure 

// *****************************************
// *********** Group Form

&atclient
procedure Commit ( Command )
	
	Notify ( Enum.MessageUserRightsChanged (), rightsStorage () );
	Close ();
	
endprocedure

&atserver
function rightsStorage ()
	
	return PutToTempStorage ( FormDataToValue ( Rights, Type ( "ValueTree" ) ), UUID );

endfunction

// *****************************************
// *********** Table Rights

&atclient
procedure MarkAllRights ( Command )
	
	RightsTree.MarkAll ( Rights );
	
endprocedure

&atclient
procedure UnmarkAllRights ( Command )
	
	RightsTree.UnmarkAll ( Rights );
	
endprocedure

&atclient
procedure RightsBeforeAddRow ( Item, Cancel, Clone, Parent, Folder, Parameter )
	
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
	
	RightsTree.FillChanges ( ThisObject );
	RightsTree.ShowConfirmation ( ThisObject );
	
endprocedure

&atclient
procedure ConfirmRights ( Command )
	
	RightsTree.HideConfirmation ( ThisObject );	
	
endprocedure

&atclient
procedure RevertRights ( Command )	
	
	RightsTree.RevertRights ( ThisObject );
	
endprocedure

&atclient
procedure Help ( Command )
	
	Output.RightsConfirmation ();
	
endprocedure
