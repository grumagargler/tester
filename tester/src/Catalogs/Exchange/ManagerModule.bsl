
#if ( server or thickclientordinaryapplication or externalconnection ) then
	
function GetNodeData ( Node ) export

	p = new Structure ();
	p.Insert ( "MasterNode", ( ExchangePlans.MasterNode () = undefined ) );
	s = "
	|select
	|	Node.ThisNode as ThisNode, 
	|	ExchangeTransport as ExchangeTransport
	|from 
	|	Catalog.Exchange
	|where 
	|	Ref = &Node 
	|";
	q = new Query ( s );
	q.SetParameter ( "Node", Node );		
	result = q.Execute ();
	selection = result.Select ();
	selection.Next ();
	p.Insert ( "ExchangeTransport", selection.ExchangeTransport );
	p.Insert ( "ThisNode", selection.ThisNode );
	return p; 
	
endfunction

procedure WriteAttributes ( Ref, Attributes ) export
	
	object = Ref.GetObject ();
	for each item in Attributes do
		object [ item.Key ] = item.Value;
	enddo; 
	object.Write ();
	
endprocedure 

#endif
