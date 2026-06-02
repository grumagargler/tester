
&atclient
procedure CommandProcessing ( CommandParameter, CommandExecuteParameters )
	
	ClearMessages ();
	p = getNodeData ( CommandParameter );
	if ( p.MasterNode ) then
		if ( p.ExchangeTransport = PredefinedValue ( "Enum.ExchangeTransport.WebService" ) ) then
			Output.MasterNode ();
			return;
		endif;
	endif;
	if ( p.ThisNode ) then
		Output.ThisNode ();
	else
		runProcessServer ( CommandParameter );
		Output.UnloadingCompleteNotification ();
	endif;
	refreshForm ( CommandExecuteParameters.Source );
	
endprocedure

&atserver
function getNodeData ( Node )

	return Catalogs.Exchange.GetNodeData ( Node ); 
	
endfunction 

&atserver 
procedure runProcessServer ( Node )
	
	p = new Structure ();
	p.Insert ( "Node", Node );
	p.Insert ( "Update", false );
	p.Insert ( "IsJob", false );
	p.Insert ( "ID", "" );
	DataProcessors.ExchangeData.Unload ( p );	
	
endprocedure

&atclient
procedure refreshForm ( Form )
	
	name = Form.FormName;
	if ( name = "Catalog.Exchange.Form.List" ) then
		Form.Items.List.Refresh ();
	elsif ( name = "Catalog.Exchange.Form.Form" ) then
		Form.Read ();
		NotifyChanged ( Form.Object.Ref );
	else 
		return;
	endif;
	
endprocedure