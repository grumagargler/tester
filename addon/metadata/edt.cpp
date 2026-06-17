#include "edt.h"
#include "internal.h"
#include "transform.h"
#include <algorithm>
#include <filesystem>
#include <memory>
#include <nlohmann/json.hpp>
#include <optional>
#include <pugixml.hpp>
#include <string_view>
#include <unordered_map>
#include <unordered_set>
#include <utility>
#include <vector>

namespace {
using Json = nlohmann::ordered_json;
using namespace metadata::internal;
using FormColumns =
		std::unordered_map<std::string,
											 std::unordered_map<std::string, MetadataField>>;
constexpr const char* DefaultFillChecking = "DontCheck";

std::string trim ( const pugi::xml_node& node ) {
	return strings::trim ( node.text ().as_string () );
}

std::string fillCheckingValue ( const pugi::xml_node& node, const char* tag ) {
	const auto value = trim ( node.child ( tag ) );
	return value.empty () ? DefaultFillChecking : value;
}

std::string localizedValue ( const pugi::xml_node& node, std::string_view tag,
														 const std::string& language ) {
	for ( const auto& child : node.children ( tag.data () ) ) {
		if ( trim ( child.child ( "key" ) ) == language ) {
			return trim ( child.child ( "value" ) );
		}
	}
	return {};
}

std::string localizedFormValue ( const pugi::xml_node& node,
																 const std::string& language ) {
	auto value = localizedValue ( node, "toolTip", language );
	if ( value.empty () ) {
		value = localizedValue ( node, "title", language );
	}
	return value;
}

std::vector<std::string> typeValues ( const pugi::xml_node& node ) {
	std::vector<std::string> values;
	for ( const auto& child : node.children ( "types" ) ) {
		auto value = trim ( child );
		if ( !value.empty () ) {
			values.push_back ( value );
		}
	}
	return values;
}

std::string lowerCamel ( const std::string& value ) {
	if ( value.empty () ) {
		return {};
	}
	auto result = value;
	result [ 0 ] = std::tolower ( result [ 0 ] );
	return result;
}

std::string typeFromReferenceValue ( const pugi::xml_node& node ) {
	const auto value = trim ( node.child ( "fillValue" ).child ( "value" ) );
	if ( value.empty () ) {
		return {};
	}
	const auto parts = strings::split ( value, "." );
	if ( parts.size () < 3 ) {
		return {};
	}
	if ( parts [ 0 ] == "Catalog" ) {
		return "CatalogRef." + parts [ 1 ];
	}
	if ( parts [ 0 ] == "Document" ) {
		return "DocumentRef." + parts [ 1 ];
	}
	if ( parts [ 0 ] == "ExchangePlan" ) {
		return "ExchangePlanRef." + parts [ 1 ];
	}
	if ( parts [ 0 ] == "ChartOfAccounts" ) {
		return "ChartOfAccountsRef." + parts [ 1 ];
	}
	if ( parts [ 0 ] == "BusinessProcess" ) {
		return "BusinessProcessRef." + parts [ 1 ];
	}
	if ( parts [ 0 ] == "ChartOfCharacteristicTypes" ) {
		return "ChartOfCharacteristicTypesRef." + parts [ 1 ];
	}
	if ( parts [ 0 ] == "ChartOfCalculationTypes" ) {
		return "ChartOfCalculationTypesRef." + parts [ 1 ];
	}
	if ( parts [ 0 ] == "Task" ) {
		return "TaskRef." + parts [ 1 ];
	}
	return {};
}

class Repository {
public:
	Repository ( std::filesystem::path sources, std::string language )
			: sources ( std::move ( sources ) ), language ( std::move ( language ) ) {
	}

