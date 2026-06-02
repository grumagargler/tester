function GetBalanceDate ( Object ) export
	
	if ( Object.Date = Date ( 1, 1, 1 ) ) then
		return undefined;
	elsif ( Object.Ref.IsEmpty () ) then
		#if ( Client ) then
			date = CurrentDate ();
		#else
			date = CurrentSessionDate ();
		#endif
		if ( BegOfDay ( Object.Date ) = BegOfDay ( date ) ) then
			return undefined;
		else
			return Object.Date;
		endif; 
	else
		return Object.Date;
	endif; 
	
endfunction

function GetDocumentDate ( Object ) export
	
	if ( Object.Date = Date ( 1, 1, 1 ) ) then
		return PeriodsSrv.GetCurrentSessionDate ();
	elsif ( Object.Ref.IsEmpty () ) then
		date = PeriodsSrv.GetCurrentSessionDate ();
		if ( BegOfDay ( Object.Date ) = BegOfDay ( date ) ) then
			return date;
		else
			return Object.Date;
		endif; 
	else
		return Object.Date;
	endif; 
	
endfunction

&atserver
function GetOperationalDate ( Date ) export
	
	if ( Date = undefined ) then
		return undefined;
	endif;
	today = CurrentSessionDate ();
	if ( BegOfDay ( today ) = BegOfDay ( Date ) ) then
		return undefined;
	else
		return Date;
	endif; 

endfunction

&atserver
function Ok ( DateStart, DateEnd ) export
	
	if ( DateStart = Date ( 1, 1, 1 ) ) or ( DateEnd = Date ( 1, 1, 1 ) ) then
		return true;
	endif; 
	if ( DateStart <= DateEnd ) then
		return true;
	endif; 
	return false;
	
endfunction

function Presentation ( DateStart, DateEnd ) export
	
	try
		presentation = PeriodPresentation ( DateStart, DateEnd, "FP=true" );
	except
		presentation = Output.WrongPeriod ();
	endtry;
	return presentation;

endfunction