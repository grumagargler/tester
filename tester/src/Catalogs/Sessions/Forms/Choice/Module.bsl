// *****************************************
// *********** Form events

&atserver
procedure OnCreateAtServer ( Cancel, StandardProcessing )
	
	init ();
	
endprocedure

&atserver
procedure init ()
	
	User = SessionParameters.User;
	
endprocedure