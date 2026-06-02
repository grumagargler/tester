function Exists ( Ref, Field ) export

	fieldAndTable = getTableAndFieldName ( Field );
	meta = Ref.Metadata ();
	if ( fieldAndTable.Table <> undefined ) then
		meta = meta.TabularSections [ fieldAndTable.Table ];
	endif; 
	return meta.Attributes.Find ( fieldAndTable.Field ) <> undefined;

endfunction

function getTableAndFieldName ( Field )
	
	parts = Conversion.StringToArray ( Field, "." );
	result = new Structure ( "Table, Field" );
	if ( parts.Count () = 1 ) then
		result.Insert ( "Field", parts [ 0 ] );
	else
		result.Insert ( "Table", parts [ 0 ] );
		result.Insert ( "Field", parts [ 1 ] );
	endif; 
	return result;
	
endfunction 

procedure Constructor ( Object ) export
	
	meta = Object.Metadata ();
	catalog = Metadata.Catalogs.Contains ( meta );
	folder = catalog
		and meta.Hierarchical
		and meta.HierarchyType = Metadata.ObjectProperties.HierarchyType.HierarchyFoldersAndItems
		and Object.IsFolder;	
	for each item in meta.Attributes do
		value = item.FillValue;			
		if ( value = undefined ) then
			continue;
		endif;
		if ( catalog ) then
			use = item.Use;
			if ( folder ) then
				if ( use = Metadata.ObjectProperties.AttributeUse.ForItem ) then
					continue;
				endif;
			else
				if ( use = Metadata.ObjectProperties.AttributeUse.ForFolder ) then
					continue;
				endif;
			endif;
		endif;
		Object [ item.Name ] = value;
	enddo;

endprocedure

function IsFolder ( Value ) export
	
	meta = Metadata.FindByType ( TypeOf ( value ) );
	if ( meta = undefined ) then
		return false;
	endif;
	if ( Metadata.Catalogs.Contains ( meta ) ) then
		folder = meta.Hierarchical
		and meta.HierarchyType = Metadata.ObjectProperties.HierarchyType.HierarchyFoldersAndItems
		and DF.Pick ( value, "IsFolder", false );
	elsif ( Metadata.ChartsOfAccounts.Contains ( meta ) ) then
		folder = DF.Pick ( value, "Folder", false );
	else
		folder = false;
	endif;
	return folder;

endfunction

function ToType ( Meta ) export
	
	if ( Metadata.Catalogs.Contains ( Meta ) ) then
		class = "CatalogRef";
	elsif (  Metadata.BusinessProcesses.Contains ( Meta ) ) then
		class = "BusinessProcessRef";
	elsif ( Metadata.ChartsOfAccounts.Contains ( Meta ) ) then
		class = "ChartOfAccountsRef";
	elsif ( Metadata.ChartsOfCalculationTypes.Contains ( Meta ) ) then
		class = "ChartOfCalculationTypesRef";
	elsif ( Metadata.ChartsOfCharacteristicTypes.Contains ( Meta ) ) then
		class = "ChartOfCharacteristicTypesRef";
	elsif ( Metadata.Documents.Contains ( Meta ) ) then
		class = "DocumentRef";
	elsif ( Metadata.Tasks.Contains ( Meta ) ) then
		class = "TaskRef";
	elsif ( Metadata.ExchangePlans.Contains ( Meta ) ) then
		class = "ExchangePlanRef";
	endif; 
	return Type ( class + "." + Meta.Name );

endfunction

function GetManager ( Source ) export
	
	if ( TypeOf ( Source ) = Type ( "String" ) ) then
		return getManagerByName ( Source );
	else
		return getManagerByObject ( Source );
	endif; 
	
endfunction 

