&atclient
var Completed;
&atclient
var Messages;
&atclient
var ClosingStarted;

// *****************************************
// *********** Form events

&atserver
procedure OnCreateAtServer ( Cancel, StandardProcessing )
	
	initStatus ();
	
endprocedure

&atserver
procedure initStatus ()
	
	Status = Output.Processing ();
	
endprocedure 

&atclient
procedure OnOpen ( Cancel )
	
	init ();
	if ( Parameters.ShowStatus ) then
		AttachIdleHandler ( "checkStatus", 1 );
	else
		AttachIdleHandler ( "checkFinish", 1 );
	endif;
	
endprocedure

&atclient
procedure init ()

	Completed = false;
	ClosingStarted = false;

endprocedure

&atclient
procedure checkStatus () export
	
	currentStatus = "";
	error = false;
	active = getStatus ( Parameters.JobKey, currentStatus, error, Messages );
	if ( active ) then
		if ( currentStatus <> "" and currentStatus <> Status ) then
			Status = currentStatus;
		endif; 
	else
		DetachIdleHandler ( "checkStatus" );
		if ( error ) then
			Status = currentStatus;
		endif;
		showMessages ( error );
	endif; 
	
endprocedure 

&atservernocontext
function getStatus ( val JobKey, Status, Error, Messages )
	
	failed = false;
	active = jobIsActive ( JobKey, Messages, failed );
	if ( failed ) then
		Status = Output.JobFailed ();
		Error = true;
	else
		data = InformationRegisters.Jobs.Get ( new Structure ( "JobKey", JobKey ) );
		Status = data.Status;
		Error = data.Error;
	endif;
	return active;
	
endfunction

&atservernocontext
function jobIsActive ( val JobKey, Messages, Failed )
	
	Failed = false;
	job = Jobs.GetBackground ( JobKey, false );
	if ( job = undefined ) then
		return false;
	elsif ( job.State = BackgroundJobState.Active ) then
		return true;
	else
		Failed = ( job.State = BackgroundJobState.Failed );
		scope = getMessages ( job.GetUserMessages () );
		exception = job.ErrorInfo;
		if ( exception <> undefined ) then
			scope.Add ( exceptionMessage ( exception ) );
		endif;
		if ( scope.Count () > 0 ) then
			Messages = scope;
		endif; 
		return false;
	endif;
	
endfunction

&atservernocontext
function getMessages ( Messages )
	
	list = new Array ();
	limit = Messages.UBound ();
	for i = 0 to limit do
		duplicate = false;
		msg = Messages [ i ];
		undefinedKey = not ValueIsFilled ( msg.DataKey );
		for j = i + 1 to limit do
			next = Messages [ j ];
			if ( next.Text = msg.Text
				and next.Field = msg.Field
				and next.DataPath = msg.DataPath
				and ( next.DataKey = msg.DataKey
					or undefinedKey )
			) then
				duplicate = true;
				break;
			endif;
		enddo;
		if ( not duplicate ) then
			if ( not undefinedKey ) then
				msg.Text = msg.Text + " (" + msg.DataKey + ")";
			endif;
			list.Add ( msg );
		endif;
	enddo;
	return list;
	
endfunction

&atservernocontext
function exceptionMessage ( Exception )
	
	msg = new UserMessage ();
	msg.Text = Exception.Description;
	return msg;
	
endfunction

&atclient
procedure showMessages ( Error )
	
	havingMessages = Messages <> undefined;
	if ( not ( Error or havingMessages ) ) then
		Completed = true;
		closeProgress ();
		return;
	endif;
	target = Parameters.MessageReceiver;
	noTarget = ( target = undefined );
	showHere = noTarget or ( Parameters.ShowMessages = Enum.ShowMessagesInSeparateWindow () );
	if ( showHere ) then
		if ( havingMessages ) then
			for each msg in Messages do
				MessagesList.Add ( , msg.Text );
			enddo;
		endif;
		if ( Error ) then
			Title = Output.ErrorTitle ();
			MessagesList.Add ( , Status );
		else
			Title = Output.InfoDetected ();
		endif;
		Items.CloseMessages.DefaultButton = true;
		Items.Progress.Visible = false;
		Items.Messages.Visible = true;
	else
		if ( havingMessages ) then
			for each msg in Messages do
				msg.TargetID = target; 
				msg.Message ();
			enddo;
		endif;
		if ( Error ) then
			msg = new UserMessage ();
			msg.TargetID = target;
			msg.Text = Status;
			msg.Message ();
		endif;
		closeProgress ();
	endif;
	
endprocedure 

&atclient
procedure closeProgress ()
	
	ClosingStarted = true;
	Close ( Completed );
	
endprocedure 

&atclient
procedure checkFinish () export
	
	failed = false;
	if ( jobIsActive ( Parameters.JobKey, Messages, failed ) ) then
		return;
	endif; 
	DetachIdleHandler ( "checkFinish" );
	if ( failed ) then
		Status = Output.JobFailed ();
	endif;
	showMessages ( failed );
	
endprocedure 

&atclient
procedure BeforeClose ( Cancel, Exit, MessageText, StandardProcessing )
	
	if ( ClosingStarted ) then
		return;
	endif; 
	Cancel = true;
	ClosingStarted = true;
	AttachIdleHandler ( "startClosing", 0.1, true );
	
endprocedure

&atclient
procedure startClosing ()
	
	// Bug workaround to prevent 8.3.14 failing into infinite loop
	Close ( Completed );
	
endprocedure
