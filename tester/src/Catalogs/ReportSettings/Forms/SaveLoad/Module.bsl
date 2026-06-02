
// *****************************************
// *********** Form events

&atserver
procedure OnCreateAtServer ( Cancel, StandardProcessing )
	
	loadParameters ();
	setReplacing ();
	setTitle ();
	setDefaultButton ( ThisObject );
	loadVariants ();
	initList ();
	activateRecord ();
	readAppearance ();
	Appearance.Apply ( ThisObject );
	
endprocedure

&atserver
procedure loadParameters ()
	
	Report = Catalogs.Metadata.Ref ( "Report." + Parameters.Report );

endprocedure

&atserver
procedure setTitle ()
	
	if ( Parameters.Settings ) then
		Title = Output.ShowingReportSettings ();
	else
		Title = Output.ShowingReportVariants ();
	endif; 
	
endprocedure 

&atclientatservernocontext
procedure setDefaultButton ( Form )
	
	if ( Form.Parameters.Saving ) then
		if ( Form.Replacing = 0 ) then
			Form.Items.FormSave.DefaultButton = true;
		else
			Form.Items.FormChoose.DefaultButton = true;
		endif;
	else
		if ( Form.Loading = 0
			and not Form.Parameters.Settings ) then
			Form.Items.FormChooseStandard.DefaultButton = true;
		else
			Form.Items.FormChoose.DefaultButton = true;
		endif;
	endif;

endprocedure

&atserver
procedure loadVariants ()
	
	if ( Parameters.Saving
		or Parameters.Settings ) then
		return;
	endif;
	admin = Logins.Admin ();
	schema = Reporter.GetSchema ( Parameters.Report );
	for each variant in schema.SettingVariants do
		if ( admin
			or not isSystemVariant ( variant ) ) then
			StandardVariants.Add ( variant.Name, variant.Presentation );
		endif; 
	enddo; 
	
endprocedure

&atclient
procedure StandardVariantsValueChoice ( Item, Value, StandardProcessing )
	
	chooseStandard ();

endprocedure

&atclient
procedure chooseStandard ()
	
	item = Items.StandardVariants.CurrentData;
	if ( item = undefined ) then
		return;
	endif;
	NotifyChoice ( "#" + item.Value );

endprocedure

&atserver
function isSystemVariant ( Variant )
	
	return StrStartsWith ( Variant.Name, "#" );
	
endfunction

&atserver
procedure initList ()
	
	DC.ChangeFilter ( List, "Report", Report, true );
	DC.ChangeFilter ( List, "IsSettings", Parameters.Settings, true );

endprocedure

&atserver
procedure activateRecord ()
	
	if ( Parameters.Saving ) then
		record = Parameters.ReportSettings;
	elsif ( TypeOf ( Parameters.ReportVariant ) = Type ( "CatalogRef.ReportSettings" ) ) then
		record = Parameters.ReportVariant;
	endif;
	if ( ValueIsFilled ( record ) ) then
		Items.List.CurrentRow = record;
	endif;

endprocedure

&atserver
procedure setReplacing ()
	
	if ( not Parameters.Saving ) then
		return;
	endif;
	settings = Parameters.Settings;
	if ( settings
		and ValueIsFilled ( Parameters.ReportSettings )
		or ( not settings
			and ValueIsFilled ( Parameters.ReportVariant )
			and TypeOf ( Parameters.ReportVariant  ) = Type ( "CatalogRef.ReportSettings" ) ) )
	then
		Replacing = 1;
	endif;

endprocedure

&atserver
procedure readAppearance ()

	rules = new Array ();
	rules.Add ( "
	|#s StandardVariants hide Parameters.Saving or Parameters.Settings;
	|StandardVariants enable Loading = 0;
	|List enable ( Replacing = 1 or Loading = 1 ) or ( Parameters.Settings and not Parameters.Saving );
	|FormChoose show ( Replacing = 1 or Loading = 1 ) or ( Parameters.Settings and not Parameters.Saving );
	|FormChooseStandard show Loading = 0 and not Parameters.Settings and not Parameters.Saving ;
	|FormSave show Parameters.Saving and Replacing = 0;
	|SavingGroup show Parameters.Saving;
	|RecordDescription OpenAccess enable Replacing = 0 and Parameters.Saving;
	|LoadingStandard LoadingUser hide Parameters.Saving or Parameters.Settings;
	|" );
	Appearance.Read ( ThisObject, rules );

endprocedure

&atserver
procedure FillCheckProcessingAtServer ( Cancel, CheckedAttributes )

	if ( Parameters.Saving and Replacing = 0 ) then
		CheckedAttributes.Add ( "RecordDescripion" );
	endif;

endprocedure

&atclient
procedure OnOpen ( Cancel )
	
	setCurrentItem ();

endprocedure

&atclient
procedure setCurrentItem ()
	
	if ( Parameters.Saving ) then
		if ( Replacing = 0 ) then
			CurrentItem = Items.RecordDescription;
		else
			CurrentItem = Items.List;
		endif;
	else
		if ( Loading = 0 ) then
			CurrentItem = Items.StandardVariants;
		else
			CurrentItem = Items.List;
		endif;
	endif;

endprocedure

// *****************************************
// *********** Group Form

&atclient
async Procedure Save ( Command )
	
	if ( CheckFilling () ) then
		item = saveData ( Items.List.CurrentData );
		if ( Replacing = 0 ) then
			answer = await Output.NewReportAccessDefinition ();
			if ( answer = DialogReturnCode.Yes ) then
				OpenForm ( "Catalog.ReportSettings.ObjectForm", new Structure ( "Key", item ), , , , ,
					new CallbackDescription ( "AccessChanged", ThisObject ) );
				return;
			endif;
		endif;
		NotifyChoice ( item );
	endif;
	
endprocedure

&atclient
procedure AccessChanged ( Result, Ref ) export
	
	NotifyChoice ( Ref );

endprocedure

&atserver
function saveData ( val Ref = undefined )
	
	if ( Replacing = 0 ) then
		obj = Catalogs.ReportSettings.CreateItem ();
		obj.Description = RecordDescription;
		obj.User = SessionParameters.User;
		obj.Report = Report;
	else
		obj = Ref.GetObject ();
	endif; 
	obj.IsSettings = Parameters.Settings;
	obj.LastUpdateDate = CurrentSessionDate ();
	obj.Storage = new ValueStorage ( GetFromTempStorage ( Parameters.SettingsAddress ), new Deflation () );
	obj.Write ();
	return obj.Ref;

endfunction

&atclient
procedure SavingVariantOnChange ( Item )
	
	applySavingVariant (); 
	
endprocedure

&atclient
procedure applySavingVariant ()
	
	setDefaultButton ( ThisObject );
	Appearance.Apply ( ThisObject, "Replacing" );
	setCurrentItem ();

endprocedure

&atclient
procedure ListValueChoice ( Item, Value, StandardProcessing )
	
	if ( Parameters.Saving ) then
		saveData ( Value );
	endif;

endprocedure

&atclient
procedure LoadingStandardOnChange ( Item )
	
	applyLoadingVariant ();

endprocedure

&atclient
procedure applyLoadingVariant ()
	
	setDefaultButton ( ThisObject );
	Appearance.Apply ( ThisObject, "Loading" );
	setCurrentItem ();

endprocedure