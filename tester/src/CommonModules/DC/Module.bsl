function CreateFilter ( LeftValue, RightValue = undefined, ComparisonType = undefined, Use = true, ViewMode = undefined, Hide = false ) export
	
	filter = new Structure ( "LeftValue, ComparisonType, RightValue, ViewMode, Use, Hide",
		new DataCompositionField ( LeftValue ),
		ComparisonType,
		RightValue,
		? ( ViewMode = undefined, DataCompositionSettingsItemViewMode.QuickAccess, ViewMode ), Use, Hide );
	applyFilter ( filter, ComparisonType, RightValue );
	return filter; 
	
endfunction

procedure applyFilter ( Filter, ComparisonType, Value )
	
	if ( ComparisonType = undefined ) then
		if ( TypeOf ( Value ) = Type ( "Array" ) ) then
			if ( Value.Count () = 1 ) then
				Filter.ComparisonType = DataCompositionComparisonType.Equal;
				Filter.RightValue = Value [ 0 ];
			else
				list = new ValueList ();
				list.LoadValues ( Value );
				Filter.ComparisonType = DataCompositionComparisonType.InList;
				Filter.RightValue = list;
			endif;
		else
			Filter.ComparisonType = DataCompositionComparisonType.Equal;
			Filter.RightValue = Value;
		endif;
	else
		Filter.ComparisonType = ComparisonType;
		Filter.RightValue = Value;
	endif;
	
endprocedure
 
function CreateParameter ( Parameter, Value = undefined, Use = true, ViewMode = undefined, Hide = false ) export
	
	return new Structure ( "Parameter, Value, ViewMode, Use, Hide",
		new DataCompositionParameter ( Parameter ),
		Value,
		? ( ViewMode = undefined, DataCompositionSettingsItemViewMode.QuickAccess, ViewMode ),
		Use,
		Hide );
	
endfunction

procedure DeleteFilter ( Source, Name ) export
	
	while ( true ) do
		filter = DC.FindFilter ( Source, Name );
		if ( filter = undefined ) then
			break;
		endif; 
		if ( filter.Parent = undefined ) then
			Source.Filter.Items.Delete ( filter );
		else
			filter.Parent.Items.Delete ( filter );
		endif; 
	enddo; 
	
endprocedure

function FindFilter ( Source, Name, Deeply = true ) export
	
	composer = ( TypeOf ( Source ) = Type ( "DataCompositionSettingsComposer" ) );
	settings = ? ( composer, Source.Settings, Source );
	filter = filterItem ( Name, settings.Filter.Items, Deeply );
	if ( composer ) then
		if ( filter <> undefined
			and filter.UserSettingID <> "" ) then
			filter = Source.UserSettings.Items.Find ( filter.UserSettingID );
		endif; 
	endif; 
	return filter;
	
endfunction

function filterItem ( Name, Items, Deeply )
	
	field = new DataCompositionField ( Name );
	group = Type ( "DataCompositionFilterItemGroup" );
	for each filter in Items do
		if ( TypeOf ( filter ) = group ) then
			if ( Deeply ) then
				result = filterItem ( Name, filter.Items, Deeply );
				if ( result <> undefined ) then
					return result;
				endif; 
			endif; 
		else
			if ( filter.LeftValue = field ) then
				return filter;
			endif; 
		endif; 
	enddo;
	return undefined;
	
endfunction

procedure ChangeFilter ( Source, Name, Value, Setup, ComparisonType = undefined ) export
	
	DC.DeleteFilter ( Source, Name );
	if ( Setup ) then
		DC.SetFilter ( Source, Name, Value, ComparisonType );
	endif;
	
endprocedure

procedure SetFilter ( Source, Name, Value, ComparisonType = undefined, ViewMode = undefined ) export
	
	item = DC.FindFilter ( Source, Name );
	if ( item = undefined ) then
		composer = ( TypeOf ( Source ) = Type ( "DataCompositionSettingsComposer" ) );
		if ( composer ) then
			id = Source.Settings.Filter.UserSettingID;
			if ( id = "" ) then
				items = Source.Settings.Filter.Items;
			else
				items = Source.UserSettings.Items.Find ( id ).Items;
			endif; 
		else
			items = Source.Filter.Items;
		endif; 
		item = items.Add ( Type ( "DataCompositionFilterItem" ) );
		item.LeftValue = new DataCompositionField ( Name );
	endif; 
	if ( ComparisonType <> undefined ) then
		item.ComparisonType = ComparisonType;
	endif;
	applyFilter ( item, ComparisonType, Value );
	item.Use = true;
	item.ViewMode = ? ( ViewMode = undefined, DataCompositionSettingsItemViewMode.Inaccessible, ViewMode );
	
