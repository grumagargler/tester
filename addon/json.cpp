#include "json.h"
#include <algorithm>
#include <map>
#include <memory>
#include <nlohmann/json.hpp>
#include <set>
#include <sstream>
#include <utility>

namespace JSON {
namespace {
using Json = nlohmann::json;

const std::set<std::string> NamedCollections { "ChildObjects", "Items", "Columns" };
const std::set<std::string> SummaryKeys { "ID", "TitleText", "Type" };

std::string normalizePath ( const std::string& path ) {
	if ( path.empty () ) {
		return "Root";
	}
	return path;
}

std::string joinPath ( const std::string& path, const std::string& segment ) {
	if ( path.empty () ) {
		return segment;
	}
	if ( segment.empty () ) {
		return path;
	}
	return path + "/" + segment;
}

std::string indexPath ( const std::string& path, size_t index ) {
	std::ostringstream result;
	result << normalizePath ( path ) << "[" << index << "]";
	return result.str ();
}

bool isNamedNode ( const Json& value ) {
	return value.is_object () && value.contains ( "ID" ) &&
				 value.at ( "ID" ).is_string ();
}

std::string nodeName ( const Json& value ) {
	if ( isNamedNode ( value ) ) {
		return value.at ( "ID" ).get<std::string> ();
	}
	return {};
}

bool hasUniqueNames ( const Json& value ) {
	if ( !value.is_array () ) {
		return false;
	}
	std::set<std::string> names;
	for ( const auto& item : value ) {
		if ( !isNamedNode ( item ) ) {
			return false;
		}
		if ( !names.insert ( nodeName ( item ) ).second ) {
			return false;
		}
	}
	return true;
}

Json nodeSummary ( const Json& node ) {
	auto result = Json::object ();
	if ( !node.is_object () ) {
		return result;
	}
	for ( const auto& key : SummaryKeys ) {
		if ( node.contains ( key ) ) {
			result [ key ] = node.at ( key );
		}
	}
	return result;
}

Json windowSummary ( const Json& root ) {
	if ( root.is_array () && !root.empty () && root.at ( 0 ).is_object () ) {
		return nodeSummary ( root.at ( 0 ) );
	}
	if ( root.is_object () ) {
		return nodeSummary ( root );
	}
	return nullptr;
}

void appendNodeMetadata ( Json* change, const Json& node ) {
	if ( !node.is_object () ) {
		return;
	}
	for ( const auto& key : SummaryKeys ) {
		if ( node.contains ( key ) ) {
			( *change ) [ key ] = node.at ( key );
		}
	}
}

void addPropertyChange ( Json* changes, const std::string& path,
												 const Json& node, const std::string& kind,
												 const std::string& property, const Json* oldValue,
												 const Json* newValue ) {
	auto change = Json::object ();
	change [ "Path" ] = normalizePath ( path );
	change [ "ChangeKind" ] = kind;
	change [ "Property" ] = property;
	appendNodeMetadata ( &change, node );
	change [ "OldValue" ] = oldValue ? *oldValue : Json ( nullptr );
	change [ "NewValue" ] = newValue ? *newValue : Json ( nullptr );
	changes->push_back ( std::move ( change ) );
}

void addNodeChange ( Json* changes, const std::string& path,
										 const std::string& kind, const Json& node ) {
	auto change = Json::object ();
	change [ "Path" ] = normalizePath ( path );
	change [ "ChangeKind" ] = kind;
	appendNodeMetadata ( &change, node );
	change [ "Node" ] = node;
	changes->push_back ( std::move ( change ) );
}

void addNodeReplace ( Json* changes, const std::string& path,
											const Json& before, const Json& after ) {
	auto change = Json::object ();
	change [ "Path" ] = normalizePath ( path );
	change [ "ChangeKind" ] = "NodeReplaced";
	appendNodeMetadata ( &change, after.is_object () ? after : before );
	change [ "OldNode" ] = before;
	change [ "NewNode" ] = after;
	changes->push_back ( std::move ( change ) );
}

void compareNodes ( const std::string& path, const Json& before,
										const Json& after, Json* changes );

void compareArrays ( const std::string& path, const Json& before,
										 const Json& after, Json* changes ) {
	if ( hasUniqueNames ( before ) && hasUniqueNames ( after ) ) {
		std::map<std::string, const Json*> beforeItems;
		std::map<std::string, const Json*> afterItems;
		for ( const auto& item : before ) {
			beforeItems.emplace ( nodeName ( item ), &item );
		}
		for ( const auto& item : after ) {
			afterItems.emplace ( nodeName ( item ), &item );
		}
		std::set<std::string> names;
		for ( const auto& [ name, _ ] : beforeItems ) {
			names.insert ( name );
		}
		for ( const auto& [ name, _ ] : afterItems ) {
			names.insert ( name );
		}
		for ( const auto& name : names ) {
			const auto currentPath = joinPath ( path, name );
			const auto beforeIt = beforeItems.find ( name );
			const auto afterIt = afterItems.find ( name );
			if ( beforeIt == beforeItems.end () ) {
				addNodeChange ( changes, currentPath, "ControlAdded",
												*afterIt->second );
				continue;
			}
			if ( afterIt == afterItems.end () ) {
				addNodeChange ( changes, currentPath, "ControlRemoved",
												*beforeIt->second );
				continue;
			}
			compareNodes ( currentPath, *beforeIt->second, *afterIt->second,
										 changes );
		}
		return;
	}

	const auto common = std::min ( before.size (), after.size () );
	for ( size_t index = 0; index < common; ++index ) {
		compareNodes ( indexPath ( path, index ), before.at ( index ),
									 after.at ( index ), changes );
	}
	for ( size_t index = common; index < before.size (); ++index ) {
		addNodeChange ( changes, indexPath ( path, index ), "ItemRemoved",
										before.at ( index ) );
	}
	for ( size_t index = common; index < after.size (); ++index ) {
		addNodeChange ( changes, indexPath ( path, index ), "ItemAdded",
										after.at ( index ) );
	}
}

void compareObjects ( const std::string& path, const Json& before,
											const Json& after, Json* changes ) {
	std::set<std::string> keys;
	for ( auto it = before.begin (); it != before.end (); ++it ) {
		keys.insert ( it.key () );
	}
	for ( auto it = after.begin (); it != after.end (); ++it ) {
		keys.insert ( it.key () );
	}

	for ( const auto& key : keys ) {
		const auto beforeHas = before.contains ( key );
		const auto afterHas = after.contains ( key );
		if ( !beforeHas ) {
			if ( after.at ( key ).is_primitive () || after.at ( key ).is_null () ) {
				addPropertyChange ( changes, path, after, "PropertyAdded", key, nullptr,
														&after.at ( key ) );
			} else {
				addNodeChange ( changes, joinPath ( path, key ), "NodeAdded",
												after.at ( key ) );
			}
			continue;
		}
		if ( !afterHas ) {
			if ( before.at ( key ).is_primitive () || before.at ( key ).is_null () ) {
				addPropertyChange ( changes, path, before, "PropertyRemoved", key,
														&before.at ( key ), nullptr );
			} else {
				addNodeChange ( changes, joinPath ( path, key ), "NodeRemoved",
												before.at ( key ) );
			}
			continue;
		}

		if ( NamedCollections.contains ( key ) ) {
			compareArrays ( path, before.at ( key ), after.at ( key ), changes );
			continue;
		}

		const auto& beforeValue = before.at ( key );
		const auto& afterValue = after.at ( key );
		if ( beforeValue.type () != afterValue.type () ) {
			if ( beforeValue.is_primitive () || beforeValue.is_null () ||
					 afterValue.is_primitive () || afterValue.is_null () ) {
				addPropertyChange ( changes, path, after, "PropertyChanged", key,
														&beforeValue, &afterValue );
			} else {
				addNodeReplace ( changes, joinPath ( path, key ), beforeValue,
												 afterValue );
			}
			continue;
		}
		if ( beforeValue.is_object () ) {
			compareObjects ( joinPath ( path, key ), beforeValue, afterValue,
											 changes );
			continue;
		}
		if ( beforeValue.is_array () ) {
			compareArrays ( joinPath ( path, key ), beforeValue, afterValue,
											changes );
			continue;
		}
		if ( beforeValue != afterValue ) {
			addPropertyChange ( changes, path, after, "PropertyChanged", key,
													&beforeValue, &afterValue );
		}
	}
}

void compareNodes ( const std::string& path, const Json& before,
										const Json& after, Json* changes ) {
	if ( before.type () != after.type () ) {
		addNodeReplace ( changes, path, before, after );
		return;
	}
	if ( before.is_object () ) {
		compareObjects ( path, before, after, changes );
		return;
	}
	if ( before.is_array () ) {
		compareArrays ( path, before, after, changes );
		return;
	}
	if ( before != after ) {
		auto change = Json::object ();
		change [ "Path" ] = normalizePath ( path );
		change [ "ChangeKind" ] = "ValueChanged";
		change [ "OldValue" ] = before;
		change [ "NewValue" ] = after;
		changes->push_back ( std::move ( change ) );
	}
}
}

std::wstring toHex ( wchar_t Value ) {
	std::wstring result;
	result += Hex [ ( Value & 0xF000 ) >> 12 ];
	result += Hex [ ( Value & 0xF00 ) >> 8 ];
	result += Hex [ ( Value & 0xF0 ) >> 4 ];
	result += Hex [ ( Value & 0x0F ) >> 0 ];
	return result;
}

void escape ( std::wstring* Result, const std::wstring& s ) {
	for ( wchar_t c : s ) {
		switch ( c ) {
		case '"':
			Result->append ( L"\\\"" );
			break;
		case '\\':
			Result->append ( L"\\\\" );
			break;
		case '\b':
			Result->append ( L"\\b" );
			break;
		case '\f':
			Result->append ( L"\\f" );
			break;
		case '\n':
			Result->append ( L"\\n" );
			break;
		case '\r':
			Result->append ( L"\\r" );
			break;
		case '\t':
			Result->append ( L"\\t" );
			break;
		default:
			if ( '\x00' <= c && c <= '\x1f' ) {
				Result->append ( L"\\u" + toHex ( c ) );
			} else {
				Result->push_back ( c );
			}
		}
	}
}

Value::Value ( std::wstring Name ) : Name ( std::move ( Name ) ) {
}

void Value::Presentation ( std::wstring* Result ) {
	if ( !Name.empty () ) {
		Result->push_back ( L'\"' );
		escape ( Result, Name );
		Result->append ( L"\":" );
	}
}

void String::Set ( const std::wstring& Value ) {
	Storage = Value;
}

void String::Presentation ( std::wstring* Result ) {
	Value::Presentation ( Result );
	Result->push_back ( L'\"' );
	escape ( Result, Storage );
	Result->push_back ( L'\"' );
}

[[maybe_unused]] void Number::Set ( int Value ) {
	Storage = std::to_wstring ( Value );
}

void Number::Presentation ( std::wstring* Result ) {
	Value::Presentation ( Result );
	escape ( Result, Storage );
}

void Null::Presentation ( std::wstring* Result ) {
	Value::Presentation ( Result );
	Result->append ( L"null" );
}

void Container::ItemsPresentation ( std::wstring* Result ) {
	bool next { false };
	for ( const auto& item : Items ) {
		if ( next ) {
			Result->push_back ( L',' );
		}
		item->Presentation ( Result );
		next = true;
	}
}

void Object::Presentation ( std::wstring* Result ) {
	Value::Presentation ( Result );
	Result->push_back ( L'{' );
	ItemsPresentation ( Result );
	Result->push_back ( L'}' );
}

void Array::Presentation ( std::wstring* Result ) {
	Value::Presentation ( Result );
	Result->push_back ( L'[' );
	ItemsPresentation ( Result );
	Result->push_back ( L']' );
}

std::string compare ( const std::string& first, const std::string& second ) {
	const auto before = Json::parse ( first );
	const auto after = Json::parse ( second );
	auto result = Json::object ();
	result [ "Mode" ] = "Delta";
	result [ "PreviousWindow" ] = windowSummary ( before );
	result [ "CurrentWindow" ] = windowSummary ( after );
	result [ "WindowChanged" ] =
			result.at ( "PreviousWindow" ) != result.at ( "CurrentWindow" );
	result [ "Changes" ] = Json::array ();

	compareNodes ( "", before, after, &result [ "Changes" ] );
	result [ "ChangeCount" ] = result.at ( "Changes" ).size ();
	if ( result.at ( "ChangeCount" ) == 0 && !result.at ( "WindowChanged" ) ) {
		result [ "Mode" ] = "Equal";
	}
	return result.dump ();
}
}
