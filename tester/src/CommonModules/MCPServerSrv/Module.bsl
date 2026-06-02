function Settings () export

	address = Constants.MCPServer.Get ();
	parts = StrSplit ( address, ":" );
	if ( parts.Count () = 2 ) then
		return new Structure ( "Address, Port, EditScenarios",
			parts [ 0 ], parts [ 1 ], Logins.CanEditScenarios () );
	endif;

endfunction
