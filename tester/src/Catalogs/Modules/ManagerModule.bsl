procedure PresentationFieldsGetProcessing ( Fields, StandardProcessing )
	
	Fields.Add ( "Path" );
	Fields.Add ( "IsVersion" );
	StandardProcessing = false;
	
endprocedure

procedure PresentationGetProcessing ( Data, Presentation, StandardProcessing )
	
	StandardProcessing = false;
	Presentation = ? ( Data.IsVersion, Enum.OthersVersionPrefix (), "" ) + Data.Path;
	
endprocedure
