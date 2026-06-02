
function GetGroup ( Source, Name, SearchInFields = false ) export
	
	composer = ( TypeOf ( Source ) = Type ( "DataCompositionSettingsComposer" ) );
	settings = ? ( composer, Source.Settings, Source );
	list = new Array ();
	groupsByName ( settings.Structure, Name, SearchInFields, list );
	if ( list.Count () = 0 ) then
		return undefined; 
	endif;
	groups = new Array ();
	if ( composer ) then
		items = Source.UserSettings.Items;
		for each group in list do
			groups.Add ( items.Find ( group.UserSettingID ) );
		enddo;
	else
		groups = list;
	endif; 
	return ? ( groups.Count () = 1, groups [ 0 ], groups );
	
endfunction
 
procedure groupsByName ( Container, Name, SearchInFields, Groups )
	
	groupType = Type ( "DataCompositionGroup" );
	tableType = Type ( "DataCompositionTable" );
	tableGroupType = Type ( "DataCompositionTableGroup" );
	for each item in Container do
		type = TypeOf ( item ); 
		if ( type = tableType ) then
			items = new Array ();
			items.Add ( item.Rows );
			items.Add ( item.Columns );
			for each element in items do
				groupsByName ( element, Name, SearchInFields, Groups );
			enddo; 
		elsif ( type = groupType
			or type = tableGroupType ) then
			if ( item.Name = Name ) then
				Groups.Add ( item );
			endif;
			if ( SearchInFields ) then
				field = new DataCompositionField ( Name );
				for each group in item.GroupFields.Items do
					if ( group.Field = field ) then
						Groups.Add ( item );
					endif; 
				enddo; 
			endif; 
			if ( item.Structure.Count () > 0 ) then
				groupsByName ( item.Structure, Name, SearchInFields, Groups );
			endif; 
		endif; 
	enddo; 
	
endprocedure

function FindField ( Group, Name ) export
	
	field = new DataCompositionField ( Name );
	for each item in Group.GroupFields.Items do
		if ( item.Field = field ) then
			return item;
		endif; 
	enddo; 
	return undefined;
	
endfunction 

function GetField ( Selection, Path ) export
	
	field = new DataCompositionField ( Path );
	groupType = Type ( "DataCompositionSelectedFieldGroup" );
	fieldType = Type ( "DataCompositionSelectedField" );
	for each item in Selection.Items do
		itemType = TypeOf ( item );
		if ( itemType = groupType ) then
			foundField = GetField ( item, Path );
			if ( foundField <> undefined ) then
				return foundField;
			endif; 
		elsif ( itemType = fieldType ) then
			if ( item.Field = field ) then
				return item;
			endif; 
		endif; 
	enddo; 
	return undefined;
	
endfunction

function Insert ( Item, Destination ) export
	
	return runCopying ( Item.Parent, Item, Destination, undefined, new Map () );
	
endfunction 

