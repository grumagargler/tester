procedure PresentationFieldsGetProcessing ( Fields, StandardProcessing )
	
	StandardProcessing = false;
	Fields.Add ( "Number" );
	Fields.Add ( "Memo" );

endprocedure

procedure PresentationGetProcessing ( Data, Presentation, StandardProcessing )
	
	StandardProcessing = false;
	parts = new Array ();
	memo = Data.Memo;
	if ( memo = "" ) then
		parts.Add ( Metadata.Documents.Job.Synonym );
	else
		parts.Add ( memo );
	endif;
	parts.Add ( " #" + Data.Number );
	Presentation = StrConcat ( parts, " " );
	
endprocedure
