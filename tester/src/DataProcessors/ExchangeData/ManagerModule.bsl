	
procedure Unload ( Params ) export
	
	dp = getProcessor ();
	dp.Unload ( Params );
	
endprocedure

procedure Load ( Params ) export
	
	dp = getProcessor ();
	dp.Load ( Params );
	
endprocedure

function getProcessor ()
	
	return DataProcessors.ExchangeData.Create ();
	
endfunction