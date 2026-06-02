procedure Listen () export
	
	#if ( ThinClient or ThickClientManagedApplication ) then
		if ( IAmAgent ) then
			AttachIdleHandler ( "agentListener", 5, true );
		endif;
	#endif
	
endprocedure

procedure Serve () export
	
	#if ( ThinClient or ThickClientManagedApplication ) then
		try
			work = TesterAgent.GetWork ();
			if ( work <> undefined ) then
				job = work.Job;
				startServing ( job );
				table = Collections.DeserializeTable ( work.Scenarios );
				try
					proceed ( work, table );
				except
					Output.AgentRunnerError ( new Structure ( "Job, Error", job, ErrorDescription () ) );
				endtry;
				stopServing ();
			endif;
		except
			Output.AgentRunnerError ( new Structure ( "Job, Error", job, ErrorDescription () ) );
		endtry;
		AgentRunner.Listen ();
	#endif
	
endprocedure

procedure startServing ( Job )
	
	RunningDelegatedJob = true;
	ВыполняетсяДелегированноеЗадание = true;
	CurrentDelegatedJob = new Structure ( "Job, Row", Job );
		
endprocedure

procedure proceed ( Work, Table )
	
	job = Work.Job;
	params = ? ( Work.Parameters = "", "", Conversion.FromJSON ( Work.Parameters ) ); 
	for each row in Table do
		error = undefined;
		ln = row.LineNumber;
		CurrentDelegatedJob.Row = ln;
		TesterAgent.StartScenario ( job, ln );
		try
			options = getJobOptions ( row );
			applyOptionsBeforeExec ( options );
			try
				Test.Exec ( row.Scenario, row.Application, , , , , params );
			except
			endtry;
			applyOptionsAfterExec ( options );
		except
			error = ErrorDescription ();
		endtry;
		TesterAgent.FinishScenario ( job, ln );
		splitSessions ();
		if ( error <> undefined ) then
			raise error;
		endif;
	enddo;
	
endprocedure

function getJobOptions ( Row )
	
	try
		options = Conversion.FromJSON ( Row.Options );
	except
		options = ParametersService.JobRecord ();
	endtry;
	return options;
	
endfunction

procedure applyOptionsBeforeExec ( Options )
	
	app = Options.PinApplication;
	if ( app <> undefined ) then
		PinApplication ( app );
	endif;
	version = Options.PinVersion;
	if ( version <> undefined ) then
		PinApplication ( version );
	endif;
	
endprocedure

procedure applyOptionsAfterExec ( Options )
	
	try
		if ( options.CloseAllAfter ) then
			CloseAll ();
		endif;
		if ( options.Disconnect ) then
			Disconnect ();
		endif;
	except
	endtry;
	
endprocedure

procedure splitSessions ()
	
	ExternalLibrary.Pause ( 2 );
	
endprocedure

procedure stopServing ()
	
	TesterAgent.Finish ( CurrentDelegatedJob.Job );
	RunningDelegatedJob = false;
	ВыполняетсяДелегированноеЗадание = false;
	CurrentDelegatedJob = undefined;
		
endprocedure
