function Values ( val Ref, val Fields ) export
	
	set = ? ( TypeOf ( Fields ) = Type ( "Array" ), StrConcat ( Fields, "," ), Fields );
	meta = Ref.Metadata ();
	typesStructure = getTypes ( meta, set );
	s = "
	|select allowed " + set + "
	|from " + meta.FullName () + " as T_a_b_l_e
	|where T_a_b_l_e.Ref = &Ref
	|";
	q = new Query ( s );
	q.SetParameter ( "Ref", Ref );
	queryResult = q.Execute ();
	selection = queryResult.Select ();
	selection.Next ();
	result = new Structure ();
	for each column in queryResult.Columns do
		name = column.Name;
		if ( Metadata.ScriptVariant = Metadata.ObjectProperties.ScriptVariant.Russian ) then
			if ( name = "Код" ) then
				name = "Code";
			elsif ( name = "Наименование" ) then
				name = "Description";
			endif; 
		endif; 
		valueType = typesStructure [ name ];
		value = selection [ name ];
		if ( valueType <> undefined ) then
			value = valueType.AdjustValue ( value );
		endif; 
		result.Insert ( name, value );
	enddo; 
	return result;
	
endfunction

function getTypes ( Meta, Fields )
	
	var field;
	var name;
	types = new Structure ();
	attributesArray = Conversion.StringToArray ( Fields );
	for each attribute in attributesArray do
		setFieldAndName ( attribute, field, name );
		types.Insert ( name, getFieldType ( meta, field ) );
	enddo; 
	return types;
	
endfunction

procedure setFieldAndName ( Attribute, Field, Name )
	
	synonym = Find ( Attribute, " as " );
	if ( synonym = 0 ) then
		Name = StrReplace ( Attribute, ".", "" );
		Field = Attribute;
	else
		Field = Left ( Attribute, synonym - 1 );
		Name = Mid ( Attribute, synonym + 4 );
	endif; 
	
endprocedure

function getFieldType ( Meta, Field )
	
	currentMeta = Meta;
	attributesArray = Conversion.StringToArray ( Field, "." );
	for each attribute in attributesArray do
		foundAttr = currentMeta.Attributes.Find ( attribute );
		if ( foundAttr = undefined ) then
			if ( Metadata.Tasks.Contains ( currentMeta ) ) then
				foundAttr = currentMeta.AddressingAttributes.Find ( attribute );
			elsif ( Metadata.ChartsOfAccounts.Contains ( currentMeta ) ) then
				foundAttr = currentMeta.AccountingFlags.Find ( attribute );
			endif;
			if ( foundAttr = undefined ) then
				foundAttr = currentMeta.StandardAttributes [ attribute ]; // StandardAttributes does not support Find () method
			endif; 
		endif; 
		currentType = foundAttr.Type;
		currentTypeTypes = currentType.Types ();
		if ( currentType = Type ( "Date" )
			or currentType = Type ( "String" )
			or currentType = Type ( "Number" )
			or currentType = Type ( "Boolean" )
			or currentType = Type ( "ValueStorage" ) ) then
			break;
		endif; 
		if ( currentTypeTypes.Count () > 1 ) then
			currentType = undefined;
			break;
		endif; 
		currentMeta = Metadata.FindByType ( currentTypeTypes [ 0 ] );
	enddo; 
	return currentType;

endfunction

function Pick ( val Ref, val Field, val Default = undefined ) export
	
	if ( Default <> undefined
		and Ref.IsEmpty () ) then
		return Default;
	endif; 
	name = fieldName ( Field );
	return Values ( Ref, Field ) [ name ];
	
endfunction

function fieldName ( Field )
	
	synonym = Find ( Field, " as " );
	if ( synonym = 0 ) then
		return StrReplace ( Field, ".", "" );
	else
		return Mid ( Field, synonym + 4 );
	endif; 
	
endfunction

function GetOriginal ( Exception, Field, Value, Owner = undefined ) export
	
	if ( not ValueIsFilled ( Value ) ) then
		return undefined;
	endif; 
	s = "
	|select top 1 Ref as Ref
	|from " + Metadata.FindByType ( TypeOf ( Exception ) ).FullName () + "
	|where " + Field + " = &" + Field;
	if ( Owner <> undefined ) then
		s = s + " and Owner = &Owner";
	endif; 
	if ( not Exception.IsEmpty () ) then
		s = s + " and Ref <> &Ref";
	endif; 
	q = new Query ( s );
	q.SetParameter ( "Ref", Exception );
	q.SetParameter ( "Owner", Owner );
	q.SetParameter ( Field,	Value );
	result = q.Execute ().Unload ();
	return ? ( result.Count () = 0, undefined, result [ 0 ].Ref );
		
endfunction
