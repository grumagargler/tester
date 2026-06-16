#include "transform.h"
#include <algorithm>
#include <cctype>
#include <cstdint>
#include <cwctype>
#include <string>
#include <string_view>
#include <vector>
#include <xxhash.h>

namespace strings {
uint64_t toHash ( const std::string& string, bool addBOM ) {
	if ( !addBOM ) {
		return XXH3_64bits ( string.data (), string.size () );
	}
	std::string data;
	data.reserve ( string.size () + 3 );
	data.append ( "\xEF\xBB\xBF", 3 );
	data += string;
	return XXH3_64bits ( data.data (), data.size () );
}

void trim ( std::string& string ) {
	if ( string.size () >= 3 &&
			 static_cast<unsigned char> ( string [ 0 ] ) == 0xEF &&
			 static_cast<unsigned char> ( string [ 1 ] ) == 0xBB &&
			 static_cast<unsigned char> ( string [ 2 ] ) == 0xBF ) {
		string.erase ( 0, 3 );
	}
	const auto begin = string.begin ();
	string.erase (
			begin, std::find_if_not ( begin, string.end (), [] ( unsigned char c ) {
				return isspace ( c );
			} ) );
	string.erase (
			std::find_if_not ( string.rbegin (), string.rend (),
												 [] ( unsigned char c ) { return isspace ( c ); } )
					.base (),
			string.end () );
}

std::string trim ( std::string&& string ) {
	trim ( string );
	return std::move ( string );
}

std::vector<std::string> split ( const std::string& string,
																 const std::string& splitter ) {
	std::vector<std::string> result;
	size_t start = 0, end = 0, len = splitter.length ();
	auto add = [ & ] {
		auto chunk = trim ( string.substr ( start, end - start ) );
		if ( !chunk.empty () ) {
			result.emplace_back ( chunk );
		}
	};
	while ( ( end = string.find ( splitter, start ) ) != std::string::npos ) {
		add ();
		start = end + len;
	}
	add ();
	return result;
}

std::string lower ( const std::string& str ) {
	std::string result;
	result.resize ( str.size () );
	std::transform ( str.begin (), str.end (), result.begin (),
									 [] ( unsigned char c ) { return std::tolower ( c ); } );
	return result;
}

namespace {
struct ParseResult {
	bool ok = false;
	std::string normalized, error;
	std::size_t errorPosition;
};

class NumberParser {
public:
	explicit NumberParser ( std::wstring_view string, wchar_t decimalSeparator,
													wchar_t groupSeparator )
			: source ( string ), sourceSize ( source.size () ),
				decimalSeparator ( decimalSeparator ),
				groupSeparator ( groupSeparator ) {
		groupSpaceSeparator = isSpace ( groupSeparator );
	}

	std::wstring parse () {
		if ( parseSource () ) {
			return normalized;
		}
		return original ();
	}

	bool isNumber () {
		return parseSource ();
	}

private:
	bool parseSource () {
		skipSpaces ();
		parseSign ();
		if ( !parseNumber () ) {
			return false;
		}
		if ( isDecimalDelimiter () ) {
			if ( !parseFractionalPart () ) {
				return false;
			}
		}
		skipSpaces ();
		return end ();
	}

	std::wstring_view source;
	std::wstring normalized;
	const std::size_t sourceSize;
	wchar_t decimalSeparator, groupSeparator;
	std::size_t position = 0;
	bool groupSpaceSeparator;

	static bool isSpace ( wchar_t value ) {
		return std::iswspace ( static_cast<std::wint_t> ( value ) ) != 0 ||
					 value == L'\u00A0';
	}

	bool isDecimalDelimiter () const {
		return decimalSeparator != L'\0' && peek () == decimalSeparator;
	}

	std::wstring original () const {
		return std::wstring ( source );
	}

	bool end () const {
		return position >= sourceSize;
	}

	wchar_t peek () const {
		if ( end () ) {
			return L'\0';
		} else {
			return source [ position ];
		}
	}

	wchar_t get () {
		if ( end () ) {
			return L'\0';
		} else {
			return source [ position++ ];
		}
	}

	bool isDigit () const {
		return std::iswdigit ( static_cast<std::wint_t> ( peek () ) ) != 0;
	}

	bool isDigitAhead () const {
		const auto i = position + 1;
		return i < sourceSize &&
					 std::iswdigit ( static_cast<std::wint_t> ( source [ i ] ) ) != 0;
	}

	void next () {
		++position;
	}

	void skipSpaces () {
		while ( isSpace ( peek () ) ) {
			next ();
		}
	}

	void parseSign () {
		if ( peek () == L'-' ) {
			normalized.push_back ( get () );
			if ( isSpace ( peek () ) ) {
				next ();
			}
		}
	}

	bool groupDelimeter () {
		return groupSeparator != L'\0' && peek () == groupSeparator &&
					 ( !groupSpaceSeparator || isDigitAhead () );
	}

	bool parseNumber () {
		const auto size = parseDigits ();
		if ( size == 0 ) {
			return false;
		}
		if ( groupDelimeter () ) {
			if ( size > 3 ) {
				return false;
			}
			return parseGroup ();
		}
		return true;
	}

	std::size_t parseDigits () {
		std::size_t count = 0;
		while ( isDigit () ) {
			normalized.push_back ( get () );
			++count;
		}
		return count;
	}

	bool parseGroup () {
		while ( groupDelimeter () ) {
			get ();
			if ( !parseThreeDigits () ) {
				return false;
			}
		}
		return true;
	}

	bool parseThreeDigits () {
		for ( int i = 0; i < 3; ++i ) {
			if ( !isDigit () ) {
				return false;
			}
			normalized.push_back ( get () );
		}
		return true;
	}

	bool parseFractionalPart () {
		normalized.push_back ( L'.' );
		next ();
		return parseDigits () > 0;
	}
};
}

std::wstring toNumber ( std::wstring_view string, wchar_t decimalSeparator,
												wchar_t groupSeparator ) {
	// number = { white_space }, sign?, sign_space?, integer_part,
	//          fractional_part?, { white_space }
	// sign = "-"
	// sign_space = white_space
	// integer_part = plain_integer | grouped_integer
	// plain_integer = digit, { digit }
	// grouped_integer = digits_group, { group_separator, digit, digit, digit }
	// digits_group = digit | digit, digit | digit, digit, digit
	// fractional_part = decimal_separator, digit, { digit }
	// white_space = wide whitespace | NBSP
	// decimal_separator = caller-provided character
	// group_separator = caller-provided character
	NumberParser parser ( string, decimalSeparator, groupSeparator );
	return parser.parse ();
}

bool isNumber ( std::wstring_view string, wchar_t decimalSeparator,
								wchar_t groupSeparator ) {
	NumberParser parser ( string, decimalSeparator, groupSeparator );
	return parser.isNumber ();
}
}
