// *****************************************
// *********** Group Form

&atclient
procedure ListSelection ( Item, SelectedRow, Field, StandardProcessing )
	
	StandardProcessing = false;
	openRecord ( Item, SelectedRow );
	
endprocedure

&atclient
procedure openRecord ( Item, RecordKey )
	
	OpenForm ( "InformationRegister.ScheduledReports.RecordForm", new Structure ( "Key", RecordKey ), Item );
	
endprocedure 