	std::shared_ptr<const MetadataDescription>
	metadata ( const MetadataType& type ) {
		if ( type.family == MetadataFamily::Unknown || type.name.empty () ) {
			return nullptr;
		}
		const auto key =
				std::to_string ( static_cast<int> ( type.family ) ) + ":" + type.name;
		if ( const auto found = metadataCache.find ( key );
				 found != metadataCache.end () ) {
			return found->second;
		}
		const auto path = metadataPath ( type );
		const auto document = loadDocument ( path );
		if ( !document ) {
			metadataCache [ key ] = nullptr;
			return nullptr;
		}
		auto description = std::make_shared<MetadataDescription> (
				buildMetadata ( *document, type ) );
		metadataCache [ key ] = description;
		return description;
	}

	std::shared_ptr<const pugi::xml_document>
	document ( const std::filesystem::path& path ) {
		return loadDocument ( path );
	}

	std::string formatType ( const pugi::xml_node& node ) {
		const auto types = formatTypes ( node );
		return strings::concat ( types, ", " );
	}

private:
	std::shared_ptr<const pugi::xml_document>
	loadDocument ( const std::filesystem::path& path ) {
		const auto key = pathToUTF8 ( path );
		if ( const auto found = documents.find ( key );
				 found != documents.end () ) {
			return found->second;
		}
		auto document = std::make_shared<pugi::xml_document> ();
		if ( document->load_file ( path.c_str () ) ) {
			documents [ key ] = document;
			return document;
		}
		documents [ key ] = nullptr;
		return nullptr;
	}

	std::filesystem::path metadataPath ( const MetadataType& type ) const {
		const auto folder = SourceFolders.find ( type.family );
		if ( folder == SourceFolders.end () ) {
			return {};
		}
		return sources / folder->second / utf8PathSegment ( type.name ) /
					 utf8PathSegment ( type.name + ".mdo" );
	}

	std::optional<MetadataType>
	parseMetadataType ( const std::string& typeName ) const {
		for ( const auto& [ prefix, family ] : TypePrefixes ) {
			if ( !typeName.starts_with ( prefix ) ) {
				continue;
			}
			const auto rest = typeName.substr ( prefix.size () );
			const auto parts = strings::split ( rest, "." );
			if ( parts.empty () ) {
				return std::nullopt;
			}
			return MetadataType { family, parts [ 0 ] };
		}
		return std::nullopt;
	}

	std::vector<std::string> formatTypes ( const pugi::xml_node& node ) {
		std::vector<std::string> result;
		std::unordered_set<std::string> seen;
		for ( const auto& type : typeValues ( node ) ) {
			if ( type.starts_with ( "DefinedType." ) ) {
				const auto definedName =
						type.substr ( std::string { "DefinedType." }.size () );
				const auto path = sources / "DefinedTypes" /
													utf8PathSegment ( definedName ) /
													utf8PathSegment ( definedName + ".mdo" );
				const auto defined = loadDocument ( path );
				if ( defined ) {
					for ( const auto& resolved : formatTypes (
										defined->document_element ().child ( "type" ) ) ) {
						if ( seen.insert ( resolved ).second ) {
							result.push_back ( resolved );
						}
					}
				}
				continue;
			}
			auto value = type;
			if ( type == "Number" ) {
				const auto qualifiers = node.child ( "numberQualifiers" );
				const auto precision = trim ( qualifiers.child ( "precision" ) );
				auto scale = trim ( qualifiers.child ( "scale" ) );
				if ( !precision.empty () ) {
					if ( scale.empty () ) {
						scale = "0";
					}
					value += "(" + precision + "," + scale + ")";
				}
			} else if ( type == "String" ) {
				const auto length =
						trim ( node.child ( "stringQualifiers" ).child ( "length" ) );
				if ( !length.empty () ) {
					value += "(" + length + ")";
				}
			}
			if ( seen.insert ( value ).second ) {
				result.push_back ( value );
			}
		}
		return result;
	}

	std::string typeWithLength ( const std::string& typeName,
															 const std::string& length ) const {
		if ( typeName.empty () ) {
			return {};
		}
		if ( typeName == "String" && !length.empty () ) {
			return typeName + "(" + length + ")";
		}
		return typeName;
	}

