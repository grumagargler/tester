&atserver
procedure Read ( Form, Rules = undefined ) export
	
	p = Form.Parameters.FunctionalOptionsParameters;
	p.Insert ( "User", SessionParameters.User );
	p.Insert ( "Session", SessionParameters.Session );
	if ( Rules = undefined ) then
		return;
	endif;
	Form.AppearanceData = CoreLibrary.ParseAppearance ( Rules );
	
endprocedure

procedure Apply ( Form, Value = undefined, CanBeDisallowed = false ) export
	
	if ( appearanceIsReady ( Form ) ) then
		if ( Value = undefined ) then
			values = new Array ();
			values.Add ( undefined );
		else
			values = Conversion.StringToArray ( Value );
		endif;
		for each item in values do
			applyAppearance ( Form, item, false, CanBeDisallowed );
		enddo;
	endif; 
	
endprocedure 

function appearanceIsReady ( Form )
	
	return Form.AppearanceData <> undefined;
	
endfunction 

procedure applyAppearance ( Form, Value, IsItemUpdate, CanBeDisallowed )
	
	items = Form.Items;
	dependencyFound = false;
	for each item in Form.AppearanceData do
		directive = item.Directive;
		if ( directive <> "" ) then
			#if ( not ThickClientManagedApplication ) then
				#if ( Server or ExternalConnection ) then
					if ( directive = "c"
						or directive = "к" ) then
						continue;
					endif;
				#endif
				#if ( Client ) then
					if ( directive = "s"
						or directive = "с" ) then // 'c' is Russian
						continue;
					endif;
				#endif
			#endif
		endif;
		if ( not appearanceDependsOn ( item, Value, IsItemUpdate ) ) then
			continue;
		endif; 
		dependencyFound = true;
		#if ( ThickClientManagedApplication ) then
			try
				result = eval ( item.Expression );
			except
				continue;
			endtry;
		#else
			result = eval ( item.Expression );
		#endif
		formatFields ( Form, items, item, result );
	enddo;
	if ( Value = undefined or CanBeDisallowed or dependencyFound ) then
	else
		raise "Conditional appearance cannot find dependency by name: " + Value;
	endif; 
	
endprocedure 

function appearanceDependsOn ( Item, Value, IsItemUpdate )
	
	if ( Value = undefined ) then
		return true;
	endif;
	if ( IsItemUpdate ) then
		return Item.Controls.Find ( Value ) <> undefined;
	else
		return Item.Fields.Find ( Value ) <> undefined;
	endif; 
	
endfunction 

procedure formatFields ( Form, Items, AppearanceItem, Result )
	
	yes = Result;
	no = not Result;
	formats = new Array ();
	for each operation in AppearanceItem.Appearance do
		formats.Add ( StrSplit ( operation, "/" ) );
	enddo;
	for each field in AppearanceItem.Controls do
		if ( field = "ThisObject"
			or field = "ЭтотОбъект" ) then
			item = Form;
		else
			item = Items.Find ( field );
			if ( item = undefined ) then
				continue;
			endif;
		endif;
		for each operation in formats do
			format = operation [ 0 ];
			if ( format = "show"
				or format = "показать" ) then
				item.Visible = yes;
			elsif ( format = "hide"
				or format = "скрыть" ) then
				item.Visible = no;
			elsif ( format = "enable"
				or format = "включить" ) then
				item.Enabled = yes;
			elsif ( format = "disable"
				or format = "выключить" ) then
				item.Enabled = no;
			elsif ( format = "lock"
				or format = "закрыть" ) then
				if ( TypeOf ( Item ) = Type ( "FormButton" ) ) then
					item.Enabled = yes;
				else
					item.ReadOnly = yes;
				endif;
			elsif ( format = "unlock"
				or format = "открыть" ) then
				item.ReadOnly = no;
			elsif ( format = "press"
				or format = "прижать" ) then
				item.Check = yes;
			elsif ( format = "release"
				or format = "отжать" ) then
				item.Check = no;
			elsif ( format = "mark"
				or format = "отметить" ) then
				item.MarkIncomplete = yes;
			elsif ( format = "unmark"
				or format = "снятьотметку" ) then
				item.MarkIncomplete = no;
			elsif ( format = "title"
				or format = "назвать" ) then
				if ( yes ) then
					item.Title = expressionToValue ( Form, operation [ 1 ] );
				endif;
			elsif ( format = "hint"
				or format = "подсказать" ) then
				if ( yes ) then
					item.InputHint = expressionToValue ( Form, operation [ 1 ] );
				endif;
			elsif ( format = "assign"
				or format = "назначить" ) then
				item.DefaultButton = yes;
			endif;
		enddo;
	enddo; 
	
endprocedure 

function expressionToValue ( Form, Expression )
	
	try
		return eval ( Expression + "()" );
	except
		return eval ( "String(" + Expression + ")" );
	endtry;
	
endfunction

procedure Update ( Form, Item, CanBeDisallowed = false ) export
	
	if ( appearanceIsReady ( Form ) ) then
		applyAppearance ( Form, Item, true, CanBeDisallowed );
	endif;
	
endprocedure 

#region BuiltitFunction

function inlist ( Value, _1, _2 = undefined, _3 = undefined, _4 = undefined, _5 = undefined, _6 = undefined, _7 = undefined, _8 = undefined, _9 = undefined, _10 = undefined, _11 = undefined, _12 = undefined, _13 = undefined, _14 = undefined, _15 = undefined, _16 = undefined, _17 = undefined, _18 = undefined, _19 = undefined, _20 = undefined ) export
	
	return Value = _1
	or Value = _2
	or Value = _3
	or Value = _4
	or Value = _5
	or Value = _6
	or Value = _7
	or Value = _8
	or Value = _9
	or Value = _10
	or Value = _11
	or Value = _12
	or Value = _13
	or Value = _14
	or Value = _15
	or Value = _16
	or Value = _17
	or Value = _18
	or Value = _19
	or Value = _20;
	
endfunction

function всписке ( Value, _1, _2 = undefined, _3 = undefined, _4 = undefined, _5 = undefined, _6 = undefined, _7 = undefined, _8 = undefined, _9 = undefined, _10 = undefined, _11 = undefined, _12 = undefined, _13 = undefined, _14 = undefined, _15 = undefined, _16 = undefined, _17 = undefined, _18 = undefined, _19 = undefined, _20 = undefined ) export
	
	return inlist ( Value, _1, _2, _3, _4, _5, _6, _7, _8, _9, _10, _11, _12, _13, _14, _15, _16, _17, _18, _19, _20 );
	
endfunction

function field ( Value, Name ) export
	
	return DF.Pick ( Value, Name );

endfunction

function поле ( Value, Name ) export
	
	return field ( Value, Name );

endfunction

#endregion
