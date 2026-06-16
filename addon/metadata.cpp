#include "metadata.h"
#include "metadata/metadata.h"
#include <exception>

Metadata::Metadata () : Extender ( L"Metadata" ) {
	addFunction ( L"GetFormInfo", L"ПолучитьИнформациюФормы", 3,
								[ & ] ( tVariant* Params, tVariant* Result ) {
									return getFormInfo ( Params, Result );
								} );
	addFunction ( L"GetFormDataPaths", L"ПолучитьПутиДанныхФормы", 2,
								[ & ] ( tVariant* Params, tVariant* Result ) {
									return getFormDataPaths ( Params, Result );
								} );
}

bool Metadata::getFormInfo ( tVariant* Params, tVariant* Result ) {
	std::string sources, formName, language;
	if ( !readString ( Params [ 0 ], sources, "sources" ) ||
			 !readString ( Params [ 1 ], formName, "formName" ) ||
			 !readString ( Params [ 2 ], language, "language" ) ) {
		return false;
	}
	auto metadata = Metadata1C ( sources, formName, language );
	try {
		const auto body = metadata.getFormInfo ();
		if ( body.empty () ) {
			SetError ( "Could not resolve form info for the requested form: " +
								 formName );
			return false;
		}
		returnString ( Result, Chars::stringToWide ( body ) );
		return true;
	} catch ( const std::exception& error ) {
		SetError ( error.what () );
		return false;
	} catch ( ... ) {
		SetError ( "Unknown error occurred while reading form info" );
		return false;
	}
}

bool Metadata::getFormDataPaths ( tVariant* Params, tVariant* Result ) {
	std::string sources, formName;
	if ( !readString ( Params [ 0 ], sources, "sources" ) ||
			 !readString ( Params [ 1 ], formName, "formName" ) ) {
		return false;
	}
	auto metadata = Metadata1C ( sources, formName );
	try {
		const auto body = metadata.getFormDataPaths ();
		if ( body.empty () ) {
			SetError ( "Could not resolve form data paths for the requested form: " +
								 formName );
			return false;
		}
		returnString ( Result, Chars::stringToWide ( body ) );
		return true;
	} catch ( const std::exception& error ) {
		SetError ( error.what () );
		return false;
	} catch ( ... ) {
		SetError ( "Unknown error occurred while reading form data paths" );
		return false;
	}
}