	std::string
	standardAttributeType ( const MetadataType& type, const pugi::xml_node& root,
													const std::string& attributeName,
													const pugi::xml_node& attribute = {},
													const std::string& tableName = {} ) const {
		const auto name = attributeName.empty ()
													? trim ( attribute.child ( "name" ) )
													: attributeName;
		if ( name.empty () ) {
			return {};
		}
		if ( name == "DeletionMark" || name == "Predefined" || name == "Active" ||
				 name == "Posted" || name == "Started" || name == "Completed" ||
				 name == "Executed" || name == "OffBalance" || name == "IsFolder" ||
				 name == "ActionPeriodIsBasic" || name == "TurnoversOnly" ||
				 name == "Currency" || name == "Quantitative" ) {
			return "Boolean";
		}
		if ( name == "LineNumber" || name == "Order" || name == "ReceivedNo" ||
				 name == "SentNo" ) {
			return "Number";
		}
		if ( name == "Date" || name == "Period" || name == "ExchangeDate" ) {
			return "Date";
		}
		if ( name == "ValueType" ) {
			return "TypeDescription";
		}
		if ( name == "Ref" ) {
			return referenceType ( type );
		}
		if ( name == "ThisNode" ) {
			return referenceType ( type );
		}
		if ( name == "Description" ) {
			return typeWithLength ( "String",
															trim ( root.child ( "descriptionLength" ) ) );
		}
		if ( name == "Code" ) {
			auto codeType = trim ( root.child ( "codeType" ) );
			if ( codeType.empty () ) {
				codeType = "String";
			}
			return typeWithLength ( codeType, trim ( root.child ( "codeLength" ) ) );
		}
		if ( name == "Number" ) {
			auto numberType = trim ( root.child ( "numberType" ) );
			if ( numberType.empty () ) {
				numberType = "String";
			}
			return typeWithLength ( numberType,
															trim ( root.child ( "numberLength" ) ) );
		}
		if ( name == "Parent" ) {
			return referenceType ( type );
		}
		if ( name == "PredefinedDataName" ) {
			return "String";
		}
		if ( name == "BusinessProcess" || name == "HeadTask" ) {
			if ( const auto referenced = typeFromReferenceValue ( attribute );
					 !referenced.empty () ) {
				return referenced;
			}
			if ( name == "HeadTask" ) {
				const auto task = trim ( root.child ( "task" ) );
				if ( !task.empty () ) {
					const auto parts = strings::split ( task, "." );
					if ( parts.size () == 2 ) {
						return "TaskRef." + parts [ 1 ];
					}
				}
			}
		}
		if ( name == "Type" && type.family == MetadataFamily::ChartOfAccounts ) {
			return "ChartOfAccounts." + type.name + ".AccountType";
		}
		if ( name == "ExtDimensionType" &&
				 type.family == MetadataFamily::ChartOfAccounts &&
				 tableName == "ExtDimensionTypes" ) {
			const auto value = trim ( root.child ( "extDimensionTypes" ) );
			if ( const auto parsed = parseMetadataType ( value );
					 parsed.has_value () ) {
				return referenceType ( *parsed );
			}
		}
		if ( name == "CalculationType" &&
				 type.family == MetadataFamily::ChartOfCalculationTypes ) {
			std::vector<std::string> values;
			const auto tag = lowerCamel ( tableName );
			for ( const auto& item : root.children ( tag.c_str () ) ) {
				const auto value = trim ( item );
				if ( const auto parsed = parseMetadataType ( value );
						 parsed.has_value () ) {
					values.push_back ( referenceType ( *parsed ) );
				}
			}
			if ( values.empty () ) {
				values.push_back ( referenceType ( type ) );
			}
			return strings::concat ( values, ", " );
		}
		if ( const auto referenced = typeFromReferenceValue ( attribute );
				 !referenced.empty () ) {
			return referenced;
		}
		return {};
	}

	void addField ( std::unordered_map<std::string, MetadataField>& fields,
									const std::string& name, MetadataField field ) const {
		if ( name.empty () || field.type.empty () ) {
			return;
		}
		fields.try_emplace ( name, std::move ( field ) );
	}

