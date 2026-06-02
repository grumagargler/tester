// *****************************************
// *********** Form events

&atclient
procedure OnOpen ( Cancel )

	if ( Framework.IsLinux () ) then
		adjustHint ();
	endif;

endprocedure

&atclient
procedure adjustHint ()
	
	Items.VSCode.InputHint = Output.LinuxVSCode ();
	
endprocedure
 
// *****************************************
// *********** Group Form

&atclient
procedure VSCodeStartChoice ( Item, ChoiceData, StandardProcessing )
	
	StandardProcessing = false;
	chooseFile ();
	
endprocedure

&atclient
procedure chooseFile ()
	
	dialog = new FileDialog ( FileDialogMode.Open );
	dialog.Show ( new NotifyDescription ( "SelectFile", ThisObject ) );
	
endprocedure 

&atclient
procedure SelectFile ( File, Params ) export
	
	if ( File = undefined ) then
		return;
	endif; 
	Object.VSCode = File [ 0 ];
	
endprocedure
