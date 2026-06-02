#include "chars.h"
#include "corestrings.h"
#include <algorithm>
#include <cstring>
#include <iterator>
#include <string>
#include <utf8.h>

namespace {
std::u16string ToUtf16 ( const std::string& source ) {
	std::u16string result;
	utf8::utf8to16 ( source.begin (), source.end (),
									 std::back_inserter ( result ) );
	return result;
}

std::string FromUtf16 ( const std::u16string& source ) {
	std::string result;
	utf8::utf16to8 ( source.begin (), source.end (),
									 std::back_inserter ( result ) );
	return result;
}
}

// NOLINTBEGIN(cppcoreguidelines-avoid-c-arrays)
// NOLINTBEGIN(cppcoreguidelines-pro-bounds-pointer-arithmetic)
// NOLINTBEGIN(cppcoreguidelines-pro-type-const-cast)

uint32_t Chars::wcharLength ( const WCHAR_T* Source ) {
	uint32_t length = 0;
	auto tmpShort = const_cast<WCHAR_T*> ( Source );
	while ( *tmpShort++ )
		++length;
	return length;
}

std::unique_ptr<wchar_t []> Chars::fromWchar ( const WCHAR_T* Source,
																							 size_t Length ) {
	if ( !Length ) {
		Length = wcharLength ( Source );
	}
	++Length;
	std::unique_ptr<wchar_t []> result { new wchar_t [ Length ] };
	auto receiver = result.get ();
	memset ( receiver, 0, Length * sizeof ( wchar_t ) );
	while ( --Length && *Source ) {
		*receiver++ = *Source++;
	}
	return result;
}

std::wstring Chars::stringToWide ( const std::string& Source,
																	 bool cleanFirst ) {
	std::u16string temp;
	if ( cleanFirst ) {
		temp = ToUtf16 ( strings::clean ( Source ) );
	} else {
		temp = ToUtf16 ( Source );
	}
	std::wstring result;
	result.resize ( temp.size () );
	std::copy ( temp.begin (), temp.end (), result.begin () );
	return result;
}

std::string Chars::wideToString ( const std::wstring& Source ) {
	std::string result;
	std::u16string temp;
	temp.resize ( Source.size () );
	std::copy ( Source.begin (), Source.end (), temp.begin () );
	result = FromUtf16 ( temp );
	return result;
}

std::filesystem::path Chars::wideToPath ( const std::wstring& Source ) {
#ifdef _WIN32
	return std::filesystem::path ( Source );
#else
	return std::filesystem::path ( Chars::wideToString ( Source ) );
#endif
}

std::wstring Chars::wcharToWide ( const WCHAR_T* String, size_t Length ) {
	if ( String == nullptr ) {
		return {};
	}
	const auto result = fromWchar ( String, Length );
	if ( Length ) {
		return { result.get (), Length };
	}
	return result.get ();
}

// NOLINTEND(cppcoreguidelines-pro-type-const-cast)
// NOLINTEND(cppcoreguidelines-pro-bounds-pointer-arithmetic)
// NOLINTEND(cppcoreguidelines-avoid-c-arrays)
