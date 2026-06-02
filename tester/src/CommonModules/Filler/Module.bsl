function GetParams () export
	
	p = new Structure ();
	p.Insert ( "Report" );
	p.Insert ( "Variant", "#Fill" );
	p.Insert ( "Filters" );
	p.Insert ( "Processor", "Filling" );
	p.Insert ( "ProposeClearing", true );
	p.Insert ( "ClearTable", true );
	p.Insert ( "Background", false );
	p.Insert ( "Batch", false );
	p.Insert ( "CloseOnErrors", false );
	return p;
	
endfunction 

function Result () export
	
	p = new Structure ();
	p.Insert ( "Address", "" );
	p.Insert ( "ClearTable", true );
	p.Insert ( "Completed" );
	return p;
	
endfunction 

&atclient
procedure Open ( Params, Caller ) export
	
	callback = callbackParams ( Params, Caller );
	p = new Structure ( "Caller, Filling", Caller.UUID, Params );
	OpenForm ( "CommonForm.Filling", p, Caller, , , , new CallbackDescription ( "Filling", ThisObject, callback ) );
	
endprocedure 

&atclient
function callbackParams ( Params, Caller )
	
	p = new Structure ();
	p.Insert ( "Report", Params.Report );
	p.Insert ( "Variant", Params.Variant );
	p.Insert ( "Processor", Params.Processor );
	p.Insert ( "Caller", Caller );
	return p;
	
endfunction 

&atclient
procedure Filling ( Result, Params ) export
	
	if ( Result = undefined ) then
		return;
	endif;
	RunCallback ( new CallbackDescription ( Params.Processor, Params.Caller, Params ), Result );

endprocedure 

&atclient
procedure ProcessData ( Params, Caller ) export
	
	id = Caller.UUID;
	resultAddress = "";
	FillerSrv.StartProcess ( Params, id, resultAddress );
	result = Filler.Result ();
	result.Address = resultAddress;
	callback = callbackParams ( Params, Caller );
	p = new Structure ( "Callback, Result", callback, Result );
	Progress.Open ( id, Caller, new CallbackDescription ( "ProcessComplete", ThisObject, p ) );
	
endprocedure

&atclient
procedure ProcessComplete ( Result, Params ) export
	
	Filler.Filling ( Params.Result, Params.Callback );
	
endprocedure 

&atserver
function Fetch ( Result ) export
	
	table = GetFromTempStorage ( Result.Address );
	if ( table = undefined
		or table.Count () = 0 ) then
		return undefined;
	else
		return table;
	endif;
	
endfunction