#include "metadata.h"
#include "designer.h"
#include "edt.h"
#include "internal.h"
#include <filesystem>
#include <utility>

namespace {
bool designerSources ( const std::filesystem::path& sources ) {
	return std::filesystem::exists ( sources / "Configuration.xml" );
}
}

Metadata1C::Metadata1C ( std::string sources, std::string formName,
												 std::string language )
		: sources ( metadata::internal::utf8PathSegment ( sources ) ),
			formName ( std::move ( formName ) ),
			language ( std::move ( language ) ) {
}

Metadata1C::Metadata1C ( std::string sources, std::string formName )
		: Metadata1C ( std::move ( sources ), std::move ( formName ), {} ) {
}

std::string Metadata1C::getFormInfo () {
	if ( designerSources ( sources ) ) {
		return metadata::designer::getFormInfo ( sources, formName, language );
	} else {
		return metadata::edt::getFormInfo ( sources, formName, language );
	}
}

std::string Metadata1C::getFormDataPaths () {
	if ( designerSources ( sources ) ) {
		return metadata::designer::getFormDataPaths ( sources, formName );
	} else {
		return metadata::edt::getFormDataPaths ( sources, formName );
	}
}
