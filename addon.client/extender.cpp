#include "extender.h"
#include <chrono>
#include <cstdint>
#include <limits>
#include <mutex>
#include <iostream>
#ifdef __linux__
#include <cwchar>
#include <utility>
#elif _WIN32
#include <clocale>
#endif

// NOLINTBEGIN(cppcoreguidelines-pro-bounds-pointer-arithmetic)

Extender::Extender ( const std::wstring &Extension )
	: testingMode ( false ), baseConnector ( nullptr ), memoryManager ( nullptr ) {
	ExtensionID = nullptr;
	Chars::ToWCHAR ( &ExtensionID, Extension.data () );
	addFunction ( L"Version", L"Версия", 0, [ & ] ( tVariant *, tVariant *Result ) {
		version ( Result );
		return true;
		} );
	addFunction ( L"Problem", L"Проблема", 0, [ & ] ( tVariant *, tVariant *Result ) {
		getLastError ( Result );
		return true;
		} );
	addFunction ( L"Error", L"Ошибка", 0, [ & ] ( tVariant *, tVariant *Result ) {
		isError ( Result );
		return true;
		} );
	addProcedure ( L"SetLicense", L"УстановитьЛицензию", 1, [ & ] ( tVariant *Params ) {
		setLicense ( Params );
		return true;
		} );
	addProcedure ( L"SetTestingMode", L"УстановитьРежимТестирования", 1, [ & ] ( tVariant *Params ) {
		setTesting ( Params );
		return true;
		} );
}

Extender::~Extender () {
	delete [] ExtensionID;
}

void Extender::setTesting ( tVariant *Params ) {
	testingMode = Params->bVal;
}

void Extender::setLicense ( tVariant *Params ) {
	// TODO
}

// NOLINTBEGIN(cppcoreguidelines-narrowing-conversions)
// NOLINTBEGIN(bugprone-narrowing-conversions)
double Extender::getNumber ( tVariant *Params ) {
	switch ( Params->vt ) {
	case VTYPE_I2:
		return Params->shortVal;
	case VTYPE_I4:
		return Params->lVal;
	case VTYPE_R4:
		return Params->fltVal;
	case VTYPE_R8:
		return Params->dblVal;
	case VTYPE_ERROR:
		return Params->errCode;
	case VTYPE_BOOL:
		return Params->bVal;
	case VTYPE_I1:
		return Params->i8Val;
	case VTYPE_UI1:
		return Params->ui8Val;
	case VTYPE_UI2:
		return Params->ushortVal;
	case VTYPE_UI4:
		return Params->ulVal;
	case VTYPE_I8:
		return Params->llVal;
	case VTYPE_UI8:
		return Params->ullVal;
	case VTYPE_INT:
		return Params->intVal;
	case VTYPE_UINT:
		return Params->uintVal;
	default:
		return 0;
	}
}
// NOLINTEND(bugprone-narrowing-conversions)
// NOLINTEND(cppcoreguidelines-narrowing-conversions)

IAddInDefBase *Extender::getBaseConnector () {
	return baseConnector;
}

WCHAR_T *Extender::getExtensionID () {
	return ExtensionID;
}

bool Extender::Init ( void *Connection ) {
	baseConnector = static_cast<IAddInDefBase *>( Connection );
	baseConnector->SetEventBufferDepth ( YellowBuffer );
	return baseConnector != nullptr;
}

bool Extender::setMemManager ( void *Pointer ) {
	memoryManager = static_cast<IMemoryManager *>( Pointer );
	return memoryManager != nullptr;
}

long Extender::GetInfo () {
	return 9040;
}

bool Extender::RegisterExtensionAs ( WCHAR_T **Entry ) {
	return allocate ( ExtensionID, Entry );
}

bool Extender::allocate ( const WCHAR_T *Source, WCHAR_T **Destination ) const {
	if ( !memoryManager ) {
		return false;
	}
	auto size = Chars::WCHARLength ( Source ) + 1;
	if ( !memoryManager->AllocMemory ( reinterpret_cast<void **>( Destination ), size * sizeof ( WCHAR_T ) ) ) {
		return false;
	}
	auto to = *Destination;
	while ( size-- ) *to++ = *Source++;
	return true;
}

