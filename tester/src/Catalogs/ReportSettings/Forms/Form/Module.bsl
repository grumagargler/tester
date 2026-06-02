
// *****************************************
// *********** Form events

&atserver
procedure OnCreateAtServer ( Cancel, StandardProcessing )
	
	protectSetting ();

endprocedure

&atserver
procedure protectSetting ()

	if ( Object.User = SessionParameters.User ) then
		Items.Warning.Visible = false;
	else
		Items.Warning.Visible = true;
		ReadOnly = true;
	endif;

endprocedure