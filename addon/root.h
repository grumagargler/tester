#ifndef __root_h__
#define __root_h__
#include "extender.h"
#include "shooter.h"

class Root : public Extender {
public:
	Root ();

private:
	bool augmentQuery ( tVariant* Params );
	bool adjustQuery ( tVariant* Params, tVariant* Result );
	bool queryTables ( tVariant* Params, tVariant* Result );
	bool parseAppearance ( tVariant* Params, tVariant* Result );
	bool shoot ( tVariant* Params, tVariant* Result );
	bool getHash ( tVariant* Params, tVariant* Result );
	bool getStringHash ( tVariant* Params, tVariant* Result );
	bool normalizeNumber ( tVariant* Params, tVariant* Result );
	bool isNumber ( tVariant* Params, tVariant* Result );
	bool readNumberParams ( tVariant* Params, std::wstring& string,
													wchar_t& decimalDelimiter,
													wchar_t& groupDelimiter );
	bool compareJSON ( tVariant* Params, tVariant* Result );
	bool maximize ( tVariant* Params );
	bool minimize ( tVariant* Params );
	static void pause ( tVariant* Params );
	bool getEnvironment ( tVariant* Params, tVariant* Result );
	static void gotoConsole ( [[maybe_unused]] tVariant* Params );
#ifdef __linux__
	void getPicture ( Shooter::RawBuffer& Buffer, tVariant* Result ) const;
#elif _WIN32
	void getPicture ( IStream* Image, tVariant* Result ) const;
#endif
};
#endif
