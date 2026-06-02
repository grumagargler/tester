
#if ( server or thickclientordinaryapplication or externalconnection ) then
	
var TempDirectory;
var IsJob;
var ReadChangesConfiguration;
var CounterFiles;
var IDProcess;
var DataNodes;
var ThisNode;

procedure Unload ( Params ) export 
	
	init ( Params );
	fillDataNodes ( "Unload", Params );
	for each item in DataNodes do
		node = item.Key;
		data = item.Value;
		if ( node = ThisNode ) then
			continue;
		endif;                                   
		fileName = createFile ( data );
		if ( fileName = "" ) then
			continue;
		endif;
		Output.UnloadBegin ( new Structure ( "Node", data.Code ) );
		unloadFile ( data, fileName );
		Output.UnloadFinish ( new Structure ( "Node", data.Code ) );
		luckyUnload ( data.Ref );
		Exchange.EraseFile ( fileName );
	enddo;
	Exchange.DeleteTempDirectory ( TempDirectory );

endprocedure

procedure Load ( Params ) export
	
	init ( Params );
	if ( Params.Update ) then
		updateConfiguration ( Params );
	else			
		ReadChangesConfiguration = false;
		fillDataNodes ( "Load", Params );
		for each item in DataNodes do
			node = item.Key;
			data = item.Value;
			if ( node = ThisNode ) then
				continue;
			endif;
			Output.LoadDataFromNode ( new Structure ( "Node", Data.Code ) );
			CounterFiles = 0;
			loadFile ( data );
			if ( ReadChangesConfiguration ) then
				Params.Update = true;
				Params.ID = IDProcess;
				break;
			endif;
			Output.LoadDataFromNodeOver ( new Structure ( "Node", Data.Code ) );
			if ( CounterFiles = 0 ) then
				handleErrors ( Data );
			endif;
		enddo;
		if ( not Params.Update ) then
			Exchange.DeleteTempDirectory ( TempDirectory );
		endif;
	endif;
			
endprocedure

procedure init ( Params )
	
	IsJob = Params.IsJob;
	IDProcess = ? ( Params.ID = "", String ( new UUID () ), Params.ID );
	ThisNode = undefined;
	if ( Params.Update ) then
		TempDirectory = Exchange.GetTempDir ( Params.ID );
	else
		postfix = "ExchangeDataTemp_" + IDProcess;
		TempDirectory = Exchange.CreateTempDir ( postfix );
	endif;
	
endprocedure

