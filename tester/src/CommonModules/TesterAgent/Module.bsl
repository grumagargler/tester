
function GetWork () export
	
	if ( Jobs.GetBackground ( "Exchange" ) <> undefined ) then
		return undefined;
	endif;
	job = takeJob ();
	if ( job = undefined ) then
		return undefined;
	else
		return new Structure ( "Job, Parameters, Scenarios", job.Job, job.Parameters, getScenarios ( job ) );
	endif;
	
endfunction

function takeJob ()
	
	timeout = true;
	attempts = 15;
	BeginTransaction ();
	for attempt = 1 to attempts do
		try
			lockJobs ();
			timeout = false;
			break;
		except
			RollbackTransaction ();
			BeginTransaction ();
		endtry;
	enddo;
	if ( timeout ) then
		RollbackTransaction ();
		willTryAnotherTime = undefined;
		return willTryAnotherTime;
	endif;
	job = getJob ();
	if ( job <> undefined ) then
		start ( job.Job );
	endif;
	CommitTransaction ();
	return job;
	
endfunction

procedure lockJobs ()
	
	lock = new DataLock ();
	item = lock.Add ( "InformationRegister.Jobs" );
	item.Mode = DataLockMode.Exclusive;
	lock.Lock ();
	
endprocedure

function getJob ()
	
	s = "
	|select top 1 Jobs.Job as Job, Jobs.Job.Parameters as Parameters
	|from InformationRegister.Jobs as Jobs
	|where Jobs.Agent = &Agent
	|and Jobs.Computer in ( value ( Catalog.Computers.EmptyRef ), &Computer )
	|order by Jobs.Created
	|";
	q = new Query ( s );
	q.SetParameter ( "Agent", SessionParameters.User );
	q.SetParameter ( "Computer", SessionData.Computer () );
	table = q.Execute ().Unload ();
	return ? ( table.Count () = 0, undefined, table [ 0 ] );
	
endfunction

function getScenarios ( Job )
	
	s = "
	|select Scenarios.Scenario as Scenario, Scenarios.Application as Application,
	|	Scenarios.LineNumber as LineNumber, Scenarios.Options as Options
	|from Document.Job.Scenarios as Scenarios
	|where Scenarios.Ref = &Job
	|order by Scenarios.LineNumber
	|";
	q = new Query ( s );
	q.SetParameter ( "Job", Job.Job );
	return Collections.Serialize ( q.Execute ().Unload () );
	
endfunction

procedure start ( Job )
	
	TesterAgent.AgentStatus ( Enums.AgentStatuses.Busy );
	SetPrivilegedMode ( true );
	r = InformationRegisters.Jobs.CreateRecordManager ();
	r.Job = Job;
	r.Delete ();
	r = InformationRegisters.AgentJobs.CreateRecordManager ();
	r.Job = Job;
	r.Started = CurrentSessionDate ();
	r.Start = CurrentUniversalDateInMilliseconds ();
	r.Session = SessionParameters.Session;
	r.Status = Enums.JobStatuses.Running;
	r.Write ();
	
endprocedure

procedure AgentStatus ( val Status ) export
	
	SetPrivilegedMode ( true );
	r = InformationRegisters.AgentStatuses.CreateRecordManager ();
	session = SessionParameters.Session;
	r.Session = session;
	r.Read ();
	if ( r.Status = Status ) then
		return;
	endif;
	r.Session = session;
	r.Status = Status;
	ExchangeKillers.Write ( r );
	
endprocedure

procedure Finish ( val Job ) export
	
	SetPrivilegedMode ( true );
	r = InformationRegisters.AgentJobs.CreateRecordManager ();
	r.Job = Job;
	r.Read ();
	r.Finished = CurrentSessionDate ();
	finish = CurrentUniversalDateInMilliseconds ();
	r.Finish = finish;
	r.Duration = finish - r.Start;
	r.Status = ? ( hasErrors ( Job ), Enums.JobStatuses.Fault, Enums.JobStatuses.Passed );
	r.Write ();
	TesterAgent.AgentStatus ( Enums.AgentStatuses.Available );
	
endprocedure

function hasErrors ( Job )
	
	s = "
	|select top 1 1
	|from Catalog.ErrorLog as Log
	|where Log.Job = &Ref
	|";
	q = new Query ( s );
	q.SetParameter ( "Ref", Job );
	return not q.Execute ().IsEmpty ();
	
endfunction

procedure StartScenario ( val Job, val Row ) export
	
	SetPrivilegedMode ( true );
	r = InformationRegisters.AgentScenarios.CreateRecordManager ();
	r.Job = Job;
	r.Row = Row;
	r.Started = CurrentSessionDate ();
	r.Write ();
	
endprocedure

procedure FinishScenario ( val Job, val Row ) export
	
	SetPrivilegedMode ( true );
	r = InformationRegisters.AgentScenarios.CreateRecordManager ();
	r.Job = Job;
	r.Row = Row;
	r.Read ();
	r.Finished = CurrentSessionDate ();
	r.Write ();
	
endprocedure

procedure Create ( Job, Agent, Date, Computer ) export
	
	SetPrivilegedMode ( true );
	r = InformationRegisters.AgentJobs.CreateRecordManager ();
	r.Job = Job;
	r.Status = Enums.JobStatuses.Pending;
	r.Write ();
	r = InformationRegisters.Jobs.CreateRecordManager ();
	r.Job = Job;
	r.Agent = Agent;
	r.Created = Date;
	r.Computer = Computer;
	r.Write ();
	
