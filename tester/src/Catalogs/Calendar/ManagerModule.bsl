#if ( server or thickclientordinaryapplication or externalconnection ) then

procedure PresentationFieldsGetProcessing ( Fields, StandardProcessing )
	
	StandardProcessing = false;
	Fields.Add ( "Date" );
	
endprocedure

procedure PresentationGetProcessing ( Data, Presentation, StandardProcessing )
	
	StandardProcessing = false;
	Presentation = Format ( Data.Date, "DLF=D" );
	
endprocedure

function GetDate ( Date ) export
	
	SetPrivilegedMode ( true );
	BeginTransaction ();
	lock ();
	looking = BegOfDay ( Date );
	result = Catalogs.Calendar.FindByAttribute ( "Date", looking );
	if ( result.IsEmpty () ) then
		obj = Catalogs.Calendar.CreateItem ();
		obj.Date = looking;
		obj.Description = Format ( looking, "DLF=D" );
		obj.Write ();
		result = obj.Ref;
		CommitTransaction ();
	endif;
	return result;
	
endfunction

procedure lock ()
	
	lock = new DataLock ();
	item = lock.Add ( "Catalog.Calendar");
	item.Mode = DataLockMode.Exclusive;
	lock.Lock ();
	
endprocedure

#endif