procedure fillDataNodes ( Command, Params )
	
	s = "
	|// 
	|// Data nodes 
	|// 
	|select 
	|	Settings.Ref as Ref, Settings.Code as Code, Settings.Description as Description,
	|	Settings.DateLoad as DateLoad, Settings.DateUnload as DateUnload, Settings.EMailLoad as EMailLoad,
	|	Settings.EMailUnLoad as EMailUnLoad, Settings.FileMessage as FileMessage,
	|	Settings.FolderDiskLoadHandle as FolderDiskLoadHandle,  Settings.FolderDiskLoadJob as FolderDiskLoadJob,
	|	Settings.FolderDiskUnLoadHandle as FolderDiskUnLoadHandle, Settings.FolderDiskUnLoadJob as FolderDiskUnLoadJob,
	|	Settings.FolderFTPLoad as FolderFTPLoad, Settings.FolderFTPUnLoad as FolderFTPUnLoad,
	|	Settings.MaximumErrors as MaximumErrors, Settings.Node as Node,
	|	Settings.NumbersOfErrors as NumbersOfErrors, Settings.ExchangeTransport as ExchangeTransport,
	|	Settings.PasswordEmail as PasswordEmail, Settings.PasswordFTPLoad as PasswordFTPLoad,
	|	Settings.PasswordFTPUnLoad as PasswordFTPUnLoad, Settings.PasswordWebService as PasswordWebService,
	|	Settings.Periodicity as Periodicity, Settings.PortFTPLoad as PortFTPLoad,
	|	Settings.PortFTPUnLoad as PortFTPUnLoad, Settings.PortIncoming as PortIncoming,
	|	Settings.PortOutgoing as PortOutgoing, Settings.PrefixFileName as PrefixFileName,
	|	Settings.SendedEMailError as SendedEMailError, Settings.SendEMailErrors as SendEMailErrors,
	|	Settings.ServerFTPLoad as ServerFTPLoad, Settings.ServerFTPUnLoad as ServerFTPUnLoad,
	|	Settings.ServerIncoming as ServerIncoming, Settings.ServerOutgoing as ServerOutgoing,
	|	Settings.ServerTimeOut as ServerTimeOut, Settings.Update as Update,
	|	Settings.UseAutomatic as UseAutomatic, Settings.UserEmail as UserEmail,
	|	Settings.UserFTPLoad as UserFTPLoad, Settings.UserFTPUnLoad as UserFTPUnLoad,
	|	Settings.UserWebService as UserWebService, Settings.UseSSLOutgoing as UseSSLOutgoing,
	|	Settings.UseSSLIncoming as UseSSLIncoming, Settings.UseStandartFTPClient as UseStandartFTPClient, 
	|	Settings.WebService as WebService, Full.ThisNode as ThisNode, Full.SentNo as SentNo, 
	|	Full.ReceivedNo as ReceivedNo, Settings.Protocol as Protocol, Settings.PassiveModeFTP as PassiveModeFTP
	|from
	|	Catalog.Exchange as Settings
	|		// 
	|		// Exchange plan ""Full""
	|		// 
	|		left join ExchangePlan.Full as Full
	|		on Settings.Node = Full.Ref 
	|where
	|	case 
	|		when &Node = value ( ExchangePlan.Full.EmptyRef )
	|			then true
	|		when Settings.Node = &Node
	|			then true
	|		when Settings.Node <> &Node and Full.ThisNode
	|			then true
	|		else 
	|			case when &IsJob = true then UseAutomatic else true end
	|			and 
	|			case
	|				when &IsMasterNode and ExchangeTransport = value ( Enum.ExchangeTransport.WebService ) 
	|					then false
	|				else true
	|			end
	|   		and
	|			case
	|				when &CheckTime // check time for unload
	|					then 
	|						case
	|							when ( Periodicity = value ( Enum.ExchangePeriodicity.Constant  ) ) then
	|								true
	|							when ( Periodicity = value ( Enum.ExchangePeriodicity.Daily ) ) and ( &Date > dateadd ( beginofperiod ( DateUnload, day ), day, 1 ) ) then
	|								true
	|							when ( Periodicity = value ( Enum.ExchangePeriodicity.Weekly ) ) and ( &Date > dateadd ( beginofperiod ( DateUnload, day ), week, 1 ) ) then
	|								true                                                                                                                                          	
	|							when ( Periodicity = value ( Enum.ExchangePeriodicity.Monthly ) ) and ( &Date > dateadd ( beginofperiod ( DateUnload, day ), month, 1 ) ) then
	|								true
	|							when ( Periodicity = value ( Enum.ExchangePeriodicity.Quarterly ) )	and ( &Date > dateadd ( beginofperiod ( DateUnload, day ), quarter, 1 ) ) then
	|								true
	|							when ( Periodicity = value ( Enum.ExchangePeriodicity.Yearly ) ) and ( &Date > dateadd ( beginofperiod ( DateUnload, day ), year, 1 ) ) then
	|								true
	|							else 
	|								false
	|						end
	|				else
	|					true
	|			end
	|	end 
	|";
	q = new Query ( s );
	q.SetParameter ( "IsJob", IsJob );
	q.SetParameter ( "Date", CurrentSessionDate () );
	q.SetParameter ( "IsMasterNode", ( ExchangePlans.MasterNode () = undefined ) );
	checkTime = ? ( IsJob and Command = "Unload", true, false ); 
	q.SetParameter ( "CheckTime", checkTime );
	q.SetParameter ( "Node", Params.Node );
	result = q.Execute ();
	selection = result.Select ();
	DataNodes = new Map ();
	while selection.Next () do
		data = fillData ( result.Columns, selection );
		DataNodes.Insert ( selection.Ref, data );
	enddo;
	defineThisNode ();
	
endprocedure

function fillData ( Columns, Selection )	
	
	p = new Structure ();
	for each column in Columns do
		p.Insert ( column.Name, Selection [ column.Name ] );	
	enddo;
	return p; 
	
