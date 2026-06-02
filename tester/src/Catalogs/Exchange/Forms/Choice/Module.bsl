
&atserver
procedure OnCreateAtServer ( Cancel, StandardProcessing )
	
	Appearance.Read ( ThisObject );
	Appearance.Apply ( ThisObject );
	
endprocedure