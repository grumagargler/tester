// *****************************************
// *********** Form events

&atserver
procedure OnCreateAtServer ( Cancel, StandardProcessing )
	
	setDefaults ();
	
endprocedure

&atserver
procedure setDefaults ()
	
	Mode = Enums.Recording.Tester;
	
endprocedure 

&atclient
procedure OnOpen ( Cancel )
	
	fixLang ();
	
endprocedure

&atclient
procedure fixLang ()
	
	if ( Items.Lang.ChoiceList.FindByValue ( Lang ) = undefined ) then
		Lang = CurrentLanguage ();
	endif; 
	
endprocedure 

// *****************************************
// *********** Group Form

&atclient
procedure Convert ( Command )
	
	if ( CheckFilling () ) then
		Close ( getLog () );
	endif; 
	
endprocedure

&atclient
function getLog ()
	
	return new Structure ( "Log, Lang, Mode", Log, Lang, Mode );
	
endfunction

&atclient
procedure ModeClearing ( Item, StandardProcessing )
	
	StandardProcessing = false;
	
endprocedure
 