endfunction

procedure defineThisNode ()
	
	for each item in DataNodes do
		data = item.Value;
		if ( data.ThisNode ) then
			ThisNode = item.Key;
			break;
		endif;	
	enddo;
	if ( ThisNode = undefined ) then
		raise Output.NotDefineThisNode ();
	endif;
	
endprocedure

function createFile ( Data )
	
	fileName = "";
	if ( Data.ExchangeTransport = Enums.ExchangeTransport.WebService ) then
		postfixDate = "";
	else
		cancel = checkFileExist ( Data );
		if ( cancel ) then
			return fileName; 
		endif; 
		postfixDate = "_Date_" + getUniversalTime ();
	endif;
	name = getFileName ( DataNodes [ ThisNode ].Code, Data.Code, Data.PrefixFileName );
	name = name + postfixDate;
	fileName = writeChanges ( name, Data.Node );
	return fileName;
	
endfunction

function checkFileExist ( Data )
	
	Output.CheckPreviousFileExchange ();
	name = getFileName ( DataNodes [ ThisNode ].Code, Data.Code, Data.PrefixFileName ) + "*";
	transport = Data.ExchangeTransport;
	cancel = false;
	if ( transport = Enums.ExchangeTransport.Email ) then
		// code ...
	elsif ( transport = Enums.ExchangeTransport.WebService ) then
		// code ...
	elsif ( transport = Enums.ExchangeTransport.FTP ) then
		cancel = checkFileFtp ( Data, name );
	elsif ( transport = Enums.ExchangeTransport.NetworkDisk ) then
		cancel = checkFileDisk ( Data, name );
	endif;
	return cancel; 
	
endfunction

function getFileName ( From, Target, Prefix )
	
	return "Message_from_" + From + "_to_" + Target + ? ( Prefix = "", "", "_" ) + Prefix;
	
endfunction

function checkFileFtp ( Data, Mask )
	
	if ( StrLen ( Data.FolderFTPUnLoad ) > 0 ) then
		folder = Data.FolderFTPUnLoad + "/";
	else
		folder = "";
	endif;
	cancel = checkStandartClient ( folder, Data, Mask );
	return cancel; 

endfunction

function checkStandartClient ( Folder, Data, Mask )
	
	cancel = false;
	ftp = getFTPClient ( Data );
	if ( ftp <> Undefined ) then
		ftp.SetCurrentDirectory ( folder );
		a = ftp.FindFiles ( ftp.GetCurrentDirectory (), Mask );
		for each item in a do
			cancel = checkDateExchange ( item.Name );
			if ( cancel ) then
				Output.ItWasFoundFileExchange ( new Structure ( "Node, File", Data.Code, item.Name ) );
			endif;
		enddo;		
	endif; 
	return cancel; 
	
endfunction

function getFTPClient ( Data )
	
	try
		ftp = new FTPConnection (
			Data.ServerFTPLoad, Data.PortFTPLoad, Data.UserFTPLoad,
			Data.PasswordFTPLoad, , Data.PassiveModeFTP, 30
		);
	except
		ftp = Undefined;
		Output.FTPConnectionError ( new Structure ( "Error", ErrorDescription () ) );
	endtry; 
	return ftp; 

endfunction

function checkDateExchange ( File )
	
	stringDate = Mid ( Right ( File, 18 ), 1, 14 );
	return ( Date ( stringDate ) < ToUniversalTime ( CurrentSessionDate () ) ); 
	
endfunction

function checkFileDisk ( Data, Mask )
	
	if ( IsJob ) then
		folder = Data.FolderDiskUnLoadJob;
	else
		folder = Data.FolderDiskUnLoadHandle;
	endif;
	cancelZip = findFilesDisk ( Data, folder, Mask, "*.zip" );
	cancelXml = findFilesDisk ( Data, folder, Mask, "*.xml" );
	return ( cancelZip or cancelXml );	

endfunction

function findFilesDisk ( Data, Folder, Mask, Postfix )
	
	files = FindFiles ( Folder, Mask + Postfix );	
	cancel = false;
	for each f in files do
		cancel = checkDateExchange ( f.Name );
		if ( cancel ) then
			Output.ItWasFoundFileExchange ( new Structure ( "Node, File", Data.Code, f.FullName ) );
		endif; 
	enddo;
	return cancel; 
	
