#include "designer.h"
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

std::string normalizeTypeName ( const std::string& typeName ) {
	auto value = typeName;
	if ( value.starts_with ( "cfg:" ) ) {
		value = value.substr ( 4 );
	}
	if ( value.starts_with ( "v8:" ) ) {
		value = value.substr ( 3 );
	}
	if ( value.starts_with ( "mxl:" ) ) {
		value = value.substr ( 4 );
	}
	if ( value == "xs:boolean" ) {
		return "Boolean";
	}
	if ( value == "xs:string" ) {
		return "String";
	}
	if ( value == "xs:decimal" ) {
		return "Number";
	}
	if ( value == "xs:dateTime" ) {
		return "Date";
	}
	if ( value == "ValueListType" ) {
		return "ValueList";
	}
	if ( value == "ValueTreeType" ) {
		return "ValueTree";
	}
	return value;
}

std::string lowerCamel ( const std::string& value ) {
	if ( value.empty () ) {
		return {};
	}
	auto result = value;
	result [ 0 ] = std::tolower ( result [ 0 ] );
	return result;
}

bool fieldNode ( std::string_view name ) {
	return name.ends_with ( "Field" );
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

pugi::xml_node firstElementChild ( const pugi::xml_node& node ) {
	for ( const auto& child : node.children () ) {
		if ( child.type () == pugi::node_element ) {
			return child;
		}
	}
	return {};
}

std::string localizedValue ( const pugi::xml_node& node,
														 const std::string& language ) {
	for ( const auto& item : node.children ( "v8:item" ) ) {
		if ( trim ( item.child ( "v8:lang" ) ) == language ) {
			return trim ( item.child ( "v8:content" ) );
		}
	}
	return {};
}

std::string localizedFormValue ( const pugi::xml_node& node,
																 const std::string& language ) {
	auto value = localizedValue ( node.child ( "ToolTip" ), language );
	if ( value.empty () ) {
		value = localizedValue ( node.child ( "Title" ), language );
	}
	return value;
}

std::vector<std::string> typeValues ( const pugi::xml_node& node ) {
	std::vector<std::string> values;
	for ( const auto& child : node.children () ) {
		const auto name = std::string_view ( child.name () );
		if ( name != "v8:Type" && name != "v8:TypeSet" ) {
			continue;
		}
		auto value = trim ( child );
		if ( !value.empty () ) {
			values.push_back ( value );
		}
	}
	return values;
}

std::filesystem::path formPath ( const std::filesystem::path& sources,
																 const std::string& formName ) {
	const auto parts = strings::split ( formName, "." );
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
					 "Ext" / "Form.xml";
	}
	if ( parts.size () < 4 ) {
		return {};
	}
	return sources / folder->second / utf8PathSegment ( parts [ 1 ] ) /
				 "Forms" / utf8PathSegment ( parts [ 3 ] ) / "Ext" / "Form.xml";
}

class Repository {
public:
	Repository ( std::filesystem::path sources, std::string language )
			: sources ( std::move ( sources ) ), language ( std::move ( language ) ) {
	}

	std::shared_ptr<const pugi::xml_document>
	document ( const std::filesystem::path& path ) {
		return loadDocument ( path );
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
		const auto document = loadDocument ( metadataPath ( type ) );
		if ( !document ) {
			metadataCache [ key ] = nullptr;
			return nullptr;
		}
		auto description = std::make_shared<MetadataDescription> (
				buildMetadata ( *document, type ) );
		metadataCache [ key ] = description;
		return description;
	}

	std::string formatType ( const pugi::xml_node& node ) {
		return strings::concat ( formatTypes ( node ), ", " );
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
		if ( !document->load_file ( path.c_str () ) ) {
			documents [ key ] = nullptr;
			return nullptr;
		}
		documents [ key ] = document;
		return document;
	}

	std::filesystem::path metadataPath ( const MetadataType& type ) const {
		const auto folder = SourceFolders.find ( type.family );
		if ( folder == SourceFolders.end () ) {
			return {};
		}
		return sources / folder->second /
					 utf8PathSegment ( type.name + ".xml" );
	}