function runCopying ( Node, Item, Destination, Index, Map )
	
	type = TypeOf ( Item );
	params = copyingParams ( type, Destination );
	if ( params.TypeRequired ) then
		if ( Index = undefined ) then
			row = Destination.Add ( type );
		else
			Index = Index + 1;
			row = Destination.Insert ( Index, type );
		endif;
	else
		if ( Index = undefined ) then
			row = Destination.Add ();
		else
			Index = Index + 1;
			row = Destination.Insert ( Index );
		endif;
	endif;
	if ( params.ExcludeProperties <> "*" ) then
		FillPropertyValues ( row, Item, , params.ExcludeProperties );
	endif;
	if ( params.Tree ) then
		Map.Insert ( Item, row );
		nestedSet = Item.GetItems ();
		if nestedSet.Count () > 0 then
			nestedItems = row.GetItems ();
			for each subRow in nestedSet do
				runCopying ( Node, subRow, nestedItems, undefined, Map );
			enddo;
		endif;
	else
		oldID = Node.GetIDByObject ( Item );
		newID = Node.GetIDByObject ( row );
		Map.Insert ( oldID, newID );
		if ( params.Settings ) then
			row = row.Settings;
			subRow = subRow.Settings;
		endif;
		if ( params.Items ) then
			nestedSet = Item.Items;
			if ( nestedSet.Count () > 0 ) then
				nestedItems = row.Items;
				for each subRow in nestedSet do
					runCopying ( Node, subRow, nestedItems, undefined, Map );
				enddo;
			endif;
		endif;
		if ( params.Selection ) then
			FillPropertyValues(row.Selection, Item.Selection, , "SelectionAvailableFields, Items" );
			nestedSet = Item.Selection.Items;
			if ( nestedSet.Count () > 0 ) then
				nestedItems = row.Selection.Items;
				for each subRow in nestedSet do
					runCopying ( Node, subRow, nestedItems, undefined, Map );
				enddo;
			endif;
		endif;
		if ( params.Filter ) then
			FillPropertyValues ( row.Filter, Item.Filter, , "FilterAvailableFields, Items" );
			nestedSet = Item.Filter.Items;
			if ( nestedSet.Count () > 0 ) then
				nestedItems = row.Filter.Items;
				for each subRow in nestedSet do
					runCopying ( Node, subRow, nestedItems, undefined, new Map () );
				enddo;
			endif;
		endif;
		if ( params.OutputParams ) then
			nestedSet = Item.OutputParameters.Items;
			if ( nestedSet.Count () > 0 ) then
				nestedNode = row.OutputParameters;
				for each subRow in nestedSet do
					value = nestedNode.FindParameterValue ( subRow.Parameter );
					if ( value <> undefined ) then
						FillPropertyValues ( value, subRow );
					endif;
				enddo;
			endif;
		endif;
		if ( params.DataParams ) then
			nestedSet = Item.DataParameters.Items;
			if ( nestedSet.Count () > 0 ) then
				nestedItems = row.DataParameters.Items;
				for each subRow in nestedSet do
					runCopying ( Node, subRow, nestedItems, undefined, Map );
				enddo;
			endif;
		endif;
		if ( params.UserFields ) then
			nestedSet = Item.UserFields.Items;
			if ( nestedSet.Count () > 0 ) then
				nestedItems = row.UserFields.Items;
				for each subRow in nestedSet do
					runCopying ( Node, subRow, nestedItems, undefined, Map );
				enddo;
			endif;
		endif;
		if ( params.GroupFields ) then
			nestedSet = Item.GroupFields.Items;
			if nestedSet.Count () > 0 then
				nestedItems = row.GroupFields.Items;
				for each subRow in nestedSet do
					runCopying ( Node, subRow, nestedItems, undefined, new Map () );
				enddo;
			endif;
		endif;
		if ( params.Order ) then
			FillPropertyValues ( row.Order, Item.Order, , "OrderAvailableFields, Items" );
			nestedSet = Item.Order.Items;
			if ( nestedSet.Count () > 0 ) then
				nestedItems = row.Order.Items;
				for each subRow in nestedSet do
					runCopying ( Node, subRow, nestedItems, undefined, Map );
				enddo;
			endif;
		endif;
		if ( params.Structure ) then
			FillPropertyValues ( row.Structure, Item.Structure );
			nestedSet = Item.Structure;
			if ( nestedSet.Count () > 0 ) then
				nestedItems = row.Structure;
				for each subRow in nestedSet do
					runCopying ( Node, subRow, nestedItems, undefined, Map );
				enddo;
			endif;
		endif;
		if ( params.Appearance ) then
			FillPropertyValues ( row.ConditionalAppearance, Item.ConditionalAppearance, , "FilterAvailableFields, FieldsAvailableFields, Items" );
			nestedSet = Item.ConditionalAppearance.Items;
			if ( nestedSet.Count () > 0 ) then
				nestedItems = row.ConditionalAppearance.Items;
				for each subRow in nestedSet do
					runCopying ( Node, subRow, nestedItems, undefined, Map );
				enddo;
			endif;
		endif;
		if ( params.RowsColumns ) then
			nestedSet = Item.Columns;
			nestedItems = row.Columns;
			oldID = Node.GetIDByObject ( nestedSet );
			newID = Node.GetIDByObject ( nestedItems );
			Map.Insert ( oldID, newID );
			for each subRow in nestedSet do
				runCopying ( Node, subRow, nestedItems, undefined, Map );
			enddo;
			nestedSet = Item.Rows;
			nestedItems = row.Rows;
			oldID = Node.GetIDByObject ( nestedSet );
			newID = Node.GetIDByObject ( nestedItems );
			Map.Insert ( oldID, newID );
			for each subRow in nestedSet do
				runCopying ( Node, subRow, nestedItems, undefined, Map );
			enddo;
		endif;
		if ( params.Points ) then
			nestedSet = Item.Series;
			nestedItems = row.Series;
			oldID = Node.GetIDByObject ( nestedSet );
			newID = Node.GetIDByObject ( nestedItems );
			Map.Insert ( oldID, newID );
			for each subRow in nestedSet do
				runCopying ( Node, subRow, nestedItems, undefined, Map );
			enddo;
			nestedSet = Item.Points;
			nestedItems = row.Points;
			oldID = Node.GetIDByObject ( nestedSet );
			newID = Node.GetIDByObject ( nestedItems );
			Map.Insert ( oldID, newID );
			for each subRow in nestedSet do
				runCopying ( Node, subRow, nestedItems, undefined, Map );
			enddo;
		endif;
		if ( params.NestedParams ) then
			for each subRow in Item.NestedParameterValues do
				runCopying ( Node, subRow, row.NestedParameterValues, undefined, Map );
			enddo;
		endif;
		if ( params.FieldsAppearance ) then
			for each field in Item.Fields.Items do
				FillPropertyValues ( row.Fields.Items.Add (), field );
			enddo;
			for each source in Item.Appearance.Items do
				receiver = row.Appearance.FindParameterValue ( source.Parameter );
				if ( receiver <> undefined ) then
					FillPropertyValues ( receiver, source, , "Parent" );
				endif;
			enddo;
		endif;
	endif;
	return row;
	
