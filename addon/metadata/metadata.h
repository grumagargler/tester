#pragma once
#include <string>

class Metadata1C {
public:
	Metadata1C ( std::string sources, std::string formName );
	Metadata1C ( std::string sources, std::string formName,
							 std::string language );
	std::string getFormInfo ();
	std::string getFormDataPaths ();

private:
	std::string sources, formName, language;
};