	void
	addExplicitFields ( std::unordered_map<std::string, MetadataField>& fields,
											const pugi::xml_node& root, const char* tag ) {
		for ( const auto& child : root.children ( tag ) ) {
			const auto name = trim ( child.child ( "name" ) );
			const auto type = formatType ( child.child ( "type" ) );
			addField ( fields, name,
								 MetadataField { localizedValue ( child, "toolTip", language ),
															 type,
															 fillCheckingValue ( child, "fillChecking" ) } );
		}
	}

	void
	addStandardFields ( std::unordered_map<std::string, MetadataField>& fields,
											const pugi::xml_node& metadataRoot,
											const pugi::xml_node& owner, const MetadataType& type,
											const char* tag,
											const std::string& tableName = {} ) const {
		for ( const auto& child : owner.children ( tag ) ) {
			const auto name = trim ( child.child ( "name" ) );
			addField (
					fields, name,
					MetadataField { localizedValue ( child, "toolTip", language ),
													standardAttributeType ( type, metadataRoot, name,
																									child, tableName ),
													fillCheckingValue ( child, "fillChecking" ) } );
		}
	}

	void addImplicitStandardFields (
			std::unordered_map<std::string, MetadataField>& fields,
			const pugi::xml_node& root, const MetadataType& type ) const {
		const auto implicit = ImplicitStandardFields.find ( type.family );
		if ( implicit == ImplicitStandardFields.end () ) {
			return;
		}
		for ( const auto& name : implicit->second ) {
			if ( fields.contains ( name ) ) {
				continue;
			}
			addField (
					fields, name,
					MetadataField { "", standardAttributeType ( type, root, name ),
													DefaultFillChecking } );
		}
	}

	MetadataDescription buildMetadata ( const pugi::xml_document& document,
																			const MetadataType& type ) {
		MetadataDescription description;
		const auto root = document.document_element ();
		description.explanation = localizedValue ( root, "explanation", language );
		addStandardFields ( description.fields, root, root, type,
												"standardAttributes" );
		addImplicitStandardFields ( description.fields, root, type );
		addExplicitFields ( description.fields, root, "attributes" );
		if ( type.family == MetadataFamily::InformationRegister ) {
			addExplicitFields ( description.fields, root, "dimensions" );
			addExplicitFields ( description.fields, root, "resources" );
		}
		for ( const auto& table : root.children ( "tabularSections" ) ) {
			const auto tableName = trim ( table.child ( "name" ) );
			if ( tableName.empty () ) {
				continue;
			}
			auto& fields = description.tables [ tableName ];
			addStandardFields ( fields, root, table, type, "standardAttributes",
													tableName );
			addExplicitFields ( fields, table, "attributes" );
		}
		for ( const auto& table : root.children ( "standardTabularSections" ) ) {
			const auto tableName = trim ( table.child ( "name" ) );
			if ( tableName.empty () ) {
				continue;
			}
			auto& fields = description.tables [ tableName ];
			addStandardFields ( fields, root, table, type, "standardAttributes",
													tableName );
		}
		return description;
	}