endprocedure

procedure AddFilter ( Source, Name, Value, ComparisonType = undefined, ViewMode = undefined ) export
	
	composer = ( TypeOf ( Source ) = Type ( "DataCompositionSettingsComposer" ) );
	if ( composer ) then
		id = Source.Settings.Filter.UserSettingID;
		if ( id = "" ) then
			items = Source.Settings.Filter.Items;
		else
			items = Source.UserSettings.Items.Find ( id ).Items;
		endif; 
	else
		items = Source.Filter.Items;
	endif; 
	item = items.Add ( Type ( "DataCompositionFilterItem" ) );
	item.LeftValue = new DataCompositionField ( Name );
	applyFilter ( item, ComparisonType, Value );
	item.Use = true;
	item.ViewMode = ? ( ViewMode = undefined, DataCompositionSettingsItemViewMode.Inaccessible, ViewMode );
	
endprocedure

procedure SetParameter ( Source, Name, Value, Setup = true ) export
	
	parameter = DC.GetParameter ( Source, Name );
	if ( Setup ) then
		parameter.Value = Value;
		parameter.Use = true;
	else
		parameter.Use = false;
	endif;
	
endprocedure

function GetParameter ( Source, Name ) export
	
	parameter = DC.FindParameter ( Source, Name );
	if ( parameter = undefined ) then
		type = TypeOf ( Source );
		if ( type = Type ( "DataCompositionSettingsComposer" ) ) then
			parameter = Source.Settings.DataParameters.Items.Add ();
		elsif ( type = Type ( "DataCompositionSettings" ) ) then
			parameter = Source.DataParameters.Items.Add ();
		endif;
		if ( parameter <> undefined ) then
			parameter.Parameter = new DataCompositionParameter ( Name );
		endif;
	endif; 
	return parameter;
	
endfunction

function FindParameter ( Source, Name ) export
	
	composer = ( TypeOf ( Source ) = Type ( "DataCompositionSettingsComposer" ) );
	settings = ? ( composer, Source.Settings, Source );
	target = new DataCompositionParameter ( Name );
	try
		parameter = settings.DataParameters.FindParameterValue ( target );
	except
	endtry;
	if ( parameter = undefined ) then
		try
			parameter = settings.Parameters.FindParameterValue ( target );
		except
		endtry;
	endif; 
	if ( composer
		and parameter <> undefined
		and parameter.UserSettingID <> "" ) then
		return Source.UserSettings.Items.Find ( parameter.UserSettingID );
	endif; 
	return parameter;
	
endfunction

procedure SetOrder ( List, Expression ) export
	
	p = getOrderParams ( Expression );
	deleteOrder ( List.Order.Items, p.Field );
	item = List.Order.Items.Add ( Type ( "DataCompositionOrderItem" ) );
	item.Use = true;
	item.Field = p.Field;
	item.OrderType = p.Direction;
	
endprocedure

function getOrderParams ( Expression )
	
	exp = Conversion.StringToArray ( Expression, " " );
	p = new Structure ();
	p.Insert ( "Field", new DataCompositionField ( exp [ 0 ] ) );
	p.Insert ( "Direction", ? ( exp.Count () = 1, DataCompositionSortDirection.Asc, DataCompositionSortDirection [ exp [ 1 ] ] ) );
	return p;
	
endfunction 

procedure deleteOrder ( Items, Field )
	
	i = Items.Count ();
	while ( i > 0 ) do
		i = i - 1;
		item = Items [ i ];
		if ( item.Field = Field ) then
			Items.Delete ( item );
		endif;
	enddo; 
	
endprocedure

procedure RemoveOrder ( List, Name ) export
	
	deleteOrder ( List.Order.Items, new DataCompositionField ( Name ) );
	
endprocedure 

function FindValue ( Composer, Name ) export
	
	value = undefined;
	item = DC.FindFilter ( Composer, Name, false );
	if ( item = undefined ) then
		item = DC.FindParameter ( Composer, Name );
		if ( item <> undefined
			and item.Use ) then
			value = item.Value;
		endif; 
	else
		if ( item.Use
			and item.ComparisonType = DataCompositionComparisonType.Equal ) then
			value = item.RightValue;
		endif;
	endif;
	return ? ( ValueIsFilled ( value ), value, undefined );
	
endfunction 

function FindSetting ( Composer, Name ) export
	
	item = DC.FindFilter ( Composer, Name, false );
	if ( item = undefined ) then
		item = DC.FindParameter ( Composer, Name );
	endif;
	return item;
	
endfunction 
