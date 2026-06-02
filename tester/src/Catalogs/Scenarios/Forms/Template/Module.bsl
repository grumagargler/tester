// *****************************************
// *********** Form events

&atserver
procedure OnCreateAtServer ( Cancel, StandardProcessing )
	
	init ();
	setTemplates ();
	readAppearance ();
	Appearance.Apply ( ThisObject );
	
endprocedure

&atserver
procedure readAppearance ()

	rules = new Array ();
	rules.Add ( "
	|Template1 enable Variant1 = 1;
	|Template2 enable Variant2 = 1;
	|Template3 enable Variant3 = 1;
	|Template4 enable Variant4 = 1
	|" );
	Appearance.Read ( ThisObject, rules );

endprocedure

&atserver
procedure init ()
	
	Everywhere = true;
	Variant1 = 1;
	
endprocedure 

&atserver
procedure setTemplates ()
	
	text = Parameters.Text;
	Template1 = "{*}";
	words = StrSplit ( text, " ", false );
	Template2 = "{" + words [ 0 ] + " *}";
	if ( words.Count () > 1 ) then
		Template3 = "{" + words [ 0 ] + " " + words [ 1 ] + " *}";
	else
		Template3 = "{" + text + "}";
	endif; 
	Template4 = "{" + text + "}";
	
endprocedure 

// *****************************************
// *********** Group Form

&atclient
procedure Replace ( Command )
	
	p = new Structure ( "Template, Everywhere", getTemplate (), Everywhere );
	Close ( p );
	
endprocedure

&atclient
function getTemplate ()
	
	if ( Variant1 = 1 ) then
		return Template1;
	elsif ( Variant2 = 1 ) then
		return Template2;
	elsif ( Variant3 = 1 ) then
		return Template3;
	else
		return Template4;
	endif; 
	
endfunction 

&atclient
procedure Variant1OnChange ( Item )
	
	Variant2 = 0;
	Variant3 = 0;
	Variant4 = 0;
	Appearance.Apply ( ThisObject );
	
endprocedure


&atclient
procedure Variant2OnChange ( Item )
	
	Variant1 = 0;
	Variant3 = 0;
	Variant4 = 0;
	Appearance.Apply ( ThisObject );
	
endprocedure

&atclient
procedure Variant3OnChange ( Item )
	
	Variant1 = 0;
	Variant2 = 0;
	Variant4 = 0;
	Appearance.Apply ( ThisObject );
	
endprocedure

&atclient
procedure Variant4OnChange ( Item )
	
	Variant1 = 0;
	Variant2 = 0;
	Variant3 = 0;
	Appearance.Apply ( ThisObject );
	
endprocedure