	std::filesystem::path sources;
	std::string language;
	std::unordered_map<std::string, std::shared_ptr<const pugi::xml_document>>
			documents;
	std::unordered_map<std::string, std::shared_ptr<const MetadataDescription>>
			metadataCache;
};

std::optional<MetadataType> formMetadataType ( const std::string& formName ) {
	const auto parts = strings::split ( formName, "." );
	if ( parts.size () < 2 ) {
		return std::nullopt;
	}
	const auto kind = FormKinds.find ( parts [ 0 ] );
	if ( kind == FormKinds.end () ) {
		return std::nullopt;
	}
	return MetadataType { kind->second, parts [ 1 ] };
}

std::unordered_map<std::string, FormAttribute>
formAttributes ( const pugi::xml_node& root, Repository& repository,
								 const std::string& language ) {
	std::unordered_map<std::string, FormAttribute> result;
	for ( const auto& attribute : root.children ( "attributes" ) ) {
		const auto name = trim ( attribute.child ( "name" ) );
		if ( name.empty () ) {
			continue;
		}
		auto& value = result [ name ];
		value.types = typeValues ( attribute.child ( "valueType" ) );
		value.mainTable =
				trim ( attribute.child ( "extInfo" ).child ( "mainTable" ) );
		value.field = MetadataField {
				localizedFormValue ( attribute, language ),
				repository.formatType ( attribute.child ( "valueType" ) ),
				fillCheckingValue ( attribute, "fillChecking" ),
		};
	}
	return result;
}

void addFormColumn ( FormColumns& result, const std::string& tablePath,
										 const std::string& name, MetadataField field ) {
	if ( tablePath.empty () || name.empty () || field.type.empty () ) {
		return;
	}
	result [ tablePath ].try_emplace ( name, std::move ( field ) );
}

void collectFormColumns ( FormColumns& result, const std::string& tablePath,
													const pugi::xml_node& owner,
													Repository& repository,
													const std::string& language ) {
	for ( const auto& column : owner.children ( "columns" ) ) {
		const auto name = trim ( column.child ( "name" ) );
		addFormColumn (
				result, tablePath, name,
				MetadataField { localizedFormValue ( column, language ),
												repository.formatType ( column.child ( "valueType" ) ),
												fillCheckingValue ( column, "fillChecking" ) } );
	}
}

FormColumns formColumns ( const pugi::xml_node& root, Repository& repository,
													const std::string& language ) {
	FormColumns result;
	for ( const auto& attribute : root.children ( "attributes" ) ) {
		const auto name = trim ( attribute.child ( "name" ) );
		collectFormColumns ( result, name, attribute, repository, language );
		for ( const auto& additional : attribute.children ( "additionalColumns" ) ) {
			auto tablePath = trim ( additional.child ( "tablePath" ).child (
					"segments" ) );
			if ( tablePath.empty () ) {
				tablePath = trim ( additional.child ( "tablePath" ) );
			}
			collectFormColumns ( result, tablePath, additional, repository,
													 language );
		}
	}
	return result;
}

std::optional<ParsedPath> parsePath ( const std::string& path ) {
	const auto parts = strings::split ( path, "." );
	if ( parts.size () == 1 ) {
		return ParsedPath { parts [ 0 ], {}, std::nullopt };
	}
	if ( parts.size () == 2 ) {
		return ParsedPath { parts [ 0 ], parts [ 1 ], std::nullopt };
	}
	if ( parts.size () == 3 ) {
		return ParsedPath { parts [ 0 ], parts [ 1 ], parts [ 2 ] };
	}
	if ( parts.size () == 4 && parts [ 0 ] == "Items" &&
			 parts [ 2 ] == "CurrentData" ) {
		return ParsedPath { parts [ 1 ], parts [ 3 ], std::nullopt };
	}
	return std::nullopt;
}

std::optional<MetadataType> resolveSource (
		const ParsedPath& path,
		const std::unordered_map<std::string, FormAttribute>& attributes ) {
	const auto found = attributes.find ( path.source );
	if ( found == attributes.end () ) {
		return std::nullopt;
	}
	if ( !found->second.mainTable.empty () ) {
		return formMetadataType ( found->second.mainTable );
	}
	for ( const auto& type : found->second.types ) {
		for ( const auto& [ prefix, family ] : TypePrefixes ) {
			if ( !type.starts_with ( prefix ) ) {
				continue;
			}
			const auto rest = type.substr ( prefix.size () );
			const auto parts = strings::split ( rest, "." );
			if ( !parts.empty () ) {
				return MetadataType { family, parts [ 0 ] };
			}
		}
	}
	return std::nullopt;
}

bool hasType ( const pugi::xml_node& node, std::string_view type ) {
	return std::string_view ( node.attribute ( "xsi:type" ).as_string () ) ==
				 type;
}

const MetadataField*
resolveFormColumn ( const ParsedPath& path, const FormColumns& formColumns ) {
	auto tablePath = path.source;
	auto fieldName = path.member;
	if ( path.field.has_value () ) {
		tablePath += "." + path.member;
		fieldName = *path.field;
	}
	const auto table = formColumns.find ( tablePath );
	if ( table == formColumns.end () ) {
		return nullptr;
	}
	const auto field = table->second.find ( fieldName );
	if ( field == table->second.end () ) {
		return nullptr;
	}
	return &field->second;
}

const MetadataField* resolveFormAttribute (
		const ParsedPath& path,
		const std::unordered_map<std::string, FormAttribute>& attributes ) {
	if ( !path.member.empty () || path.field.has_value () ) {
		return nullptr;
	}
	const auto attribute = attributes.find ( path.source );
	if ( attribute == attributes.end () || attribute->second.field.type.empty () ) {
		return nullptr;
	}
	return &attribute->second.field;
}

const MetadataField*
resolveField ( const ParsedPath& path,
							 const std::unordered_map<std::string, FormAttribute>& attributes,
							 const FormColumns& formColumns, Repository& repository ) {
	if ( const auto field = resolveFormAttribute ( path, attributes ) ) {
		return field;
	}
	if ( const auto field = resolveFormColumn ( path, formColumns ) ) {
		return field;
	}
	const auto source = resolveSource ( path, attributes );
	if ( !source.has_value () ) {
		return nullptr;
	}
	const auto metadata = repository.metadata ( *source );
	if ( !metadata ) {
		return nullptr;
	}
	if ( path.field.has_value () ) {
		const auto table = metadata->tables.find ( path.member );
		if ( table == metadata->tables.end () ) {
			return nullptr;
		}
		const auto field = table->second.find ( *path.field );
		if ( field == table->second.end () ) {
			return nullptr;
		}
		return &field->second;
	}
	const auto field = metadata->fields.find ( path.member );
	if ( field == metadata->fields.end () ) {
		return nullptr;
	}
	return &field->second;
}

void addResultField ( Json& target, const std::string& name,
											const MetadataField& field ) {
	if ( name.empty () || target.contains ( name ) ) {
		return;
	}
	target [ name ] = Json { { "tooltip", field.tooltip },
													 { "type", field.type },
													 { "fillChecking",
														 field.fillChecking.empty () ? DefaultFillChecking
																												: field.fillChecking } };
}

void addInvisibleItem ( Json& result, const std::string& name ) {
	if ( name.empty () ) {
		return;
	}
	auto& items = result [ "invisibleFields" ];
	const auto found = std::any_of (
			items.begin (), items.end (), [ &name ] ( const Json& item ) {
				return item.is_string () && item.get<std::string> () == name;
			} );
	if ( !found ) {
		items.push_back ( name );
	}
}

void addDataPath ( Json& result, const std::string& name,
									 const std::string& dataPath ) {
	if ( name.empty () || dataPath.empty () ) {
		return;
	}
	result [ "dataPaths" ].push_back (
			Json { { "name", name }, { "dataPath", dataPath } } );
}

bool userVisible ( const pugi::xml_node& node ) {
	return trim ( node.child ( "userVisible" ).child ( "common" ) ) == "true";
}

void collectFormItems (
		const pugi::xml_node& node, const std::string& currentTable,
		const std::unordered_map<std::string, FormAttribute>& attributes,
		const FormColumns& formColumns, Repository& repository, Json& result ) {
	const auto itemName = trim ( node.child ( "name" ) );
	auto tableName = currentTable;
	if ( hasType ( node, "form:Table" ) && !itemName.empty () ) {
		tableName = itemName;
	}
	if ( hasType ( node, "form:FormField" ) ) {
		const auto segments =
				trim ( node.child ( "dataPath" ).child ( "segments" ) );
		if ( const auto path = parsePath ( segments ); path.has_value () ) {
			if ( const auto field =
							 resolveField ( *path, attributes, formColumns, repository ) ) {
				if ( tableName.empty () ) {
					addResultField ( result [ "fields" ], itemName, *field );
				} else {
					auto& target = result [ "tables" ][ tableName ];
					if ( target.is_null () ) {
						target = Json::object ();
					}
					addResultField ( target, itemName, *field );
				}
			}
		}
	}
	for ( const auto& child : node.children ( "items" ) ) {
		collectFormItems ( child, tableName, attributes, formColumns, repository,
											 result );
	}
}

void collectInvisibleItems ( const pugi::xml_node& node, Repository& repository,
														 Json& result ) {
	if ( std::string_view ( node.name () ) == "items" && !userVisible ( node ) ) {
		addInvisibleItem ( result, trim ( node.child ( "name" ) ) );
	}
	for ( const auto& child : node.children () ) {
		collectInvisibleItems ( child, repository, result );
	}
}

void collectDataPaths ( const pugi::xml_node& node, Json& result ) {
	if ( std::string_view ( node.name () ) == "items" ) {
		auto dataPath = trim ( node.child ( "dataPath" ).child ( "segments" ) );
		if ( dataPath.empty () ) {
			dataPath = trim ( node.child ( "dataPath" ) );
		}
		addDataPath ( result, trim ( node.child ( "name" ) ), dataPath );
	}
	for ( const auto& child : node.children () ) {
		collectDataPaths ( child, result );
	}
}

std::filesystem::path formPath ( const std::filesystem::path& sources,
																 const std::string& formName ) {
	auto parts = strings::split ( formName, "." );
	if ( parts.empty () ) {
		return {};
	}
	const auto kind = FormKinds.find ( parts [ 0 ] );
	if ( kind == FormKinds.end () ) {
		return {};
	}
	const auto folder = SourceFolders.find ( kind->second );
	if ( folder == SourceFolders.end () ) {
		return {};
	}
	if ( kind->second == MetadataFamily::CommonForm ) {
		if ( parts.size () != 2 ) {
			return {};
		}
		return sources / folder->second / utf8PathSegment ( parts [ 1 ] ) /
					 "Form.form";
	}
	if ( parts.size () < 4 ) {
		return {};
	}
	return sources / folder->second / utf8PathSegment ( parts [ 1 ] ) /
				 "Forms" / utf8PathSegment ( parts [ 3 ] ) / "Form.form";
}
}

