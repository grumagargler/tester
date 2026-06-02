
procedure RunExchange ( Load = true, Unload = true ) export
	
	activeJobs = ScheduledJobs.GetScheduledJobs ( new Structure ( "Key", Metadata.ScheduledJobs.Exchange.Key ) );
	if ( activeJobs.Count () > 1 ) then
		Output.AlreadyRunExchangeFull ();
		return;
	endif;
	p = new Structure ();
	p.Insert ( "Node", Catalogs.Exchange.EmptyRef () );
	p.Insert ( "Update", false );
	p.Insert ( "IsJob", true );
	p.Insert ( "ID", "" );
	DataProcessors.ExchangeData.Load ( p );
	if ( p.Update ) then
		DataProcessors.Update.Run ( p.ID );
	else
		DataProcessors.ExchangeData.Unload ( p );
	endif;
	
endprocedure

procedure SendEMail ( Data ) export 
	
	if ( Data.TableReceivers <> undefined ) then
		mail = new InternetMail ();
		try
			mail.Logon ( Data.Profile, Data.Protocol );	
		except
			Output.ErrorLogonInternetMail ( new Structure ( "ErrorDescription", ErrorDescription () ) );
			return;
		endtry;
		sendReport ( Data, mail );
	endif; 
	mail.Logoff ();
	
endprocedure

procedure sendReport ( Data, Mail )	
	
	for each receiver in Data.TableReceivers do
		msg = getEmailMessage ( Data.Profile.SMTPUser, receiver, Data.Theme, Data.TextMessage );
		msg.To.Add ( receiver.EmailAddress );
	enddo;
	recipients = mail.Send ( msg );
	if ( Recipients.Count () = 0 ) then
		return;
	else
		checkRecipients ( recipients ); 	
	endif;
			
endprocedure
	
procedure checkRecipients ( Recipients )
	
	for each item in Recipients do
		p = new Structure ();
		p.Insert ( "EMailUnLoad", item.Key );
		p.Insert ( "Error", item.Value ); 
		Output.IncorrectReportRecipients ();
	enddo;
	
endprocedure 

function getEmailMessage ( User, DataReceiver, Theme, TextMessage ) export
	
	msg = new InternetMailMessage ();
	msg.From = User;
	msg.Subject = Theme;
	msg.SenderName = User;
	if ( ValueIsFilled ( TextMessage ) ) then
		msg.Texts.Add ( TextMessage, InternetMailTextType.HTML );
	endif;
	return msg;
	
endfunction

procedure WSRead ( Params ) export
	
	proxy = getProxy ( Params );
	Output.ConnectToWS ();	
	error = proxy.Begin ( Params.Node, Params.Description, Params.Incoming, Params.Outgoing );
	Params.Result = not error;
	if ( error ) then
		return;
	endif;
	Output.ReadWS ();
	data = proxy.Read ( Params.Node );
	binary = data.Get ();
	binary.Write ( Params.Path );
	
endprocedure

procedure WSWrite ( Params ) export 	
	
	proxy = getProxy ( Params );
	Output.ConnectToWS ();
	error = proxy.Begin ( Params.Node, Params.Description, Params.Incoming, Params.Outgoing );
	Params.Result = not error;
	if ( error ) then
		return;
	endif;
	Output.WriteWS ();
	binData = new BinaryData ( Params.Path );
	data = new ValueStorage ( binData, new Deflation ( 9 ) );
	proxy.Write ( Params.Node, data, Params.FileExchange );
	
endprocedure

function getProxy ( Params )
	
	address = Params.WebService + "/ws/wsExchange.1cws?wsdl";
	definitions = new WSDefinitions ( address, Params.User, Params.Password, , 30 );
	uri = wsExchange ();
	proxy = new WSProxy ( definitions, URI, "Exchange", "ExchangeSoap", , 30 );
	proxy.User = Params.User;
	proxy.Password = Params.Password;
	return proxy;
	
endfunction

function wsExchange ()
    
    return "http://localhost/wsExchange";
    
endfunction

function CreateTempDir ( PostFix ) export
	
	folder = new File ( TempFilesDir () + PostFix );
	if ( folder.Exist () ) then
		EraseFile ( folder.FullName );
	endif;
	CreateDirectory ( folder.FullName );
	return ( folder.FullName + GetPathSeparator () );
	
endfunction

function GetTempDir ( ID ) export
	
	postfix = "ExchangeDataTemp_" + ID;
	f = new File ( TempFilesDir () + postfix );
	if ( f.Exist () ) then
		return ( f.FullName + GetPathSeparator () );
	else
		return ""; 
	endif;
	
endfunction 

procedure DeleteTempDirectory ( TempDirectory ) export
	
	EraseFile ( Mid ( TempDirectory, 1, ( StrLen ( TempDirectory ) - 1 ) ) );	
	
endprocedure

procedure EraseFile ( File ) export
	
	try
		DeleteFiles ( File );
	except
		Output.FileDeletionError ( new Structure ( "File, Error", File, ErrorDescription () ) );	
	endtry;
	
endprocedure

procedure RecordChanges ( Ref ) export
	
	SetPrivilegedMode ( true );
	registerScenario ( Ref );
	
endprocedure

procedure registerScenario ( Scenario )
	
	nodes = getNodes ( Scenario );
	ExchangePlans.RecordChanges ( nodes, Scenario );
	
endprocedure

function getNodes ( Ref )
	
	s = "
	|select
	|	Ref as Node
	|from
	|	ExchangePlan.Full
	|where
	|	not ThisNode
	|	and not DeletionMark
	|"; 
	q = new Query ( s );
	result = q.Execute ();
	return result.Unload ().UnloadColumn ( "Node" ); 
	
endfunction

procedure RereadData () export 
	
	Output.StartReReadData ();
	data = getData ();
	if ( data = undefined ) then
		return;
	endif;
	if ( data.FileMessage <> "" ) then
		id = "";
		try
			xml = new File ( data.FileMessage );
			id = Left ( Right ( xml.Path, 37 ), 36 );
		except
			return;
		endtry;
		Output.ExchangeLoadingAgain ( new Structure ( "Node, ID", data.Node, id ) );
		runRereadData ( data, id );
	endif;
	Output.CloseCurrentSession ();
	Connections.DisconnectMe ();
	
endprocedure

function getData ()

	s = "
	|select top 1 
	|	Ref as Ref, 
	|	Node as Node,
	|	FileMessage as FileMessage
	|from 
	|	Catalog.Exchange
	|where
	|	Node = &MasterNode
	|";
	query = new Query ( s );
	query.SetParameter ( "MasterNode", ExchangePlans.MasterNode () );
	result = query.Execute ();
	if ( result.IsEmpty () ) then
		return undefined;
	else
		selection = result.Select ();
		selection.Next ();
		return selection;
	endif;
	
endfunction 

procedure runRereadData ( Data, ID )
	
	p = new Structure ();
	p.Insert ( "Node", data.Ref );
	p.Insert ( "IsJob", true );
	p.Insert ( "Update", true );
	p.Insert ( "ID", ID );
	Output.ReReadLoad ();
	DataProcessors.ExchangeData.Load ( p );
	Output.ReReadUnLoad ();
	DataProcessors.ExchangeData.UnLoad ( p );
	
endprocedure

procedure WriteLog ( Text ) export
	
	WriteLogEvent ( "Exchange", EventLogLevel.Information, , , Text );
	
endprocedure
