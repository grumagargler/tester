#pragma once
#include "1c/types.h"
#include <cstdint>
#include <filesystem>
#include <memory>
#include <string>

class Chars {
public:
	template <typename SourceType>
	static uint32_t toWchar ( WCHAR_T** Destination, const SourceType* Source ) {
		std::basic_string_view<SourceType> const string ( Source );
		const auto size = string.length () + 1;
		if ( !*Destination ) {
			*Destination = new WCHAR_T [ size ];
		}
		uint32_t const converted { 0 };
		memset ( *Destination, 0, size * sizeof ( WCHAR_T ) );
		auto receiver = *Destination;
		for ( auto c : string ) {
			*receiver++ = c;
		}
		return converted;
	}

	static std::unique_ptr<WCHAR_T []> toWchar ( char Source ) {
		auto size = 2;
		std::unique_ptr<WCHAR_T []> result { new WCHAR_T [ size ] };
		auto receiver = result.get ();
		memset ( receiver, 0, size * sizeof ( WCHAR_T ) );
		// NOLINTNEXTLINE(cppcoreguidelines-pro-bounds-pointer-arithmetic)
		receiver [ 0 ] = Source;
		return result;
	}

	template <typename SourceType>
	static std::unique_ptr<WCHAR_T []> toWchar ( const SourceType* Source ) {
		std::basic_string_view<SourceType> const string ( Source );
		const auto size = string.length () + 1;
		std::unique_ptr<WCHAR_T []> result { new WCHAR_T [ size ] };
		auto receiver = result.get ();
		memset ( receiver, 0, size * sizeof ( WCHAR_T ) );
		for ( auto c : string ) {
			*receiver++ = c;
		}
		return result;
	}

	// NOLINTNEXTLINE(cppcoreguidelines-avoid-c-arrays)
	static std::unique_ptr<wchar_t []> fromWchar ( const WCHAR_T* Source,
																								 size_t Length = 0 );
	static std::wstring stringToWide ( const std::string& Source,
																		 bool cleanFirst = false );
	static std::string wideToString ( const std::wstring& Source );
	static std::filesystem::path wideToPath ( const std::wstring& Source );
	static std::wstring wcharToWide ( const WCHAR_T* String, size_t Length = 0 );
	static uint32_t wcharLength ( const WCHAR_T* Source );
};
