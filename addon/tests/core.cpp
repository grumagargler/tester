#define DOCTEST_CONFIG_IMPLEMENT
#include "1c/componentbase.h"
#include "1c/imemorymanager.h"
#include "chars.h"
#include "json.h"
#include "metadata/metadata.h"
#include "transform.h"
#include "types.h"
#include <algorithm>
#include <array>
#include <chrono>
#include <cstdlib>
#include <doctest/doctest.h>
#include <filesystem>
#include <fstream>
#include <nlohmann/json.hpp>
#include <optional>
#include <thread>
#include <vector>

namespace {
struct NonComparable {
	int value { 0 };
};

class TestMemoryManager : public IMemoryManager {
public:
	bool ADDIN_API AllocMemory ( void** Memory, unsigned long Bytes ) override {
		if ( Bytes == 0 ) {
			*Memory = nullptr;
			return true;
		}
		*Memory = std::malloc ( Bytes );
		return *Memory != nullptr;
	}

	void ADDIN_API FreeMemory ( void** Memory ) override {
		std::free ( *Memory );
		*Memory = nullptr;
	}
};

std::filesystem::path tooltipSources () {
	return std::filesystem::path ( __FILE__ ).parent_path () / "files" / "src";
}

std::filesystem::path designerTooltipSources () {
	return std::filesystem::path ( __FILE__ ).parent_path () / "files" /
				 "designer";
}

std::filesystem::path cyrillicDesignerTooltipSources () {
	return std::filesystem::path ( __FILE__ ).parent_path () /
				 "cyrillic_designer";
}

std::filesystem::path unicodePathSegment ( const char* utf8,
																					 const wchar_t* wide ) {
#ifdef _WIN32
	return std::filesystem::path ( wide );
#else
	return std::filesystem::path ( utf8 );
#endif
}

std::string pathAsUTF8 ( const std::filesystem::path& path ) {
	const auto value = path.u8string ();
#ifdef __cpp_char8_t
	return std::string ( reinterpret_cast<const char*> ( value.data () ),
											 value.size () );
#else
	return value;
#endif
}

nlohmann::json readFormInfoFrom ( const std::filesystem::path& sources,
																	const std::string& formName,
																	const std::string& language = "en" ) {
	Metadata1C metadata ( sources.string (), formName, language );
	const auto body = metadata.getFormInfo ();
	REQUIRE_FALSE ( body.empty () );
	return nlohmann::json::parse ( body );
}

nlohmann::json readFormInfo ( const std::string& formName ) {
	return readFormInfoFrom ( tooltipSources (), formName );
}

nlohmann::json readDesignerFormInfo ( const std::string& formName,
																			const std::string& language = "en" ) {
	return readFormInfoFrom ( designerTooltipSources (), formName, language );
}

nlohmann::json readFormDataPathsFrom ( const std::filesystem::path& sources,
																			 const std::string& formName ) {
	Metadata1C metadata ( sources.string (), formName );
	const auto body = metadata.getFormDataPaths ();
	REQUIRE_FALSE ( body.empty () );
	return nlohmann::json::parse ( body );
}

nlohmann::json readFormDataPaths ( const std::string& formName ) {
	return readFormDataPathsFrom ( tooltipSources (), formName );
}

nlohmann::json readDesignerFormDataPaths ( const std::string& formName ) {
	return readFormDataPathsFrom ( designerTooltipSources (), formName );
}

bool jsonArrayContains ( const nlohmann::json& array,
												 const std::string& value ) {
	return std::any_of (
			array.begin (), array.end (), [ &value ] ( const auto& item ) {
				return item.is_string () && item.template get<std::string> () == value;
			} );
}

bool jsonArrayContainsDataPath ( const nlohmann::json& array,
																 const std::string& name,
																 const std::string& dataPath ) {
	return std::any_of (
			array.begin (), array.end (), [ &name, &dataPath ] ( const auto& item ) {
				if ( !item.is_object () ) {
					return false;
				}
				const auto itemName = item.find ( "name" );
				const auto itemDataPath = item.find ( "dataPath" );
				return itemName != item.end () && itemName->is_string () &&
							 itemName->template get<std::string> () == name &&
							 itemDataPath != item.end () && itemDataPath->is_string () &&
							 itemDataPath->template get<std::string> () == dataPath;
			} );
}

bool jsonArrayContainsDataPathName ( const nlohmann::json& array,
																		 const std::string& name ) {
	return std::any_of (
			array.begin (), array.end (), [ &name ] ( const auto& item ) {
				if ( !item.is_object () ) {
					return false;
				}
				const auto itemName = item.find ( "name" );
				return itemName != item.end () && itemName->is_string () &&
							 itemName->template get<std::string> () == name;
			} );
}

void setStringVariant ( tVariant& Variant, const std::string& Value ) {
	tVarInit ( &Variant );
	const auto wide = Chars::stringToWide ( Value );
	Variant.pwstrVal = Chars::toWchar ( wide.c_str () ).release ();
	Variant.wstrLen = wide.size ();
	Variant.vt = VTYPE_PWSTR;
}

void clearStringVariant ( tVariant& Variant ) {
	delete [] Variant.pwstrVal;
	tVarInit ( &Variant );
}

std::string variantString ( const tVariant& Variant ) {
	REQUIRE ( Variant.vt == VTYPE_PWSTR );
	return Chars::wideToString (
			Chars::wcharToWide ( Variant.pwstrVal, Variant.wstrLen ) );
}

std::string
callComponentMethod ( IComponentBase* Component,
											TestMemoryManager& MemoryManager, const WCHAR_T* Name,
											std::initializer_list<std::string> Arguments ) {
	const auto method = Component->FindMethod ( Name );
	REQUIRE ( method > 0 );
	std::vector<tVariant> params ( Arguments.size () );
	auto argument = Arguments.begin ();
	for ( auto& param : params ) {
		setStringVariant ( param, *argument++ );
	}
	tVariant result;
	tVarInit ( &result );
	const auto ok = Component->CallAsFunc (
			method, &result, params.data (), static_cast<long> ( params.size () ) );
	for ( auto& param : params ) {
		clearStringVariant ( param );
	}
	REQUIRE ( ok );
	const auto value = variantString ( result );
	MemoryManager.FreeMemory ( reinterpret_cast<void**> ( &result.pwstrVal ) );
	tVarInit ( &result );
	return value;
}

bool callComponentBoolMethod ( IComponentBase* Component, const WCHAR_T* Name,
															 std::initializer_list<std::string> Arguments ) {
	const auto method = Component->FindMethod ( Name );
	REQUIRE ( method > 0 );
	std::vector<tVariant> params ( Arguments.size () );
	auto argument = Arguments.begin ();
	for ( auto& param : params ) {
		setStringVariant ( param, *argument++ );
	}
	tVariant result;
	tVarInit ( &result );
	const auto ok = Component->CallAsFunc (
			method, &result, params.data (), static_cast<long> ( params.size () ) );
	for ( auto& param : params ) {
		clearStringVariant ( param );
	}
	REQUIRE ( ok );
	REQUIRE ( result.vt == VTYPE_BOOL );
	return result.bVal;
}

void callComponentProcedure ( IComponentBase* Component, const WCHAR_T* Name,
															std::vector<tVariant>& Params ) {
	const auto method = Component->FindMethod ( Name );
	REQUIRE ( method > 0 );
	const auto ok = Component->CallAsProc (
			method, Params.empty () ? nullptr : Params.data (),
			static_cast<long> ( Params.size () ) );
	REQUIRE ( ok );
}

std::string callComponentMethod ( IComponentBase* Component,
																	TestMemoryManager& MemoryManager,
																	const WCHAR_T* Name,
																	std::vector<tVariant>& Params ) {
	const auto method = Component->FindMethod ( Name );
	REQUIRE ( method > 0 );
	tVariant result;
	tVarInit ( &result );
	const auto ok = Component->CallAsFunc (
			method, &result, Params.data (), static_cast<long> ( Params.size () ) );
	REQUIRE ( ok );
	const auto value = variantString ( result );
	MemoryManager.FreeMemory ( reinterpret_cast<void**> ( &result.pwstrVal ) );
	tVarInit ( &result );
	return value;
}
}

