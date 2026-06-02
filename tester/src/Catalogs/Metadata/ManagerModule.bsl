
function Ref ( Path ) export

	item = FindByDescription ( Path, true );
	if ( item.IsEmpty () ) then
		obj = CreateItem ();
		obj.Description = Path;
		obj.Write ();
		return obj.Ref;
	else
		return item;
	endif; 
	
endfunction
