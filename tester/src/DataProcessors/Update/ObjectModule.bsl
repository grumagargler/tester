  
#if ( server or thickclientordinaryapplication or externalconnection ) then 

var UpdaterFolder;

procedure Update ( ID ) export
	
	cancel = checkingExistence ();
	if ( cancel ) then
		Output.NotFoundExecuteFile1C ();
		return;
	endif;
	Output.StartUpdateScriptProcedure ();
	Connections.Lock ();
	Connections.LeaveMeAlone ();
	saveUpdater ( ID );
	runUpdater ( ID );  
		
endprocedure

function checkingExistence ()
	
	exeFile = BinDir () + "1cv8.exe";  
	file = new File ( exeFile );
	return not file.Exist (); 
	
endfunction 

procedure saveUpdater ( ID )
	
	name = updaterName ();
	tempDir = Exchange.GetTempDir ( ID ); 
	UpdaterFolder = tempDir + "\" + Metadata.Name + "_" + name + ID;
	db = UpdaterFolder + GetPathSeparator () + "db.zip";
	data = getUpdater ( name );	
	data.Write ( db );
	zip = new ZipFileReader ( db );
	zip.ExtractAll ( UpdaterFolder );
	zip.Close (); 
	
endprocedure

function updaterName ()
	
	return Metadata.DataProcessors.Update.Templates [ 0 ].Name;
	
endfunction

function getUpdater ( Name )
	
	archive = DataProcessors.Update.GetTemplate ( Name );
	return archive;
	
endfunction

procedure runUpdater ( ID )
	
	p = getParameters ( ID );
	params = Conversion.ToJSON ( p );
	app = """" + BinDir () + "1cv8c.exe"" ENTERPRISE /F """ + UpdaterFolder + "" + """ /N ""admin""" + " /C """ + StrReplace ( params, """", """""" ) + """";
	RunApp ( app );
	
endprocedure

function getParameters ( ID )
	
	credentials = Connections.GetCredentials ();
	p = new Structure ();
	p.Insert ( "User", credentials.CloudUser );
	p.Insert ( "Password", credentials.CloudPassword );
	p.Insert ( "Key", ? ( credentials.ServerCode = "", "EXCHANGE", credentials.ServerCode ) );
	p.Insert ( "ID", ID );
	p.Insert ( "Connection", getConnection () );
	return p; 
	
endfunction 

function getConnection ()
	
	connectDB = InfoBaseConnectionString ();
	if ( Find ( connectDB, "File=" ) = 1 ) then
		s = " /F " + """" + NStr ( connectDB, "File" ) + """";
	else
		s = " /S " + """" + NStr ( connectDB, "Srvr" ) + "\" + NStr ( connectDB, "Ref" ) + """";
	endif;
	return s;	        

endfunction

#endif
