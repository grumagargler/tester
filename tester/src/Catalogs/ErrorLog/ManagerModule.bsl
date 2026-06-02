
function Add ( Debug, Error, Screenshot ) export
	
	obj = Catalogs.ErrorLog.CreateItem ();
	obj.Compose ( Debug, Error, Screenshot );
	return new Structure ( "Log, Error, Scenario, Line", obj.Ref, obj.FullText, obj.Scenario, obj.Line );
	
endfunction
