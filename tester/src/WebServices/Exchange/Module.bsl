
function Begin ( Node, Device, Incoming, Outgoing )
	
	env = getEnv ( Node, Device, Incoming, Outgoing );
	checkAccess ( env );
	SetPrivilegedMode ( true );
	error = checkNodes ( env );
	SetPrivilegedMode ( false );
	return error;
	
endfunction

function getEnv ( Node, Device, Incoming, Outgoing )
	
	env = new Structure ();
	env.Insert ( "Node", Node );
	env.Insert ( "Device", Device );
	env.Insert ( "Incoming", Incoming );
	env.Insert ( "Outgoing", Outgoing );
	return env;
	
endfunction

procedure checkAccess ( Env )
	
	if ( not AccessRight ( "Read", Metadata.ExchangePlans.Full ) ) then
		raise Output.ExchangeReadDataError ( new Structure ( "User", SessionParameters.User ) );
	endif;
	
endprocedure

function checkNodes ( Env )
	
	error = true;
	code = Env.Node;
	node = ExchangePlans.Full.FindByCode ( code );
	if ( node.IsEmpty () ) then
		nodes = createNodes ( Env );
		codeFull = nodes.Full;
	else
		if ( node.DeletionMark or node.Description <> Env.Device or node.SentNo <> Env.Incoming or node.ReceivedNo <> Env.Outgoing ) then
			resetNodes ( node, Env );
		endif;
		codeFull = code;
	endif;
	if ( ValueIsFilled ( codeFull ) ) then
		error = false;
	endif;
	return error;
	
endfunction

function createNodes ( Env )
	
	codes = createCodes ( Env );
	full = ExchangePlans.Full.CreateNode ();
	full.Code = codes.Full;
	full.Description = Env.Device;
	full.SentNo = Env.Incoming;
	full.ReceivedNo = Env.Outgoing;
	full.Write ();
	enrollNode ( full.Ref, Metadata.ExchangePlans.Full );
	return codes;
	
endfunction

function createCodes ( Env )
	
	BeginTransaction ( DataLockControlMode.Managed );
	lock = new DataLock ();
	item = lock.Add ( "Constant.CounterFull" );
	item.Mode = DataLockMode.Exclusive;
	lock.Lock ();
	full = Constants.CounterFull.Get ();
	if ( full = 0 ) then 
		full = 2;
	endif;	
	Constants.CounterFull.Set ( full + 1 );
	CommitTransaction ();
	meta = Metadata.ExchangePlans;
	codes = new Structure ();
	codes.Insert ( "Full", Format ( full, "ND=" + meta.Full.CodeLength + "; NLZ=; NG=" ) );
	return codes;
	
endfunction

procedure enrollNode ( Node, Plan )
	
	for each item in Plan.Content do
		ExchangePlans.RecordChanges ( Node, item.Metadata );
	enddo;
	
endprocedure

procedure resetNodes ( Node, Env  )
	
	obj = Node.GetObject ();
	if ( obj.DeletionMark ) then
		obj.DeletionMark = false;
	endif; 
	if ( obj.Description <> Env.Device ) then
		obj.Description = Env.Device;
	endif; 
	if ( obj.SentNo <> Env.Incoming ) then
		obj.SentNo = Env.Incoming;
	endif;
	if ( obj.ReceivedNo <> Env.Outgoing ) then
		obj.ReceivedNo = Env.Outgoing;
	endif; 
	obj.Write ();
	enrollNode ( obj.Ref, Metadata.ExchangePlans.Full );
			
endprocedure

function Read ( Node )
    
	full = getNode ( Node );
	if ( full.IsEmpty () ) then
		raise Output.UnknownNode ( new Structure ( "Code", Node ) );
	endif;
    return getChanges ( full );	
	
endfunction

function getChanges ( Node )
	
	id = getUUID ();
	postfix = getPostFix ( id );
	folder = Exchange.CreateTempDir ( postfix );
	p = new Structure ();
	p.Insert ( "Node", Node );
	p.Insert ( "Update", false );
	p.Insert ( "ID", id );
	p.Insert ( "IsJob", false );
	DataProcessors.ExchangeData.Unload ( p );
	Catalogs.Exchange.WriteAttributes ( Node, new Structure ( "DateLoad", CurrentSessionDate () ) );
	fileName = folder + id + ".zip";
	binData = new BinaryData ( fileName );
	changes = new ValueStorage ( binData, new Deflation ( 9 ) );
	Exchange.EraseFile ( Mid ( folder, 1, ( StrLen ( folder ) - 1 ) ) );
	return changes;

endfunction

procedure Write ( Node, Data, File )
	
	id = getUUID ();
	postfix = getPostFix ( id );
	folder = Exchange.CreateTempDir ( postfix );
	binData = Data.Get ();
	binData.Write ( folder + File );
	p = new Structure ();
	full = getNode ( Node );
	p.Insert ( "Node", full );
	p.Insert ( "Update", false );
	p.Insert ( "ID", id );
	p.Insert ( "IsJob", false );
	DataProcessors.ExchangeData.Load ( p );
	Catalogs.Exchange.WriteAttributes ( full, new Structure ( "DateLoad", CurrentSessionDate () ) );
	Exchange.EraseFile ( Mid ( folder, 1, ( StrLen ( folder ) - 1 ) ) );
	
endprocedure

function getPostFix ( ID )
	
	return "ExchangeWebService_" + ID;
	
endfunction 

function getUUID ()
	
	return String ( new UUID () ); 
	
endfunction

function getNode ( Code )
	
	return Catalogs.Exchange.FindByCode ( Code ); 

endfunction