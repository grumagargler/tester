
procedure BeforeWrite ( Cancel )
	
	if ( DataExchange.Load ) then
		return;
	endif;
	trimAllAttributes ();
	
endprocedure

procedure OnWrite ( Cancel )
	
	if ( DataExchange.Load ) then
		return;
	endif;
	
endprocedure

procedure BeforeDelete ( Cancel )
	
	UseAutomatic = false;	
	
endprocedure

procedure trimAllAttributes ()
	
	attributes = getAttributes ();
	for each attribute in attributes do
		ThisObject [ attribute ] = TrimAll ( ThisObject [ attribute ] );
	enddo; 
		
endprocedure

function getAttributes ()
	
	a = new Array ();
	a.Add ( "Code" );
	a.Add ( "EMailLoad" );
	a.Add ( "EMailUnLoad" );
	a.Add ( "FolderDiskLoadHandle" );
	a.Add ( "FolderDiskLoadJob" );
	a.Add ( "FolderDiskUnLoadHandle" );
	a.Add ( "FolderDiskUnLoadJob" );
	a.Add ( "FolderFTPLoad" );
	a.Add ( "FolderFTPUnLoad" );
	a.Add ( "PrefixFileName" );
	a.Add ( "ServerFTPLoad" );
	a.Add ( "ServerFTPUnLoad" );
	a.Add ( "ServerIncoming" );
	a.Add ( "ServerOutgoing" );
	a.Add ( "UserEmail" );
	a.Add ( "UserFTPLoad" );
	a.Add ( "UserFTPUnLoad" );
	a.Add ( "UserWebService" );
	a.Add ( "WebService" );
	return a; 
	
endfunction 