function getManagerByObject ( Object )
	
	classAndName = Metafields.ClassAndName ( Object.Metadata ().FullName () );
	if ( classAndName.Class = "Catalog" or classAndName.Class = "Справочник" ) then
		return Catalogs [ classAndName.Name ];
	elsif ( classAndName.Class = "AccountingRegister" or classAndName.Class = "РегистрБухгалтерии" ) then
		return AccountingRegisters [ classAndName.Name ];
	elsif ( classAndName.Class = "AccumulationRegister" or classAndName.Class = "РегистрНакопления" ) then
		return AccumulationRegisters [ classAndName.Name ];
	elsif ( classAndName.Class = "BusinessProcess" or classAndName.Class = "БизнесПроцесс" ) then
		return BusinessProcesses [ classAndName.Name ];
	elsif ( classAndName.Class = "CalculationRegister" or classAndName.Class = "РегистрРасчета" ) then
		return CalculationRegisters [ classAndName.Name ];
	elsif ( classAndName.Class = "ChartOfAccounts" or classAndName.Class = "ПланСчетов" ) then
		return ChartsOfAccounts [ classAndName.Name ];
	elsif ( classAndName.Class = "ChartsOfCalculationType" or classAndName.Class = "ПланВидовРасчета" ) then
		return ChartsOfCalculationTypes [ classAndName.Name ];
	elsif ( classAndName.Class = "ChartOfCharacteristicTypes" or classAndName.Class = "ПланВидовХарактеристик" ) then
		return ChartsOfCharacteristicTypes [ classAndName.Name ];
	elsif ( classAndName.Class = "DataProcessor" or classAndName.Class = "Обработка" ) then
		return DataProcessors [ classAndName.Name ];
	elsif ( classAndName.Class = "Document" or classAndName.Class = "Документ" ) then
		return Documents [ classAndName.Name ];
	elsif ( classAndName.Class = "DocumentJournal" ) or classAndName.Class = "ЖурналДокументов" then
		return DocumentJournals [ classAndName.Name ];
	elsif ( classAndName.Class = "InformationRegister" or classAndName.Class = "РегистрСведений" ) then
		return InformationRegisters [ classAndName.Name ];
	elsif ( classAndName.Class = "Report" or classAndName.Class = "Отчет" ) then
		return Reports [ classAndName.Name ];
	elsif ( classAndName.Class = "Task" or classAndName.Class = "Задача" ) then
		return Tasks [ classAndName.Name ];
	elsif ( classAndName.Class = "Enum" or classAndName.Class = "Перечисление" ) then
		return Enums [ classAndName.Name ];
	elsif ( classAndName.Class = "ExchangePlan" or classAndName.Class = "ПланОбмена" ) then
		return ExchangePlans [ classAndName.Name ];
	endif; 
	
endfunction
 
function getManagerByName ( Manager )
	
	classAndName = Metafields.ClassAndName ( Manager );
	if ( classAndName.Class = "Catalogs" or classAndName.Class = "Справочники" ) then
		return Catalogs [ classAndName.Name ];
	elsif ( classAndName.Class = "AccountingRegisters" or classAndName.Class = "РегистрыБухгалтерии" ) then
		return AccountingRegisters [ classAndName.Name ];
	elsif ( classAndName.Class = "AccumulationRegisters" or classAndName.Class = "РегистрыНакопления" ) then
		return AccumulationRegisters [ classAndName.Name ];
	elsif ( classAndName.Class = "BusinessProcesses" or classAndName.Class = "БизнесПроцессы" ) then
		return BusinessProcesses [ classAndName.Name ];
	elsif ( classAndName.Class = "CalculationRegisters" or classAndName.Class = "РегистрыРасчета" ) then
		return CalculationRegisters [ classAndName.Name ];
	elsif ( classAndName.Class = "ChartsOfAccounts" or classAndName.Class = "ПланыСчетов" ) then
		return ChartsOfAccounts [ classAndName.Name ];
	elsif ( classAndName.Class = "ChartsOfCalculationTypes" or classAndName.Class = "ПланыВидовРасчета" ) then
		return ChartsOfCalculationTypes [ classAndName.Name ];
	elsif ( classAndName.Class = "ChartsOfCharacteristicTypes" or classAndName.Class = "ПланыВидовХарактеристик" ) then
		return ChartsOfCharacteristicTypes [ classAndName.Name ];
	elsif ( classAndName.Class = "DataProcessors" or classAndName.Class = "Обработки" ) then
		return DataProcessors [ classAndName.Name ];
	elsif ( classAndName.Class = "Documents" or classAndName.Class = "Документы" ) then
		return Documents [ classAndName.Name ];
	elsif ( classAndName.Class = "DocumentJournals" ) or classAndName.Class = "ЖурналыДокументов" then
		return DocumentJournals [ classAndName.Name ];
	elsif ( classAndName.Class = "InformationRegisters" or classAndName.Class = "РегистрыСведений" ) then
		return InformationRegisters [ classAndName.Name ];
	elsif ( classAndName.Class = "Reports" or classAndName.Class = "Отчеты" ) then
		return Reports [ classAndName.Name ];
	elsif ( classAndName.Class = "Tasks" or classAndName.Class = "Задачи" ) then
		return Tasks [ classAndName.Name ];
	elsif ( classAndName.Class = "Enums" or classAndName.Class = "Перечисления" ) then
		return Enums [ classAndName.Name ];
	elsif ( classAndName.Class = "ExchangePlans" or classAndName.Class = "ПланыОбмена" ) then
		return ExchangePlans [ classAndName.Name ];
	endif; 
	
endfunction

function ClassAndName ( FullName ) export
	
	partsNames = Conversion.StringToArray ( FullName, "." );
	classAndName = new Structure ();
	classAndName.Insert ( "Class", partsNames [ 0 ] );
	classAndName.Insert ( "Name", partsNames [ 1 ] );
	return classAndName;
	
endfunction
