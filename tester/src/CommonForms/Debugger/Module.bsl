&atclient
var Closing;

// *****************************************
// *********** Form events

&atserver
procedure OnCreateAtServer ( Cancel, StandardProcessing )
	
	loadParams ();
	
endprocedure

&atserver
procedure loadParams ()
	
	IsVersion = Parameters.IsVersion;
	Row = Parameters.Row;
	code = Parameters.Module;
	Scenario = ? ( IsVersion, Catalogs.Versions.FindByCode ( code ), Catalogs.Scenarios.FindByCode ( code ) );
	
endprocedure 

&atclient
procedure OnOpen ( Cancel )
	
	if ( ScenariosPanel.TryActivate ( Scenario ) ) then
		Notify ( Enum.MessageDebugger (), Row, Scenario );
		loadEvaluation ();
	else
		complete ( Enum.DebuggerOpenScenario () );
		return;
	endif;
	
endprocedure

&atclient
procedure loadEvaluation ()
	
	EvaluationResult = Debug.EvaluationResult;
	Items.EvaluationResult.TextColor = ? ( Debug.EvaluationError, new Color ( 255, 0, 0 ), new Color ( 0, 128, 0 ) );
	
endprocedure 

&atclient
procedure complete ( Command )
	
	if ( Closing ) then
		return;
	endif; 
	Closing = true;
	result = getResult ( Command );
	Close ( result );
	
endprocedure 

&atclient
function getResult ( Command )
	
	p = new Structure ();
	p.Insert ( "Command", Command );
	p.Insert ( "Scenario", Scenario );
	p.Insert ( "Expression", Expression );
	return p;
	
endfunction 

&atclient
procedure BeforeClose ( Cancel, Exit, MessageText, StandardProcessing )
	
	if ( Closing ) then
		return;
	endif; 
	Cancel = true;
	complete ( Enum.DebuggerStop () );
	
endprocedure

// *****************************************
// *********** Group Form

&atclient
procedure Step ( Command )
	
	complete ( Enum.DebuggerStepInto () );
	
endprocedure

&atclient
procedure StepOver ( Command )
	
	complete ( Enum.DebuggerStepOver () );
	
endprocedure

&atclient
procedure StopScenario ( Command )
	
	complete ( Enum.DebuggerStop () );
	
endprocedure

&atclient
procedure ContinueRunning ( Command )
	
	complete ( Enum.DebuggerContinue () );
	
endprocedure

&atclient
procedure Evaluate ( Command )
	
	calcResult ();
	
endprocedure

&atclient
procedure calcResult ()
	
	if ( Closing
		or IsBlankString ( Expression ) ) then
		return;
	endif; 
	complete ( Enum.DebuggerEval () );
	
endprocedure 

&atclient
procedure ExpressionOnChange ( Item )
	
	calcResult ();
	
endprocedure

// *****************************************
// *********** Variables Initialization

Closing = false;