	std::optional<MetadataType>
	parseMetadataType ( const std::string& typeName ) const {
		const auto value = normalizeTypeName ( typeName );
		for ( const auto& [ prefix, family ] : TypePrefixes ) {
			if ( !value.starts_with ( prefix ) ) {
				continue;
			}
			const auto rest = value.substr ( prefix.size () );
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
		for ( const auto& item : typeValues ( node ) ) {
			const auto type = normalizeTypeName ( item );
			if ( type.starts_with ( "DefinedType." ) ) {
				const auto definedName =
						type.substr ( std::string { "DefinedType." }.size () );
				const auto defined = loadDocument (
						sources / "DefinedTypes" /
						utf8PathSegment ( definedName + ".xml" ) );
				if ( defined ) {
					const auto object =
							firstElementChild ( defined->document_element () );
					for ( const auto& resolved : formatTypes (
										object.child ( "Properties" ).child ( "Type" ) ) ) {
						if ( seen.insert ( resolved ).second ) {
							result.push_back ( resolved );
						}
					}
				}
				continue;
			}
			auto value = type;
			if ( type == "Number" ) {
				const auto qualifiers = node.child ( "v8:NumberQualifiers" );
				const auto precision = trim ( qualifiers.child ( "v8:Digits" ) );
				auto scale = trim ( qualifiers.child ( "v8:FractionDigits" ) );
				if ( !precision.empty () ) {
					if ( scale.empty () ) {
						scale = "0";
					}
					value += "(" + precision + "," + scale + ")";
				}
			} else if ( type == "String" ) {
				const auto length =
						trim ( node.child ( "v8:StringQualifiers" ).child ( "v8:Length" ) );
				if ( !length.empty () && length != "0" ) {
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
		if ( typeName == "String" && !length.empty () && length != "0" ) {
			return typeName + "(" + length + ")";
		}
		return typeName;
	}

	std::string typeFromReferenceValue ( const pugi::xml_node& node ) const {
		auto value = trim ( node.child ( "xr:FillValue" ) );
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

	std::string standardAttributeType (
			const MetadataType& type, const pugi::xml_node& properties,
			const std::string& attributeName, const pugi::xml_node& attribute = {},
			const std::string& tableName = {} ) const {
		const auto name =
				attributeName.empty ()
						? std::string ( attribute.attribute ( "name" ).as_string () )
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
		if ( name == "Ref" || name == "ThisNode" || name == "Parent" ) {
			return referenceType ( type );
		}
		if ( name == "Description" ) {
			return typeWithLength (
					"String", trim ( properties.child ( "DescriptionLength" ) ) );
		}
		if ( name == "Code" ) {
			auto codeType =
					normalizeTypeName ( trim ( properties.child ( "CodeType" ) ) );
			if ( codeType.empty () ) {
				codeType = "String";
			}
			return typeWithLength ( codeType,
															trim ( properties.child ( "CodeLength" ) ) );
		}
		if ( name == "Number" ) {
			auto numberType =
					normalizeTypeName ( trim ( properties.child ( "NumberType" ) ) );
			if ( numberType.empty () ) {
				numberType = "String";
			}
			return typeWithLength ( numberType,
															trim ( properties.child ( "NumberLength" ) ) );
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
				const auto task = trim ( properties.child ( "Task" ) );
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
			if ( const auto parsed = parseMetadataType (
							 trim ( properties.child ( "ExtDimensionTypes" ) ) );
					 parsed.has_value () ) {
				return referenceType ( *parsed );
			}
		}
		if ( name == "CalculationType" &&
				 type.family == MetadataFamily::ChartOfCalculationTypes ) {
			std::vector<std::string> values;
			auto group = properties.child ( tableName.c_str () );
			if ( !group ) {
				const auto fallback = lowerCamel ( tableName );
				group = properties.child ( fallback.c_str () );
			}
			for ( const auto& item : group.children () ) {
				if ( const auto parsed = parseMetadataType ( trim ( item ) );
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
											const pugi::xml_node& childObjects, const char* tag ) {
		for ( const auto& child : childObjects.children ( tag ) ) {
			const auto properties = child.child ( "Properties" );
			const auto name = trim ( properties.child ( "Name" ) );
			addField ( fields, name,
								 MetadataField { localizedValue (
																		 properties.child ( "ToolTip" ), language ),
															 formatType ( properties.child ( "Type" ) ),
															 fillCheckingValue ( properties,
																									 "FillChecking" ) } );
		}
	}

	void
	addStandardFields ( std::unordered_map<std::string, MetadataField>& fields,
											const pugi::xml_node& properties,
											const pugi::xml_node& owner, const MetadataType& type,
											const char* tag,
											const std::string& tableName = {} ) const {
		for ( const auto& child : owner.children ( tag ) ) {
			const auto name = std::string ( child.attribute ( "name" ).as_string () );
			addField ( fields, name,
								 MetadataField {
										 localizedValue ( child.child ( "xr:ToolTip" ), language ),
										 standardAttributeType ( type, properties, name, child,
																						 tableName ),
										 fillCheckingValue ( child, "xr:FillChecking" ),
								 } );
		}
	}

	void addImplicitStandardFields (
			std::unordered_map<std::string, MetadataField>& fields,
			const pugi::xml_node& properties, const MetadataType& type ) const {
		const auto implicit = ImplicitStandardFields.find ( type.family );
		if ( implicit == ImplicitStandardFields.end () ) {
			return;
		}
		for ( const auto& name : implicit->second ) {
			if ( fields.contains ( name ) ) {
				continue;
			}
			addField ( fields, name,
								 MetadataField {
										 "",
										 standardAttributeType ( type, properties, name ),
										 DefaultFillChecking,
								 } );
		}
	}

	MetadataDescription buildMetadata ( const pugi::xml_document& document,
																			const MetadataType& type ) {
		MetadataDescription description;
		const auto object = firstElementChild ( document.document_element () );
		const auto properties = object.child ( "Properties" );
		const auto childObjects = object.child ( "ChildObjects" );
		description.explanation =
				localizedValue ( properties.child ( "Explanation" ), language );
		addStandardFields ( description.fields, properties,
												properties.child ( "StandardAttributes" ), type,
												"xr:StandardAttribute" );
		addImplicitStandardFields ( description.fields, properties, type );
		addExplicitFields ( description.fields, childObjects, "Attribute" );
		if ( type.family == MetadataFamily::InformationRegister ) {
			addExplicitFields ( description.fields, childObjects, "Dimension" );
			addExplicitFields ( description.fields, childObjects, "Resource" );
		}
		for ( const auto& table : childObjects.children ( "TabularSection" ) ) {
			const auto tableProperties = table.child ( "Properties" );
			const auto tableName = trim ( tableProperties.child ( "Name" ) );
			if ( tableName.empty () ) {
				continue;
			}
			auto& fields = description.tables [ tableName ];
			addStandardFields ( fields, properties,
													tableProperties.child ( "StandardAttributes" ), type,
													"xr:StandardAttribute", tableName );
			addExplicitFields ( fields, table.child ( "ChildObjects" ), "Attribute" );
		}
		for ( const auto& table : properties.child ( "StandardTabularSections" )
																	.children ( "xr:StandardTabularSection" ) ) {
			const auto tableName =
					std::string ( table.attribute ( "name" ).as_string () );
			if ( tableName.empty () ) {
				continue;
			}
			auto& fields = description.tables [ tableName ];
			addStandardFields ( fields, properties,
													table.child ( "xr:StandardAttributes" ), type,
													"xr:StandardAttribute", tableName );
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

std::unordered_map<std::string, FormAttribute>
formAttributes ( const pugi::xml_node& root, Repository& repository,
								 const std::string& language ) {
	std::unordered_map<std::string, FormAttribute> result;
	for ( const auto& attribute :
				root.child ( "Attributes" ).children ( "Attribute" ) ) {
		const auto name =
				std::string ( attribute.attribute ( "name" ).as_string () );
		if ( name.empty () ) {
			continue;
		}
		auto& value = result [ name ];
		value.types = typeValues ( attribute.child ( "Type" ) );
		value.mainTable =
				trim ( attribute.child ( "Settings" ).child ( "MainTable" ) );
		value.field = MetadataField {
				localizedFormValue ( attribute, language ),
				repository.formatType ( attribute.child ( "Type" ) ),
				fillCheckingValue ( attribute, "FillCheck" ),
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
	for ( const auto& column : owner.children ( "Column" ) ) {
		const auto name = std::string ( column.attribute ( "name" ).as_string () );
		addFormColumn (
				result, tablePath, name,
				MetadataField {
						localizedFormValue ( column, language ),
						repository.formatType ( column.child ( "Type" ) ),
						fillCheckingValue ( column, "FillCheck" ),
				} );
	}
}

FormColumns formColumns ( const pugi::xml_node& root, Repository& repository,
													const std::string& language ) {
	FormColumns result;
	for ( const auto& attribute :
				root.child ( "Attributes" ).children ( "Attribute" ) ) {
		const auto name =
				std::string ( attribute.attribute ( "name" ).as_string () );
		const auto columns = attribute.child ( "Columns" );
		collectFormColumns ( result, name, columns, repository, language );
		for ( const auto& additional : columns.children ( "AdditionalColumns" ) ) {
			collectFormColumns (
					result, std::string ( additional.attribute ( "table" ).as_string () ),
					additional, repository, language );
		}
	}
	return result;
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
	for ( const auto& rawType : found->second.types ) {
		const auto type = normalizeTypeName ( rawType );
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
	const auto value = node.child ( "UserVisible" );
	return !value || trim ( value.child ( "xr:Common" ) ) == "true";
}

bool commandInterfaceVisible ( const pugi::xml_node& node ) {
	const auto value = node.child ( "Visible" );
	const auto common = value.child ( "xr:Common" );
	return !common || trim ( common ) == "true";
}

void collectFormItems (
		const pugi::xml_node& node, const std::string& currentTable,
		const std::unordered_map<std::string, FormAttribute>& attributes,
		const FormColumns& formColumns, Repository& repository, Json& result ) {
	const auto nodeName = std::string_view ( node.name () );
	const auto itemName = std::string ( node.attribute ( "name" ).as_string () );
	auto tableName = currentTable;
	if ( nodeName == "Table" && !itemName.empty () ) {
		tableName = itemName;
	}
	if ( fieldNode ( nodeName ) ) {
		const auto pathText = trim ( node.child ( "DataPath" ) );
		if ( const auto path = parsePath ( pathText ); path.has_value () ) {
			if ( const auto field =
							 resolveField ( *path, attributes, formColumns, repository ) ) {
				if ( tableName.empty () ) {
					addResultField ( result [ "fields" ], itemName, *field );
				} else {
					auto& table = result [ "tables" ][ tableName ];
					if ( table.is_null () ) {
						table = Json::object ();
					}
					addResultField ( table, itemName, *field );
				}
			}
		}
	}
	for ( const auto& child : node.child ( "ChildItems" ).children () ) {
		collectFormItems ( child, tableName, attributes, formColumns, repository,
											 result );
	}
}

void collectInvisibleItems ( const pugi::xml_node& node, Json& result ) {
	if ( !userVisible ( node ) || !commandInterfaceVisible ( node ) ) {
		addInvisibleItem ( result,
											 std::string ( node.attribute ( "name" ).as_string () ) );
	}
	for ( const auto& child : node.children () ) {
		collectInvisibleItems ( child, result );
	}
}

void collectDataPaths ( const pugi::xml_node& node, Json& result ) {
	addDataPath ( result,
								std::string ( node.attribute ( "name" ).as_string () ),
								trim ( node.child ( "DataPath" ) ) );
	for ( const auto& child : node.children () ) {
		collectDataPaths ( child, result );
	}
}
}

std::string
metadata::designer::getFormInfo ( const std::filesystem::path& sources,
																	const std::string& formName,
																	const std::string& language ) {
	Repository repository { sources, language };
	const auto form = repository.document ( formPath ( sources, formName ) );
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
	for ( const auto& item : root.child ( "ChildItems" ).children () ) {
		collectFormItems ( item, {}, attributes, formDefinedColumns, repository,
											 result );
	}
	collectInvisibleItems ( root, result );
	return result.dump ();
}

std::string metadata::designer::getFormDataPaths (
		const std::filesystem::path& sources, const std::string& formName ) {
	Repository repository { sources, {} };
	const auto form = repository.document ( formPath ( sources, formName ) );
	if ( !form ) {
		return {};
	}
	Json result {
			{ "dataPaths", Json::array () },
	};
	collectDataPaths ( form->document_element (), result );
	return result [ "dataPaths" ].dump ();
}
