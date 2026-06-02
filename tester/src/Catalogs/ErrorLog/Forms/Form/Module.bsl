// *****************************************
// *********** Form events

&atserver
procedure OnReadAtServer ( CurrentObject )

	readApplication ();
	setScreenshot ();
	setTitle ();
	ErrorLogForm.UpdateStack ( Object.Ref, Stack );
	readAppearance ();
	Appearance.Apply ( ThisObject );
	
endprocedure

&atserver
procedure readAppearance ()

	rules = new Array ();
	rules.Add ( "
	|ScreenshotGroup show Object.ScreenshotExists;
	|InfoGroup show not Object.ScreenshotExists
	|" );
	Appearance.Read ( ThisObject, rules );

endprocedure

&atserver
procedure readApplication ()
	
	ScenarioApplication = DF.Pick ( Object.Scenario, "Application" );
	
endprocedure

&atserver
procedure setScreenshot ()
	
	if ( Object.ScreenshotExists ) then
		Screenshot = GetURL ( Object.Ref, "Screenshot" );
	else
		Screenshot = "";
	endif; 

endprocedure

&atserver
procedure setTitle ()
	
	Title = Title + ": " + Object.Date;
	
endprocedure 

// *****************************************
// *********** Group Form

&atclient
procedure ShowInList ( Command )
	
	openList ();
	Close ();
	
endprocedure

&atclient
procedure openList ()
	
	ref = Object.Ref;
	form = GetForm ( "Catalog.ErrorLog.ListForm", new Structure ( "CurrentRow", ref ) );
	table = form.Items.List;
	table.CurrentRow = ref;
	form.Open ();
	if ( table.CurrentRow = undefined ) then
		Output.ErrorNotLocated ();
	endif;
	
endprocedure

// *****************************************
// *********** Table Stack

&atclient
procedure StackSelection ( Item, SelectedRow, Field, StandardProcessing )
	
	StandardProcessing = false;
	data = Item.CurrentData;
	ScenarioForm.GotoLine ( data.Ref, data.Row, Object.Ref );
	Close ();
	
endprocedure

// *****************************************
// *********** Screenshot Field

&atclient
procedure ScreenshotClick ( Item, StandardProcessing )
	
	StandardProcessing = false;
	showPicture ();
	
endprocedure

&atclient
procedure showPicture ()
	
	if ( Screenshot = "" ) then
		return;
	endif; 
	p = new Structure ();
	p.Insert ( "Title", Object.Ref );
	p.Insert ( "URL", Screenshot );
	OpenForm ( "CommonForm.Screenshot", p );
	
endprocedure 