TEST_CASE ( "JSON::compare returns structured property changes" ) {
	const std::string previous = R"json([
		{
			"Name":"Catalog.Organizations.Form.Form",
			"TitleText":"Контрагенты (create)",
			"Type":"TestedForm",
			"ChildObjects":[
				{
					"Name":"EntityGroup",
					"TitleText":"Entity group",
					"Type":"TestedFormGroup",
					"ChildObjects":[
						{
							"Name":"FullDescription",
							"TitleText":"Официальное",
							"Type":"TestedFormField",
							"Value":""
						},
						{
							"Name":"Description",
							"TitleText":"Короткое",
							"Type":"TestedFormField",
							"Value":""
						}
					]
				}
			]
		}
	])json";

	const std::string current = R"json([
		{
			"Name":"Catalog.Organizations.Form.Form",
			"TitleText":"Контрагенты (create)",
			"Type":"TestedForm",
			"ChildObjects":[
				{
					"Name":"EntityGroup",
					"TitleText":"Entity group",
					"Type":"TestedFormGroup",
					"ChildObjects":[
						{
							"Name":"FullDescription",
							"TitleText":"Официальное",
							"Type":"TestedFormField",
							"Value":"SRL TechVision Moldova"
						},
						{
							"Name":"Description",
							"TitleText":"Короткое",
							"Type":"TestedFormField",
							"Value":"SRL TechVision Moldova"
						}
					]
				}
			]
		}
	])json";
	const auto result =
			nlohmann::json::parse ( JSON::compare ( previous, current ) );
	REQUIRE ( result.at ( "Mode" ) == "Delta" );
	REQUIRE ( result.at ( "WindowChanged" ) == false );
	REQUIRE ( result.at ( "ChangeCount" ) == 2 );
	REQUIRE ( result.at ( "Changes" ).is_array () );
	const auto& first = result.at ( "Changes" ).at ( 0 );
	const auto& second = result.at ( "Changes" ).at ( 1 );
	CHECK ( first.at ( "Path" ) ==
					"Catalog.Organizations.Form.Form/EntityGroup/Description" );
	CHECK ( first.at ( "Property" ) == "Value" );
	CHECK ( first.at ( "OldValue" ) == "" );
	CHECK ( first.at ( "NewValue" ) == "SRL TechVision Moldova" );
	CHECK ( second.at ( "Path" ) ==
					"Catalog.Organizations.Form.Form/EntityGroup/FullDescription" );
	CHECK ( second.at ( "Property" ) == "Value" );
	CHECK ( second.at ( "OldValue" ) == "" );
	CHECK ( second.at ( "NewValue" ) == "SRL TechVision Moldova" );
}

TEST_CASE ( "JSON::compare matches named controls independently from order" ) {
	const std::string previous = R"json([
		{
			"Name":"Form",
			"TitleText":"Window",
			"Type":"TestedForm",
			"ChildObjects":[
				{ "Name":"A", "TitleText":"A", "Type":"TestedFormField", "Value":"1" },
				{ "Name":"B", "TitleText":"B", "Type":"TestedFormField", "Value":"2" }
			]
		}
	])json";
	const std::string current = R"json([
		{
			"Name":"Form",
			"TitleText":"Window",
			"Type":"TestedForm",
			"ChildObjects":[
				{ "Name":"B", "TitleText":"B", "Type":"TestedFormField", "Value":"2" },
				{ "Name":"A", "TitleText":"A", "Type":"TestedFormField", "Value":"1" }
			]
		}
	])json";
	const auto result =
			nlohmann::json::parse ( JSON::compare ( previous, current ) );
	CHECK ( result.at ( "ChangeCount" ) == 0 );
	CHECK ( result.at ( "Changes" ).empty () );
}

TEST_CASE ( "SafeValue stores non-comparable optionals" ) {
	types::SafeValue<std::optional<NonComparable>> safeValue;
	safeValue = NonComparable { 42 };
	const auto value = safeValue.get ();
	REQUIRE ( value.has_value () );
	CHECK ( value->value == 42 );
}

TEST_CASE ( "SafeValue::waitFor observes async updates" ) {
	using namespace std::chrono_literals;
	types::SafeValue<std::optional<int>> safeValue;
	std::jthread worker ( [ &safeValue ] {
		std::this_thread::sleep_for ( 10ms );
		safeValue = 7;
	} );
	CHECK ( safeValue.waitFor (
			1, [] ( const auto& value ) { return value.has_value (); } ) );
	CHECK ( safeValue.get () == std::optional<int> { 7 } );
}

