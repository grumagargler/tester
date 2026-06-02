
&atclient
procedure Start ( Name ) export
	
	LocalFiles.Prepare ( new NotifyDescription ( "Download", ThisObject, Name ) );
	
endprocedure

&atclient
procedure Download ( Result, Name ) export
	
	list = new Array ();
	list.Add ( new TransferableFileDescription ( Name + ".epf", DownloadTemplateSrv.GetLocation ( Name ) ) );
	BeginGettingFiles ( new NotifyDescription ( "Complete", ThisObject ), list, , true );
	
endprocedure 

&atclient
procedure Complete ( Result, Params ) export
	
	if ( Result = undefined ) then
		return;
	endif; 
	Output.DownloadCompleted ();
	
endprocedure 
