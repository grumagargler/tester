#include "root.h"
#include "appearanceparser.h"
#include "files.h"
#include "json.h"
#include "sql.h"
#include "transform.h"
#include <cmath>
#include <cwctype>
#include <exception>
#include <fstream>
#include <string>
#if __linux__
#include <unistd.h>
#elif _WIN32
#include <cctype>
#include <sstream>
#endif

Root::Root () : Extender ( L"Root" ) {
	addProcedure (
			L"AugmentQuery", L"УлучшитьЗапрос", 1,
			[ & ] ( tVariant* Params ) { return augmentQuery ( Params ); } );
	addFunction ( L"AdjustQuery", L"ПоправитьЗапрос", 1,
								[ & ] ( tVariant* Params, tVariant* Result ) {
									return adjustQuery ( Params, Result );
								} );
	addFunction ( L"QueryTables", L"ТаблицыЗапроса", 1,
								[ & ] ( tVariant* Params, tVariant* Result ) {
									return queryTables ( Params, Result );
								} );
	addFunction ( L"ParseAppearance", L"РазобратьОформление", 1,
								[ & ] ( tVariant* Params, tVariant* Result ) {
									return parseAppearance ( Params, Result );
								} );
	addFunction ( L"Shoot", L"Снять", 2,
								[ & ] ( tVariant* Params, tVariant* Result ) {
									return shoot ( Params, Result );
								} );
	addProcedure ( L"Maximize", L"Максимизировать", 1,
								 [ & ] ( tVariant* Params ) { return maximize ( Params ); } );
	addProcedure ( L"Minimize", L"Минимизировать", 1,
								 [ & ] ( tVariant* Params ) { return minimize ( Params ); } );
	addProcedure ( L"Pause", L"Пауза", 1, [ & ] ( tVariant* Params ) {
		pause ( Params );
		return true;
	} );
	addProcedure ( L"GotoConsole", L"ПерейтиВКонсоль", 0,
								 [ & ] ( tVariant* Params ) {
									 gotoConsole ( Params );
									 return true;
								 } );
	addFunction ( L"GetEnv", L"ПеременнаяСреды", 1,
								[ & ] ( tVariant* Params, tVariant* Result ) {
									return getEnvironment ( Params, Result );
								} );
	addFunction ( L"GetHash", L"ПолучитьHash", 1,
								[ & ] ( tVariant* Params, tVariant* Result ) {
									return getHash ( Params, Result );
								} );
	addFunction ( L"GetStringHash", L"ПолучитьHashСтроки", 2,
								[ & ] ( tVariant* Params, tVariant* Result ) {
									return getStringHash ( Params, Result );
								} );
	addFunction ( L"CompareJSON", L"СравнитьJSON", 2,
								[ & ] ( tVariant* Params, tVariant* Result ) {
									return compareJSON ( Params, Result );
								} );
}

bool Root::augmentQuery ( tVariant* Params ) {
	std::wstring data;
	if ( !readWideString ( Params [ 0 ], data, "query" ) ) {
		return false;
	}
	if ( isTesting () ) {
		sql query { data.data (), data.length () };
		returnString ( Params, query.adjust () );
	}
	return true;
}

bool Root::adjustQuery ( tVariant* Params, tVariant* Result ) {
	std::wstring query;
	if ( !readWideString ( Params [ 0 ], query, "query" ) ) {
		return false;
	}
	const std::wstring expression { L"NULL = &P" };
	const std::wstring stub { L"true" };
	const auto size = expression.size ();
	size_t i { 0 };
	while ( true ) {
		i = query.find ( expression, i );
		if ( i == std::wstring::npos ) {
			break;
		}
		auto j = i + size;
		auto suffix = 0;
		while ( j < query.size () && std::iswdigit ( query [ j ] ) != 0 ) {
			++j;
			++suffix;
		}
		query.replace ( i, size + suffix, stub );
		i += stub.size ();
	}
	returnString ( Result, query );
	return true;
}

bool Root::queryTables ( tVariant* Params, tVariant* Result ) {
	std::wstring data;
	if ( !readWideString ( Params [ 0 ], data, "query" ) ) {
		return false;
	}
	sql query { data.data (), data.length () };
	returnString ( Result, query.get () );
	return true;
}

bool Root::parseAppearance ( tVariant* Params, tVariant* Result ) {
	std::wstring code;
	if ( !readWideString ( Params [ 0 ], code, "rules" ) ) {
		return false;
	}
	appearance::appearance parser;
	returnString ( Result, parser.parse ( code ) );
	return true;
}

bool Root::shoot ( tVariant* Params, tVariant* Result ) {
	std::wstring title;
	if ( !readWideString ( Params [ 0 ], title, "title" ) ) {
		return false;
	}
#if __linux__
	Shooter screenshot;
	std::optional<Shooter::RawBuffer> result;
	try {
		result = screenshot.Take ( title );
	} catch ( std::regex_error& error ) {
		ShowError ( error.what () );
		return false;
	} catch ( ... ) {
		// There is no reason to notify client about internal stuff
		return true;
	}
	if ( result != std::nullopt ) {
		getPicture ( result.value (), Result );
	}
#elif _WIN32
	Shooter screenshot;
	std::optional<IStream*> result;
	try {
		result = screenshot.Window ( title.data (), ( Params + 1 )->bVal );
	} catch ( std::regex_error& error ) {
		ShowError ( error.what () );
		return false;
	} catch ( ... ) {
		ShowError ( "Method screenshot.Window caused an internal error" );
		return false;
	}
	if ( result ) {
		getPicture ( result.value (), Result );
	}
#endif
	return true;
}

