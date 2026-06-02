function GetParams ( ReportName = undefined ) export
	
	p = new Structure ();
	setParams ( p, ReportName );
	return p;
	
endfunction

procedure setParams ( Params, ReportName )
	
	Params.Insert ( "ReportName", ReportName );
	Params.Insert ( "Command", "OpenReport" );
	Params.Insert ( "Filters" );
	Params.Insert ( "Parent" );
	Params.Insert ( "ReportVariant" );
	Params.Insert ( "ReportSettings" );
	Params.Insert ( "StoredSettings" );
	Params.Insert ( "GenerateOnOpen", false );
	
endprocedure

&atclient
procedure Open ( Params, Owner = undefined, Unique = undefined,
	Window = undefined ) export

	OpenForm ( "Report." + Params.ReportName + ".Form", Params, Owner, Unique );

endprocedure

&atserver
function URL ( Params ) export
	
	report = GetUrl ( Metadata.Reports [ Params.ReportName ],
		String ( new UUID () ), Params );
	return report;
		
endfunction
