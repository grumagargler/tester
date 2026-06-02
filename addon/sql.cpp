#include "sql.h"
#include "chars.h"
#include <nlohmann/json.hpp>
#include <regex>

sql::sql ( const wchar_t* query, const size_t length )
		: query ( query ), length ( length ) {
}

std::wstring sql::get () {
	if ( length == 0 ) {
		return {};
	}
	json = nlohmann::json::array ();
	index = 0;
	size_t start { 0 };
	while ( start <= length ) {
		auto end = start;
		while ( end < length && query [ end ] != L'\n' ) {
			++end;
		}
		row = query + start;
		len = end - start;
		if ( len > 0 && row [ len - 1 ] == L'\r' ) {
			--len;
		}
		if ( nextQuery () )
			++index;
		else
			addRecord ();
		if ( end == length ) {
			break;
		}
		start = end + 1;
	}
	return Chars::stringToWide ( json.dump () );
}

std::wstring sql::adjust () {
	const std::wregex pattern ( L"// :" );
	return std::regex_replace ( query, pattern, L"" );
}

void sql::addRecord () {
	for ( auto command : commands ) {
		auto commandBegins = begins ( row, command.signature );
		if ( commandBegins ) {
			auto object = nlohmann::json::object ();
			object [ "Name" ] =
					Chars::wideToString ( { commandBegins, len - command.signatureLen } );
			object [ "Type" ] = command.type;
			object [ "Index" ] = index;
			json.push_back ( std::move ( object ) );
		}
	}
}

const wchar_t* sql::begins ( const wchar_t* string1,
														 const wchar_t* string2 ) const {
	size_t i = 0;
	while ( true ) {
		if ( *string2 == 0 )
			return string1;
		if ( i++ == len || *string1++ != *string2++ )
			break;
	}
	return nullptr;
}

bool sql::nextQuery () const {
	return begins ( row, L";" );
}
