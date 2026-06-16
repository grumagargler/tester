#pragma once
#include <cstdint>
#include <numeric>
#include <string>
#include <string_view>
#include <vector>

namespace strings {
uint64_t toHash ( const std::string& string, bool addBOM = false );
void trim ( std::string& string );
[[nodiscard]] std::string trim ( std::string&& string );
std::vector<std::string> split ( const std::string& string,
																 const std::string& splitter );
template <typename Collection>
std::string concat ( const Collection& collection, const std::string& splitter,
										 bool skipEmpty = true ) {
	std::string result;
	auto first = true;
	for ( const std::string& str : collection ) {
		if ( skipEmpty && str.empty () ) {
			continue;
		}
		if ( !first ) {
			result += splitter;
		}
		result += str;
		first = false;
	}
	return result;
}

std::string lower ( const std::string& str );
std::wstring toNumber ( std::wstring_view string, wchar_t decimalSeparator,
												wchar_t groupSeparator );
bool isNumber ( std::wstring_view string, wchar_t decimalSeparator,
								wchar_t groupSeparator );
}
