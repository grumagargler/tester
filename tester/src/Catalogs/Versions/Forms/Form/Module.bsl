// *****************************************
// *********** Form events

&atserver
procedure OnReadAtServer ( CurrentObject )
	
	restoreTemplate ( CurrentObject );
	
endprocedure

&atserver
procedure restoreTemplate ( Scenario )
	
	TabDoc = Scenario.Template.Get ();
	entitleTemplate ();
	markAreas ();
	
endprocedure 

&atserver
procedure entitleTemplate ()
	
	caption = Output.TemplateCaption ();
	if ( 0 < ( TabDoc.TableWidth + TabDoc.TableHeight ) ) then
		caption = caption + " *";
	endif; 
	Items.PageTemplate.Title = caption;
	
endprocedure 

&atserver
procedure markAreas ()
	
	noline = new Line ( SpreadsheetDocumentCellLineType.None );
	redLine = new Line ( SpreadsheetDocumentCellLineType.LargeDashed, 3 );
	redColor = new Color ( 255, 0, 0 );
	for each item in Object.Areas do
		area = TabDoc.Area ( item.Name );
		area.TopBorder = noline;
		area.LeftBorder = noline;
		area.RightBorder = noline;
		area.BottomBorder = noline;
		area.Outline ( redLine, redLine, redLine, redLine );
		area.BorderColor = redColor;
	enddo; 
			
endprocedure 

&atclient
procedure OnOpen ( Cancel )
	
	ScenariosPanel.Push ( ThisObject );
	
endprocedure

&atclient
procedure NotificationProcessing ( EventName, Parameter, Source )
	
	if ( EventName = Enum.MessageActivateError ()
		or EventName = Enum.MessageDebugger () ) then
		if ( Source = Object.Ref ) then
			activateEditor ();
			activateRow ( Parameter );
		endif; 
	endif; 
	
endprocedure

&atclient
procedure activateEditor () export
	
	CurrentItem = Items.Script;
	
endprocedure 

&atclient
procedure activateRow ( Line )
	
	Items.Script.SetTextSelectionBounds ( Line, 1, Line, StrLen ( StrGetLine ( Object.Script, Line ) ) + 1 );
	
endprocedure 

&atclient
procedure OnClose ( Exit )
	
	ScenariosPanel.Pop ( Object.Ref );
	
endprocedure
