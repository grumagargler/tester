
function module ()
	
	return CoreExtension;
	
endfunction

procedure AdjustQuery ( Query ) export
	
	//@skip-warning
	Query.Text = module ().GetLibrary ( "Root" ).AdjustQuery ( Query.Text );
	
endprocedure

function QueryTables ( Query ) export
	
	//@skip-warning
	return Conversion.FromJSON ( module ().GetLibrary ( "Root" ).QueryTables ( Query ) );
	
endfunction

procedure AugmentQuery ( Query ) export
	
	//@skip-warning
	module ().GetLibrary ( "Root" ).AugmentQuery ( Query );
	
endprocedure

function ParseAppearance ( Rules ) export
	
	//@skip-warning
	result = Conversion.FromJSON ( module ().GetLibrary ( "Root" ).ParseAppearance ( StrConcat ( Rules, ";" ) ) );
	if ( TypeOf ( result ) = Type ( "Structure" ) ) then
		raise "Conditional Appearance " + result.Error + " at " + result.Position;
	endif;
	return new FixedArray ( result );
	
endfunction

function codemodule ()
	
	return CoreFunctions;
	
endfunction

function Condition1 ( Value1, Value2 ) export
	
	//@skip-warning
	return module ().GetLibrary ( "Collections" ).Condition1 ( Value1, Value2 );
	
endfunction

function Condition2 ( Value1, Value2, Value3 ) export
	
	//@skip-warning
	return module ().GetLibrary ( "Collections" ).Condition2 ( Value1, Value2, Value3 );
	
endfunction

function GetFileHash ( File ) export

	return module ().GetLibrary ( "Root" ).GetHash ( File );

endfunction

function GetStringHash ( String, AddBOM ) export

	return module ().GetLibrary ( "Root" ).GetStringHash ( String, AddBOM );

endfunction