TEST_CASE ( "Root exposes moved server methods" ) {
	IComponentBase* component { nullptr };
	REQUIRE ( GetClassObject ( u"Root", &component ) != 0 );
	REQUIRE ( component != nullptr );

	TestMemoryManager memoryManager;
	REQUIRE ( component->setMemManager ( &memoryManager ) );

	CHECK ( callComponentMethod ( component, memoryManager, u"AdjustQuery",
																{ "where NULL = &P1 or NULL = &P" } ) ==
					"where true or true" );

	const auto tables = nlohmann::json::parse ( callComponentMethod (
			component, memoryManager, u"QueryTables",
			{ "// #Catalog.Items\n;\n// @Document.Invoice\n" } ) );
	REQUIRE ( tables.size () == 2 );
	CHECK ( tables.at ( 0 ).at ( "Name" ) == "Catalog.Items" );
	CHECK ( tables.at ( 0 ).at ( "Type" ) == 1 );
	CHECK ( tables.at ( 0 ).at ( "Index" ) == 0 );
	CHECK ( tables.at ( 1 ).at ( "Name" ) == "Document.Invoice" );
	CHECK ( tables.at ( 1 ).at ( "Type" ) == 3 );
	CHECK ( tables.at ( 1 ).at ( "Index" ) == 1 );

	const auto appearance = nlohmann::json::parse (
			callComponentMethod ( component, memoryManager, u"ParseAppearance",
														{ "Name show Filled(Name);" } ) );
	REQUIRE ( appearance.size () == 1 );
	CHECK ( appearance.at ( 0 ).at ( "Controls" ).at ( 0 ) == "Name" );
	CHECK ( appearance.at ( 0 ).at ( "Appearance" ).at ( 0 ) == "show" );
	CHECK ( appearance.at ( 0 ).at ( "Fields" ).at ( 0 ) == "Name" );
	CHECK ( appearance.at ( 0 ).at ( "Expression" ) ==
					"valueisfilled(Form.Name)" );

	const auto method = component->FindMethod ( u"GetStringHash" );
	REQUIRE ( method > 0 );
	CHECK ( component->GetNParams ( method ) == 2 );

	std::vector<tVariant> params ( 2 );
	setStringVariant ( params [ 0 ], "Watcher" );
	tVarInit ( &params [ 1 ] );
	params [ 1 ].vt = VTYPE_BOOL;
	params [ 1 ].bVal = false;
	CHECK ( callComponentMethod ( component, memoryManager, u"GetStringHash",
																params ) ==
					std::to_string ( strings::toHash ( "Watcher", false ) ) );
	params [ 1 ].bVal = true;
	CHECK ( callComponentMethod ( component, memoryManager, u"GetStringHash",
																params ) ==
					std::to_string ( strings::toHash ( "Watcher", true ) ) );
	clearStringVariant ( params [ 0 ] );

	CHECK ( DestroyObject ( &component ) == 0 );
	CHECK ( component == nullptr );
}

TEST_CASE ( "Read form info for a document form" ) {
	const auto result = readFormInfo ( "Document.Invoice.Form.Form" );
	CHECK ( result.at ( "explanation" ) ==
					"Document which records sale of items to the customer" );
	CHECK ( result.at ( "fields" ).at ( "Customer" ).at ( "tooltip" ) ==
					"Customer" );
	CHECK ( result.at ( "fields" ).at ( "Customer" ).at ( "type" ) ==
					"CatalogRef.Organizations" );
	CHECK ( result.at ( "fields" ).at ( "Amount" ).at ( "type" ) ==
					"Number(15,2)" );
	CHECK ( result.at ( "tables" )
							.at ( "ItemsTable" )
							.at ( "ItemsPrice" )
							.at ( "tooltip" ) == "Price" );
	CHECK ( result.at ( "tables" )
							.at ( "ItemsTable" )
							.at ( "ItemsPrice" )
							.at ( "type" ) == "Number(10,2)" );
	CHECK_FALSE ( result.at ( "tables" )
										.at ( "ItemsTable" )
										.contains ( "ItemsTableItemUnit" ) );
	CHECK_FALSE ( result.at ( "tables" ).contains ( "Items" ) );
	CHECK_FALSE ( result.contains ( "dataPaths" ) );
}

TEST_CASE ( "Read form data paths without language" ) {
	const auto edt = readFormDataPaths ( "Document.Invoice.Form.Form" );
	CHECK ( jsonArrayContainsDataPath ( edt, "Customer", "Object.Customer" ) );
	CHECK ( jsonArrayContainsDataPath ( edt, "ItemsTable", "Object.Items" ) );
	CHECK ( jsonArrayContainsDataPath ( edt, "ItemsTableItemUnit",
																			"Object.Items.Item.Unit" ) );
	CHECK_FALSE ( jsonArrayContainsDataPathName ( edt, "AccessLabel" ) );

	const auto dataProcessor =
			readFormDataPaths ( "DataProcessor.TestAIVision.Form.Form" );
	CHECK (
			jsonArrayContainsDataPath ( dataProcessor, "Items", "Object.Items" ) );
	CHECK ( jsonArrayContainsDataPath ( dataProcessor, "ItemsItem",
																			"Object.Items.Item" ) );
	CHECK ( jsonArrayContainsDataPath ( dataProcessor, "GoodsFieldString",
																			"Goods.FieldString" ) );
	CHECK ( jsonArrayContainsDataPath ( dataProcessor, "ItemsListCode",
																			"ItemsList.Code" ) );

	const auto designer =
			readDesignerFormDataPaths ( "Document.Invoice.Form.Form" );
	CHECK (
			jsonArrayContainsDataPath ( designer, "Customer", "Object.Customer" ) );
	CHECK (
			jsonArrayContainsDataPath ( designer, "ItemsTable", "Object.Items" ) );
	CHECK ( jsonArrayContainsDataPath ( designer, "ItemsTableItemUnit",
																			"Object.Items.Item.Unit" ) );
	CHECK_FALSE ( jsonArrayContainsDataPathName ( designer, "AccessLabel" ) );

	const auto russian = readFormDataPathsFrom (
			cyrillicDesignerTooltipSources (),
			"Документ.ПлатежноеПоручение.Форма.ФормаДокумента" );
	CHECK ( jsonArrayContainsDataPath ( russian, "Организация",
																			"Объект.Организация" ) );
}

TEST_CASE ( "Read form info for a catalog form" ) {
	const auto result = readFormInfo ( "Catalog.Items.Form.Form" );
	CHECK ( result.at ( "explanation" ) ==
					"Items and services catalog. This catalog is important for many "
					"application subsystems. The catalog stores both tangible and "
					"intangible assets" );
	CHECK ( result.at ( "fields" ).at ( "Weight" ).at ( "tooltip" ) ==
					"Weight of base unit" );
	CHECK ( result.at ( "fields" ).at ( "Weight" ).at ( "type" ) ==
					"Number(10,3)" );
}

