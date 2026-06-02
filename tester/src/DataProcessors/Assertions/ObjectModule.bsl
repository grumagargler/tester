// **************************************************************************************************
// Fluent assertions.
// Ported from https://github.com/wizi4d/xUnitFor1C_2/blob/develop/Plugins/УтвержденияBDD.epf @wizi4d
// Adopted by @JohnyDeath, @Grumagargler
// **************************************************************************************************

function That ( Something, Message = "" ) export 
	
	Value = Something;
	Details = Message;
	Negation = false;
	return ThisObject;
	
endfunction

function Not_ () export
	
	Negation = true;
	return ThisObject;
	
endfunction

function Не_ () export
	
	return Not_ ();
	
endfunction

function IsTrue () export
	
	if ( wrongResult ( Value = true ) ) then 
		throwError ( valuePresentation ( true ), "should" );
	endif;
	return ThisObject;
	
endfunction

function valuePresentation ( Something )
	
	length = undefined;
	type = TypeOf ( Something );
	if ( type = Type ( "Null" )
		or type = Type ( "Undefined" ) ) then
		display = "" + type;
	elsif ( type = Type ( "Boolean" ) ) then
		display = Format ( Something, Output.YesNo () );
	else
		display = "" + Something;
		if ( type = Type ( "Array" )
			or type = Type ( "FixedArray" )
			or type = Type ( "Structure" )
			or type = Type ( "FixedStructure" )
			or type = Type ( "Map" )
			or type = Type ( "FixedMap" )
			or type = Type ( "ValueList" ) ) then
			length = Something.Count ();
		elsif ( type = Type ( "String" ) ) then
			length = StrLen ( String ( Something ) );
		endif;
	endif;
	return display + ? ( length = undefined, "", "[" + Format ( length, "NG=;NZ=" ) + "]" );
	
endfunction

function wrongResult ( Result )
	
	wrong = ? ( Negation, Result, not Result );
	if ( wrong ) then
		return true;
	else
		Negation = false;
		return false;
	endif;
	
endfunction

procedure throwError ( RightValue, About )
	
	expression = new Array ();
	expression.Add ( displayValue () );
	if ( About = "should" ) then
		verb = ? ( Negation, Output.ShouldNotBe (), Output.ShouldBe () );
	elsif ( About = "contain" ) then
		verb = ? ( Negation, Output.ShouldNotContain (), Output.ShouldContain () );
	elsif ( About = "have" ) then
		verb = ? ( Negation, Output.ShouldNotHave (), Output.ShouldHave () );
	endif;
	expression.Add ( verb );
	expression.Add ( RightValue );
	msg = StrConcat ( expression, " " );
	if ( Details <> "" ) then
		msg = msg + Chars.LF + Details;
	endif;
	raise msg;
	
endprocedure

function displayValue ()
	
	return Output.Value () + " " + valuePresentation ( Value );
	
endfunction

function ЭтоИстина () export
	
	return IsTrue ();
	
endfunction

function IsFalse () export
	
	needed = Value = false;
	if ( wrongResult ( needed ) ) then 
		throwError ( valuePresentation ( needed ), "should" );
	endif;
	return ThisObject;
	
endfunction

function ЭтоЛожь () export
	
	return IsFalse ();
	
endfunction

function Equal ( Something ) export
	
	if ( wrongResult ( Value = Something )) then 
		comparisonError ( Something, DataCompositionComparisonType.Equal );
	endif;
	return ThisObject;
	
endfunction

procedure comparisonError ( RightValue, Operator )
	
	expression = new Array ();
	expression.Add ( Lower ( "" + Operator ) );
	expression.Add ( " " + valuePresentation ( RightValue ) );
	throwError ( StrConcat ( expression ), "should" );
	
endprocedure

function Равно ( Something ) export
	
	return Equal ( Something );
	
endfunction

function NotEqual ( Something ) export
	
	if ( wrongResult ( Value <> Something )) then 
		comparisonError ( Something, DataCompositionComparisonType.NotEqual );
	endif;
	return ThisObject;
	
endfunction

function НеРавно ( Something ) export
	
	return NotEqual ( Something );
	
endfunction

function Greater ( Something ) export
	
	if ( wrongResult ( Value > Something )) then 
		comparisonError ( Something, DataCompositionComparisonType.Greater );
	endif;
	return ThisObject;
	
endfunction

function Больше ( Something ) export
	
	return Greater ( Something );
	
endfunction

