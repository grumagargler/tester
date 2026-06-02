
&atclient
procedure CommandProcessing ( User, ExecuteParameters )

	OpenForm ( "ExchangePlan.Repositories.ListForm", new Structure ( "User", User ), ExecuteParameters.Source, ExecuteParameters.Uniqueness, ExecuteParameters.Window, ExecuteParameters.URL);

endprocedure