TEST_CASE ( "Read form info for an exchange plan form" ) {
	const auto result = readFormInfo ( "ExchangePlan.Full.Form.Form" );
	CHECK ( result.at ( "explanation" ) ==
					"Full exchange data. Includes all objects, without objects from "
					"exchange plan Classifiers" );
	CHECK ( result.at ( "fields" ).at ( "Code" ).at ( "tooltip" ) == "" );
	CHECK ( result.at ( "fields" ).at ( "Code" ).at ( "type" ) == "String(9)" );

	const auto implicit = readFormInfo ( "ExchangePlan.Classifiers.Form.Form" );
	CHECK ( implicit.at ( "fields" ).at ( "Code" ).at ( "type" ) == "String(3)" );
}

TEST_CASE ( "Read form info for a business process form" ) {
	const auto result = readFormInfo ( "BusinessProcess.Command.Form.Form" );
	CHECK ( result.at ( "explanation" ) == "Internal command process" );
	CHECK ( result.at ( "fields" ).at ( "Appearance" ).at ( "tooltip" ) ==
					"The color scheme used for placing records in the calendar" );
	CHECK ( result.at ( "fields" ).at ( "Appearance" ).at ( "type" ) ==
					"CatalogRef.CalendarAppearance" );
}

TEST_CASE ( "Read form info for a chart of characteristic types form" ) {
	const auto result =
			readFormInfo ( "ChartOfCharacteristicTypes.Properties.Form.Form" );
	CHECK ( result.at ( "explanation" ) == "Types of configurable properties" );
	CHECK ( result.at ( "fields" ).at ( "Common" ).at ( "tooltip" ) ==
					"Common property" );
	CHECK ( result.at ( "fields" ).at ( "Common" ).at ( "type" ) == "Boolean" );
}

TEST_CASE ( "Read form info for a chart of calculation types form" ) {
	const auto result =
			readFormInfo ( "ChartOfCalculationTypes.Taxes.Form.Form" );
	CHECK ( result.at ( "explanation" ) ==
					"Taxes and fees from employee's payroll" );
	CHECK ( result.at ( "fields" ).at ( "Account" ).at ( "tooltip" ) ==
					"Default Tax Account" );
	CHECK ( result.at ( "fields" ).at ( "Account" ).at ( "type" ) ==
					"ChartOfAccountsRef.General" );
	CHECK ( result.at ( "tables" )
							.at ( "Base" )
							.at ( "BaseCalculationType" )
							.at ( "type" ) == "ChartOfCalculationTypesRef.Taxes, "
																"ChartOfCalculationTypesRef.Compensations" );
}

TEST_CASE ( "Read form info for a chart of accounts form" ) {
	const auto result = readFormInfo ( "ChartOfAccounts.General.Form.Form" );
	CHECK ( result.at ( "explanation" ) == "General chart account" );
	CHECK ( result.at ( "fields" ).at ( "Class" ).at ( "tooltip" ) ==
					"Account class" );
	CHECK ( result.at ( "fields" ).at ( "Class" ).at ( "type" ) ==
					"EnumRef.Accounts" );
	CHECK ( result.at ( "tables" )
							.at ( "ExtDimensionTypes" )
							.at ( "ExtDimensionTypesExtDimensionType" )
							.at ( "type" ) == "ChartOfCharacteristicTypesRef.Dimensions" );
	CHECK ( jsonArrayContains ( result.at ( "invisibleFields" ),
															"ExtDimensionTypesTurnoversOnly" ) );
	CHECK ( jsonArrayContains ( result.at ( "invisibleFields" ),
															"ExtDimensionTypesAccrual" ) );
	CHECK ( jsonArrayContains ( result.at ( "invisibleFields" ),
															"ExtDimensionTypesCurrency" ) );
	CHECK ( jsonArrayContains ( result.at ( "invisibleFields" ),
															"ExtDimensionTypesQuantitative" ) );
	CHECK_FALSE ( jsonArrayContains ( result.at ( "invisibleFields" ),
																		"ExtDimensionTypesExtDimensionType" ) );
}

TEST_CASE ( "Read form info for a task form" ) {
	const auto result = readFormInfo ( "Task.UserTask.Form.Form" );
	CHECK ( result.at ( "explanation" ) == "User task or reminder" );
	CHECK ( result.at ( "fields" ).at ( "BusinessProcess" ).at ( "tooltip" ) ==
					"Command" );
	CHECK ( result.at ( "fields" ).at ( "BusinessProcess" ).at ( "type" ) ==
					"BusinessProcessRef.Command" );
}

TEST_CASE ( "Read form info for an information register list form" ) {
	const auto result =
			readFormInfo ( "InformationRegister.DepartmentItems.Form.List" );
	CHECK ( result.at ( "explanation" ) ==
					"Produced products by production departments" );
	CHECK ( result.at ( "tables" )
							.at ( "List" )
							.at ( "Department" )
							.at ( "tooltip" ) == "Department" );
	CHECK (
			result.at ( "tables" ).at ( "List" ).at ( "Department" ).at ( "type" ) ==
			"CatalogRef.Departments" );
	CHECK_FALSE ( result.at ( "fields" ).contains ( "Department" ) );
	CHECK_FALSE ( result.at ( "fields" ).contains ( "DepartmentFilter" ) );
}

TEST_CASE ( "Read form info for a document form in designer format" ) {
	const auto result = readDesignerFormInfo ( "Document.Invoice.Form.Form" );
	CHECK ( result.at ( "explanation" ) ==
					"Document which records sale of items to the customer" );
	CHECK ( result.at ( "fields" ).at ( "Customer" ).at ( "tooltip" ) ==
					"Customer" );
	CHECK ( result.at ( "fields" ).at ( "Customer" ).at ( "type" ) ==
					"CatalogRef.Organizations" );
	CHECK ( result.at ( "fields" ).at ( "Amount" ).at ( "type" ) ==
					"Number(15,2)" );
	CHECK ( result.at ( "tables" )
							.at ( "ItemsTable" )
							.at ( "ItemsPrice" )
							.at ( "tooltip" ) == "Price" );
	CHECK ( result.at ( "tables" )
							.at ( "ItemsTable" )
							.at ( "ItemsPrice" )
							.at ( "type" ) == "Number(10,2)" );
	CHECK_FALSE ( result.at ( "tables" )
										.at ( "ItemsTable" )
										.contains ( "ItemsTableItemUnit" ) );
	CHECK_FALSE ( result.at ( "tables" ).contains ( "Items" ) );
	CHECK_FALSE ( result.contains ( "dataPaths" ) );
}