function GreaterOrEqual ( Something ) export
	
	if ( wrongResult ( Value >= Something )) then 
		comparisonError ( Something, DataCompositionComparisonType.GreaterOrEqual );
	endif;
	return ThisObject;
	
endfunction

function БольшеИлиРавно ( Something ) export
	
	return GreaterOrEqual ( Something );
	
endfunction

function Less ( Something ) export
	
	if ( wrongResult ( Value < Something )) then 
		comparisonError ( Something, DataCompositionComparisonType.Less );
	endif;
	return ThisObject;
	
endfunction

function Меньше ( Something ) export
	
	return Less ( Something );
	
endfunction

function LessOrEqual ( Something ) export
	
	if ( wrongResult ( Value <= Something )) then 
		comparisonError ( Something, DataCompositionComparisonType.LessOrEqual );
	endif;
	return ThisObject;
	
endfunction

function МеньшеИлиРавно ( Something ) export
	
	return LessOrEqual ( Something );
	
endfunction

function Filled () export
	
	if ( wrongResult ( ValueIsFilled ( Value ) )) then 
		throwError ( Output.Filled (), "should" );
	endif;
	return ThisObject;
	
endfunction

function Заполнено () export
	
	return Filled ();
	
endfunction

function Empty () export
	
	if ( wrongResult ( not ValueIsFilled ( Value ) ) ) then 
		throwError ( Output.Empty (), "should" );
	endif;
	return ThisObject;
	
endfunction

function Пусто () export
	
	return Empty ();
	
endfunction

function Exists () export
	
	needed = ( Value <> undefined ) and ( Value <> null );
	if ( wrongResult ( needed ) ) then 
		throwError ( Output.Existed (), "should" );
	endif;
	return ThisObject;
	
endfunction

function Существует () export
	
	return Exists ();
	
endfunction

function IsNull () export
	
	if ( wrongResult ( Value = null ) ) then 
		throwError ( null, "should" );
	endif;
	return ThisObject;
	
endfunction

function ЭтоNull () export
	
	return IsNull ();
	
endfunction

function ЕстьNull () export
	
	return IsNull ();
	
endfunction

function IsUndefined () export
	
	if ( wrongResult ( Value = undefined )) then 
		throwError ( undefined, "should" );
	endif;
	return ThisObject;
	
endfunction

function ЭтоНеопределено () export
	
	return IsUndefined ();
	
endfunction

function Between ( Start, Finish ) export
	
	needed = ( Value >= Start ) and ( Value <= Finish );
	if ( wrongResult ( needed ) ) then 
		throwError ( Output.Between ( new Structure ( "Start, Finish", Start, Finish ) ), "should" );
	endif;
	return ThisObject;
	
endfunction

function Между ( Start, Finish ) export
		
	return Between ( Start, Finish );
	
endfunction

function Contains ( Something ) export
	
	found = undefined;
	type = TypeOf ( Value );
	if ( type = Type ( "Array" )
		or type = Type ( "FixedArray" ) ) then 
		found = Value.Find ( Something ) <> undefined;
	elsif ( type = Type ( "Structure" )
		or type = Type ( "FixedStructure" )
		or type = Type ( "Map" )
		or type = Type ( "FixedMap" ) ) then 	
		for each item in Value do
			found = ( item.Value = Something );
			if ( found ) then 
				break;
			endif;			
		enddo;		
	elsif ( type = Type ( "ValueList" ) ) then
		found = Value.FindByValue ( Something ) <> undefined;
	else
		found = Find ( String ( Value ), Something ) > 0;
	endif;
	if ( wrongResult ( found = true ) ) then 
		throwError ( Something, "contain" );
	endif;
	return ThisObject;
	
endfunction

function Содержит ( Something ) export
	
	return Contains ( Something );
	
endfunction

function Has ( Size ) export
	
	type = TypeOf ( Value );
	if ( type = Type ( "Array" )
		or type = Type ( "FixedArray" )
		or type = Type ( "Structure" )
		or type = Type ( "FixedStructure" )
		or type = Type ( "Map" )
		or type = Type ( "FixedMap" )
		or type = Type ( "ValueList" ) ) then
		length = Value.Count ();					
	else
		length = StrLen ( String ( Value ) );
	endif;
	if ( wrongResult ( length = Size )) then 
		throwError ( Size, "have" );
	endif;
	return ThisObject;
	
endfunction

function ИмеетДлину ( Size ) export
	
	return Has ( Size );
	
endfunction

function Вмещает ( Size ) export
	
	return Has ( Size );
	
endfunction
