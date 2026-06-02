
function Init ( Name ) export
	
	id = "AddIn.Extender." + Name;
	try
		lib = new ( id );
	except
		Load ();
		lib = new ( id );
	endtry;
	return lib;
	
endfunction

procedure Load () export
	
	loaded = false;
	file = EnvironmentSrv.Library ();
	if ( file <> "" ) then
		try
			loaded = attach ( file );
		except
		endtry;
		if ( not loaded ) then
			Output.WrongExternalLibrary ( new Structure ( "File", file ) );
		endif;
	endif;
	if ( not loaded ) then
		loaded = attach ( "CommonTemplate.ExternalLibrary" );
		#if ( Client ) then
			if ( not loaded ) then
				InstallAddIn ( "CommonTemplate.ExternalLibrary" );
				loaded = attach ( "CommonTemplate.ExternalLibrary" );
			endif;
		#endif
	endif;
	if ( not ( loaded and requiredVersion () ) ) then
		raise Output.LibraryFailed ();
	endif;
	
endprocedure 

function attach ( Path )
	
	return AttachAddIn ( Path, "Extender", AddInType.Native, AddInAttachmentType.NotIsolated );
	
endfunction

function requiredVersion ()
	
	required = 9039;
	try
		lib = new ( "AddIn.Extender.Root" );
		version = lib.Version ();
	except
		version = 0;
	endtry;
	return version >= required;
		
endfunction
