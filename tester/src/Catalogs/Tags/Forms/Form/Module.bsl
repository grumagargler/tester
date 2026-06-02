// *****************************************
// *********** Form events

&atserver
procedure OnReadAtServer ( CurrentObject )
	
	OldName = Object.Description;
	
endprocedure

&atserver
procedure OnWriteAtServer ( Cancel, CurrentObject, WriteParameters )
	
	if ( OldName <> "" and OldName <> Object.Description ) then
		updateKeys ();
	endif; 
	
endprocedure

&atserver
procedure updateKeys ()
	
	lock ();
	list = getKeys ();
	for each ref in list do
		obj = ref.GetObject ();
		obj.SetDescription ();
		obj.Write ();
	enddo; 
	
endprocedure 

&atserver
procedure lock ()
	
	lock = new DataLock ();
	item = lock.Add ( "Catalog.TagKeys" );
	item.Mode = DataLockMode.Exclusive;
	lock.Lock ();
	
endprocedure 

&atserver
function getKeys ()
	
	s = "
	|select Tags.Ref as Ref
	|from Catalog.TagKeys.Tags as Tags
	|where Tags.Tag = &Tag
	|";
	q = new Query ( s );
	q.SetParameter ( "Tag", Object.Ref );
	return q.Execute ().Unload ().UnloadColumn ( "Ref" );
	
endfunction 
