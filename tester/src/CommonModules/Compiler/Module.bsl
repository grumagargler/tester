function Build ( val Scenario, val ProgramCode = undefined, val ServerOnly = false ) export
	
	processor = DataProcessors.Compiler.Create ();
	processor.Scenario = Scenario;
	processor.Script = ProgramCode;
	processor.ServerOnly = ServerOnly;
	return processor.Compile ();
	
endfunction

function Call ( val Scenario, val Module, val IsVersion, val Application, val InsideFolder, val OnServer ) export
	
	parent = ? ( InsideFolder, getParent ( Module, IsVersion ), undefined );
	ref = RuntimeSrv.FindScenario ( Scenario, getApplication ( Module, IsVersion ), Application, parent );
	if ( ref = undefined ) then
		return undefined;
	endif;
	processor = DataProcessors.Compiler.Create ();
	processor.Scenario = ref;
	processor.ServerOnly = OnServer;
	result = new Structure ( "Compilation, Scenario", processor.Compile (), ref );
	return result;
	
endfunction

function getParent ( Module, IsVersion )
	
	s = "
	|select case when Scenarios.Tree then Scenarios.Ref else Scenarios.Parent end as Parent
	|from Catalog.Scenarios as Scenarios
	|";
	if ( IsVersion ) then
		s = s + "
		|where Scenarios.Ref in ( select top 1 Scenario from Catalog.Versions where Code = &Module )
		|";
	else
		s = s + "
		|where Scenarios.Code = &Module
		|";
	endif;
	q = new Query ( s );
	q.SetParameter ( "Module", Module );
	return q.Execute ().Unload () [ 0 ].Parent;
	
endfunction

function getApplication ( Module, IsVersion )
	
	s = "
	|select top 1 Scenarios.Application as Application
	|from Catalog." + ? ( IsVersion, "Versions", "Scenarios" ) + " as Scenarios
	|where Scenarios.Code = &Module
	|";
	q = new Query ( s );
	q.SetParameter ( "Module", Module );
	application = q.Execute ().Unload () [ 0 ].Application;
	return ? ( application.IsEmpty (), EnvironmentSrv.GetApplication (), application );
	
endfunction

function SyntaxCode ( val ProgramCode ) export
	
	processor = DataProcessors.Compiler.Create ();
	processor.Script = ProgramCode;
	processor.ServerOnly = false;
	return processor.SyntaxCode ();
	
endfunction