endprocedure

procedure Testing ( Job ) export
	
	BeginTransaction ();
	lockJob ( Job );
	skip = not DF.Pick ( Job, "IgnoreCompletion" )
	and jobActive ( Job );
	if ( skip ) then
		RollbackTransaction ();
		return;
	endif;
	obj = Job.GetObject ().Copy ();
	obj.Date = CurrentSessionDate ();
	obj.Mode = Enums.Running.Now;
	obj.Job = Job;
	obj.Memo = "";
	obj.Write ();
	TesterAgent.Create ( obj.Ref, obj.Agent, obj.Date, obj.Computer );
	CommitTransaction ();
	
endprocedure

procedure lockJob ( Job )
	
	lock = new DataLock ();
	item = lock.Add ( "Document.Job" );
	item.Mode = DataLockMode.Exclusive;
	item.SetValue ( "Ref", Job );
	lock.Lock ();
	
endprocedure

function jobActive ( Job )
	
	s = "
	|select top 1 1
	|from Document.Job as Jobs
	|	//
	|	// AgentJobs
	|	//
	|	join InformationRegister.AgentJobs as AgentJobs
	|	on AgentJobs.Job = Jobs.Ref
	|	and AgentJobs.Status in ( value ( Enum.JobStatuses.Pending ), value ( Enum.JobStatuses.Running ) )
	|where Jobs.Job = &Job
	|and not Jobs.DeletionMark
	|order by Jobs.Date desc
	|";
	q = new Query ( s );
	q.SetParameter ( "Job", Job );
	return not q.Execute ().IsEmpty ();
	
endfunction

function Canceled ( val Job ) export
	
	s = "
	|select top 1 1
	|from InformationRegister.AgentJobs as AgentJobs
	|where AgentJobs.Job = &Job
	|and AgentJobs.Status = value ( Enum.JobStatuses.Removed )
	|";
	q = new Query ( s );
	q.SetParameter ( "Job", Job );
	return not q.Execute ().IsEmpty ();
	
endfunction

procedure CreateJob ( val Agent, val Scenarios, val Application, val Parameters, val Computer, val Memo,
	val Schedule, val Parent ) export
	
	obj = Documents.Job.CreateDocument ();
	obj.Date = CurrentSessionDate ();
	obj.Job = Parent;
	obj.Agent = findAgent ( Agent );
	if ( Computer <> undefined ) then
		obj.Computer = findComputer ( Computer );
	endif;
	obj.Creator = SessionParameters.User;
	obj.Parameters = Conversion.ToJSON ( Parameters, false );
	obj.Memo = Memo;
	if ( Schedule = undefined ) then
		obj.Mode = Enums.Running.Now;
	else
		obj.Schedule = jobSchedule ( Schedule );
		obj.Mode = Enums.Running.Schedule;
	endif;
	app = EnvironmentSrv.FindApplication ( Application );
	stringType = Type ( "String" );
	if ( TypeOf ( Scenarios ) = stringType ) then
		row = obj.Scenarios.Add ();
		p = ParametersService.JobRecord ();
		p.Scenario = Scenarios;
		row.Scenario = findScenario ( Scenarios, Application );
		row.Application = app;
		row.Options = Conversion.ToJSON ( p );
	else
		for each record in Scenarios do
			row = obj.Scenarios.Add ();
			scenario = record.Scenario;
			if ( TypeOf ( scenario ) = stringType ) then
				row.Scenario = findScenario ( scenario, Application );
			else
				row.Scenario = scenario;
			endif;
			row.Application = app;
			row.Options = Conversion.ToJSON ( record );
		enddo;
	endif;
	obj.Write ();
	
endprocedure

function findAgent ( Agent )
	
	ref = Catalogs.Users.FindByDescription ( Agent, true );
	if ( ref.IsEmpty () ) then
		raise Output.AgentNotFound ( new Structure ( "Agent", Agent ) );
	endif;
	return ref;
	
endfunction

function findComputer ( Computer )
	
	ref = Catalogs.Computers.FindByDescription ( Computer, true );
	if ( ref.IsEmpty () ) then
		raise Output.ComputerNotFound ( new Structure ( "Computer", Computer ) );
	endif;
	return ref;
	
endfunction

function findScenario ( Scenario, Application )
	
	ref = RuntimeSrv.FindScenario ( Scenario, undefined, Application, undefined, true );
	if ( ref = undefined ) then
		raise Output.ScenarioNotFound ( new Structure ( "Name", Scenario ) );
	endif;
	return ref;
	
endfunction

function jobSchedule ( Schedule )
	
	type = TypeOf ( Schedule );
	if ( type = Type ( "Date" ) ) then
		date = Schedule;
		begin = BegOfDay ( date );
		time = Date ( 1, 1, 1 ) + ( date - begin );
		plan = new JobSchedule ();
		plan.BeginDate = begin;
		plan.BeginTime = time;
		return Conversion.ObjectToJSON ( plan );
	elsif ( type = Type ( "JobSchedule" ) ) then
		return Conversion.ObjectToJSON ( Schedule );
	else
		return Schedule;
	endif;
	
endfunction
