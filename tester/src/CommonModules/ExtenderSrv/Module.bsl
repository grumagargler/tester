
function CallServer ( Debug, Scenario, Params = undefined, Application = undefined ) export
	
	return Runtime.Perform ( Scenario, Params, Application, false, Debug );
	
endfunction

function ВызватьСервер ( Debug, Scenario, Params = undefined, Application = undefined ) export
	
	return CallServer ( Debug, Scenario, Params, Application );
	
endfunction

function RunServer ( Debug, Scenario, Params = undefined, Application = undefined ) export
	
	return Runtime.Perform ( Scenario, Params, Application, true, Debug );
	
endfunction

function ПозватьСервер ( Debug, Scenario, Params = undefined, Application = undefined ) export
	
	return RunServer ( Debug, Scenario, Params, Application );
	
endfunction

procedure CheckTable ( Debug, Table, Standard, Params = undefined, Options = undefined ) export
	
	TableProcessor.CompareVTAndTable ( Debug, Table, Standard, Params, Options );
	
endprocedure 

procedure ПроверитьТаблицу ( Debug, Table, Standard, Params = undefined, Options = undefined ) export
	
	CheckTable ( Debug, Table, Standard, Params, Options );
	
endprocedure 
