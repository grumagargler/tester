&atclient
function That ( CheckVal, Message = "" ) export 
	
	runMethod ( "That", 2, CheckVal, Message );
	return ThisObject;
	
endfunction

&atserver
procedure runMethod ( val Method, val Agruments, val P1 = undefined, val P2 = undefined )
	
	p = new Array ();
	for i = 1 to Agruments do
		p.Add ( "P" + Format ( i, "NG=" ) );
	enddo;
	obj = FormAttributeToValue ( "Object" );
	Execute ( "obj." + Method + "( " + StrConcat ( p, "," ) + " )" );
	ValueToFormAttribute ( obj, "Object" );
	
endprocedure

&atclient
function Not_ () export
	
	runMethod ( "Not_", 0 );
	return ThisObject;
	
endfunction

&atclient
function Не_ () export
	
	return Not_ ();
	
endfunction

&atclient
function IsTrue () export 
	
	runMethod ( "IsTrue", 0 );
	return ThisObject;
	
endfunction

&atclient
function ЭтоИстина () export
	
	return IsTrue ();
	
endfunction

&atclient
function IsFalse () export 
	
	runMethod ( "IsFalse", 0 );
	return ThisObject;
	
endfunction

&atclient
function ЭтоЛожь () export
	
	return IsFalse ();
	
endfunction

&atclient
function Equal ( Value ) export 
	
	runMethod ( "Equal", 1, Value );
	return ThisObject;
	
endfunction

&atclient
function Равно ( Value ) export
	
	return Equal ( Value );
	
endfunction

&atclient
function NotEqual ( Value ) export 
	
	runMethod ( "NotEqual", 1, Value );
	return ThisObject;
	
endfunction

&atclient
function НеРавно ( Value ) export
	
	return NotEqual ( Value );
	
endfunction

&atclient
function Greater ( Value ) export 
	
	runMethod ( "Greater", 1, Value );
	return ThisObject;
	
endfunction

&atclient
function Больше ( Value ) export
	
	return Greater ( Value );
	
endfunction

&atclient
function GreaterOrEqual ( Value ) export 
	
	runMethod ( "GreaterOrEqual", 1, Value );
	return ThisObject;
	
endfunction

&atclient
function БольшеИлиРавно ( Value ) export
	
	return GreaterOrEqual ( Value );
	
endfunction

&atclient
function Less ( Value ) export 
	
	runMethod ( "Less", 1, Value );
	return ThisObject;
	
endfunction

&atclient
function Меньше ( Value ) export
	
	return Less ( Value );
	
endfunction

&atclient
function LessOrEqual ( Value ) export 
	
	runMethod ( "LessOrEqual", 1, Value );
	return ThisObject;
	
endfunction

&atclient
function МеньшеИлиРавно ( Value ) export
	
	return LessOrEqual ( Value );
	
endfunction

&atclient
function Filled () export 
	
	runMethod ( "Filled", 0 );
	return ThisObject;
	
endfunction

&atclient
function Заполнено () export
	
	return Filled ();
	
endfunction

&atclient
function Empty () export 
	
	runMethod ( "Empty", 0 );
	return ThisObject;
	
endfunction

&atclient
function Пусто () export
	
	return Empty ();
	
endfunction

&atclient
function Exists () export 
	
	runMethod ( "Exists", 0 );
	return ThisObject;
	
endfunction

&atclient
function Существует () export
	
	return Exists ();
	
endfunction

&atclient
function IsNull () export 
	
	runMethod ( "IsNull", 0 );
	return ThisObject;
	
endfunction

&atclient
function ЭтоNull () export
	
	return IsNull ();
	
endfunction

&atclient
function ЕстьNull () export
	
	return IsNull ();
	
endfunction

&atclient
function IsUndefined () export 
	
	runMethod ( "IsUndefined", 0 );
	return ThisObject;
	
endfunction

&atclient
function ЭтоНеопределено () export
	
	return IsUndefined ();
	
endfunction

&atclient
function Between ( Start, Finish ) export 
	
	runMethod ( "Between", 2, Start, Finish );
	return ThisObject;
	
endfunction

&atclient
function Между ( Start, Finish ) export
	
	return Between ( Start, Finish );
	
endfunction

&atclient
function Contains ( Value ) export 
	
	runMethod ( "Contains", 1, Value );
	return ThisObject;
	
endfunction

&atclient
function Содержит ( Value ) export
	
	return Contains ( Value );
	
endfunction

&atclient
function Has ( Size ) export 
	
	runMethod ( "Has", 1, Size );
	return ThisObject;
	
endfunction

&atclient
function ИмеетДлину ( Size ) export
	
	return Has ( Size );
	
endfunction

&atclient
function Вмещает ( Size ) export
	
	return Has ( Size );
	
endfunction
