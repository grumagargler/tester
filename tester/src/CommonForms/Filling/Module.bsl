&atserver
var Presentation;

// *****************************************
// *********** Form events

&atserver
procedure OnCreateAtServer ( Cancel, StandardProcessing )

	loadParams ();
	init ();
	fetchHiddenSettings ();
	hideSettings ();
	setTitle ();
	readAppearance ();
	Appearance.Apply ( ThisObject );
	
endprocedure

&atserver
procedure readAppearance ()

	rules = new Array ();
	rules.Add ( "
	|ClearTable show ProposeClearing
	|" );
	Appearance.Read ( ThisObject, rules );

endprocedure

&atserver
procedure loadParams ()
	
	filling = Parameters.Filling;
	Report = filling.Report;
	Variant = filling.Variant;
	Background = filling.Background;
	Batch = filling.Batch;
	ProposeClearing = filling.ProposeClearing;
	CloseOnErrors = filling.CloseOnErrors;
	ClearTable = filling.ClearTable;
	
endprocedure

&atserver
procedure init ()
	
	SetPrivilegedMode ( true );
	schema = Reporter.GetSchema ( Report );
	SetPrivilegedMode ( false );
	SchemaAddress = PutToTempStorage ( schema, SchemaAddress );
	Composer.Initialize ( new DataCompositionAvailableSettingsSource ( SchemaAddress ) );
	Composer.LoadSettings ( schema.SettingVariants [ Variant ].Settings );
	Presentation = schema.SettingVariants [ Variant ].Presentation;
	ResultAddress = PutToTempStorage ( new ValueTable (), Parameters.Caller );
	Reporter.ApplyFilters ( Composer, Parameters.Filling );
	Items.UserSettings.ViewMode = DataCompositionSettingsViewMode.QuickAccess;

endprocedure 

&atserver
procedure fetchHiddenSettings ()

	filters = undefined;
	Parameters.Filling.Property ( "Filters", filters );
	if ( filters = undefined ) then
		return;
	endif;
	settings = Composer.Settings;
	for each filter in filters do
		if ( not filter.Hide ) then
			continue;
		endif;
		if ( filter.Property ( "Parameter" ) ) then
			name = "" + filter.Parameter;
			item = DC.GetParameter ( Composer, name );
			fields = "Use, Value";
		else
			name = "" + filter.LeftValue;
			item = DC.FindFilter ( Composer, name );
			fields = "Use, ComparisonType, RightValue";
		endif; 
		source = DC.FindSetting ( settings, name );
		FillPropertyValues ( source, item, fields );
		HiddenSettings.Add ( name, item.UserSettingID );
	enddo; 

endprocedure

&atserver
procedure hideSettings ()

	settings = Composer.Settings;
	for each setting in HiddenSettings do
		DC.FindSetting ( settings, setting.Value ).UserSettingID = "";
	enddo;

endprocedure

&atserver
procedure setTitle ()
	
	Title = Presentation;

endprocedure 

&atclient
procedure OnOpen ( Cancel )
	
	Caller = FormOwner.UUID;
	
endprocedure

// *****************************************
// *********** Group Form

&atclient
procedure Fill ( Command )
	
	perform ( Background );
	if ( Background ) then
		Progress.Open ( UUID, FormOwner, new CallbackDescription ( "Complete", ThisObject ) );
	else
		Close ( getResult ( true ) );
	endif; 
	
endprocedure

&atserver
procedure perform ( Background )
	
	schema = GetFromTempStorage ( SchemaAddress );
	args = new Array ();
	args.Add ( Report );
	args.Add ( Variant );
	args.Add ( getSettings () );
	args.Add ( schema );
	args.Add ( ResultAddress );
	args.Add ( Batch );
	args.Add ( ClearTable );
	Jobs.Run ( "FillerSrv.Perform", args, UUID, , not Background );

endprocedure

&atserver
function getSettings ()

	loadHiddenSettings ();
	settings = Composer.GetSettings ();
	hideSettings ();
	FillerSrv.ExtractTables ( settings );
	return settings;

endfunction

&atserver
procedure loadHiddenSettings ()

	settings = Composer.Settings;
	for each setting in HiddenSettings do
		DC.FindSetting ( settings, setting.Value ).UserSettingID = setting.Presentation;
	enddo;

endprocedure

&atclient
procedure Complete ( Completed, Params ) export
	
	if ( Completed or CloseOnErrors ) then
		Close ( getResult ( Completed ) );
	endif; 
	
endprocedure 

&atclient
function getResult ( Completed )
	
	result = Filler.Result ();
	result.ClearTable = ClearTable;
	result.Address = ResultAddress;
	result.Completed = Completed;
	return result;
	
endfunction 

&atclient
procedure MarkAll ( Command )
	
	mark ( true );
	
endprocedure

&atclient
procedure UnmarkAll ( Command )
	
	mark ( false );
	
endprocedure

&atclient
procedure mark ( Flag )
	
	for each item in Composer.UserSettings.Items do
		if ( TypeOf ( item ) = Type ( "DataCompositionFilterItem" )
			or TypeOf ( item ) = Type ( "DataCompositionSettingsParameterValue" ) )
			and ( item.ViewMode = DataCompositionSettingsItemViewMode.QuickAccess ) then
			item.Use = Flag;
		endif; 
	enddo; 
	
endprocedure

&atclient
procedure OpenSettings ( Command )
	
	switchSettings ();
	
endprocedure

&atserver
procedure switchSettings ()
	
	if ( Items.UserSettings.ViewMode = DataCompositionSettingsViewMode.QuickAccess ) then
		Items.OpenSettings.Check = true;
		Items.UserSettings.ViewMode = DataCompositionSettingsViewMode.All;
	else
		Items.OpenSettings.Check = false;
		Items.UserSettings.ViewMode = DataCompositionSettingsViewMode.QuickAccess;
	endif;
	
endprocedure
