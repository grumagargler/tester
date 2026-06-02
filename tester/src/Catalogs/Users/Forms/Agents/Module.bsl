// *****************************************
// *********** List

&atclient
procedure ListValueChoice ( Item, Value, StandardProcessing )
	
	StandardProcessing = false;
	postSelection ();
	
endprocedure

&atclient
procedure postSelection ()
	
	data = Items.List.CurrentData;
	NotifyChoice ( new Structure ( "Agent, Computer", data.Ref, data.Computer ) );
	
endprocedure