
&atserver
procedure OnCreateAtServer ( Cancel, StandardProcessing )
	
	setViewSettings ();
	readAppearance ();
	Appearance.Apply ( ThisObject );
	
endprocedure

&atserver
procedure readAppearance ()

	rules = new Array ();
	rules.Add ( "
	|OpenConstants show ViewSettings
	|" );
	Appearance.Read ( ThisObject, rules );

endprocedure

&atserver                                                                                                        
procedure setViewSettings ()
	
	ViewSettings = ( AccessRight ( "Edit", Metadata.Constants.Agent )
					and AccessRight ( "Edit", Metadata.Constants.CloudPassword )
					and AccessRight ( "Edit", Metadata.Constants.CloudUser )
					and AccessRight ( "Edit", Metadata.Constants.ClusterAdministrator )
					and AccessRight ( "Edit", Metadata.Constants.ClusterPassword )
					and AccessRight ( "Edit", Metadata.Constants.ServerAdministrator )
					and AccessRight ( "Edit", Metadata.Constants.ServerCode )
					and AccessRight ( "Edit", Metadata.Constants.ServerPassword ) );
					
endprocedure 

&atclient
procedure OpenConstants ( Command )
	
	OpenForm ( "Catalog.Exchange.Form.Settings" );	
	
endprocedure