
// *****************************************
// *********** Form events

&atserver
procedure OnCreateAtServer ( Cancel, StandardProcessing )

	readAppearance ();

endprocedure

&atserver
procedure readAppearance ()

	rules = new Array ();
	rules.Add ( "
	|#c MCPWorking show MCPWorking and not MCPRestartRequired;
	|#c MCPNotWorking hide MCPWorking or MCPRestartRequired;
	|#c MCPRestartRequired show MCPRestartRequired
	|" );
	Appearance.Read ( ThisObject, rules );

endprocedure

&atclient
procedure AfterWrite ( WriteParameters )
	
	Notify ( Enum.MessageApplicationSettingsSaved () );
	
endprocedure

&atclient
procedure OnOpen ( Cancel )
	
	checkMCP ();
	Appearance.Apply ( ThisObject );
	
endprocedure

&atclient
procedure checkMCP ()

	MCPWorking = MCPD <> undefined;

endprocedure

// *****************************************
// *********** Form

&atclient
procedure IDOnChange ( Item )

	adjustID ();

endprocedure

// Server is used to make WebClient possible to use
&atserver
procedure adjustID ()
	
	id = Upper ( TrimAll ( ConstantsSet.ID ) );
	matches = Regexp.Select ( id, "[\d,[A-Z]+" );
	if ( matches.Count () = 0 ) then
		ConstantsSet.ID = "A000";
	else
		ConstantsSet.ID = matches [ 0 ].Value;
	endif;
	
endprocedure

&atclient
procedure MCPServerOnChange ( Item )

	applyMCPServer ();
	
endprocedure

&atclient
procedure applyMCPServer ()

	MCPRestartRequired = true;
	Appearance.Apply ( ThisForm, "MCPRestartRequired" );

endprocedure