TEST_CASE ( "Read form info for a Russian document form in designer format" ) {
	const auto result = readFormInfoFrom (
			cyrillicDesignerTooltipSources (),
			"Документ.ПлатежноеПоручение.Форма.ФормаДокумента", "ru" );
	CHECK ( result.at ( "explanation" ) ==
					"Платежный документ для перечисления денег" );
	CHECK ( result.at ( "fields" ).at ( "Номер" ).at ( "type" ) == "String(11)" );
	CHECK ( result.at ( "fields" ).at ( "Организация" ).at ( "tooltip" ) ==
					"Организация плательщика" );
	CHECK ( result.at ( "fields" ).at ( "Организация" ).at ( "type" ) ==
					"CatalogRef.Организации" );
	CHECK ( result.at ( "fields" ).at ( "СуммаДокумента" ).at ( "type" ) ==
					"Number(15,2)" );
	CHECK_FALSE ( result.contains ( "dataPaths" ) );
}

TEST_CASE ( "Read form info for a catalog form in designer format" ) {
	const auto result = readDesignerFormInfo ( "Catalog.Items.Form.Form" );
	CHECK ( result.at ( "explanation" ) ==
					"Items and services catalog. This catalog is important for many "
					"application subsystems. The catalog stores both tangible and "
					"intangible assets" );
	CHECK ( result.at ( "fields" ).at ( "Weight" ).at ( "tooltip" ) ==
					"Weight of base unit" );
	CHECK ( result.at ( "fields" ).at ( "Weight" ).at ( "type" ) ==
					"Number(10,3)" );
}

TEST_CASE ( "Read form info for an exchange plan form in designer format" ) {
	const auto result = readDesignerFormInfo ( "ExchangePlan.Full.Form.Form" );
	CHECK ( result.at ( "explanation" ) ==
					"Full exchange data. Includes all objects, without objects from "
					"exchange plan Classifiers" );
	CHECK ( result.at ( "fields" ).at ( "Code" ).at ( "tooltip" ) == "" );
	CHECK ( result.at ( "fields" ).at ( "Code" ).at ( "type" ) == "String(9)" );

	const auto implicit =
			readDesignerFormInfo ( "ExchangePlan.Classifiers.Form.Form" );
	CHECK ( implicit.at ( "fields" ).at ( "Code" ).at ( "type" ) == "String(3)" );
}

TEST_CASE ( "Read form info for a business process form in designer format" ) {
	const auto result =
			readDesignerFormInfo ( "BusinessProcess.Command.Form.Form" );
	CHECK ( result.at ( "explanation" ) == "Internal command process" );
	CHECK ( result.at ( "fields" ).at ( "Appearance" ).at ( "tooltip" ) ==
					"The color scheme used for placing records in the calendar" );
	CHECK ( result.at ( "fields" ).at ( "Appearance" ).at ( "type" ) ==
					"CatalogRef.CalendarAppearance" );
}

TEST_CASE ( "Read form info for a chart of characteristic types form in "
						"designer format" ) {
	const auto result = readDesignerFormInfo (
			"ChartOfCharacteristicTypes.Properties.Form.Form" );
	CHECK ( result.at ( "explanation" ) == "Types of configurable properties" );
	CHECK ( result.at ( "fields" ).at ( "Common" ).at ( "tooltip" ) ==
					"Common property" );
	CHECK ( result.at ( "fields" ).at ( "Common" ).at ( "type" ) == "Boolean" );
}

TEST_CASE ( "Read form info for a chart of calculation types form in designer "
						"format" ) {
	const auto result =
			readDesignerFormInfo ( "ChartOfCalculationTypes.Taxes.Form.Form" );
	CHECK ( result.at ( "explanation" ) ==
					"Taxes and fees from employee's payroll" );
	CHECK ( result.at ( "fields" ).at ( "Account" ).at ( "tooltip" ) ==
					"Default Tax Account" );
	CHECK ( result.at ( "fields" ).at ( "Account" ).at ( "type" ) ==
					"ChartOfAccountsRef.General" );
	CHECK ( result.at ( "tables" )
							.at ( "Base" )
							.at ( "BaseCalculationType" )
							.at ( "type" ) == "ChartOfCalculationTypesRef.Taxes, "
																"ChartOfCalculationTypesRef.Compensations" );
}

TEST_CASE ( "Read form info for a chart of accounts form in designer format" ) {
	const auto result =
			readDesignerFormInfo ( "ChartOfAccounts.General.Form.Form" );
	CHECK ( result.at ( "explanation" ) == "General chart account" );
	CHECK ( result.at ( "fields" ).at ( "Class" ).at ( "tooltip" ) ==
					"Account class" );
	CHECK ( result.at ( "fields" ).at ( "Class" ).at ( "type" ) ==
					"EnumRef.Accounts" );
	CHECK ( result.at ( "tables" )
							.at ( "ExtDimensionTypes" )
							.at ( "ExtDimensionTypesExtDimensionType" )
							.at ( "type" ) == "ChartOfCharacteristicTypesRef.Dimensions" );
	CHECK ( jsonArrayContains ( result.at ( "invisibleFields" ),
															"ExtDimensionTypesTurnoversOnly" ) );
	CHECK ( jsonArrayContains ( result.at ( "invisibleFields" ),
															"ExtDimensionTypesAccrual" ) );
	CHECK ( jsonArrayContains ( result.at ( "invisibleFields" ),
															"ExtDimensionTypesCurrency" ) );
	CHECK ( jsonArrayContains ( result.at ( "invisibleFields" ),
															"ExtDimensionTypesQuantitative" ) );
	CHECK_FALSE ( jsonArrayContains ( result.at ( "invisibleFields" ),
																		"ExtDimensionTypesExtDimensionType" ) );
}

TEST_CASE ( "Read form info for a task form in designer format" ) {
	const auto result = readDesignerFormInfo ( "Task.UserTask.Form.Form" );
	CHECK ( result.at ( "explanation" ) == "User task or reminder" );
	CHECK ( result.at ( "fields" ).at ( "BusinessProcess" ).at ( "tooltip" ) ==
					"Command" );
	CHECK ( result.at ( "fields" ).at ( "BusinessProcess" ).at ( "type" ) ==
					"BusinessProcessRef.Command" );
}

