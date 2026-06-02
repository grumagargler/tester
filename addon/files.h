#pragma once
#include <cstdint>
#include <filesystem>
#include <string>

namespace files {
std::string toString ( const std::string& file );
std::string toString ( const std::filesystem::path& file );
uint64_t toHash ( const std::string& file );
uint64_t toHash ( const std::filesystem::path& file );
std::string pathToUtf8 ( const std::filesystem::path& path );
}
