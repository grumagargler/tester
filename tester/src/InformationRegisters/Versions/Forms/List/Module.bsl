&atclient
var TableRow;

// *****************************************
// *********** Form events

&atserver
procedure OnCreateAtServer ( Cancel, StandardProcessing )
	
	displayCaption ();
	filterByScenario ();
	
endprocedure

&atserver
procedure displayCaption ()
	
	Title = Parameters.Scenario;
	
endprocedure 

&atserver
procedure filterByScenario ()
	
	DC.ChangeFilter ( List, "Scenario", Parameters.Scenario, true );
	
endprocedure 

// *****************************************
// *********** List

&atclient
procedure ListOnActivateRow ( Item )
	
	TableRow = Item.CurrentData;
	AttachIdleHandler ( "showCode", 0.1, true );
	
endprocedure

&atclient
procedure showCode () export
	
	if ( TableRow = undefined ) then
		Script = "";
		return;
	endif; 
	if ( TableRow.Version = OldVersion ) then
		return;
	endif; 
	OldVersion = TableRow.Version;
	Script = DF.Pick ( OldVersion, "Script" );
	
endprocedure 

&atclient
procedure ListSelection ( Item, SelectedRow, Field, StandardProcessing )
	
	StandardProcessing = false;
	ShowValue ( , TableRow.Version );
	
endprocedure

&atclient
procedure ListBeforeRowChange ( Item, Cancel )
	
	Cancel = true;
	ShowValue ( , TableRow.Version );
	
endprocedure
