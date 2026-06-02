function Create ( Query ) export
	
	env = new Structure ();
	env.Insert ( "Q", new Query () );
	env.Insert ( "Selection", new Array () );
	env.Selection.Add ( Query );
	return env;
	
endfunction

procedure Init ( Env ) export
	
	if ( Env = undefined ) then
		Env = new Structure ();
	endif; 
	Env.Insert ( "Q", new Query () );
	Env.Insert ( "Selection", new Array () );
	
endprocedure

procedure Prepare ( Env ) export
	
	q = Env.Q;
	q.Text = StrConcat ( Env.Selection, ";" );
	CoreLibrary.AugmentQuery ( q.Text );
	SQL.DefineTempManager ( q );
	Env.Selection = new Array ();

endprocedure 

procedure DefineTempManager ( Q ) export
	
	if ( Find ( Q.Text, "into " ) > 0
		or Find ( Q.Text, "INTO " ) > 0 ) then
		if ( Q.TempTablesManager = undefined ) then
			Q.TempTablesManager = new TempTablesManager ();
		endif; 
	endif; 
	
endprocedure 

procedure Unload ( Env, Data = undefined ) export

	q = Env.Q;
	if ( Data = undefined ) then
		CoreLibrary.AugmentQuery ( q.Text );
		result = q.ExecuteBatch ();
	else
		result = Data;
	endif;
	tables = CoreLibrary.QueryTables ( q.Text );
	if ( tables <> undefined ) then
		extractData ( tables, Env, result );
	endif;
	
endprocedure

procedure extractData ( Tables, Env, Data )
	
	indexExists = false;
	for each table in Tables do
		type = table.Type;
		name = table.Name;
		index = table.Index;
		if ( type = 1 ) then
			Env.Insert ( name, Data [ index ].Unload () );
		elsif ( type = 2 ) then
			Env.Insert ( "i" + name, index );
			indexExists = true;
		else
			rows = Data [ index ].Unload ();
			if ( rows.Count () = 0 ) then
				Env.Insert ( name, undefined );
			else
				Env.Insert ( name, Conversion.RowToStructure ( rows ) );
			endif; 
		endif;
	enddo;
	if ( indexExists ) then
		Env.Insert ( "Data", Data );
	endif; 
	
endprocedure 

procedure Perform ( Env, CheckAccess = true ) export
	
	if ( not CheckAccess ) then
		SetPrivilegedMode ( true );
	endif;
	SQL.Prepare ( Env );
	SQL.Unload ( Env );
	
endprocedure 

function Fetch ( Env, Name ) export
	
	field = "i" + Mid ( Name, 2 );
	index = Env [ field ];
	return Env.Data [ index ].Unload ();
	
endfunction 

function Exec ( Q, CheckAccess = true ) export
	
	if ( not CheckAccess ) then
		SetPrivilegedMode ( true );
	endif;
	SQL.DefineTempManager ( Q );
	env = new Structure ();
	CoreLibrary.AugmentQuery ( q.Text );
	tables = CoreLibrary.QueryTables ( q.Text );
	extractData ( tables, env, Q.ExecuteBatch () );
	return env;
	
endfunction 