TEST_CASE ( "Read form info for an information register list form in designer "
						"format" ) {
	const auto result =
			readDesignerFormInfo ( "InformationRegister.DepartmentItems.Form.List" );
	CHECK ( result.at ( "explanation" ) ==
					"Produced products by production departments" );
	CHECK ( result.at ( "tables" )
							.at ( "List" )
							.at ( "Department" )
							.at ( "tooltip" ) == "Department" );
	CHECK (
			result.at ( "tables" ).at ( "List" ).at ( "Department" ).at ( "type" ) ==
			"CatalogRef.Departments" );
	CHECK_FALSE ( result.at ( "fields" ).contains ( "Department" ) );
	CHECK_FALSE ( result.at ( "fields" ).contains ( "DepartmentFilter" ) );
}

TEST_CASE ( "Metadata component exposes form info to 1C" ) {
	const auto classes =
			Chars::wideToString ( Chars::wcharToWide ( GetClassNames () ) );
	CHECK ( classes.find ( "Metadata" ) != std::string::npos );

	IComponentBase* component { nullptr };
	REQUIRE ( GetClassObject ( u"Metadata", &component ) != 0 );
	REQUIRE ( component != nullptr );

	TestMemoryManager memoryManager;
	REQUIRE ( component->setMemManager ( &memoryManager ) );

	const auto fromParts = nlohmann::json::parse ( callComponentMethod (
			component, memoryManager, u"GetFormInfo",
			{ tooltipSources ().string (), "Document.Invoice.Form.Form", "en" } ) );
	CHECK ( fromParts.at ( "fields" ).at ( "Customer" ).at ( "type" ) ==
					"CatalogRef.Organizations" );

	const auto dataPaths = nlohmann::json::parse ( callComponentMethod (
			component, memoryManager, u"GetFormDataPaths",
			{ tooltipSources ().string (), "Document.Invoice.Form.Form" } ) );
	CHECK (
			jsonArrayContainsDataPath ( dataPaths, "Customer", "Object.Customer" ) );
	CHECK (
			jsonArrayContainsDataPath ( dataPaths, "ItemsTable", "Object.Items" ) );

	const auto catalog = nlohmann::json::parse ( callComponentMethod (
			component, memoryManager, u"GetFormInfo",
			{ tooltipSources ().string (), "Catalog.Items.Form.Form", "en" } ) );
	CHECK ( catalog.at ( "fields" ).at ( "Weight" ).at ( "type" ) ==
					"Number(10,3)" );

	const auto designer = nlohmann::json::parse (
			callComponentMethod ( component, memoryManager, u"GetFormInfo",
														{ designerTooltipSources ().string (),
															"Document.Invoice.Form.Form", "en" } ) );
	CHECK ( designer.at ( "tables" )
							.at ( "ItemsTable" )
							.at ( "ItemsPrice" )
							.at ( "type" ) == "Number(10,2)" );

	const auto russian = nlohmann::json::parse ( callComponentMethod (
			component, memoryManager, u"GetFormInfo",
			{ cyrillicDesignerTooltipSources ().string (),
				"Документ.ПлатежноеПоручение.Форма.ФормаДокумента", "ru" } ) );
	CHECK ( russian.at ( "fields" ).at ( "Организация" ).at ( "type" ) ==
					"CatalogRef.Организации" );

	CHECK ( DestroyObject ( &component ) == 0 );
	CHECK ( component == nullptr );
}

TEST_CASE ( "Watcher GetChanges scans a Cyrillic repository path" ) {
	const auto testRoot = std::filesystem::temp_directory_path () /
												unicodePathSegment ( "tester-mcp-watcher-кириллица",
																						 L"tester-mcp-watcher-кириллица" );
	const auto repository =
			testRoot / unicodePathSegment ( "репозиторий", L"репозиторий" );
	const auto script =
			repository / unicodePathSegment ( "пинг.bsl", L"пинг.bsl" );
	std::filesystem::remove_all ( testRoot );
	std::filesystem::create_directories ( repository );

	std::ofstream file ( script, std::ios::binary );
	REQUIRE ( file );
	file << "Watcher";
	file.close ();

	IComponentBase* component { nullptr };
	REQUIRE ( GetClassObject ( u"Watcher", &component ) != 0 );
	REQUIRE ( component != nullptr );

	TestMemoryManager memoryManager;
	REQUIRE ( component->setMemManager ( &memoryManager ) );

	std::vector<tVariant> startParams ( 2 );
	setStringVariant ( startParams [ 0 ], pathAsUTF8 ( repository ) );
	tVarInit ( &startParams [ 1 ] );
	startParams [ 1 ].vt = VTYPE_BOOL;
	startParams [ 1 ].bVal = false;
	callComponentProcedure ( component, u"Start", startParams );
	clearStringVariant ( startParams [ 0 ] );

	const auto changes = nlohmann::json::parse (
			callComponentMethod ( component, memoryManager, u"GetChanges", {} ) );
	REQUIRE ( changes.is_array () );
	REQUIRE ( changes.size () == 1 );
	CHECK ( changes.at ( 0 ).at ( "path" ).get<std::string> ().find (
							"пинг.bsl" ) != std::string::npos );
	CHECK ( changes.at ( 0 ).at ( "content" ) ==
					strings::toHash ( "Watcher", false ) );

	std::vector<tVariant> stopParams;
	callComponentProcedure ( component, u"Stop", stopParams );
	CHECK ( DestroyObject ( &component ) == 0 );
	CHECK ( component == nullptr );
	std::filesystem::remove_all ( testRoot );
}

TEST_CASE ( "Root GetHash reads a file from a Cyrillic repository path" ) {
	const auto testRoot =
			std::filesystem::temp_directory_path () /
			unicodePathSegment ( "tester-mcp-кириллица", L"tester-mcp-кириллица" );
	const auto repository =
			testRoot / unicodePathSegment ( "репозиторий", L"репозиторий" );
	const auto script =
			repository / unicodePathSegment ( "пинг.bsl", L"пинг.bsl" );
	std::filesystem::remove_all ( testRoot );
	std::filesystem::create_directories ( repository );
	std::ofstream file ( script, std::ios::binary );
	REQUIRE ( file );
	file << "Watcher";
	file.close ();
	IComponentBase* component { nullptr };
	REQUIRE ( GetClassObject ( u"Root", &component ) != 0 );
	REQUIRE ( component != nullptr );

	TestMemoryManager memoryManager;
	REQUIRE ( component->setMemManager ( &memoryManager ) );

	CHECK ( callComponentMethod ( component, memoryManager, u"GetHash",
																{ pathAsUTF8 ( script ) } ) ==
					std::to_string ( strings::toHash ( "Watcher", false ) ) );

	CHECK ( DestroyObject ( &component ) == 0 );
	CHECK ( component == nullptr );
	std::filesystem::remove_all ( testRoot );
}

