// *****************************************
// *********** Form events

&atserver
procedure OnCreateAtServer ( Cancel, StandardProcessing )
	
	loadParams ();
	
endprocedure

&atserver
procedure loadParams ()
	
	Title = Parameters.Title;
	Screenshot = Parameters.URL;
	
endprocedure 