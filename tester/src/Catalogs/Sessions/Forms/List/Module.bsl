// *****************************************
// *********** Form events

&atserver
procedure OnCreateAtServer ( Cancel, StandardProcessing )
	
	init ();
	
endprocedure

&atserver
procedure init ()
	
	MySession = SessionParameters.Session;
	
endprocedure