
procedure CheckDoubles ( Source, Cancel, CheckedAttributes ) export
	
	if ( IsInRole ( Metadata.Roles.DoublesAllowed ) ) then
		return;
	endif; 
	if ( exception ( Source ) ) then
		return;
	endif; 
	original = DF.GetOriginal ( Source.Ref, "Description", Source.Description, getOwner ( Source ) );
	if ( original = undefined ) then
		return;
	endif; 
	Cancel = true;
	Output.ObjectNotOriginal ( new Structure ( "Value", Source.Description ), "Description" );
	
endprocedure

function exception ( Source )
	
	type = TypeOf ( Source );
	return type = Type ( "CatalogObject.ReportSettings" )
	or type = Type ( "CatalogObject.Metadata" )
	or type = Type ( "CatalogObject.ErrorLog" )
	or type = Type ( "CatalogObject.Scenarios" )
	or type = Type ( "CatalogObject.Sessions" )
	or type = Type ( "CatalogObject.TagKeys" )
	or type = Type ( "CatalogObject.Versions" )
	or type = Type ( "CatalogObject.Users" );

endfunction 

function getOwner ( Source )
	
	meta = Source.Metadata ();
	if ( Metadata.Catalogs.Contains ( meta )
		and meta.Owners.Count () > 0 ) then
		return Source.Owner;
	else
		return undefined;
	endif; 

endfunction 
