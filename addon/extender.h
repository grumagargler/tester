#ifndef addin_h
#define addin_h
#include "1c/addindefbase.h"
#include "1c/componentbase.h"
#include "1c/imemorymanager.h"
#include "chars.h"
#include <cstddef>
#include <cstdint>
#include <functional>
#include <iostream>
#include <map>
#include <string_view>

constexpr int BASE_ERRNO = 7;

class Extender : public IComponentBase {
public:
	typedef std::function<bool ( tVariant* Params )> procedure;
	typedef std::function<bool ( tVariant* Params, tVariant* Result )> function;

	Extender () = delete;
	Extender ( const Extender& ) = delete;
	Extender ( Extender&& ) = delete;
	Extender& operator= ( const Extender& ) = delete;
	Extender& operator= ( Extender&& ) = delete;
	explicit Extender ( const std::wstring& Extension );
	~Extender () override;
	bool ADDIN_API Init ( void* Connection ) override;
	bool ADDIN_API setMemManager ( void* Pointer ) override;
	long ADDIN_API GetInfo () override;
	bool ADDIN_API RegisterExtensionAs ( WCHAR_T** Entry ) override;
	bool allocate ( const WCHAR_T* Source, WCHAR_T** Destination ) const;
	bool allocate ( size_t Bytes, char** Destination ) const;
	long ADDIN_API GetNProps () override;
	long ADDIN_API FindProp ( const WCHAR_T* Name ) override;
	const WCHAR_T* ADDIN_API GetPropName ( long Property, long Lang ) override;
	bool ADDIN_API GetPropVal ( long Property, tVariant* Value ) override;
	bool ADDIN_API SetPropVal ( long Property, tVariant* Value ) override;
	bool ADDIN_API IsPropReadable ( long Property ) override;
	bool ADDIN_API IsPropWritable ( long Property ) override;
	long ADDIN_API GetNMethods () override;
	long ADDIN_API FindMethod ( const WCHAR_T* Name ) override;
	const WCHAR_T* ADDIN_API GetMethodName ( long Method, long Lang ) override;
	long ADDIN_API GetNParams ( long Method ) override;
	bool ADDIN_API GetParamDefValue ( long Method, long Parameter,
																		tVariant* Default ) override;
	bool ADDIN_API HasRetVal ( long Method ) override;
	bool ADDIN_API CallAsProc ( long Method, tVariant* Params,
															long Count ) override;
	bool checkParams ( long Method, long Count );
	bool ADDIN_API CallAsFunc ( long Method, tVariant* Result, tVariant* Params,
															long Count ) override;
	void ADDIN_API SetLocale ( const WCHAR_T* Locale ) override;
	void ADDIN_API SetUserInterfaceLanguageCode ( const WCHAR_T* lang ) override;
	void ADDIN_API Done () override;
	void ShowError ( const char* Message ) const;
	void SetError ( std::wstring_view Message );
	void SetError ( std::string_view Message );
	template <typename T> void SendError ( const T& Message ) {
		std::wstring text;
		if constexpr ( std::is_same_v<T, std::wstring> ) {
			text = Message;
		} else if constexpr ( std::is_same_v<T, const char*> ) {
			text = Chars::stringToWide ( std::string ( Message ), true );
		} else {
			text = Chars::stringToWide ( Message, true );
		}
		baseConnector->ExternalEvent ( ExtensionID, ErrorSignature,
																	 Chars::toWchar ( text.data () ).get () );
	}
	void addProcedure ( const wchar_t* English, const wchar_t* Russian,
											int Parameters, procedure Handler );
	void addFunction ( const wchar_t* English, const wchar_t* Russian,
										 int Parameters, function Handler );
	void AddProperty ( const std::wstring& English, const std::wstring& Russian );
	void returnString ( tVariant* Result, const std::wstring& String ) const;
	static void returnBool ( tVariant* Result, bool Value );
	static double getNumber ( tVariant* Params );
	IAddInDefBase* getBaseConnector ();
	WCHAR_T* getExtensionID ();

protected:
	bool isTesting () const;
	bool readWideString ( const tVariant& Param, std::wstring& Value,
												const char* Name );
	bool readString ( const tVariant& Param, std::string& Value,
										const char* Name );

private:
	struct propertiesList {
		int Count { 0 };
		std::map<std::wstring, long> Properties;
		std::map<std::wstring, long> PropertiesRu;
		std::map<long, std::wstring> PropertyKeys;
		std::map<long, std::wstring> PropertyKeysRu;
	};

	struct methodsList {
		int Count { 0 };
		std::map<std::wstring, int> Methods;
		std::map<std::wstring, int> MethodsRu;
		std::map<long, std::wstring> MethodKeys;
		std::map<long, std::wstring> MethodKeysRu;
		std::map<long, bool> HasResult;
		std::map<long, int> Parameters;
		std::map<long, procedure> Procedures;
		std::map<long, function> Functions;
	};

	void addMethod ( const wchar_t* English, const wchar_t* Russian, int Params,
									 bool Function );
	void addError ( uint32_t Code, const wchar_t* Descriptor, long Id ) const;
	long getPropertyIndex ( const wchar_t* Name ) const;
	const WCHAR_T* getName ( std::map<long, std::wstring>& SetEn,
													 std::map<long, std::wstring>& SetRu, long Index,
													 long Lang ) const;
	static long getIndex ( std::map<std::wstring, int>& SetEn,
												 std::map<std::wstring, int>& SetRu,
												 const wchar_t* Name );
	bool testingMode;
	static constexpr WCHAR_T const* ErrorSignature = u"###E###";
	WCHAR_T* ExtensionID;
	const long YellowBuffer { 32758 };
	propertiesList properties;
	methodsList methods;
	IAddInDefBase* baseConnector;
	IMemoryManager* memoryManager;

	std::wstring LastError;

	static void setLicense ( tVariant* Params );
	void setTesting ( tVariant* Params );
	void version ( tVariant* Result );
	void isError ( tVariant* Result );
	void getLastError ( tVariant* Result );
};
#endif