#if __linux__
void Root::getPicture ( Shooter::RawBuffer& Buffer, tVariant* Result ) const {
	auto size = Buffer.Size;
	auto source = Buffer.Buffer;
	if ( allocate ( size, &Result->pstrVal ) ) {
		auto destination = Result->pstrVal;
		Result->strLen = size;
		Result->vt = VTYPE_BLOB;
		while ( size-- ) {
			*destination++ = *source++;
		}
	}
}
#elif _WIN32
void Root::getPicture ( IStream* Image, tVariant* Result ) const {
	STATSTG info;
	auto result = Image->Stat ( &info, STATFLAG_NONAME );
	if ( result != S_OK ) {
		Image->Release ();
		return;
	}
	auto& size = info.cbSize.QuadPart;
	if ( size && allocate ( size, &Result->pstrVal ) ) {
		ULONG copied;
		result = Image->Read ( Result->pstrVal, size, &copied );
		if ( result == S_OK ) {
			Result->strLen = copied;
			Result->vt = VTYPE_BLOB;
		}
	}
	Image->Release ();
}
#endif

bool Root::maximize ( tVariant* Params ) {
	std::wstring title;
	if ( !readWideString ( Params [ 0 ], title, "title" ) ) {
		return false;
	}
#ifdef __linux__
	Shooter processor;
#elif _WIN32
	Expander processor;
#endif
	try {
		processor.Maximize ( title.data () );
	} catch ( std::regex_error& error ) {
		ShowError ( error.what () );
		return false;
	} catch ( ... ) {
		ShowError ( "Method maximize caused an internal error" );
		return false;
	}
	return true;
}

bool Root::minimize ( tVariant* Params ) {
	std::wstring title;
	if ( !readWideString ( Params [ 0 ], title, "title" ) ) {
		return false;
	}
#ifdef __linux__
	Shooter processor;
#elif _WIN32
	Expander processor;
#endif
	try {
		processor.Minimize ( title.data () );
	} catch ( std::regex_error& error ) {
		ShowError ( error.what () );
		return false;
	} catch ( ... ) {
		ShowError ( "Method minimize caused an internal error" );
		return false;
	}
	return true;
}

bool Root::getHash ( tVariant* Params, tVariant* Result ) {
	std::wstring originalPath;
	if ( !readWideString ( Params [ 0 ], originalPath, "path" ) ) {
		return false;
	}
	const auto path = Chars::wideToPath ( originalPath );
	try {
		returnString ( Result, std::to_wstring ( files::toHash ( path ) ) );
		return true;
	} catch ( const std::exception& error ) {
		ShowError ( error.what () );
		return false;
	}
}

bool Root::getStringHash ( tVariant* Params, tVariant* Result ) {
	std::string data;
	if ( !readString ( Params [ 0 ], data, "string" ) ) {
		return false;
	}
	const auto addBOM = Params [ 1 ].bVal;
	returnString ( Result, std::to_wstring ( strings::toHash ( data, addBOM ) ) );
	return true;
}

bool Root::compareJSON ( tVariant* Params, tVariant* Result ) {
	std::string json1, json2;
	if ( !readString ( Params [ 0 ], json1, "json1" ) ||
			 !readString ( Params [ 1 ], json2, "json2" ) ) {
		return false;
	}
	try {
		strings::trim ( json1 );
		strings::trim ( json2 );
		returnString ( Result,
									 Chars::stringToWide ( JSON::compare ( json1, json2 ) ) );
		return true;
	} catch ( const std::exception& error ) {
		ShowError ( error.what () );
		return false;
	}
}

void Root::pause ( tVariant* Params ) {
	if ( Params->vt == VTYPE_EMPTY )
		return;
	auto seconds { getNumber ( Params ) };
#if __linux__
	sleep ( seconds );
#elif _WIN32
	Sleep ( 1000 * seconds );
#endif
}

bool Root::getEnvironment ( tVariant* Params, tVariant* Result ) {
	std::wstring result;
	std::wstring variable;
	if ( !readWideString ( Params [ 0 ], variable, "variable" ) ) {
		return false;
	}
#if __linux__
	auto value = std::getenv ( Chars::wideToString ( variable ).data () );
	if ( value ) {
		result = Chars::stringToWide ( value );
	}
#elif _WIN32
	auto variableName = variable.data ();
	size_t requiredSize;
	_wgetenv_s ( &requiredSize, nullptr, 0, variableName );
	if ( requiredSize > 0 ) {
		auto value =
				static_cast<wchar_t*> ( malloc ( requiredSize * sizeof ( wchar_t ) ) );
		if ( value ) {
			_wgetenv_s ( &requiredSize, value, requiredSize, variableName );
			result = value;
			free ( value );
		}
	}
#endif
	returnString ( Result, result );
	return true;
}

void Root::gotoConsole ( [[maybe_unused]] tVariant* Params ) {
#if _WIN32
	DWORD session;
	auto process = GetCurrentProcessId ();
	if ( !ProcessIdToSessionId ( process, &session ) ) {
		return;
	}
	std::ostringstream stream;
	stream << session;
	std::string cmd = "tscon " + stream.str () + " /dest:console";
#if _WIN64
	system ( cmd.data () );
#else
	system ( ( std::string ( "%windir%\\sysnative\\" ) + cmd ).data () );
#endif
#endif
}
