function XLSXData ( MXLData ) export

	stream = MXLData.OpenStreamForRead ();
	tabdoc = new SpreadsheetDocument ();
	tabdoc.Read ( stream );
	stream.Close ();
	xlsx = GetTempFileName ( "xlsx" );
	tabdoc.Write ( xlsx, SpreadsheetDocumentFileType.XLSX );
	data = new BinaryData ( xlsx );
	DeleteFiles ( xlsx );
	return data;

endfunction

function Separators () export

	settings = GetSessionRegionalSettings ();
	return new Structure ( "Fractions, Groups",
		settings.NumbersDecimalSeparator, settings.NumbersDigitGroupSeparator );

endfunction