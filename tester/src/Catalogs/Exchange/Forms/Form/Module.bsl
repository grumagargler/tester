
&atserver
procedure OnReadAtServer ( CurrentObject )
	
	Appearance.Apply ( ThisObject );
	fillNodeData ( ThisObject, CurrentObject.Node );
	
endprocedure

&atserver
procedure OnCreateAtServer ( Cancel, StandardProcessing )
	
	if ( Object.Ref.IsEmpty () ) then
		fillNew ();
	endif;
	fillAttributes ();
	readAppearance ();
	Appearance.Apply ( ThisObject );
	
endprocedure

&atserver
procedure readAppearance ()

	rules = new Array ();
	rules.Add ( "
	|PageEmail show Object.ExchangeTransport = Enum.ExchangeTransport.Email;
	|PageFTP show Object.ExchangeTransport = Enum.ExchangeTransport.FTP;
	|PageDisk show Object.ExchangeTransport = Enum.ExchangeTransport.NetworkDisk;
	|PageWebService show Object.ExchangeTransport = Enum.ExchangeTransport.WebService;
	|Periodicity enable Object.UseAutomatic;
	|PageInformation PageSettings PageReportErrors unlock not ThisNode
	|" );
	Appearance.Read ( ThisObject, rules );

endprocedure

&atserver
procedure fillNew ()	
	
	Object.ExchangeTransport = Enums.ExchangeTransport.NetworkDisk; 
	Object.UseAutomatic = true;
	Object.Periodicity = Enums.ExchangePeriodicity.Constant;
	Object.Update = false;
	Object.NumbersOfErrors = 3;
	Object.PrefixFileName = "";
	Object.ServerTimeOut = 10;
	Object.Protocol = Enums.Protocols.IMAP;
	Object.UseStandartFTPClient = true;
	Object.UseSSLIncoming = false;
	setPortIncoming ( Object );
	Object.UseSSLOutgoing = false;
	setPortOutgoing ( Object );
	
endprocedure

&atserver
procedure fillAttributes ()
	
	TypeExchange = ? ( Object.UseAutomatic, 2, 1 );
	ThisNode = getThisNode ( Object.Node );
	
endprocedure 

&atserver
procedure BeforeWriteAtServer ( Cancel, CurrentObject, WriteParameters )
	
	if ( ValueIsFilled ( CurrentObject.Node ) and CurrentObject.Ref.IsEmpty () ) then
		Cancel = checkNode ( CurrentObject.Node );
	endif;
	
endprocedure

&atserver
function checkNode ( Node )
	
	s = "
	|select Ref as Ref
	|from Catalog.Exchange
	|where Node = &Node
	|";
	q = new Query ( s );
	q.SetParameter ( "Node", Node );		
	result = q.Execute ();
	if ( result.IsEmpty () ) then
		error = false
	else
		error = true;
		Output.ExchangeDataItemAlreadyExist ( new Structure ( "Code", Node.Code ) );
	endif;
	return error; 
		
endfunction

&atserver
procedure AfterWriteAtServer ( CurrentObject, WriteParameters )
	
	Appearance.Apply ( ThisObject );

endprocedure

&atclient
procedure ExchangeTransportOnChange ( Item )
	
	Appearance.Apply ( ThisObject );
	
endprocedure

&atclient
procedure TypeExchangeOnChange ( Item )
	
	Object.UseAutomatic = ? ( TypeExchange = 2, true, false );
	Appearance.Apply ( ThisObject );
	
endprocedure

&atclient
procedure NodeOnChange ( Item )
	
	Object.Code = getCodeNode ( Object.Node );
	ThisNode = getThisNode ( Object.Node );
	if ( ThisNode ) then
		Output.SelectThisNode ();
	endif; 
	Appearance.Apply ( ThisObject );
	fillNodeData ( ThisObject, Object.Node ); 
	
endprocedure

&atservernocontext
function getCodeNode ( Node )
	
	if ( ValueIsFilled ( Node ) ) then
		code = Node.Code;
	else
		code = "";
	endif; 
	return code; 
	
endfunction 

&atclient
procedure PathStartChoice ( Item, ChoiceData, StandardProcessing )
	
	selectDirectory ( Item.Name );
	
endprocedure

&atclient
procedure selectDirectory ( Name )
	
	p = new Structure ( "Attribute", Name );
	LocalFiles.Prepare ( new NotifyDescription ( "OpenDialog", ThisObject, p ) );
	
endprocedure 

&atclient
procedure OpenDialog ( Result, Params ) export
	
	dialog = new FileDialog ( FileDialogMode.ChooseDirectory );
	dialog.Directory = getDirectory ( Params.Attribute );
	dialog.Show ( new NotifyDescription ( "SetAttribute", ThisObject, Params ) );
	
endprocedure 

&atclient
function getDirectory ( Attribute )
	
	path = Object [ Attribute ];
	directory = "";
	if ( path = "" ) then
		return directory;
	endif; 
	c = StrLen ( path );
	while c > 0 do
		if ( Mid ( path, c, 1 ) = "\" ) then
			directory = Mid ( path, 1, ( c - 1 ) );
			break;
		endif; 
		c = c - 1;		
	enddo;
	return directory; 

endfunction

&atclient
procedure SetAttribute ( Result, Params ) export
	
	if ( Result = undefined ) then
		return;
	endif; 
	Object [ Params.Attribute ] = Result [ 0 ];
	Modified = true;
	
endprocedure

&atclient
procedure PrefixFileNameOnChange ( Item )
	
	Output.ChangePrefixFileName ();
	
endprocedure

&atclient
procedure UseSSLOutgoingOnChange ( Item )
	
	setPortOutgoing ( Object );	
	
endprocedure

&atclientatservernocontext
procedure setPortOutgoing ( Object )
	
	if ( Object.UseSSLOutgoing ) then
		Object.PortOutgoing = 465;
	else
		Object.PortOutgoing = 25;
	endif; 
	
endprocedure

&atclient
procedure ProtocolOnChange ( Item )
	
	setPortIncoming ( Object );
	
endprocedure

&atclient
procedure UseSSLIncomingOnChange ( Item )
	
	setPortIncoming ( Object );
	
endprocedure

&atclientatservernocontext
procedure setPortIncoming ( Object )
	
	if ( Object.Protocol = PredefinedValue ( "Enum.Protocols.IMAP" ) ) then
		if ( Object.UseSSLIncoming ) then
			Object.PortIncoming = 993;
		else
			Object.PortIncoming = 143;
		endif; 
	elsif ( Object.Protocol = PredefinedValue ( "Enum.Protocols.POP3" ) ) then
		if ( Object.UseSSLIncoming ) then
			Object.PortIncoming = 995;
		else
			Object.PortIncoming = 110;
		endif; 
	endif;	
	
endprocedure

&atclient
procedure TestConnectionCommand ( Command )
	
	testConnection ();
	
endprocedure 

&atclient
procedure testConnection ()
	
	testConnectionSrv ();
	
endprocedure

&atserver
procedure testConnectionSrv ()
	
	profile = getProfile ();
	email = new InternetMail ();
	protocol = getMailProtocol ( Object.Protocol );
	try
		email.Logon ( profile, protocol );
		Output.LogonSuccess ();
	except 
		Output.ErrorConnectEmailProfile ( new Structure ( "Error", ErrorDescription () ) );
	endtry;	
	
endprocedure 

&atserver
function getProfile ()
	
	p = new InternetMailProfile ();
	p.User = TrimAll ( Object.UserEmail );
	p.Password = TrimAll ( Object.PasswordEmail );
	p.SMTPServerAddress = TrimAll ( Object.ServerOutgoing );
	p.SMTPUser = TrimAll ( Object.UserEmail );
	p.SMTPPassword = TrimAll ( Object.PasswordEmail );
	p.SMTPUseSSL = Object.UseSSLOutgoing;
	p.SMTPPort = Object.PortOutgoing;
	if ( Object.Protocol = PredefinedValue ( "Enum.Protocols.IMAP" ) ) then
		p.IMAPUser = TrimAll ( Object.UserEmail );
		p.IMAPPassword = TrimAll ( Object.PasswordEmail );
		p.IMAPPort = Object.PortIncoming;
		p.IMAPServerAddress = TrimAll ( Object.ServerIncoming );
		p.IMAPUseSSL = Object.UseSSLIncoming;
	else
		p.POP3Port = Object.PortIncoming;
		p.POP3ServerAddress = TrimAll ( Object.ServerIncoming );
		p.POP3UseSSL = Object.UseSSLIncoming;
	endif; 
	return p;
	
endfunction

&atserver  
function getMailProtocol ( Protocol )
	
	if ( Protocol = PredefinedValue ( "Enum.Protocols.POP3" ) ) then
		p = InternetMailProtocol.POP3;
	elsif ( Protocol = PredefinedValue ( "Enum.Protocols.IMAP" ) ) then
		p = InternetMailProtocol.IMAP;
	else
		p = InternetMailProtocol.POP3;
	endif;
	return p;
	
endfunction 

&atservernocontext
function getThisNode ( Node )
	
	if ( ValueIsFilled ( Node ) ) then
		ThisNode = Node.ThisNode; 
	else
		ThisNode = false;
	endif;
	return ThisNode; 
	
endfunction 

&atclient
procedure OnOpen ( Cancel )
	
	if ( ThisNode ) then
		Output.SelectThisNode ();
	endif;
	
endprocedure

&atclientatservernocontext
procedure fillNodeData ( Form, Node )
	
	data = getNodeData ( Node );
	Form.ReceivedNo = data.ReceivedNo;
	Form.SentNo = data.SentNo;
	
endprocedure

&atservernocontext
function getNodeData ( Node )
	
	p = new Structure ();
	p.Insert ( "ReceivedNo", 0 );
	p.Insert ( "SentNo", 0 );
	if ( ValueIsFilled ( Node ) ) then
		s = "
		|select
		|	ReceivedNo as ReceivedNo,
		|	SentNo as SentNo
		|from               
		|	ExchangePlan.Full
		|where
		|	Ref = &Ref 
		|";
		q = new Query ( s );
		q.SetParameter ( "Ref", Node );		
		result = q.Execute ();
		selection = result.Select ();
		selection.Next ();
		p.ReceivedNo = selection.ReceivedNo;
		p.SentNo = selection.SentNo;
	endif; 
	return p; 
	
endfunction 