endfunction

function copyingParams ( Type, Set )
	
	result = new Structure ();
	result.Insert ( "TypeRequired", false );
	result.Insert ( "Tree", false );
	result.Insert ( "ExcludeProperties", undefined );
	result.Insert ( "Settings", false );
	result.Insert ( "Items", false );
	result.Insert ( "Selection", false );
	result.Insert ( "Filter", false );
	result.Insert ( "OutputParams", false );
	result.Insert ( "DataParams", false );
	result.Insert ( "UserFields", false );
	result.Insert ( "GroupFields", false );
	result.Insert ( "Order", false );
	result.Insert ( "Structure", false );
	result.Insert ( "Appearance", false );
	result.Insert ( "RowsColumns", false );
	result.Insert ( "Points", false );
	result.Insert ( "NestedParams", false );
	result.Insert ( "FieldsAppearance", false );
	if ( Type = Type ( "FormDataTreeItem" ) ) then
		result.Tree = true;
	elsif ( Type = Type ( "DataCompositionSelectedFieldGroup" )
		or Type = Type ( "DataCompositionFilterItemGroup" ) ) then
		result.TypeRequired = true;
		result.ExcludeProperties = "Parent";
		result.Items = true;
	elsif ( Type = Type ( "DataCompositionSelectedField" )
		or Type = Type ( "DataCompositionAutoSelectedField" )
		or Type = Type ( "DataCompositionFilterItem" ) ) then
		result.ExcludeProperties = "Parent";
		result.TypeRequired = true;
	elsif ( Type = Type ( "DataCompositionGroupField" )
		or Type = Type ( "DataCompositionAutoGroupField" )
		or Type = Type ( "DataCompositionOrderItem" )
		or Type = Type ( "DataCompositionAutoOrderItem" ) ) then
		result.TypeRequired = true;
	elsif ( Type = Type ( "DataCompositionConditionalAppearanceItem" ) ) then
		result.Filter = true;
		result.FieldsAppearance = true;
	elsif ( Type = Type ( "DataCompositionGroup" )
		or Type = Type ( "DataCompositionTableGroup" )
		or Type = Type ( "DataCompositionChartGroup" ) ) then
		result.ExcludeProperties = "Parent";
		setType = TypeOf ( Set );
		if ( setType = Type ( "DataCompositionSettingStructureItemCollection" ) ) then
			result.TypeRequired = true;
			Type = Type ( "DataCompositionGroup" );
		endif;
		result.Selection = true;
		result.Filter = true;
		result.OutputParams = true;
		result.GroupFields = true;
		result.Order = true;
		result.Structure = true;
		result.Appearance = true;
	elsif ( Type = Type ( "DataCompositionTable" ) ) then
		result.ExcludeProperties = "Parent";
		result.TypeRequired = true;
		result.Selection = true;
		result.RowsColumns = true;
		result.OutputParams = true;
	elsif ( Type = Type ( "DataCompositionChart" ) ) then
		result.ExcludeProperties = "Parent";
		result.TypeRequired = true;
		result.Selection = true;
		result.Points = true;
		result.OutputParams = true;
	elsif ( Type = Type ( "DataCompositionNestedObjectSettings" ) ) then
		result.ExcludeProperties = "Parent";
		result.TypeRequired = true;
		result.Settings = true;
		result.Selection = true;
		result.Filter = true;
		result.OutputParams = true;
		result.DataParams = true;
		result.UserFields = true;
		result.GroupFields = true;
		result.Order = true;
		result.Structure = true;
		result.Appearance = true;
	endif;
	return result;
	
endfunction