bool Extender::allocate ( size_t Bytes, char **Destination ) const {
	if ( !memoryManager ) {
		return false;
	}
	if ( Bytes > std::numeric_limits<unsigned long>::max () ) {
		return false;
	}
	if ( Bytes == 0 ) {
		*Destination = nullptr;
		return true;
	}
	return memoryManager->AllocMemory ( reinterpret_cast<void **>( Destination ), static_cast<unsigned long> ( Bytes ) );
}

long Extender::GetNProps () {
	return properties.Count;
}

long Extender::FindProp ( const WCHAR_T *Name ) {
	return getPropertyIndex ( Chars::FromWCHAR ( Name ).get () );
}

const WCHAR_T *Extender::GetPropName ( long Property, long Lang ) {
	return getName ( properties.PropertyKeys, properties.PropertyKeysRu, Property, Lang );
}

bool Extender::GetPropVal ( long, tVariant * ) {
	return false;
}

bool Extender::SetPropVal ( long, tVariant * ) {
	return false;
}

bool Extender::IsPropReadable ( long ) {
	return false;
}

bool Extender::IsPropWritable ( long ) {
	return false;
}

long Extender::GetNMethods () {
	return methods.Count;
}

long Extender::FindMethod ( const WCHAR_T *Name ) {
	return getIndex ( methods.Methods, methods.MethodsRu, Chars::FromWCHAR ( Name ).get () );
}

const WCHAR_T *Extender::GetMethodName ( long Method, long Lang ) {
	return getName ( methods.MethodKeys, methods.MethodKeysRu, Method, Lang );
}

long Extender::GetNParams ( long Method ) {
	return methods.Parameters [ Method ];
}

bool Extender::GetParamDefValue ( long, long, tVariant *Default ) {
	TV_VT ( Default ) = VTYPE_EMPTY;
	return false;
}

bool Extender::HasRetVal ( long Method ) {
	return methods.HasResult [ Method ];
}

bool Extender::CallAsProc ( long Method, tVariant *Params, long Count ) {
	if ( !checkParams ( Method, Count ) ) return false;
	return methods.Procedures [ Method ] ( Params );
}

bool Extender::checkParams ( long Method, long Count ) {
	return Count == methods.Parameters [ Method ];
}

bool Extender::CallAsFunc ( long Method, tVariant *Result, tVariant *Params, long Count ) {
	if ( !checkParams ( Method, Count ) ) return false;
	return methods.Functions [ Method ] ( Params, Result );
}

void Extender::SetLocale ( const WCHAR_T *Locale ) {
	#if !defined( __linux__ ) && !defined(__APPLE__)
	auto locale = Chars::WCHARToWide ( Locale );
	_wsetlocale ( LC_ALL, locale.data () );
	#else
	//We convert in char* char_locale
	//also we establish locale
	//setlocale(LC_ALL, char_locale);
	#endif
}

void Extender::SetUserInterfaceLanguageCode ( const WCHAR_T *lang ) {
	#if !defined( __linux__ ) && !defined(__APPLE__)
	#else
	//We convert in char* char_locale
	//also we establish locale
	//setlocale(LC_ALL, char_locale);
	#endif
}

void Extender::Done () {}

void Extender::ShowError ( const char *Message ) const {
	auto size = mbstowcs ( nullptr, Message, 0 ) + 1;
	assert ( size );
	auto message = new WCHAR [ size ];
	memset ( message, 0, size * sizeof ( wchar_t ) );
	mbstowcs ( message, Message, size );
	addError ( ADDIN_E_VERY_IMPORTANT, message, 0 );
	delete [] message;
}

void Extender::addError ( uint32_t Code, const wchar_t *Descriptor, long Id ) const {
	if ( baseConnector ) {
		baseConnector->AddError ( Code, ExtensionID, Chars::ToWCHAR ( Descriptor ).get (), Id );
	}
}

