&atclient
var SetAsDefault;

// *****************************************
// *********** Form events

&atserver
procedure OnReadAtServer ( CurrentObject )
	
	Appearance.Apply ( ThisObject );
	
endprocedure

&atserver
procedure OnCreateAtServer ( Cancel, StandardProcessing )
	
	if ( Object.Ref.IsEmpty () ) then
		setResponsible ();
	endif; 
	initVersions ();
	filterVersions ();
	filterPorts ();
	readAppearance ();
	Appearance.Apply ( ThisObject );
	
endprocedure

&atserver
procedure readAppearance ()

	rules = new Array ();
	rules.Add ( "
	|Versions enable filled ( Object.Ref );
	|GroupPorts show filled ( Object.Ref );
	|Write Write1 show empty ( Object.Ref )
	|" );
	Appearance.Read ( ThisObject, rules );

endprocedure

&atserver
procedure initVersions ()
	
	Session = SessionParameters.Session;
	DC.SetParameter ( Versions, "User", SessionParameters.User );
	
endprocedure 

&atserver
procedure filterVersions ()
	
	ref = Object.Ref;
	DC.SetFilter ( Versions, "Owner", ref );
	DC.SetParameter ( Versions, "Owner", ref );
	
endprocedure 

&atserver
procedure filterPorts ()
	
	DC.SetFilter ( Ports, "Application", Object.Ref );
	
endprocedure 

&atserver
procedure setResponsible ()
	
	if ( not Parameters.CopyingValue.IsEmpty () ) then
		return;
	endif; 
	Object.Responsible = SessionParameters.User;
	
endprocedure 

&atclient
procedure BeforeWrite ( Cancel, WriteParameters )
	
	if ( updateMeta () ) then
		SetAsDefault = Object.Ref.IsEmpty () and theFirstApp ();
	else
		Cancel = true;
	endif;
	
endprocedure

&atservernocontext
function theFirstApp ()
	
	q = new Query ( "select allowed top 1 1 from Catalog.Applications where not DeletionMark" );
	return q.Execute ().IsEmpty ();
	
endfunction

&atclient
function updateMeta ()
	
	try
		Runtime.UpdateMeta ( Object.Metadata );
	except
		ShowMessageBox ( , ErrorDescription () );
		CurrentItem = Items.Metadata;
		return false;
	endtry;
	return true;
	
endfunction 

&atserver
procedure AfterWriteAtServer ( CurrentObject, WriteParameters )
	
	filterVersions ();
	filterPorts ();
	Appearance.Apply ( ThisObject, "Object.Ref" );
	
endprocedure

&atclient
procedure AfterWrite ( WriteParameters )
	
	if ( SetAsDefault ) then
		Environment.ChangeApplication ( Object.Ref );
	endif;
	
endprocedure

// *****************************************
// *********** Group Form

&atclient
procedure DescriptionOnChange ( Item )
	
	Object.Code = Conversion.NameToCode ( Object.Description, 4 );
	
endprocedure

&atclient
procedure DialogsTitleOnChange ( Item )
	
	setScreenshotsLocator ();
	
endprocedure

&atclient
procedure setScreenshotsLocator ()
	
	s = Object.DialogsTitle;
	if ( s = "" ) then
		return;
	endif; 
	Object.ScreenshotsLocator = ".+" + s + ".+";
	
endprocedure 
