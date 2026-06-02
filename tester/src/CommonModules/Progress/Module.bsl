&atclient
procedure Open ( JobKey, FormOwner = undefined, Notification = undefined, ShowStatus = false, ShowMessages = 0 ) export
	
	p = new Structure ();
	p.Insert ( "JobKey", JobKey );
	p.Insert ( "ShowStatus", ShowStatus );
	p.Insert ( "ShowMessages", ShowMessages );
	if ( FormOwner = undefined ) then
		mode = FormWindowOpeningMode.LockWholeInterface;
		if ( Notification = undefined ) then
			receiver = undefined;
		else
			module = Notification.Module;
			if ( TypeOf ( module ) = Type ( "ClientApplicationForm" ) ) then
				receiver = module.UUID;
			endif;
		endif;
	else
		mode = FormWindowOpeningMode.LockOwnerWindow;
		receiver = FormOwner.UUID; 
	endif;
	p.Insert ( "MessageReceiver", receiver );
	OpenForm ( "CommonForm.Progress", p, FormOwner, , , , Notification, mode );

endprocedure 

&atserver
procedure Put ( Status, JobKey, Error = false ) export
	
	r = InformationRegisters.Jobs.CreateRecordManager ();
	r.JobKey = JobKey;
	r.Status = Status;
	r.Error = Error;
	r.Write ();
	
endprocedure 
