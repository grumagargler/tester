// *****************************************
// *********** Form events

&atserver
procedure OnCreateAtServer ( Cancel, StandardProcessing )
	
	setDate ();
	
endprocedure

&atserver
procedure setDate ()
	
	Date = DF.Pick ( Parameters.CurrentRow, "Date", CurrentSessionDate () );
	
endprocedure

// *****************************************
// *********** Group Form

&atclient
procedure OK ( Command )
	
	commitChoice ();
	
endprocedure

&atclient
procedure commitChoice ()
	
	NotifyChoice ( getDate ( Date ) );
	
endprocedure

&atservernocontext
function getDate ( val Date )
	
	return Catalogs.Calendar.GetDate ( Date );
	
endfunction

&atclient
procedure DateSelection ( Item, SelectedDate )
	
	commitChoice ();
	
endprocedure