TEST_CASE ( "Root exposes NormalizeNumber" ) {
	IComponentBase* component { nullptr };
	REQUIRE ( GetClassObject ( u"Root", &component ) != 0 );
	REQUIRE ( component != nullptr );

	TestMemoryManager memoryManager;
	REQUIRE ( component->setMemManager ( &memoryManager ) );

	const auto method = component->FindMethod ( u"NormalizeNumber" );
	REQUIRE ( method > 0 );
	CHECK ( component->GetNParams ( method ) == 3 );
	CHECK ( callComponentMethod ( component, memoryManager, u"NormalizeNumber",
																{ "-1 234,56", ",", " " } ) == "-1234.56" );
	const std::string nbsp = "\xC2\xA0";
	CHECK ( callComponentMethod ( component, memoryManager, u"NormalizeNumber",
																{ std::string ( "-1" ) + nbsp + "234,56", ",",
																	nbsp } ) == "-1234.56" );

	CHECK ( DestroyObject ( &component ) == 0 );
	CHECK ( component == nullptr );
}

TEST_CASE ( "Root exposes IsNumber" ) {
	IComponentBase* component { nullptr };
	REQUIRE ( GetClassObject ( u"Root", &component ) != 0 );
	REQUIRE ( component != nullptr );

	TestMemoryManager memoryManager;
	REQUIRE ( component->setMemManager ( &memoryManager ) );

	const auto method = component->FindMethod ( u"IsNumber" );
	REQUIRE ( method > 0 );
	CHECK ( component->GetNParams ( method ) == 3 );
	CHECK ( callComponentBoolMethod ( component, u"IsNumber",
																		{ "-1 234,56", ",", " " } ) );
	CHECK ( callComponentBoolMethod ( component, u"IsNumber",
																		{ "123", "", "" } ) );
	CHECK_FALSE ( callComponentBoolMethod ( component, u"IsNumber",
																				 { "Invoice 123", ",", " " } ) );
	CHECK_FALSE ( callComponentBoolMethod ( component, u"IsNumber",
																				 { "1 23", ",", " " } ) );

	CHECK ( DestroyObject ( &component ) == 0 );
	CHECK ( component == nullptr );
}

TEST_CASE ( "strings::toNumber normalizes accounting numeric strings" ) {
	CHECK ( strings::toNumber ( L"12 345", L'.', L' ' ) == L"12345" );
	CHECK ( strings::toNumber ( L"123", L'.', L' ' ) == L"123" );
	CHECK ( strings::toNumber ( L"-123", L'.', L' ' ) == L"-123" );
	CHECK ( strings::toNumber ( L"-1 234,56", L',', L' ' ) == L"-1234.56" );
	CHECK ( strings::toNumber ( L"-1\u00A0234,56", L',', L'\u00A0' ) ==
					L"-1234.56" );
	CHECK ( strings::toNumber ( L"1,234.56", L'.', L',' ) == L"1234.56" );
	CHECK ( strings::toNumber ( L"1.234,56", L',', L'.' ) == L"1234.56" );
	CHECK ( strings::toNumber ( L"  1234567.0  ", L'.', L' ' ) == L"1234567.0" );
}

TEST_CASE ( "strings::toNumber allows omitted separators" ) {
	CHECK ( strings::toNumber ( L"1 234", L'\0', L' ' ) == L"1234" );
	CHECK ( strings::toNumber ( L"123.45", L'.', L'\0' ) == L"123.45" );
	CHECK ( strings::toNumber ( L"123", L'\0', L'\0' ) == L"123" );
}

TEST_CASE ( "strings::toNumber leaves non-numeric strings unchanged" ) {
	CHECK ( strings::toNumber ( L"", L'.', L' ' ) == L"" );
	CHECK ( strings::toNumber ( L"Invoice 123", L'.', L' ' ) == L"Invoice 123" );
	CHECK ( strings::toNumber ( L"1,,,3", L'.', L' ' ) == L"1,,,3" );
	CHECK ( strings::toNumber ( L"12-34", L'.', L' ' ) == L"12-34" );
	CHECK ( strings::toNumber ( L"1.", L'.', L' ' ) == L"1." );
	CHECK ( strings::toNumber ( L",123", L'.', L' ' ) == L",123" );
	CHECK ( strings::toNumber ( L"1 23", L'.', L' ' ) == L"1 23" );
}

TEST_CASE ( "strings::isNumber validates accounting numeric strings" ) {
	CHECK ( strings::isNumber ( L"12 345", L'.', L' ' ) );
	CHECK ( strings::isNumber ( L"123", L'\0', L'\0' ) );
	CHECK ( strings::isNumber ( L"-1 234,56", L',', L' ' ) );
	CHECK ( strings::isNumber ( L"  1234567.0  ", L'.', L' ' ) );
	CHECK_FALSE ( strings::isNumber ( L"", L'.', L' ' ) );
	CHECK_FALSE ( strings::isNumber ( L"Invoice 123", L'.', L' ' ) );
	CHECK_FALSE ( strings::isNumber ( L"1.", L'.', L' ' ) );
	CHECK_FALSE ( strings::isNumber ( L"1 23", L'.', L' ' ) );
}

TEST_CASE ( "Read form info for a document form" ) {
	const auto result = readFormInfo ( "Document.Invoice.Form.Form" );
	CHECK ( result.at ( "explanation" ) ==
					"Document which records sale of items to the customer" );
	CHECK ( result.at ( "fields" ).at ( "Customer" ).at ( "tooltip" ) ==
					"Customer" );
	CHECK ( result.at ( "fields" ).at ( "Customer" ).at ( "type" ) ==
					"CatalogRef.Organizations" );
	CHECK ( result.at ( "fields" ).at ( "Amount" ).at ( "type" ) ==
					"Number(15,2)" );
	CHECK ( result.at ( "tables" )
							.at ( "ItemsTable" )
							.at ( "ItemsPrice" )
							.at ( "tooltip" ) == "Price" );
	CHECK ( result.at ( "tables" )
							.at ( "ItemsTable" )
							.at ( "ItemsPrice" )
							.at ( "type" ) == "Number(10,2)" );
	CHECK_FALSE ( result.at ( "tables" )
										.at ( "ItemsTable" )
										.contains ( "ItemsTableItemUnit" ) );
	CHECK_FALSE ( result.at ( "tables" ).contains ( "Items" ) );
	CHECK_FALSE ( result.contains ( "dataPaths" ) );
}

