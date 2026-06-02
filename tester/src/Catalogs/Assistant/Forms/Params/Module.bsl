&atserver
var NameDefined;
&atclient
var NavigationComplete;

// *****************************************
// *********** Form events

&atserver
procedure OnCreateAtServer ( Cancel, StandardProcessing )
	
	loadParams ();
	applyParams ();
	buildExpression ( ThisObject );
	setFocus ();
	readAppearance ();
	Appearance.Apply ( ThisObject );
	
endprocedure

&atserver
procedure readAppearance ()

	rules = new Array ();
	rules.Add ( "
	|Param1 enable ParamsCount > 0;
	|Param2 enable ParamsCount > 1;
	|Param3 enable ParamsCount > 2;
	|Param4 enable ParamsCount > 3;
	|Param5 enable ParamsCount > 4;
	|Running show Picking and Connected
	|" );
	Appearance.Read ( ThisObject, rules );

endprocedure

&atserver
procedure loadParams ()
	
	Picking = Parameters.Picking;
	Help = OnlineHelp.Href ( Parameters.Help );
	
endprocedure

&atserver
procedure applyParams ()
	
	Running = Picking;
	params = putMethod ();
	if ( params <> undefined ) then
		putParams ( params );
	endif; 
	if ( Picking ) then
		EnterKeyBehavior = EnterKeyBehaviorType.DefaultButton;
	endif; 

endprocedure 

&atserver
function putMethod ()

	s = Parameters.Method;
	pattern = "(.+)\(";
	matches = Regexp.Select ( s, pattern );
	Method = TrimAll ( matches [ 0 ].Groups [ 0 ] );
	pattern = "\((.+)\)";
	matches = Regexp.Select ( s, pattern );
	if ( matches.Count () = 0 ) then
		return undefined;
	endif;
	params = StrSplit ( matches [ 0 ].Groups [ 0 ], "," );
	ParamsCount = params.Count ();
	return params;
	
endfunction 

&atserver
procedure putParams ( Params )
	
	NameDefined = ( Parameters.ControlName = "" );
	pattern = "(.+)=(.+)";
	for i = 0 to ParamsCount - 1 do
		p = TrimAll ( Params [ i ] );
		matches = Regexp.Select ( p, pattern );
		if ( matches.Count () = 0 ) then
			label = p;
			mandatory = true;
		else
			label = TrimAll ( matches [ 0 ].Groups [ 0 ] );
			mandatory = false;
		endif; 
		field = "Param" + ( i + 1 );
		control = Items [ field ];
		control.Title = label;
		control.MarkIncomplete = mandatory;
		control.AutoChoiceIncomplete = mandatory;
		if ( not NameDefined ) then
			putName ( field, label );
		endif; 
	enddo; 
	
endprocedure 

&atserver
procedure putName ( Field, Label )
	
	s = Lower ( label );
	if ( s = "name"
		or s = "имя"
		or s = "table"
		or s = "таблица" ) then
		ThisObject [ field ] = """" + Parameters.ControlName + """";
		NameDefined = true;
	endif; 
	
endprocedure 

&atserver
procedure setFocus ()
	
	if ( ParamsCount = 0 ) then
		CurrentItem = Items.Method;
	else
		CurrentItem = Items.Param1;
	endif; 
	
endprocedure 

&atclient
procedure OnOpen ( Cancel )
	
	init ();
	Appearance.Apply ( ThisObject, "Connected" );
	
endprocedure

&atclient
procedure init ()
	
	Connected = AppData <> undefined and AppData.Connected;
	
endprocedure

// *****************************************
// *********** Group Form

&atclient
procedure OK ( Command )
	
	Close ( getResult () );
	
endprocedure

&atclient
function getResult ()
	
	if ( Picking ) then
		return new Structure ( "Picking, Expression, Running", Picking, Expression, Picking and Running and Connected );
	else
		return Expression;
	endif; 
	
endfunction 

&atclient
procedure ParamStartChoice ( Item, ChoiceData, StandardProcessing )
	
	StandardProcessing = false;
	ScenarioForm.Picking ( Item, true );
	
endprocedure

&atclient
procedure ParamOnChange ( Item )
	
	if ( Quotes ) then
		quote ( Item.Name );
	endif; 
	buildExpression ( ThisObject );
	
endprocedure

&atclient
procedure quote ( Parameter )
	
	q = """";
	field = ThisObject [ Parameter ];
	text = TrimAll ( field );
	if ( field = ""
		or field = "_"
		or field = "__"
		or Left ( text, 2 ) = "_."
		or Left ( text, 3 ) = "__."
		or ( Left ( text, 1 ) = q
			and Right ( text, 1 ) = q ) ) then
		return;
	endif;
	ThisObject [ Parameter ] = q + StrReplace ( field, q, q + q ) + q;
	
endprocedure 

&atclientatservernocontext
procedure buildExpression ( Form )
	
	params = buildParams ( Form );
	if ( params = "" ) then
		Form.Expression = Form.Method + " ();";
	else
		Form.Expression = Form.Method + " ( " + params + " );";
	endif; 
	
endprocedure

&atclientatservernocontext
function buildParams ( Form )
	
	params = new Array ();
	for i = 0 to Form.ParamsCount - 1 do
		value = Form [ "Param" + ( i + 1 ) ];
		params.Add ( value );
	enddo; 
	i = i - 1;
	while ( i >= 0 ) do
		value = params [ i ];
		if ( ValueIsFilled ( value ) ) then
			break;
		else
			params.Delete ( i );
		endif; 
		i = i - 1;
	enddo; 
	return StrConcat ( params, ", " );
	
endfunction 

// *****************************************
// *********** Help

&atclient
procedure HelpDocumentComplete ( Item )
	
	if ( Framework.VersionLess ( "8.3.14" ) ) then
		return;
	endif;
	if ( NavigationComplete = undefined ) then
		NavigationComplete = true;
		Item.Document.location.hash = "#" + Parameters.Help;
	endif;

endprocedure