endfunction 

function getUniversalTime ()
	
	return Format ( ToUniversalTime ( CurrentSessionDate () ), "DF=yyyyMMddHHmmss" );
	
endfunction

function writeChanges ( Name, Node )
	
	xml = TempDirectory + Name + ".xml";
	writerXML = new XMLWriter ();
	writerXML.OpenFile ( xml );
	writer = ExchangePlans.CreateMessageWriter ();
	Output.WritingChanges ();
	BeginTransaction ();
	ExchangeKillers.Wait ();
	writer.BeginWrite ( writerXML, Node );
	ExchangePlans.WriteChanges ( writer );
	writer.EndWrite ();
	CommitTransaction ();                                  
	Output.WritingChangesComplete ();
	writerXML.Close ();
	zip = TempDirectory + Name + ".zip";
	compressFile ( xml, zip );
	Exchange.EraseFile ( xml );
	return zip; 
	
endfunction

procedure compressFile ( Source, Archive )

	writer = new ZipFileWriter ();
	writer.Open ( Archive );  
	writer.Add ( Source ); 
	writer.Write ();
		
endprocedure 

procedure unloadFile ( Data, FileName )
	
	transport = Data.ExchangeTransport;
	if ( transport = Enums.ExchangeTransport.Email ) then
		unloadToEmail ( data, fileName );
	elsif ( transport = Enums.ExchangeTransport.FTP ) then
		unloadToFTP ( data, fileName );
	elsif ( transport = Enums.ExchangeTransport.NetworkDisk ) then
		unloadToDisk ( data, fileName );
	elsif ( transport = Enums.ExchangeTransport.WebService ) then
		unloadToWS ( data, fileName );	
	endif;
	
endprocedure

