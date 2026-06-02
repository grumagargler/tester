
&atclient
procedure CommandProcessing ( User, Params )

	p = new Structure ( "User", User );
	OpenForm ( "Catalog.Sessions.ListForm", new Structure ( "Filter", p ), Params.Source, Params.Uniqueness, Params.Window, Params.URL );

endprocedure
