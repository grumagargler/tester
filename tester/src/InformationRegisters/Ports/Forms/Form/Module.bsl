// *****************************************
// *********** Form events

&atserver
procedure OnCreateAtServer ( Cancel, StandardProcessing )
	
	if ( Record.SourceRecordKey.IsEmpty () ) then
		initNew ();
	endif;
	
endprocedure

&atserver
procedure initNew ()
	
	Record.Session = SessionParameters.Session;
	
endprocedure