std::string metadata::edt::getFormInfo ( const std::filesystem::path& sources,
																				 const std::string& formName,
																				 const std::string& language ) {
	const auto path = formPath ( sources, formName );
	Repository repository { sources, language };
	const auto form = repository.document ( path );
	if ( !form ) {
		return {};
	}
	const auto root = form->document_element ();
	const auto attributes = formAttributes ( root, repository, language );
	const auto formDefinedColumns = formColumns ( root, repository, language );
	Json result {
			{ "explanation", "" },
			{ "fields", Json::object () },
			{ "tables", Json::object () },
			{ "invisibleFields", Json::array () },
	};
	if ( const auto mainType = formMetadataType ( formName );
			 mainType.has_value () ) {
		if ( const auto metadata = repository.metadata ( *mainType ) ) {
			result [ "explanation" ] = metadata->explanation;
		}
	}
	for ( const auto& item : root.children ( "items" ) ) {
		collectFormItems ( item, {}, attributes, formDefinedColumns, repository,
											 result );
	}
	collectInvisibleItems ( root, repository, result );
	return result.dump ();
}

std::string metadata::edt::getFormDataPaths (
		const std::filesystem::path& sources, const std::string& formName ) {
	const auto path = formPath ( sources, formName );
	Repository repository { sources, {} };
	const auto form = repository.document ( path );
	if ( !form ) {
		return {};
	}
	Json result {
			{ "dataPaths", Json::array () },
	};
	collectDataPaths ( form->document_element (), result );
	return result [ "dataPaths" ].dump ();
}
