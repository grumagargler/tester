
function Select ( From, How ) export
	
	exp = Libraries.Init ( "Regex" );
	result = exp.Select ( From, How );
	return Conversion.FromJSON ( result );

endfunction

function Test ( What, How ) export
	
	exp = Libraries.Init ( "Regex" );
	return exp.Test ( What, How );

endfunction

function Replace ( What, How, Replacement ) export
	
	exp = Libraries.Init ( "Regex" );
	return exp.Replace ( What, How, Replacement );

endfunction