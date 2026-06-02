procedure UpdateStack ( Error, Stack ) export
	
	Stack.Clear ();
	table = getStack ( Error );
	for each row in table do
		newRow = Stack.Add ();
		newRow.Scenario = row.Scenario + " [" + Format ( row.Row, "NG=" ) + "]";
		newRow.Ref = row.Ref;
		newRow.Row = row.Row;
		newRow.Area = row.Area;
	enddo; 
	
endprocedure

function getStack ( Error )
	
	s = "
	|select Stack.Row as Row, Stack.Scenario as Ref, presentation ( Stack.Scenario ) as Scenario,
	|	presentation ( Stack.Area ) as Area
	|from Catalog.ErrorLog.Stack as Stack
	|where Stack.Ref = &Ref
	|order by Stack.LineNumber
	|";
	q = new Query ( s );
	q.SetParameter ( "Ref", Error );
	return q.Execute ().Unload ();
	
endfunction
