procedure Lock ( User, Scenario ) export
	
	r = InformationRegisters.Editing.CreateRecordManager ();
	r.Scenario = Scenario;
	r.User = User;
	r.Date = CurrentSessionDate ();
	r.Write ();
	
endprocedure 