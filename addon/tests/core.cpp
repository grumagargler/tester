#define DOCTEST_CONFIG_IMPLEMENT
#include "1c/componentbase.h"
#include "1c/imemorymanager.h"
#include "chars.h"
#include "json.h"
#include "tooltips.h"
#include "transform.h"
#include "types.h"
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

nlohmann::json readTooltipsFrom ( const std::filesystem::path& sources,
																	const std::string& formName,
																	const std::string& language = "en" ) {
	Tooltips tips ( sources.string (), formName, language );
	const auto body = tips.get ();
	REQUIRE_FALSE ( body.empty () );
	return nlohmann::json::parse ( body );
}

nlohmann::json readTooltips ( const std::string& formName ) {
	return readTooltipsFrom ( tooltipSources (), formName );
}

nlohmann::json readDesignerTooltips ( const std::string& formName,
																			const std::string& language = "en" ) {
	return readTooltipsFrom ( designerTooltipSources (), formName, language );
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

void callComponentProcedure ( IComponentBase* Component, const WCHAR_T* Name,
															std::vector<tVariant>& Params ) {
	const auto method = Component->FindMethod ( Name );
	REQUIRE ( method > 0 );
	const auto ok =
			Component->CallAsProc ( method, Params.empty () ? nullptr : Params.data (),
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

TEST_CASE ( "Read tooltips for a document form" ) {
	const auto result = readTooltips ( "Document.Invoice.Form.Form" );
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
}

TEST_CASE ( "Read tooltips for a catalog form" ) {
	const auto result = readTooltips ( "Catalog.Items.Form.Form" );
	CHECK ( result.at ( "explanation" ) ==
					"Items and services catalog. This catalog is important for many "
					"application subsystems. The catalog stores both tangible and "
					"intangible assets" );
	CHECK ( result.at ( "fields" ).at ( "Weight" ).at ( "tooltip" ) ==
					"Weight of base unit" );
	CHECK ( result.at ( "fields" ).at ( "Weight" ).at ( "type" ) ==
					"Number(10,3)" );
}

TEST_CASE ( "Read tooltips for an exchange plan form" ) {
	const auto result = readTooltips ( "ExchangePlan.Full.Form.Form" );
	CHECK ( result.at ( "explanation" ) ==
					"Full exchange data. Includes all objects, without objects from "
					"exchange plan Classifiers" );
	CHECK ( result.at ( "fields" ).at ( "Code" ).at ( "tooltip" ) == "" );
	CHECK ( result.at ( "fields" ).at ( "Code" ).at ( "type" ) == "String(9)" );

	const auto implicit = readTooltips ( "ExchangePlan.Classifiers.Form.Form" );
	CHECK ( implicit.at ( "fields" ).at ( "Code" ).at ( "type" ) == "String(3)" );
}

TEST_CASE ( "Read tooltips for a business process form" ) {
	const auto result = readTooltips ( "BusinessProcess.Command.Form.Form" );
	CHECK ( result.at ( "explanation" ) == "Internal command process" );
	CHECK ( result.at ( "fields" ).at ( "Appearance" ).at ( "tooltip" ) ==
					"The color scheme used for placing records in the calendar" );
	CHECK ( result.at ( "fields" ).at ( "Appearance" ).at ( "type" ) ==
					"CatalogRef.CalendarAppearance" );
}

TEST_CASE ( "Read tooltips for a chart of characteristic types form" ) {
	const auto result =
			readTooltips ( "ChartOfCharacteristicTypes.Properties.Form.Form" );
	CHECK ( result.at ( "explanation" ) == "Types of configurable properties" );
	CHECK ( result.at ( "fields" ).at ( "Common" ).at ( "tooltip" ) ==
					"Common property" );
	CHECK ( result.at ( "fields" ).at ( "Common" ).at ( "type" ) == "Boolean" );
}

TEST_CASE ( "Read tooltips for a chart of calculation types form" ) {
	const auto result =
			readTooltips ( "ChartOfCalculationTypes.Taxes.Form.Form" );
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

TEST_CASE ( "Read tooltips for a chart of accounts form" ) {
	const auto result = readTooltips ( "ChartOfAccounts.General.Form.Form" );
	CHECK ( result.at ( "explanation" ) == "General chart account" );
	CHECK ( result.at ( "fields" ).at ( "Class" ).at ( "tooltip" ) ==
					"Account class" );
	CHECK ( result.at ( "fields" ).at ( "Class" ).at ( "type" ) ==
					"EnumRef.Accounts" );
	CHECK ( result.at ( "tables" )
							.at ( "ExtDimensionTypes" )
							.at ( "ExtDimensionTypesExtDimensionType" )
							.at ( "type" ) == "ChartOfCharacteristicTypesRef.Dimensions" );
}

TEST_CASE ( "Read tooltips for a task form" ) {
	const auto result = readTooltips ( "Task.UserTask.Form.Form" );
	CHECK ( result.at ( "explanation" ) == "User task or reminder" );
	CHECK ( result.at ( "fields" ).at ( "BusinessProcess" ).at ( "tooltip" ) ==
					"Command" );
	CHECK ( result.at ( "fields" ).at ( "BusinessProcess" ).at ( "type" ) ==
					"BusinessProcessRef.Command" );
}

TEST_CASE ( "Read tooltips for an information register list form" ) {
	const auto result =
			readTooltips ( "InformationRegister.DepartmentItems.Form.List" );
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

TEST_CASE ( "Read tooltips for a document form in designer format" ) {
	const auto result = readDesignerTooltips ( "Document.Invoice.Form.Form" );
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
}

TEST_CASE ( "Read tooltips for a Russian document form in designer format" ) {
	const auto result = readTooltipsFrom (
			cyrillicDesignerTooltipSources (),
			"Документ.ПлатежноеПоручение.Форма.ФормаДокумента", "ru" );
	CHECK ( result.at ( "explanation" ) ==
					"Платежный документ для перечисления денег" );
	CHECK ( result.at ( "fields" ).at ( "Номер" ).at ( "type" ) ==
					"String(11)" );
	CHECK ( result.at ( "fields" ).at ( "Организация" ).at ( "tooltip" ) ==
					"Организация плательщика" );
	CHECK ( result.at ( "fields" ).at ( "Организация" ).at ( "type" ) ==
					"CatalogRef.Организации" );
	CHECK ( result.at ( "fields" ).at ( "СуммаДокумента" ).at ( "type" ) ==
					"Number(15,2)" );
}

TEST_CASE ( "Read tooltips for a catalog form in designer format" ) {
	const auto result = readDesignerTooltips ( "Catalog.Items.Form.Form" );
	CHECK ( result.at ( "explanation" ) ==
					"Items and services catalog. This catalog is important for many "
					"application subsystems. The catalog stores both tangible and "
					"intangible assets" );
	CHECK ( result.at ( "fields" ).at ( "Weight" ).at ( "tooltip" ) ==
					"Weight of base unit" );
	CHECK ( result.at ( "fields" ).at ( "Weight" ).at ( "type" ) ==
					"Number(10,3)" );
}

TEST_CASE ( "Read tooltips for an exchange plan form in designer format" ) {
	const auto result = readDesignerTooltips ( "ExchangePlan.Full.Form.Form" );
	CHECK ( result.at ( "explanation" ) ==
					"Full exchange data. Includes all objects, without objects from "
					"exchange plan Classifiers" );
	CHECK ( result.at ( "fields" ).at ( "Code" ).at ( "tooltip" ) == "" );
	CHECK ( result.at ( "fields" ).at ( "Code" ).at ( "type" ) == "String(9)" );

	const auto implicit =
			readDesignerTooltips ( "ExchangePlan.Classifiers.Form.Form" );
	CHECK ( implicit.at ( "fields" ).at ( "Code" ).at ( "type" ) == "String(3)" );
}

TEST_CASE ( "Read tooltips for a business process form in designer format" ) {
	const auto result =
			readDesignerTooltips ( "BusinessProcess.Command.Form.Form" );
	CHECK ( result.at ( "explanation" ) == "Internal command process" );
	CHECK ( result.at ( "fields" ).at ( "Appearance" ).at ( "tooltip" ) ==
					"The color scheme used for placing records in the calendar" );
	CHECK ( result.at ( "fields" ).at ( "Appearance" ).at ( "type" ) ==
					"CatalogRef.CalendarAppearance" );
}

TEST_CASE ( "Read tooltips for a chart of characteristic types form in "
						"designer format" ) {
	const auto result = readDesignerTooltips (
			"ChartOfCharacteristicTypes.Properties.Form.Form" );
	CHECK ( result.at ( "explanation" ) == "Types of configurable properties" );
	CHECK ( result.at ( "fields" ).at ( "Common" ).at ( "tooltip" ) ==
					"Common property" );
	CHECK ( result.at ( "fields" ).at ( "Common" ).at ( "type" ) == "Boolean" );
}

TEST_CASE ( "Read tooltips for a chart of calculation types form in designer "
						"format" ) {
	const auto result =
			readDesignerTooltips ( "ChartOfCalculationTypes.Taxes.Form.Form" );
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

TEST_CASE ( "Read tooltips for a chart of accounts form in designer format" ) {
	const auto result =
			readDesignerTooltips ( "ChartOfAccounts.General.Form.Form" );
	CHECK ( result.at ( "explanation" ) == "General chart account" );
	CHECK ( result.at ( "fields" ).at ( "Class" ).at ( "tooltip" ) ==
					"Account class" );
	CHECK ( result.at ( "fields" ).at ( "Class" ).at ( "type" ) ==
					"EnumRef.Accounts" );
	CHECK ( result.at ( "tables" )
							.at ( "ExtDimensionTypes" )
							.at ( "ExtDimensionTypesExtDimensionType" )
							.at ( "type" ) == "ChartOfCharacteristicTypesRef.Dimensions" );
}

TEST_CASE ( "Read tooltips for a task form in designer format" ) {
	const auto result = readDesignerTooltips ( "Task.UserTask.Form.Form" );
	CHECK ( result.at ( "explanation" ) == "User task or reminder" );
	CHECK ( result.at ( "fields" ).at ( "BusinessProcess" ).at ( "tooltip" ) ==
					"Command" );
	CHECK ( result.at ( "fields" ).at ( "BusinessProcess" ).at ( "type" ) ==
					"BusinessProcessRef.Command" );
}

TEST_CASE ( "Read tooltips for an information register list form in designer "
						"format" ) {
	const auto result =
			readDesignerTooltips ( "InformationRegister.DepartmentItems.Form.List" );
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

TEST_CASE ( "Metadata component exposes tooltips to 1C" ) {
	const auto classes =
			Chars::wideToString ( Chars::wcharToWide ( GetClassNames () ) );
	CHECK ( classes.find ( "Metadata" ) != std::string::npos );

	IComponentBase* component { nullptr };
	REQUIRE ( GetClassObject ( u"Metadata", &component ) != 0 );
	REQUIRE ( component != nullptr );

	TestMemoryManager memoryManager;
	REQUIRE ( component->setMemManager ( &memoryManager ) );

	const auto fromParts = nlohmann::json::parse ( callComponentMethod (
			component, memoryManager, u"GetTooltips",
			{ tooltipSources ().string (), "Document.Invoice.Form.Form", "en" } ) );
	CHECK ( fromParts.at ( "fields" ).at ( "Customer" ).at ( "type" ) ==
					"CatalogRef.Organizations" );

	const auto catalog = nlohmann::json::parse ( callComponentMethod (
			component, memoryManager, u"GetTooltips",
			{ tooltipSources ().string (), "Catalog.Items.Form.Form", "en" } ) );
	CHECK ( catalog.at ( "fields" ).at ( "Weight" ).at ( "type" ) ==
					"Number(10,3)" );

	const auto designer = nlohmann::json::parse (
			callComponentMethod ( component, memoryManager, u"GetTooltips",
														{ designerTooltipSources ().string (),
															"Document.Invoice.Form.Form", "en" } ) );
	CHECK ( designer.at ( "tables" )
							.at ( "ItemsTable" )
							.at ( "ItemsPrice" )
							.at ( "type" ) == "Number(10,2)" );

	const auto russian = nlohmann::json::parse (
			callComponentMethod (
					component, memoryManager, u"GetTooltips",
					{ cyrillicDesignerTooltipSources ().string (),
						"Документ.ПлатежноеПоручение.Форма.ФормаДокумента", "ru" } ) );
	CHECK ( russian.at ( "fields" ).at ( "Организация" ).at ( "type" ) ==
					"CatalogRef.Организации" );

	CHECK ( DestroyObject ( &component ) == 0 );
	CHECK ( component == nullptr );
}

TEST_SUITE ( "current" ) {
	TEST_CASE ( "Root GetHash reads a file from a Cyrillic repository path" ) {
		const auto testRoot = std::filesystem::temp_directory_path () /
													unicodePathSegment ( "tester-mcp-кириллица",
																							 L"tester-mcp-кириллица" );
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

	TEST_CASE ( "Watcher GetChanges scans a Cyrillic repository path" ) {
		const auto testRoot =
				std::filesystem::temp_directory_path () /
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
}

int main ( int argc, char** argv ) {
	doctest::Context context;
	context.applyCommandLine ( argc, argv );
	context.addFilter ( "test-suite", "current" );
	return context.run ();
}
