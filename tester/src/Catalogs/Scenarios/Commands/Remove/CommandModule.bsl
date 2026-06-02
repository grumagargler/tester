
&atclient
procedure CommandProcessing ( Scenarios, ExecuteParameters )
	
	deletion = not DF.Pick ( Scenarios [ 0 ], "DeletionMark" );
	if ( deletion ) then
		Output.MarkForDeletion ( ThisObject, Scenarios );
	else
		Output.UnmarkForDeletion ( ThisObject, Scenarios );
	endif;
	
endprocedure

&atclient
procedure MarkForDeletion ( Answer, Scenarios ) export
	
	if ( Answer = DialogReturnCode.No ) then
		return;
	endif;
	proceedDeletion ( true, Scenarios );
	
endprocedure

&atclient
procedure proceedDeletion ( Delete, Scenarios )

	error = undefined;
	changes = setMark ( Delete, Scenarios, error );
	if ( error <> undefined ) then
		Output.ShowError ( , , new Structure ( "Error", error ) );
	endif;
	broadcast ( changes );
	RepositoryFiles.Sync ();

endprocedure

&atserver
function setMark ( val Delete, val Scenarios, Error )
	
	list = new Array ();
	for each scenario in Scenarios do
		obj = scenario.GetObject ();
		alreadyDeleted = obj.DeletionMark;
		if ( Delete = alreadyDeleted ) then
			continue;
		endif;
		try
			obj.SetDeletionMark ( Delete );
		except
			Error = ErrorProcessing.BriefErrorDescription ( ErrorInfo () );
			break;
		endtry;
		list.Add ( scenario );
	enddo;
	return list;
	
endfunction

&atclient
procedure broadcast ( Scenarios )
	
	Notify ( Enum.MessageReload (), Scenarios );
	NotifyChanged ( Type ( "CatalogRef.Scenarios" ) );
	
endprocedure 

&atclient
procedure UnmarkForDeletion ( Answer, Scenarios ) export
	
	if ( Answer = DialogReturnCode.No ) then
		return;
	endif;
	proceedDeletion ( false, Scenarios );
	
endprocedure
