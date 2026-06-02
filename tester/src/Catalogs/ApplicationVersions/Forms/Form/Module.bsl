// *****************************************
// *********** Form events

&atserver
procedure OnReadAtServer ( CurrentObject )
	
	Appearance.Apply ( ThisObject );
	
endprocedure

&atserver
procedure OnCreateAtServer ( Cancel, StandardProcessing )
	
	if ( Object.Ref.IsEmpty () ) then
		fillNew ();
	endif; 
	readAppearance ();
	Appearance.Apply ( ThisObject );
	
endprocedure

&atserver
procedure readAppearance ()

	rules = new Array ();
	rules.Add ( "
	|SetCurrent show empty ( Object.Ref )
	|" );
	Appearance.Read ( ThisObject, rules );

endprocedure

&atserver
procedure fillNew ()
	
	SetCurrent = true;
	Object.Date = CurrentSessionDate ();
	if ( not Parameters.CopyingValue.IsEmpty () ) then
		return;
	endif; 
	version = nextVersion ();
	if ( version <> undefined ) then
		FillPropertyValues ( Object, version );
	endif; 
	setDescription ( Object );

endprocedure 

&atserver
function nextVersion ()
	
	s = "
	|select top 1 allowed Versions.Major, Versions.Minor as Minor,
	|	Versions.Version as Version, Versions.Build + 1 as Build
	|from Catalog.ApplicationVersions as Versions
	|where not Versions.DeletionMark
	|and Versions.Owner = &Owner
	|and Versions.Date <= &Date
	|order by Versions.Date desc
	|";
	q = new Query ( s );
	q.SetParameter ( "Date", Object.Date );
	q.SetParameter ( "Owner", Object.Owner );
	table = q.Execute ().Unload ();
	return ? ( table.Count () = 0, undefined, table [ 0 ] );
	
endfunction 

&atclientatservernocontext
procedure setDescription ( Object )
	
	Object.Description = Format ( Object.Major, "NG=0;NZ=0" )
	+ "." + Format ( Object.Minor, "NG=0;NZ=0" )
	+ "." + Format ( Object.Version, "NG=0;NZ=0" )
	+ "." + Format ( Object.Build, "NG=0;NZ=0" );
	
endprocedure 

&atserver
procedure AfterWriteAtServer ( CurrentObject, WriteParameters )
	
	if ( SetCurrent ) then
		setByDefault ();
		Appearance.Apply ( ThisObject, "Object.Ref" );
	endif; 
	
endprocedure

&atserver
procedure setByDefault ()
	
	EnvironmentSrv.SetVersion ( Object.Ref, false );
	SetCurrent = false;
	
endprocedure 

// *****************************************
// *********** Group Form

&atclient
procedure VersionOnChange ( Item )
	
	setDescription ( Object );
	
endprocedure
