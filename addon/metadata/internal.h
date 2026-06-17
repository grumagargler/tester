#pragma once
#include "chars.h"
#include <filesystem>
#include <optional>
#include <string>
#include <unordered_map>
#include <utility>
#include <vector>

namespace metadata::internal {
enum class MetadataFamily {
	Catalog,
	ExchangePlan,
	Document,
	CommonForm,
	ChartOfAccounts,
	BusinessProcess,
	ChartOfCharacteristicTypes,
	ChartOfCalculationTypes,
	Task,
	InformationRegister,
	DataProcessor,
	Unknown
};

struct MetadataType {
	MetadataFamily family { MetadataFamily::Unknown };
	std::string name;
};

struct MetadataField {
	std::string tooltip, type, fillChecking;
};

struct FormAttribute {
	std::vector<std::string> types;
	std::string mainTable;
	MetadataField field;
};

struct MetadataDescription {
	std::string explanation;
	std::unordered_map<std::string, MetadataField> fields;
	std::unordered_map<std::string,
										 std::unordered_map<std::string, MetadataField>>
			tables;
};

struct ParsedPath {
	std::string source, member;
	std::optional<std::string> field;
};

inline const std::unordered_map<std::string, MetadataFamily> FormKinds {
		{ "Catalog", MetadataFamily::Catalog },
		{ "Справочник", MetadataFamily::Catalog },
		{ "ExchangePlan", MetadataFamily::ExchangePlan },
		{ "ПланОбмена", MetadataFamily::ExchangePlan },
		{ "Document", MetadataFamily::Document },
		{ "Документ", MetadataFamily::Document },
		{ "CommonForm", MetadataFamily::CommonForm },
		{ "ОбщаяФорма", MetadataFamily::CommonForm },
		{ "ChartOfAccounts", MetadataFamily::ChartOfAccounts },
		{ "ПланСчетов", MetadataFamily::ChartOfAccounts },
		{ "BusinessProcess", MetadataFamily::BusinessProcess },
		{ "БизнесПроцесс", MetadataFamily::BusinessProcess },
		{ "ChartOfCharacteristicTypes",
			MetadataFamily::ChartOfCharacteristicTypes },
		{ "ПланВидовХарактеристик", MetadataFamily::ChartOfCharacteristicTypes },
		{ "ChartOfCalculationTypes", MetadataFamily::ChartOfCalculationTypes },
		{ "ПланВидовРасчета", MetadataFamily::ChartOfCalculationTypes },
		{ "Task", MetadataFamily::Task },
		{ "Задача", MetadataFamily::Task },
		{ "InformationRegister", MetadataFamily::InformationRegister },
		{ "РегистрСведений", MetadataFamily::InformationRegister },
		{ "DataProcessor", MetadataFamily::DataProcessor },
		{ "Обработка", MetadataFamily::DataProcessor },
};

inline const std::unordered_map<MetadataFamily, std::string> SourceFolders {
		{ MetadataFamily::Catalog, "Catalogs" },
		{ MetadataFamily::ExchangePlan, "ExchangePlans" },
		{ MetadataFamily::Document, "Documents" },
		{ MetadataFamily::CommonForm, "CommonForms" },
		{ MetadataFamily::ChartOfAccounts, "ChartsOfAccounts" },
		{ MetadataFamily::BusinessProcess, "BusinessProcesses" },
		{ MetadataFamily::ChartOfCharacteristicTypes,
			"ChartsOfCharacteristicTypes" },
		{ MetadataFamily::ChartOfCalculationTypes, "ChartsOfCalculationTypes" },
		{ MetadataFamily::Task, "Tasks" },
		{ MetadataFamily::InformationRegister, "InformationRegisters" },
		{ MetadataFamily::DataProcessor, "DataProcessors" },
};

inline const std::unordered_map<MetadataFamily, std::string> ReferencePrefixes {
		{ MetadataFamily::Catalog, "CatalogRef." },
		{ MetadataFamily::ExchangePlan, "ExchangePlanRef." },
		{ MetadataFamily::Document, "DocumentRef." },
		{ MetadataFamily::ChartOfAccounts, "ChartOfAccountsRef." },
		{ MetadataFamily::BusinessProcess, "BusinessProcessRef." },
		{ MetadataFamily::ChartOfCharacteristicTypes,
			"ChartOfCharacteristicTypesRef." },
		{ MetadataFamily::ChartOfCalculationTypes, "ChartOfCalculationTypesRef." },
		{ MetadataFamily::Task, "TaskRef." },
		{ MetadataFamily::InformationRegister, "InformationRegisterRecordKey." },
		{ MetadataFamily::DataProcessor, "DataProcessorObject." },
};

inline const std::unordered_map<MetadataFamily, std::vector<std::string>>
		ImplicitStandardFields {
				{ MetadataFamily::Catalog,
					{ "PredefinedDataName", "Code", "Description", "IsFolder", "Parent",
						"Predefined", "DeletionMark", "Ref" } },
				{ MetadataFamily::ExchangePlan,
					{ "ExchangeDate", "ThisNode", "ReceivedNo", "SentNo", "Ref",
						"DeletionMark", "Description", "Code" } },
				{ MetadataFamily::Document,
					{ "Posted", "Ref", "DeletionMark", "Date", "Number" } },
				{ MetadataFamily::ChartOfAccounts,
					{ "PredefinedDataName", "Order", "OffBalance", "Type", "Description",
						"Code", "Parent", "Predefined", "DeletionMark", "Ref" } },
				{ MetadataFamily::BusinessProcess,
					{ "Started", "HeadTask", "Completed", "Ref", "DeletionMark", "Date",
						"Number" } },
				{ MetadataFamily::ChartOfCharacteristicTypes,
					{ "PredefinedDataName", "ValueType", "Description", "Code",
						"IsFolder", "Parent", "Predefined", "DeletionMark", "Ref" } },
				{ MetadataFamily::ChartOfCalculationTypes,
					{ "PredefinedDataName", "Predefined", "Ref", "DeletionMark",
						"ActionPeriodIsBasic", "Description", "Code" } },
				{ MetadataFamily::Task,
					{ "Executed", "Description", "RoutePoint", "BusinessProcess", "Ref",
						"DeletionMark", "Date", "Number" } },
				{ MetadataFamily::InformationRegister,
					{ "Active", "LineNumber", "Recorder", "Period" } },
		};

inline const std::vector<std::pair<std::string, MetadataFamily>> TypePrefixes {
		{ "ChartOfCharacteristicTypesObject.",
			MetadataFamily::ChartOfCharacteristicTypes },
		{ "ChartOfCharacteristicTypesRef.",
			MetadataFamily::ChartOfCharacteristicTypes },
		{ "ChartOfCharacteristicTypesSelection.",
			MetadataFamily::ChartOfCharacteristicTypes },
		{ "ChartOfCharacteristicTypesList.",
			MetadataFamily::ChartOfCharacteristicTypes },
		{ "ChartOfCharacteristicTypesManager.",
			MetadataFamily::ChartOfCharacteristicTypes },
		{ "ChartOfCharacteristicTypes.",
			MetadataFamily::ChartOfCharacteristicTypes },
		{ "ChartOfCalculationTypesObject.",
			MetadataFamily::ChartOfCalculationTypes },
		{ "ChartOfCalculationTypesRef.", MetadataFamily::ChartOfCalculationTypes },
		{ "ChartOfCalculationTypesSelection.",
			MetadataFamily::ChartOfCalculationTypes },
		{ "ChartOfCalculationTypesList.", MetadataFamily::ChartOfCalculationTypes },
		{ "ChartOfCalculationTypesManager.",
			MetadataFamily::ChartOfCalculationTypes },
		{ "ChartOfCalculationTypes.", MetadataFamily::ChartOfCalculationTypes },
		{ "ChartOfAccountsObject.", MetadataFamily::ChartOfAccounts },
		{ "ChartOfAccountsRef.", MetadataFamily::ChartOfAccounts },
		{ "ChartOfAccountsSelection.", MetadataFamily::ChartOfAccounts },
		{ "ChartOfAccountsList.", MetadataFamily::ChartOfAccounts },
		{ "ChartOfAccountsManager.", MetadataFamily::ChartOfAccounts },
		{ "ChartOfAccounts.", MetadataFamily::ChartOfAccounts },
		{ "InformationRegisterRecordSet.", MetadataFamily::InformationRegister },
		{ "InformationRegisterRecordKey.", MetadataFamily::InformationRegister },
		{ "InformationRegisterRecord.", MetadataFamily::InformationRegister },
		{ "InformationRegisterSelection.", MetadataFamily::InformationRegister },
		{ "InformationRegisterList.", MetadataFamily::InformationRegister },
		{ "InformationRegisterManager.", MetadataFamily::InformationRegister },
		{ "InformationRegister.", MetadataFamily::InformationRegister },
		{ "BusinessProcessObject.", MetadataFamily::BusinessProcess },
		{ "BusinessProcessRef.", MetadataFamily::BusinessProcess },
		{ "BusinessProcessSelection.", MetadataFamily::BusinessProcess },
		{ "BusinessProcessList.", MetadataFamily::BusinessProcess },
		{ "BusinessProcessManager.", MetadataFamily::BusinessProcess },
		{ "BusinessProcess.", MetadataFamily::BusinessProcess },
		{ "ExchangePlanObject.", MetadataFamily::ExchangePlan },
		{ "ExchangePlanRef.", MetadataFamily::ExchangePlan },
		{ "ExchangePlanSelection.", MetadataFamily::ExchangePlan },
		{ "ExchangePlanList.", MetadataFamily::ExchangePlan },
		{ "ExchangePlanManager.", MetadataFamily::ExchangePlan },
		{ "ExchangePlan.", MetadataFamily::ExchangePlan },
		{ "DocumentObject.", MetadataFamily::Document },
		{ "DocumentRef.", MetadataFamily::Document },
		{ "DocumentSelection.", MetadataFamily::Document },
		{ "DocumentList.", MetadataFamily::Document },
		{ "DocumentManager.", MetadataFamily::Document },
		{ "Document.", MetadataFamily::Document },
		{ "CatalogObject.", MetadataFamily::Catalog },
		{ "CatalogRef.", MetadataFamily::Catalog },
		{ "CatalogSelection.", MetadataFamily::Catalog },
		{ "CatalogList.", MetadataFamily::Catalog },
		{ "CatalogManager.", MetadataFamily::Catalog },
		{ "Catalog.", MetadataFamily::Catalog },
		{ "DataProcessorObject.", MetadataFamily::DataProcessor },
		{ "DataProcessorManager.", MetadataFamily::DataProcessor },
		{ "DataProcessor.", MetadataFamily::DataProcessor },
		{ "TaskObject.", MetadataFamily::Task },
		{ "TaskRef.", MetadataFamily::Task },
		{ "TaskSelection.", MetadataFamily::Task },
		{ "TaskList.", MetadataFamily::Task },
		{ "TaskManager.", MetadataFamily::Task },
		{ "Task.", MetadataFamily::Task },
};

inline std::string referenceType ( const MetadataType& type ) {
	if ( type.name.empty () ) {
		return {};
	}
	const auto prefix = ReferencePrefixes.find ( type.family );
	if ( prefix == ReferencePrefixes.end () ) {
		return {};
	}
	return prefix->second + type.name;
}

inline std::filesystem::path utf8PathSegment ( const std::string& value ) {
#ifdef _WIN32
	return Chars::wideToPath ( Chars::stringToWide ( value ) );
#else
	return std::filesystem::path ( value );
#endif
}

inline std::string pathToUTF8 ( const std::filesystem::path& path ) {
	const auto value = path.u8string ();
#ifdef __cpp_char8_t
	return std::string ( reinterpret_cast<const char*> ( value.data () ),
											 value.size () );
#else
	return value;
#endif
}
}
