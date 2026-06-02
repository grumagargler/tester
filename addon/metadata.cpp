#include "metadata.h"
#include "tooltips.h"
#include <exception>

Metadata::Metadata () : Extender ( L"Metadata" ) {
	addFunction ( L"GetTooltips", L"ПолучитьПодсказки", 3,
								[ & ] ( tVariant* Params, tVariant* Result ) {
									return getTooltips ( Params, Result );
								} );
}

bool Metadata::getTooltips ( tVariant* Params, tVariant* Result ) {
	std::string sources, formName, language;
	if ( !readString ( Params [ 0 ], sources, "sources" ) ||
			 !readString ( Params [ 1 ], formName, "formName" ) ||
			 !readString ( Params [ 2 ], language, "language" ) ) {
		return false;
	}
	auto tooltips = Tooltips ( sources, formName, language );
	try {
		const auto body = tooltips.get ();
		if ( body.empty () ) {
			SetError ( "Could not resolve tooltips for the requested form: " + formName );
			return false;
		}
		returnString ( Result, Chars::stringToWide ( body ) );
		return true;
	} catch ( const std::exception& error ) {
		SetError ( error.what () );
		return false;
	} catch ( ... ) {
		SetError ( "Unknown error occurred while reading tooltips" );
		return false;
	}
}