TEST_SUITE ( "current" ) {
	TEST_CASE ( "Read form info for a common form" ) {
		const auto edt = readFormInfo ( "CommonForm.Report" );
		CHECK ( edt.at ( "explanation" ) == "Common report form" );
		CHECK ( edt.at ( "fields" ).at ( "Result" ).at ( "tooltip" ) ==
						"Report result" );
		CHECK ( edt.at ( "fields" ).at ( "Result" ).at ( "type" ) ==
						"SpreadsheetDocument" );
		CHECK ( edt.at ( "fields" ).at ( "TotalInfo" ).at ( "type" ) ==
						"String(100)" );
		CHECK ( edt.at ( "tables" ).at ( "Tree" ).at ( "TreeName" ).at (
								"tooltip" ) == "Name" );
		CHECK ( edt.at ( "tables" ).at ( "Tree" ).at ( "TreeName" ).at (
								"type" ) == "String(50)" );
		CHECK ( edt.at ( "fields" ).at ( "TreeCurrentName" ).at ( "type" ) ==
						"String(50)" );

		const auto designer = readDesignerFormInfo ( "CommonForm.Report" );
		CHECK ( designer.at ( "explanation" ) == "Common report form" );
		CHECK ( designer.at ( "fields" ).at ( "Result" ).at ( "tooltip" ) ==
						"Report result" );
		CHECK ( designer.at ( "fields" ).at ( "Result" ).at ( "type" ) ==
						"SpreadsheetDocument" );
		CHECK ( designer.at ( "fields" ).at ( "TotalInfo" ).at ( "type" ) ==
						"String(100)" );
		CHECK ( designer.at ( "tables" )
								.at ( "Tree" )
								.at ( "TreeName" )
								.at ( "tooltip" ) == "Name" );
		CHECK ( designer.at ( "tables" )
								.at ( "Tree" )
								.at ( "TreeName" )
								.at ( "type" ) == "String(50)" );
		CHECK ( designer.at ( "fields" ).at ( "TreeCurrentName" ).at (
								"type" ) == "String(50)" );
	}

	TEST_CASE ( "Read common form data paths" ) {
		const auto edt = readFormDataPaths ( "CommonForm.Report" );
		CHECK ( jsonArrayContainsDataPath ( edt, "Result", "Result" ) );
		CHECK ( jsonArrayContainsDataPath ( edt, "TotalInfo", "TotalInfo" ) );
		CHECK ( jsonArrayContainsDataPath ( edt, "Tree", "Tree" ) );
		CHECK (
				jsonArrayContainsDataPath ( edt, "TreeName", "Tree.Name" ) );
		CHECK ( jsonArrayContainsDataPath (
				edt, "TreeCurrentName", "Items.Tree.CurrentData.Name" ) );

		const auto designer = readDesignerFormDataPaths ( "CommonForm.Report" );
		CHECK ( jsonArrayContainsDataPath ( designer, "Result", "Result" ) );
		CHECK (
				jsonArrayContainsDataPath ( designer, "TotalInfo", "TotalInfo" ) );
		CHECK ( jsonArrayContainsDataPath ( designer, "Tree", "Tree" ) );
		CHECK ( jsonArrayContainsDataPath ( designer, "TreeName", "Tree.Name" ) );
		CHECK ( jsonArrayContainsDataPath (
				designer, "TreeCurrentName", "Items.Tree.CurrentData.Name" ) );
	}

	TEST_CASE ( "Metadata component exposes common form info to 1C" ) {
		IComponentBase* component { nullptr };
		REQUIRE ( GetClassObject ( u"Metadata", &component ) != 0 );
		REQUIRE ( component != nullptr );

		TestMemoryManager memoryManager;
		REQUIRE ( component->setMemManager ( &memoryManager ) );

		const auto info = nlohmann::json::parse ( callComponentMethod (
				component, memoryManager, u"GetFormInfo",
				{ tooltipSources ().string (), "CommonForm.Report", "en" } ) );
		CHECK ( info.at ( "fields" ).at ( "Result" ).at ( "type" ) ==
						"SpreadsheetDocument" );

		const auto dataPaths = nlohmann::json::parse ( callComponentMethod (
				component, memoryManager, u"GetFormDataPaths",
				{ tooltipSources ().string (), "CommonForm.Report" } ) );
		CHECK ( jsonArrayContainsDataPath ( dataPaths, "Result", "Result" ) );

		CHECK ( DestroyObject ( &component ) == 0 );
		CHECK ( component == nullptr );
	}

	TEST_CASE ( "Read dynamic form columns for a data processor form" ) {
		const auto edt = readFormInfo ( "DataProcessor.TestAIVision.Form.Form" );
		CHECK ( edt.at ( "tables" )
								.at ( "Items" )
								.at ( "ItemsTotal" )
								.at ( "type" ) == "Number(10,0)" );
		CHECK ( edt.at ( "tables" )
								.at ( "Goods" )
								.at ( "GoodsFieldNumber" )
								.at ( "type" ) == "Number(10,0)" );

		const auto designer =
				readDesignerFormInfo ( "DataProcessor.TestAIVision.Form.Form" );
		CHECK ( designer.at ( "tables" )
								.at ( "Items" )
								.at ( "ItemsTotal" )
								.at ( "type" ) == "Number(10,0)" );
		CHECK ( designer.at ( "tables" )
								.at ( "Goods" )
								.at ( "GoodsFieldNumber" )
								.at ( "type" ) == "Number(10,0)" );
	}

	TEST_CASE ( "Read form info fill checking for data processor fields" ) {
		const auto edt = readFormInfo ( "DataProcessor.TestAIVision.Form.Form" );
		CHECK ( edt.at ( "fields" ).at ( "SomeString" ).at ( "fillChecking" ) ==
						"ShowError" );
		CHECK ( edt.at ( "fields" ).at ( "Amount" ).at ( "fillChecking" ) ==
						"ShowError" );
		CHECK ( edt.at ( "fields" ).at ( "SomeCheckBox" ).at (
								"fillChecking" ) == "DontCheck" );

		const auto designer =
				readDesignerFormInfo ( "DataProcessor.TestAIVision.Form.Form" );
		CHECK ( designer.at ( "fields" ).at ( "SomeString" ).at (
								"fillChecking" ) == "ShowError" );
		CHECK ( designer.at ( "fields" ).at ( "Amount" ).at (
								"fillChecking" ) == "ShowError" );
		CHECK ( designer.at ( "fields" ).at ( "SomeCheckBox" ).at (
								"fillChecking" ) == "DontCheck" );
	}
}

int main ( int argc, char** argv ) {
	doctest::Context context;
	context.applyCommandLine ( argc, argv );
	context.addFilter ( "test-suite", "current" );
	return context.run ();
}
