function GetData ( Params ) export
	
	var schema;
	var composer;
	loadSchema ( Params, schema, composer );
	Reporter.ApplyFilters ( composer, Params );
	FillerSrv.ExtractTables ( composer );
	return putData ( Params.Report, Params.Variant, composer, schema, Params.Batch, Params.ClearTable );
	
endfunction

procedure loadSchema ( Params, Schema, Composer )
	
	SetPrivilegedMode ( true );
	Schema = Reporter.GetSchema ( Params.Report );
	SetPrivilegedMode ( false );
	Composer = new DataCompositionSettingsComposer ();
	Composer.Initialize ( new DataCompositionAvailableSettingsSource ( Schema ) );
	Composer.LoadSettings ( schema.SettingVariants [ Params.Variant ].Settings );
	
endprocedure 

function putData ( Report, Variant, Composer, Schema, Batch, ClearTable )

	SetPrivilegedMode ( true );
	obj = prepareReport ( Report, Variant, Composer, Schema, ClearTable );
	p = obj.Params;
	events = p.Events;
	if ( events.OnCheck ) then
		cancel = false;
		obj.OnCheck ( cancel );
		if ( cancel ) then
			return undefined;
		endif; 
	endif; 
	applyChangedComposer ( p, Composer );
	if ( events.OnCompose ) then
		obj.OnCompose ();
	endif; 
	tcomposer = new DataCompositionTemplateComposer ();
	try
		template = tcomposer.Execute ( p.Schema, p.Settings, , ,
			Type ( "DataCompositionValueCollectionTemplateGenerator" ) );
	except
		Message ( ErrorProcessing.BriefErrorDescription ( ErrorInfo () ) );
		return undefined;
	endtry;
	events = p.Events;
	if ( events.OnPrepare ) then
		obj.OnPrepare ( template );
	endif; 
	if ( Batch ) then
		q = prepareBatch ( template );
		p.Result = q.ExecuteBatch ();
		p.BatchQuery = q;
	else
		processor = new DataCompositionProcessor ();
		processor.Initialize ( template );
		builder = new DataCompositionResultValueCollectionOutputProcessor ();
		p.Result = new ValueTable ();
		builder.SetObject ( p.Result );
		builder.Output ( processor, false );
	endif; 
	if ( events.AfterOutput ) then
		obj.AfterOutput ();
	endif;
	return p.Result;
	
endfunction

function prepareReport ( Report, Variant, Composer, Schema, ClearTable )
 	
	obj = Reporter.Prepare ( Report );
	p = obj.Params;
	p.Variant = Variant;
	p.Schema = Schema;
	p.Composer = Composer;
	p.ClearTable = ClearTable;
	return obj;
	
endfunction 

procedure applyChangedComposer ( Params, Composer )
	
	Params.Settings = Composer.GetSettings ();
	
endprocedure

function prepareBatch ( Template )
	
	q = new Query ( Template.DataSets [ 0 ].Query );
	SQL.DefineTempManager ( q );
	for each item in Template.ParameterValues do
		q.SetParameter ( item.Name, item.Value );
	enddo; 
	CoreLibrary.AdjustQuery ( q );
	return q;
	
endfunction 

procedure StartProcess ( val Params, val Caller, ResultAddress ) export
	
	var schema;
	var composer;
	loadSchema ( Params, schema, composer );
	Reporter.ApplyFilters ( composer, Params );
	args = new Array ();
	args.Add ( Params.Report );
	args.Add ( Params.Variant );
	settings = composer.GetSettings ();
	FillerSrv.ExtractTables ( settings );
	args.Add ( settings );
	args.Add ( schema );
	ResultAddress = PutToTempStorage ( new ValueTable (), Caller );
	args.Add ( ResultAddress );
	args.Add ( Params.Batch );
	args.Add ( Params.ClearTable );
	Jobs.Run ( "FillerSrv.Perform", args, Caller );
	
endprocedure 

procedure Perform ( Report, Variant, SettingsSource, Schema, ResultAddress, Batch, ClearTable ) export
	
	composer = getComposer ( SettingsSource, Schema );
	result = putData ( Report, Variant, composer, Schema, Batch, ClearTable );
	PutToTempStorage ( result, ResultAddress );
	
endprocedure

function getComposer ( SettingsSource, Schema )
	
	if ( TypeOf ( SettingsSource ) = Type ( "DataCompositionSettingsComposer" ) ) then
		return SettingsSource;
	else
		composer = new DataCompositionSettingsComposer ();
		composer.Initialize ( new DataCompositionAvailableSettingsSource ( Schema ) );
		composer.LoadSettings ( SettingsSource );
		return composer;
	endif;
	
endfunction 

procedure ExtractTables ( SettingsSource ) export
	
	composer = ( TypeOf ( SettingsSource ) = Type ( "DataCompositionSettingsComposer" ) );
	settings = ? ( composer, SettingsSource.Settings, SettingsSource );
	for each item in settings.DataParameters.Items do
		value = item.Value;
		if ( IsTempStorageURL ( value ) ) then
			item.Value = GetFromTempStorage ( value );
		endif;
	enddo;

endprocedure