#include "files.h"
#include "transform.h"
#include <cstdint>
#include <fstream>
#include <stdexcept>
#include <xxhash.h>

namespace files {
std::string toString ( const std::string& file ) {
	return toString ( std::filesystem::path ( file ) );
}

std::string toString ( const std::filesystem::path& file ) {
	std::ifstream stream ( file, std::ios::binary | std::ios::ate );
	if ( !stream ) {
		throw std::runtime_error ( "Failed to open: " + pathToUtf8 ( file ) );
	}
	const auto size = stream.tellg ();
	if ( size < 0 ) {
		throw std::runtime_error ( "Failed to get size: " + pathToUtf8 ( file ) );
	}
	std::string content;
	content.resize ( static_cast<size_t> ( size ) );
	stream.seekg ( 0 );
	if ( !stream.read ( content.data (), content.size () ) ) {
		throw std::runtime_error ( "Failed to read: " + pathToUtf8 ( file ) );
	}
	return content;
}

uint64_t toHash ( const std::string& file ) {
	return toHash ( std::filesystem::path ( file ) );
}

uint64_t toHash ( const std::filesystem::path& file ) {
	const auto string = strings::trim ( toString ( file ) );
	return XXH3_64bits ( string.data (), string.size () );
}
std::string pathToUtf8 ( const std::filesystem::path& path ) {
	const auto value = path.generic_u8string ();
#ifdef __cpp_char8_t
	return { reinterpret_cast<const char*> ( value.data () ), value.size () };
#else
	return value;
#endif
}
}
