procedure CleanTimelapse ( val Session, val Scenario, val DateTo ) export
	
	checkAccess ( Session );
	selection = recorderSelection ( Session, Scenario, DateTo );
	SetPrivilegedMode ( true );
	BeginTransaction ();
	while ( selection.Next () ) do
		r = InformationRegisters.Timelapse.CreateRecordSet ();
		filter = r.Filter;
		FillPropertyValues ( filter, selection );
		r.Write ();
	enddo;
	CommitTransaction ();
	
endprocedure

procedure checkAccess ( Session )
	
	if ( Session = undefined
		or IsInRole ( Metadata.Roles.Administrator ) ) then
		return;
	endif;
	q = new Query ( "select 1 from Catalog.Sessions where User = &User" );
	q.SetParameter ( "User", SessionParameters.User );
	if ( q.Execute ().IsEmpty () ) then
		raise Output.SessionAccessError ();
	endif;

endprocedure

function recorderSelection ( Session, Scenario, DateTo )
	
	q = new Query ();
	where = new Array ();
	where.Add ( "Timelapses.Session = &Session" );
	if ( Session = undefined ) then
		q.SetParameter ( "Session", SessionParameters.Session );
	else
		q.SetParameter ( "Session", Session );
	endif;
	if ( Scenario <> undefined ) then
		where.Add ( "Timelapses.Scenario = &Scenario" );
		q.SetParameter ( "Scenario", Scenario );
	endif;
	if ( DateTo <> undefined ) then
		where.Add ( "Timelapses.Date <= &DateTo" );
		q.SetParameter ( "DateTo", DateTo );
	endif;
	q.Text = "
	|select distinct Timelapses.Session as Session, Timelapses.Scenario as Scenario, Timelapses.Date as Date
	|from InformationRegister.Timelapse as Timelapses
	|where " + StrConcat ( where, " and " );
	return q.Execute ().Select ();
	
endfunction
