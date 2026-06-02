procedure Init ( Env ) export
	
	Env = new Structure ();
	Env.Insert ( "Spreadsheet" );
	Env.Insert ( "CheckSquare" );
	Env.Insert ( "HugeSquare" );
	Env.Insert ( "ManyRows" );
	Env.Insert ( "Areas" );
	Env.Insert ( "Result" );
	
endprocedure

procedure Update ( Env ) export
	
	setAreas ( Env );
	setInfo ( Env );
	if ( Env.CheckSquare
		and Env.HugeSquare ) then
		setWarning ( Env );
	else
		if ( Env.ManyRows ) then
			SpreadsheetTotalsSrv.Calculate ( Env );
		else
			SpreadsheetTotals.Calculate ( Env );
		endif; 
	endif; 
	
endprocedure 

procedure setAreas ( Env )
	
	areas = new Array ();
	rangeType = Type ( "SpreadsheetDocumentRange" );
	spreadsheet = Env.Spreadsheet;
	for each area in spreadsheet.SelectedAreas do
		if ( TypeOf ( area ) <> rangeType ) then
			continue;
		endif; 
		top = area.Top;
		if ( top = 0 ) then
			r1 = 1;
			r2 = spreadsheet.TableHeight;
		else
			r1 = top;
			r2 = area.Bottom;
		endif; 
		c1 = Max ( 1, area.Left );
		c2 = ? ( area.Right = 0, spreadsheet.TableWidth, area.Right );
		areas.Add ( new Structure ( "R1, C1, R2, C2, Calculated", r1, c1, r2, c2 ) );
	enddo;
	Env.Areas = areas;
	
endprocedure 

procedure setInfo ( Env )
	
	minRow = 0;
	maxRow = 0;
	square = 0;
	for each area in Env.Areas do
		r1 = area.R1;
		r2 = area.R2;
		c1 = area.C1;
		c2 = area.C2;
		square = square + ( r2 - r1 ) * ( c2 - c1 );
		minRow = ? ( minRow = 0, r1, Min ( minRow, r1 ) );
		maxRow = ? ( maxRow = 0, r2, Max ( maxRow, r2 ) );
	enddo; 
	Env.ManyRows = ( maxRow - minRow ) > 60;
	Env.HugeSquare = square > 3000;

endprocedure 

procedure setWarning ( Env )
	
	Env.Result = Output.CalculationAreaTooBig ();
	
endprocedure 

procedure Calculate ( Env ) export
	
	sum = 0;
	count = 0;
	quantity = 0;
	taken = new Map ();
	spreadsheet = Env.Spreadsheet;
	for each area in Env.Areas do
		info = calcArea ( spreadsheet, area, taken );
		sum = sum + info.Sum;
		quantity = quantity + info.Quantity;
		count = count + info.Count;
	enddo; 
	if ( count = 0 ) then
		Env.Result = Output.SpreadsheedAreaNotSelected ();
	else
		p = new Structure ( "Count, Average, Sum", count );
		if ( quantity = 0 ) then
			Env.Result = Output.SpreadsheedTotalCount ( p );
		else
			p.Sum = sum;
			p.Average = Round ( sum / quantity, 9 );
			Env.Result = Output.SpreadsheedTotal ( p );
		endif; 
	endif;
	
endprocedure 

function calcArea ( Spreadsheet, Area, Taken )
	
	sum = 0;
	count = 0;
	quantity = 0;
	numberType = Type ( "Number" );
	for i = Area.R1 to Area.R2 do
		for j = Area.C1 to Area.C2 do
			cell = Spreadsheet.Area ( i, j, i, j );
			if ( not cell.Visible ) then
				continue;
			endif;
			value = undefined;
			if ( cell.ContainsValue
				and TypeOf ( cell.Value ) = numberType ) then
				value = cell.Value;
			elsif ( ValueIsFilled ( cell.Text ) ) then
				try
					value = Number ( cell.Text );
				except
				endtry;
			else
				continue;
			endif;
			cellName = cell.Name;
			if ( Taken [ cellName ] <> undefined ) then
				continue;
			endif; 
			Taken [ cellName ] = true;
			count = count + 1;
			if ( value <> undefined ) then
				quantity = quantity + 1;
				sum = sum + value;
			endif; 
		enddo; 
	enddo; 
	return new Structure ( "Count, Sum, Quantity", count, sum, quantity );

endfunction 
