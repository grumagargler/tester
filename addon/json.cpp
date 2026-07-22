#include "json.h"
#include <algorithm>
#include <cstdint>
#include <iterator>
#include <memory>
#include <nlohmann/json.hpp>
#include <optional>
#include <string_view>
#include <utf8.h>
#include <utility>
#include <vector>

namespace JSON {
namespace {
using Json = nlohmann::ordered_json;

enum class Operation { changed, added, removed, reordered };

struct Change {
	Operation operation;
	std::string path;
	Json oldValue;
	Json newValue;
};

bool isBlank ( std::uint32_t character ) {
	return ( character >= 0x0009 && character <= 0x000D ) ||
				 ( character >= 0x001C && character <= 0x0020 ) ||
				 character == 0x0085 || character == 0x00A0 || character == 0x1680 ||
				 ( character >= 0x2000 && character <= 0x200A ) ||
				 character == 0x2028 || character == 0x2029 || character == 0x202F ||
				 character == 0x205F || character == 0x3000;
}

std::string trim ( const std::string& value ) {
	auto first = value.cbegin ();
	const auto end = value.cend ();
	while ( first != end ) {
		auto next = first;
		if ( !isBlank ( utf8::next ( next, end ) ) ) {
			break;
		}
		first = next;
	}
	auto last = end;
	while ( first != last ) {
		auto previous = last;
		if ( !isBlank ( utf8::prior ( previous, first ) ) ) {
			break;
		}
		last = previous;
	}
	return { first, last };
}

bool theSame ( const Json& first, const Json& second ) {
	if ( first.is_string () && second.is_string () ) {
		return trim ( first.get_ref<const std::string&> () ) ==
					 trim ( second.get_ref<const std::string&> () );
	}
	if ( first.is_boolean () && second.is_number () ) {
		return Json ( first.get<bool> () ? 1 : 0 ) == second;
	}
	if ( first.is_number () && second.is_boolean () ) {
		return first == Json ( second.get<bool> () ? 1 : 0 );
	}
	if ( first.is_array () && second.is_array () ) {
		if ( first.size () != second.size () ) {
			return false;
		}
		for ( size_t i = 0; i < first.size (); ++i ) {
			if ( !theSame ( first.at ( i ), second.at ( i ) ) ) {
				return false;
			}
		}
		return true;
	}
	if ( first.is_object () && second.is_object () ) {
		if ( first.size () != second.size () ) {
			return false;
		}
		for ( auto item = first.begin (); item != first.end (); ++item ) {
			if ( !second.contains ( item.key () ) ||
					 !theSame ( item.value (), second.at ( item.key () ) ) ) {
				return false;
			}
		}
		return true;
	}
	return first == second;
}

bool uniqueValues ( const Json& items, std::string_view field ) {
	std::vector<const Json*> values;
	for ( const auto& item : items ) {
		if ( !item.contains ( field ) ) {
			return false;
		}
		const auto& value = item.at ( field );
		if ( std::ranges::any_of ( values, [ & ] ( const Json* other ) {
					 return theSame ( value, *other );
				 } ) ) {
			return false;
		}
		values.push_back ( &value );
	}
	return true;
}

std::optional<std::string> findListKey ( const Json& items ) {
	if ( !items.is_array () || items.empty () ||
			 !std::ranges::all_of (
					 items, [] ( const Json& item ) { return item.is_object (); } ) ) {
		return std::nullopt;
	}
	if ( uniqueValues ( items, "ID" ) ) {
		return "ID";
	}
	for ( auto field = items.front ().begin (); field != items.front ().end ();
				++field ) {
		if ( field.key ().ends_with ( "LineNumber" ) &&
				 uniqueValues ( items, field.key () ) ) {
			return field.key ();
		}
	}
	return std::nullopt;
}

std::string pythonJson ( const Json& value ) {
	if ( value.is_array () ) {
		std::string result = "[";
		for ( size_t index = 0; index < value.size (); ++index ) {
			if ( index > 0 ) {
				result += ", ";
			}
			result += pythonJson ( value.at ( index ) );
		}
		return result + "]";
	}
	if ( value.is_object () ) {
		std::string result = "{";
		bool next = false;
		for ( auto item = value.begin (); item != value.end (); ++item ) {
			if ( next ) {
				result += ", ";
			}
			result +=
					Json ( item.key () ).dump () + ": " + pythonJson ( item.value () );
			next = true;
		}
		return result + "}";
	}
	return value.dump ();
}

std::string pythonStringRepresentation ( const std::string& value ) {
	const auto quote = value.find ( '\'' ) != std::string::npos &&
														 value.find ( '"' ) == std::string::npos
												 ? '"'
												 : '\'';
	std::string result ( 1, quote );
	constexpr char Hexadecimal [] = "0123456789abcdef";
	for ( const auto character : value ) {
		const auto byte = static_cast<unsigned char> ( character );
		if ( character == '\\' || character == quote ) {
			result.push_back ( '\\' );
			result.push_back ( character );
		} else if ( character == '\t' ) {
			result += "\\t";
		} else if ( character == '\n' ) {
			result += "\\n";
		} else if ( character == '\r' ) {
			result += "\\r";
		} else if ( byte < 0x20 || byte == 0x7F ) {
			result += "\\x";
			result.push_back ( Hexadecimal [ byte >> 4 ] );
			result.push_back ( Hexadecimal [ byte & 0x0F ] );
		} else {
			result.push_back ( character );
		}
	}
	result.push_back ( quote );
	return result;
}

std::string pythonRepresentation ( const Json& value ) {
	if ( value.is_string () ) {
		return pythonStringRepresentation ( value.get_ref<const std::string&> () );
	}
	if ( value.is_null () ) {
		return "None";
	}
	if ( value.is_boolean () ) {
		return value.get<bool> () ? "True" : "False";
	}
	if ( value.is_array () ) {
		std::string result = "[";
		for ( size_t index = 0; index < value.size (); ++index ) {
			if ( index > 0 ) {
				result += ", ";
			}
			result += pythonRepresentation ( value.at ( index ) );
		}
		return result + "]";
	}
	if ( value.is_object () ) {
		std::string result = "{";
		bool next = false;
		for ( auto item = value.begin (); item != value.end (); ++item ) {
			if ( next ) {
				result += ", ";
			}
			result += pythonStringRepresentation ( item.key () ) + ": " +
								pythonRepresentation ( item.value () );
			next = true;
		}
		return result + "}";
	}
	return value.dump ();
}

std::string keyText ( const Json& value ) {
	if ( value.is_string () ) {
		return value.get<std::string> ();
	}
	return pythonRepresentation ( value );
}

std::string objectPath ( const std::string& path, const std::string& key ) {
	return path.empty () ? key : path + "." + key;
}

std::string listPath ( const std::string& path, const Json& key ) {
	return path + "[" + keyText ( key ) + "]";
}

std::string indexPath ( const std::string& path, size_t index ) {
	return path + "[" + std::to_string ( index ) + "]";
}

struct KeyedItem {
	Json key;
	const Json* value;
};

using KeyedItems = std::vector<KeyedItem>;

KeyedItems keyedItems ( const Json& items, std::string_view field ) {
	KeyedItems result;
	for ( const auto& item : items ) {
		if ( !item.is_object () || !item.contains ( field ) ) {
			continue;
		}
		const auto& key = item.at ( field );
		auto found = std::ranges::find_if ( result, [ & ] ( const auto& entry ) {
			return theSame ( entry.key, key );
		} );
		if ( found == result.end () ) {
			result.push_back ( { key, &item } );
		} else {
			found->value = &item;
		}
	}
	return result;
}

const KeyedItem* findItem ( const KeyedItems& items, const Json& key ) {
	const auto found = std::ranges::find_if (
			items, [ & ] ( const auto& item ) { return theSame ( item.key, key ); } );
	return found == items.end () ? nullptr : &*found;
}

std::vector<Json> itemOrder ( const Json& items, std::string_view field ) {
	std::vector<Json> result;
	for ( const auto& item : items ) {
		if ( item.is_object () && item.contains ( field ) ) {
			result.push_back ( item.at ( field ) );
		}
	}
	return result;
}

bool sameOrder ( const std::vector<Json>& first,
								 const std::vector<Json>& second ) {
	if ( first.size () != second.size () ) {
		return false;
	}
	for ( size_t index = 0; index < first.size (); ++index ) {
		if ( !theSame ( first [ index ], second [ index ] ) ) {
			return false;
		}
	}
	return true;
}

Json jsonArray ( const std::vector<Json>& values ) {
	auto result = Json::array ();
	for ( const auto& value : values ) {
		result.push_back ( value );
	}
	return result;
}

void diff ( const Json& first, const Json& second, const std::string& path,
						std::vector<Change>* changes );

void diffObjects ( const Json& first, const Json& second,
									 const std::string& path, std::vector<Change>* changes ) {
	for ( auto item = first.begin (); item != first.end (); ++item ) {
		const auto fullPath = objectPath ( path, item.key () );
		if ( second.contains ( item.key () ) ) {
			diff ( item.value (), second.at ( item.key () ), fullPath, changes );
		} else {
			changes->push_back (
					{ Operation::removed, fullPath, item.value (), {} } );
		}
	}
	for ( auto item = second.begin (); item != second.end (); ++item ) {
		if ( !first.contains ( item.key () ) ) {
			changes->push_back ( { Operation::added,
													 objectPath ( path, item.key () ),
													 {},
													 item.value () } );
		}
	}
}

void diffKeyedLists ( const Json& oldValue, const Json& newValue,
											const std::string& path, std::string_view field,
											std::vector<Change>* changes ) {
	const auto oldItems = keyedItems ( oldValue, field );
	const auto newItems = keyedItems ( newValue, field );
	for ( const auto& oldItem : oldItems ) {
		const auto sub = listPath ( path, oldItem.key );
		const auto newItem = findItem ( newItems, oldItem.key );
		if ( newItem == nullptr ) {
			changes->push_back (
					{ Operation::removed, sub, *oldItem.value, {} } );
		} else {
			diff ( *oldItem.value, *newItem->value, sub, changes );
		}
	}
	for ( const auto& newItem : newItems ) {
		if ( findItem ( oldItems, newItem.key ) == nullptr ) {
			changes->push_back ( { Operation::added,
													 listPath ( path, newItem.key ),
													 {},
													 *newItem.value } );
		}
	}

	const auto oldOrder = itemOrder ( oldValue, field );
	const auto newOrder = itemOrder ( newValue, field );
	std::vector<Json> commonOld;
	std::vector<Json> commonNew;
	std::ranges::copy_if ( oldOrder, std::back_inserter ( commonOld ),
												 [ & ] ( const auto& key ) {
													 return findItem ( newItems, key ) != nullptr;
												 } );
	std::ranges::copy_if ( newOrder, std::back_inserter ( commonNew ),
												 [ & ] ( const auto& key ) {
													 return findItem ( oldItems, key ) != nullptr;
												 } );
	if ( !sameOrder ( commonOld, commonNew ) ) {
		changes->push_back ( { Operation::reordered, path, jsonArray ( commonOld ),
													 jsonArray ( commonNew ) } );
	}
}

void diffLists ( const Json& oldValue, const Json& newValue,
								 const std::string& path, std::vector<Change>* changes ) {
	auto key = findListKey ( oldValue );
	if ( !key ) {
		key = findListKey ( newValue );
	}
	if ( key ) {
		diffKeyedLists ( oldValue, newValue, path, *key, changes );
		return;
	}
	const auto count = std::max ( oldValue.size (), newValue.size () );
	for ( size_t index = 0; index < count; ++index ) {
		const auto sub = indexPath ( path, index );
		if ( index >= newValue.size () ) {
			changes->push_back ( { Operation::removed,
													 sub,
													 oldValue.at ( index ),
													 {} } );
		} else if ( index >= oldValue.size () ) {
			changes->push_back (
					{ Operation::added, sub, {}, newValue.at ( index ) } );
		} else {
			diff ( oldValue.at ( index ), newValue.at ( index ), sub, changes );
		}
	}
}

void diff ( const Json& first, const Json& second, const std::string& path,
						std::vector<Change>* changes ) {
	if ( first.is_object () && second.is_object () ) {
		diffObjects ( first, second, path, changes );
	} else if ( first.is_array () && second.is_array () ) {
		diffLists ( first, second, path, changes );
	} else if ( !theSame ( first, second ) ) {
		changes->push_back ( { Operation::changed, path, first, second } );
	}
}

bool commonRoot ( const Json& first, const Json& second ) {
	return first.is_array () && second.is_array () && first.size () == 1 &&
				 second.size () == 1 && first.front ().is_object () &&
				 second.front ().is_object () && first.front ().contains ( "ID" ) &&
				 second.front ().contains ( "ID" ) &&
				 theSame ( first.front ().at ( "ID" ), second.front ().at ( "ID" ) );
}

std::string renderText ( const std::vector<Change>& changes ) {
	if ( changes.empty () ) {
		return "No changes.";
	}
	std::string result;
	for ( const auto& change : changes ) {
		if ( !result.empty () ) {
			result.push_back ( '\n' );
		}
		switch ( change.operation ) {
		case Operation::changed:
			result += "~ " + change.path + ": " + pythonJson ( change.oldValue ) +
								" -> " + pythonJson ( change.newValue );
			break;
		case Operation::added:
			result += "+ " + change.path + ": " + pythonJson ( change.newValue );
			break;
		case Operation::removed:
			result += "- " + change.path + ": " + pythonJson ( change.oldValue );
			break;
		case Operation::reordered:
			result += "* " + change.path + ": order " +
								pythonRepresentation ( change.oldValue ) + " -> " +
								pythonRepresentation ( change.newValue );
			break;
		}
	}
	return result;
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

std::string compare ( const std::string& firstJSON,
											const std::string& secondJSON ) {
	const auto first = Json::parse ( firstJSON );
	const auto second = Json::parse ( secondJSON );
	std::vector<Change> changes;
	if ( commonRoot ( first, second ) ) {
		diff ( first.front (), second.front (), "", &changes );
	} else {
		diff ( first, second, "", &changes );
	}
	std::stable_sort ( changes.begin (), changes.end (),
										 [] ( const auto& firstChange, const auto& secondChange ) {
											 return firstChange.path < secondChange.path;
										 } );
	return renderText ( changes );
}
}
