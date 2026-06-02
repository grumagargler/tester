
function CreateJob ( Request )
	
	params = Conversion.FromJSON ( Request.GetBodyAsString () );
	create ( params );
	response = new HTTPServiceResponse ( 200 );
	return response;
	
endfunction

procedure create ( Params )
	
	p = new Structure ( "Agent, Scenario, Application, Parameters, Computer, Memo, Schedule" );
	FillPropertyValues ( p, Params );
	TesterAgent.CreateJob ( p.Agent, p.Scenario, p.Application, p.Parameters, p.Computer, p.Memo, p.Schedule, undefined );
	
endprocedure
