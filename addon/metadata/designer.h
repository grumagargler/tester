#pragma once
#include <filesystem>
#include <string>

namespace metadata::designer {
std::string getFormInfo ( const std::filesystem::path& sources,
													const std::string& formName,
													const std::string& language );
std::string getFormDataPaths ( const std::filesystem::path& sources,
															 const std::string& formName );
}