procedure unloadToEmail ( Data, FileName )
	
	Output.UnLoadToEmail ();
	email = getEmail ( Data );
	if ( email = Undefined ) then
		return;
	endif; 
	msg = new InternetMailMessage ();
	msg.From = Data.EMailLoad;
	msg.Subject =  "Exchange message from """ + DataNodes [ ThisNode ].Code + """ to """ + Data.Code + """ " + Data.PrefixFileName + ".";
	msg.Attachments.Add ( FileName );
	msg.To.Add ( Data.EMailUnLoad );
	msg.SenderName = DataNodes [ ThisNode ].Code + ? ( Data.PrefixFileName = "", "", "_" + Data.PrefixFileName );
	Output.SendingMail ();
	recipients = email.Send ( msg );
	checkRecipients ( Data, recipients );
	Output.MessageSent ( new Structure ( "Node", Data.Code ) );
	email.Logoff ();	
	
endprocedure

function getEmail ( Data )

	profile = getProfile ( Data );
	email = new InternetMail ();
	protocol = getMailProtocol ( Data );
	try
		Output.LogonToServerMail ();
		email.Logon ( profile, protocol );
		Output.LogonSuccess ();
	except 
		Output.ErrorConnectEmailProfile ( new Structure ( "Error", ErrorDescription () ) );
		email = undefined;
	endtry;
	return email; 
	
endfunction

function getProfile ( Data )
	
	p = new InternetMailProfile ();
	p.User = Data.UserEmail;
	p.Password = Data.PasswordEmail;
	p.SMTPServerAddress = Data.ServerOutgoing;
	p.SMTPUser = Data.UserEmail;
	p.SMTPPassword = Data.PasswordEmail;
	p.SMTPUseSSL = Data.UseSSLOutgoing;
	p.SMTPPort = Data.PortOutgoing;
	p.SMTPAuthentication = SMTPAuthenticationMode.Default;
	if ( Data.Protocol = PredefinedValue ( "Enum.Protocols.IMAP" ) ) then
		p.IMAPUser = Data.UserEmail;
		p.IMAPPassword = Data.PasswordEmail;
		p.IMAPPort = Data.PortIncoming;
		p.IMAPServerAddress = Data.ServerIncoming;
		p.IMAPUseSSL = Data.UseSSLIncoming;
	else
		p.POP3Port = Data.PortIncoming;
		p.POP3ServerAddress = Data.ServerIncoming;
		p.POP3UseSSL = Data.UseSSLIncoming;
	endif; 
	return p;

endfunction

function getMailProtocol ( Data )
	
	if ( Data.Protocol = Enums.Protocols.POP3 ) then
		protocol = InternetMailProtocol.POP3;
	elsif ( Data.Protocol = Enums.Protocols.IMAP ) then
		protocol = InternetMailProtocol.IMAP;
	else
		protocol = InternetMailProtocol.POP3;
	endif;
	return protocol;
	
endfunction

procedure checkRecipients ( Data, Recipients )
	
	if ( Recipients.Count () = 0 ) then
		return;
	endif;
	for each item in Recipients do
		p = new Structure ();
		p.Insert ( "Node", Data.Node );
		p.Insert ( "EMailUnLoad", item.Key );
		p.Insert ( "Error", item.Value ); 
		Output.IncorrectRecipients ( p );
	enddo; 
	
endprocedure 

procedure unloadToFTP ( Data, FileName )
	
	Output.UnLoadToFTP ();
	if ( StrLen ( Data.FolderFTPLoad ) > 0 ) then
		destination = Data.FolderFTPUnLoad + "/";
	else
		destination = "";
	endif;
	destination = destination + StrReplace ( FileName, TempDirectory, "" );
	ftp = getFTPClient ( Data );
	if ( ftp <> Undefined ) then
		ftp.Put ( FileName, destination );
		Output.MessageSent ( new Structure ( "Node", Data.Code ) );
	endif; 
	
endprocedure

procedure unloadToDisk ( Data, FileName )
	
	Output.UnloadToDisk ();
	destination = ? ( IsJob, Data.FolderDiskUnLoadJob, Data.FolderDiskUnLoadHandle ) + GetPathSeparator () + StrReplace ( FileName, TempDirectory, "" );
	FileCopy ( FileName, destination );
	Output.MessageSent ( new Structure ( "Node", Data.Code ) );
		
endprocedure

procedure unloadToWS ( Data, FileName )
	
	Output.UnLoadFromWS ();
	if ( ExchangePlans.MasterNode () = undefined ) then
		folder = TempFilesDir () + "ExchangeWebService_" + IDProcess + GetPathSeparator () ;
		FileCopy ( FileName, folder + IDProcess + ".zip" );
	else
		p = getWSPamas ( Data, FileName );
		p.Path = FileName;	
		Exchange.WSWrite ( p );
	endif;
	
endprocedure

function getWSPamas ( Data, FileName )
	
	p = new Structure ();
	p.Insert ( "Path", "" );
	p.Insert ( "Node", DataNodes [ ThisNode ].Code );
	p.Insert ( "Description", ThisNode.Description );
	p.Insert ( "Incoming", Data.ReceivedNo );
	p.Insert ( "Outgoing", Data.SentNo );
	p.Insert ( "WebService", Data.WebService );
	p.Insert ( "User", Data.UserWebService );
	p.Insert ( "Password", Data.PasswordWebService );
	p.Insert ( "Result", false );
	name = getFileName ( DataNodes [ ThisNode ].Code, Data.Code, Data.PrefixFileName ) + ".zip";
	p.Insert ( "FileExchange", name );
	return p; 

endfunction

procedure loadFile ( Data )
	
	transport = Data.ExchangeTransport;
	if ( transport = Enums.ExchangeTransport.Email ) then
		loadFromEmail ( Data );
	elsif ( transport = Enums.ExchangeTransport.FTP ) then
		loadFromFTP ( Data );
	elsif ( transport = Enums.ExchangeTransport.NetworkDisk ) then
		loadFromDisk ( Data );
	elsif ( transport = Enums.ExchangeTransport.WebService ) then
		loadFromWS ( Data );
	endif;
	if ( not ReadChangesConfiguration ) then
		checkCounterFiles ();		
	endif; 
	
endprocedure 

procedure loadFromEmail ( Data )
	
	email = getEmail ( Data );
	if ( email = Undefined ) then
		return;
	endif; 
	CounterFiles = 0;
	mails = email.Get ( false, , true );
	if ( mails.Count () > 0 ) then
		findMails ( Data, email, mails );
	endif;
	email.Logoff ();
			
endprocedure

procedure findMails ( Data, Email, Mails )
	
	msg = undefined;
	senderName = Data.Code + ? ( Data.PrefixFileName = "", "", "_" + Data.PrefixFileName );
	mailsDelete = new Array ();
	for i = 0 to ( Mails.Count () - 1 ) do
		mail = Mails [ i ];	
		if ( mail.SenderName <> senderName ) then
			continue;
		endif;
		if ( msg = undefined ) then
			msg = mail;
		elsif ( msg.PostingDate < mail.PostingDate ) then
			mailsDelete.Add ( msg.UID [ 0 ] );
			msg = mail;
		endif; 
	enddo;
	if ( msg <> undefined ) then
		readMail ( Data, msg );
		mailsDelete.Add ( msg.UID [ 0 ] );
	endif;
	deleteEmails ( Email, mailsDelete );
	
endprocedure

procedure readMail ( Data, Mail )
	
	attachment = Mail.Attachments [ 0 ];
	Output.MailReceived ();
	name = TempDirectory + attachment.Name;
	binary = attachment.Data; 
	binary.Write ( name );
	readTemp ( Data );
	
endprocedure

procedure deleteEmails ( Email, Mails )
	
	if ( Mails.Count () > 0 ) then
		Email.DeleteMessages ( Mails );
		Email.ClearDeletedMassages ();
	endif;	
	
endprocedure 

procedure loadFromFTP ( Data )

	if ( Data.UseStandartFTPClient ) then
		getFromFTP ( Data );
	else 
		return;
	endif;
	readTemp ( Data );
	
endprocedure

procedure getFromFTP ( Data )
	
	Output.LoadFromFTP ();
	mask = getMask ( Data );
	ftp = getFTPClient ( Data );
	if ( ftp <> Undefined ) then
		folder = ? ( StrLen ( Data.FolderFTPLoad ) > 0, ( Data.FolderFTPLoad + "/" ), "" );
		ftp.SetCurrentDirectory ( folder );
		files = ftp.FindFiles ( ftp.GetCurrentDirectory (), mask );
		for each file  in files do
			ftp.Get ( file.FullName, TempDirectory + file.Name );
			ftp.Delete ( file.FullName );
		enddo;
	endif;
		
endprocedure

procedure loadFromDisk ( Data )
	
	getFromDisk ( Data );
	readTemp ( Data );
		
endprocedure

procedure getFromDisk ( Data )	
	
	Output.LoadFromNetworkDisk ();
	mask = getMask ( Data );
	folder = ? ( IsJob, Data.FolderDiskLoadJob, Data.FolderDiskLoadHandle );
	copyToTemp ( folder, mask + ".zip" );
	copyToTemp ( folder, mask + ".xml" );
	
endprocedure

procedure copyToTemp ( Folder, Mask )
	
	files = FindFiles ( Folder, Mask );	
	for each f in files do
		FileCopy ( f.FullName, TempDirectory + f.Name );
		Exchange.EraseFile ( f.FullName );
	enddo;
	
endprocedure 

function getMask ( Data )
	
	postFix = ? ( Data.ExchangeTransport = Enums.ExchangeTransport.WebService, "*", "_Date_*" ); 
	mask = getFileName ( Data.Code, DataNodes [ ThisNode ].Code, Data.PrefixFileName ) + postFix; 
	return mask; 
	
endfunction 

procedure readTemp ( Data )	
	
	mask = getMask ( Data );
	files = FindFiles ( TempDirectory, mask );
	CounterFiles = 0;
	if ( files.Count () > 0 ) then
		for each f in Files do
			if ( f.Extension = ".zip" ) or ( f.Extension = ".xml" ) then
				read ( Data, f.FullName );
				if ( ReadChangesConfiguration ) then
					return;
				endif;
				CounterFiles = CounterFiles + 1;
			endif;
		enddo;
	endif;
	
endprocedure

procedure checkCounterFiles ()
	
	if ( CounterFiles = 0 ) then
		Output.NoNewExchangeFiles ();
	endif;	
	
endprocedure

procedure loadFromWS ( Data )
	
	Output.LoadFromWS ();
	if ExchangePlans.MasterNode () = undefined then
		result = getWSForMaster (); 
	else	
		path = TempDirectory + getFileName ( Data.Code, DataNodes [ ThisNode ].Code, Data.PrefixFileName ) + ".zip";
		p = getWSPamas ( Data, path );
		p.Path = path;
		Exchange.WSRead ( p );
		result = p.Result;
		// FileExchange = path;
	endif;
	if ( result ) then
		readTemp ( Data );
	endif; 
	
endprocedure

function getWSForMaster ()
	
	folder = TempFilesDir () + "ExchangeWebService_" + IDProcess + GetPathSeparator ();
	files = FindFiles ( folder, "Message*.zip", false );
	if ( files.Count () = 0 ) then
		result = false;
	else
		source = files [ 0 ].FullName;
		receiver = TempDirectory + files [ 0 ].Name;
		FileCopy ( source, receiver );
		result = true;	
	endif;
	return result; 
	
endfunction 
	 
procedure read ( Data, FileExchange )
	
	extension = Right ( FileExchange, 3 );
	if ( extension = "zip" ) then
		xml = unZipFile ( FileExchange );
	else
		xml = FileExchange;
	endif; 
	if ( xml = "" ) then
		return;
	endif;
	readChanges ( Data, xml );
	
endprocedure

function unZipFile ( FileExchange )	
	
	reader = new ZipFileReader ();
	reader.Open ( FileExchange );
	reader.ExtractAll ( TempDirectory );
	reader.Close ();
	xml = Mid ( FileExchange, 1, StrLen ( FileExchange ) - 3 ) + "xml";
	Exchange.EraseFile ( FileExchange );
	return xml;
	
endfunction 

procedure readChanges ( Data, FileXML )
	
	xmlReader = new XMLReader ();
	xmlReader.OpenFile ( FileXml );
	reader = ExchangePlans.CreateMessageReader ();
	Output.ReadingChanges ();
	reader.BeginRead ( xmlReader );
	try
		ExchangePlans.ReadChanges ( reader );
		reader.EndRead ();
		xmlReader.Close ();
		Output.ReceivedFromNode ( new Structure ( "Node", Data.Code ) );
	except
		xmlReader.Close ();
		checkUpdate ( Data, FileXML, ErrorDescription () );
		return;
	endtry;
	luckyReadData ( Data.Ref );	
	Exchange.EraseFile ( FileXml );
	Output.ReadingChangesComplete ( new Structure ( "Node", Data.Code ) );
	
endprocedure 

procedure checkUpdate ( Data, FileXML, Error )
	
	isUpdate = checkUpdateMessage ( Error );
	if ( isUpdate ) then
		if ( ExchangePlans.MasterNode () <> undefined ) then
			if ( ExchangePlans.MasterNode () = Data.Node and ConfigurationChanged () ) then
				readUpdateMessage ( Data.Ref, FileXML );
				ReadChangesConfiguration = true;
				Output.ReadChangesConfiguration ();
				return;
			endif;
		endif;
	endif;
	handleErrors ( Data );
	Output.ErrorReceivingData ( new Structure ( "Error, FileXml", Error, FileXml ) );
	Exchange.EraseFile ( FileXml );
	
endprocedure

function checkUpdateMessage ( Error )
	
	isUpdate = false;
	if ( StrFind ( Error, "Обновление может быть выполнено в режиме Конфигуратор." ) > 0 ) then
		isUpdate = true;
	elsif ( StrFind ( Error, "Update can be performed in Designer mode." ) > 0 ) then
		isUpdate = true;
	endif;
	return isUpdate; 
	
endfunction 

procedure handleErrors ( Data )
	
	if ( not Data.SendedEMailError ) then
		if ( IsJob ) then
			numbersOfErrors = Data.NumbersOfErrors + 1;
			writeNumbersError ( Data.Ref, numbersOfErrors );
			if ( numbersOfErrors >= Data.MaximumErrors ) then
				sendReport ( Data );
				writeSendedReport ( Data.Ref );
			endif; 
		endif; 	
	endif; 

endprocedure

procedure writeNumbersError ( Ref, NumbersOfErrors )
	
	s = new Structure ();
	s.Insert ( "NumbersOfErrors", NumbersOfErrors );
	Catalogs.Exchange.WriteAttributes ( Ref, s );	
	
endprocedure 

procedure sendReport ( Data )
	
	theme = Output.SubjectErrorReport ( new Structure ( "Node, CurrentDate", Data.Code, CurrentSessionDate () ) );
	if ( CounterFiles = 0 ) then
		s = Output.TextMessageEmailErrorReportNoNewExchangeFiles ( new Structure ( "Node, CurrentDate, MaximumErrors", Data.Code, CurrentSessionDate (), Data.MaximumErrors ) );
	else
		s = Output.TextMessageEmailErrorReport ( new Structure ( "Node, CurrentDate, Error, MaximumErrors", Data.Code, CurrentSessionDate (), "ERROR", Data.MaximumErrors ) );
	endif; 
	receivers = getReceivers ( Data );
	if ( receivers.Count () > 0 ) then
		p = new Structure ();
		p.Insert ( "Theme", theme );
		p.Insert ( "TextMessage", s );
		p.Insert ( "TableReceivers", receivers );
		p.Insert ( "Profile", getProfile ( Data ) );
		p.Insert ( "Protocol", getMailProtocol ( Data ) );
		Exchange.SendEMail ( p );
	endif; 
	
endprocedure

function getReceivers ( Data )
	
	s = "
	|select 
	|	User as User, 
	|	User.Email as EMailAddress
	|from 
	|	Catalog.Exchange.Receivers
	|where 
	|	Ref = &Ref
	|";
	query = new Query ( s );
	query.SetParameter ( "Ref", Data.Ref );		
	return ( query.Execute ().Unload () );

endfunction

procedure updateConfiguration ( Params )
	
	Output.WillBeRunRereadFileExchange ();
	fillDataNodes ( "Load", Params.Node );
	for each item in DataNodes do
		node = item.Key;
		data = item.Value;
		if ( node = ThisNode ) then
			continue;
		endif;
		try 
			read ( data, Data.FileMessage );
			Output.ExchangeReceivedFromNode ( new Structure ( "Node", Data.Code ) );
		except
			Output.ErrorReceivingData ( new Structure ( "Error", ErrorDescription () ) );
			return;
		endtry;
		break;
	enddo;
	clearUpdateAttributes ( node );
	Connections.Unlock ();
	Output.UnlockBase ( new Structure ( "Date", CurrentDate () ) );
	Exchange.EraseFile ( TempFilesDir () + "RereadData_" + IDProcess + ".epf" );
	Exchange.DeleteTempDirectory ( TempDirectory );
	Output.FinishedRereadFileExchange ();	
	
endprocedure

procedure luckyUnload ( Ref )
	
	Catalogs.Exchange.WriteAttributes ( Ref, new Structure ( "DateUnload", CurrentSessionDate () ) );
	
endprocedure

procedure luckyReadData ( Ref )
	
	s = new Structure ();
	s.Insert ( "DateLoad", CurrentSessionDate () );
	s.Insert ( "FileMessage", "" );
	s.Insert ( "NumbersOfErrors", 0 );
	s.Insert ( "SendedEMailError", false );
	Catalogs.Exchange.WriteAttributes ( Ref, s );
	
endprocedure

procedure readUpdateMessage ( Ref, FileXml )
	
	s = new Structure ();
	s.Insert ( "FileMessage", FileXml );
	s.Insert ( "NumbersOfErrors", 0 );
	s.Insert ( "Update", false );
	Catalogs.Exchange.WriteAttributes ( Ref, s );
	
endprocedure 

procedure writeSendedReport ( Ref )
	
	s = new Structure ();
	s.Insert ( "SendedEMailError", true );
	Catalogs.Exchange.WriteAttributes ( Ref, s );
	
endprocedure 

procedure clearUpdateAttributes ( Node )
	
	p = new Structure ();
	p.Insert ( "FileMessage", "" );
	p.Insert ( "NumbersOfErrors", 0 );
	Catalogs.Exchange.WriteAttributes ( Node, p )
	
endprocedure 

#endif