void Extender::addProcedure ( const wchar_t *English, const wchar_t *Russian, int Parameters, procedure Handler ) {
	const auto index = addMethod ( English, Russian, Parameters, false );
	methods.Procedures [ index ] = std::move ( Handler );
}

long Extender::addMethod ( const wchar_t *English, const wchar_t *Russian, int Params, bool Function ) {
	const auto index = methods.Count++;
	methods.Methods [ English ] = index;
	methods.MethodsRu [ Russian ] = index;
	methods.MethodKeys [ index ] = English;
	methods.MethodKeysRu [ index ] = Russian;
	methods.HasResult [ index ] = Function;
	methods.Parameters [ index ] = Params;
	return index;
}

void Extender::addFunction ( const wchar_t *English, const wchar_t *Russian, int Parameters, function Handler ) {
	const auto index = addMethod ( English, Russian, Parameters, true );
	methods.Functions [ index ] = std::move ( Handler );
}

void Extender::AddProperty ( const std::wstring &English, const std::wstring &Russian ) {
	const auto index = properties.Count++;
	properties.Properties [ English ] = index;
	properties.PropertiesRu [ Russian ] = index;
	properties.PropertyKeys [ index ] = English;
	properties.PropertyKeysRu [ index ] = Russian;
}

long Extender::getPropertyIndex ( const wchar_t *Name ) const {
	auto value = properties.Properties.find ( Name );
	if ( value == properties.Properties.end () ) {
		value = properties.PropertiesRu.find ( Name );
	} else {
		return value->second;
	}
	if ( value == properties.PropertiesRu.end () ) {
		return -1;
	}
	return value->second;
}

const WCHAR_T *
Extender::getName ( std::map<long, std::wstring> &SetEn, std::map<long, std::wstring> &SetRu, long Index,
	long Lang ) const {
	const wchar_t *name;
	switch ( Lang ) {
	case 0:
		name = SetEn [ Index ].c_str ();
		break;
	case 1:
		name = SetRu [ Index ].c_str ();
		break;
	default:
		return nullptr;
	}
	if ( name [ 0 ] == '\0' ) {
		return nullptr;
	}
	WCHAR_T *yellowName { nullptr };
	if ( allocate ( Chars::ToWCHAR ( name ).get (), &yellowName ) ) {
		return yellowName;
	} else {
		return nullptr;
	}
}

long
Extender::getIndex ( std::map<std::wstring, int> &SetEn, std::map<std::wstring, int> &SetRu, const wchar_t *Name ) {
	auto value = SetEn.find ( Name );
	if ( value == SetEn.end () ) value = SetRu.find ( Name );
	else return value->second;
	if ( value == SetRu.end () ) return -1;
	return value->second;
}

void Extender::returnString ( tVariant *Result, const std::wstring &String ) const {
	auto count = String.size ();
	auto size = ( count + 1 ) * sizeof ( WCHAR_T );
	if ( !size || !memoryManager->AllocMemory ( reinterpret_cast<void **>( &Result->pwstrVal ), size ) ) {
		return;
	}
	Chars::ToWCHAR ( &Result->pwstrVal, String.data () );
	Result->vt = VTYPE_PWSTR;
	Result->wstrLen = count;
}

void Extender::returnBool ( tVariant *Result, bool Value ) {
	Result->vt = VTYPE_BOOL;
	Result->bVal = Value;
}

void Extender::version ( tVariant *Result ) {
	Result->llVal = GetInfo ();
	Result->vt = VTYPE_I4;
}

void Extender::getLastError ( tVariant *Result ) {
	if ( !LastError.empty () ) {
		returnString ( Result, LastError );
		LastError.clear ();
	}
}

void Extender::isError ( tVariant *Result ) {
	returnBool ( Result, !LastError.empty () );
}

// NOLINTEND(cppcoreguidelines-pro-bounds-pointer-arithmetic)
