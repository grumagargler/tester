#define DOCTEST_CONFIG_IMPLEMENT_WITH_MAIN
#include "json.h"
#include <doctest/doctest.h>
#include <nlohmann/json.hpp>

TEST_CASE ( "JSON::compare returns structured property changes" ) {
	const std::string previous = R"json([
		{
			"ID":"Catalog.Organizations.Form.Form",
			"TitleText":"Контрагенты (create)",
			"Type":"TestedForm",
			"Items":[
				{
					"ID":"EntityGroup",
					"TitleText":"Entity group",
					"Type":"TestedFormGroup",
					"Items":[
						{
							"ID":"FullDescription",
							"TitleText":"Официальное",
							"Type":"TestedFormField",
							"Value":""
						},
						{
							"ID":"Description",
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
			"ID":"Catalog.Organizations.Form.Form",
			"TitleText":"Контрагенты (create)",
			"Type":"TestedForm",
			"Items":[
				{
					"ID":"EntityGroup",
					"TitleText":"Entity group",
					"Type":"TestedFormGroup",
					"Items":[
						{
							"ID":"FullDescription",
							"TitleText":"Официальное",
							"Type":"TestedFormField",
							"Value":"SRL TechVision Moldova"
						},
						{
							"ID":"Description",
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

TEST_CASE ( "JSON::compare matches identified controls independently from order" ) {
	const std::string previous = R"json([
		{
			"ID":"Form",
			"TitleText":"Window",
			"Type":"TestedForm",
			"Items":[
				{ "ID":"A", "TitleText":"A", "Type":"TestedFormField", "Value":"1" },
				{ "ID":"B", "TitleText":"B", "Type":"TestedFormField", "Value":"2" }
			]
		}
	])json";
	const std::string current = R"json([
		{
			"ID":"Form",
			"TitleText":"Window",
			"Type":"TestedForm",
			"Items":[
				{ "ID":"B", "TitleText":"B", "Type":"TestedFormField", "Value":"2" },
				{ "ID":"A", "TitleText":"A", "Type":"TestedFormField", "Value":"1" }
			]
		}
	])json";
	const auto result =
			nlohmann::json::parse ( JSON::compare ( previous, current ) );
	CHECK ( result.at ( "ChangeCount" ) == 0 );
	CHECK ( result.at ( "Changes" ).empty () );
}
