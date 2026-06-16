#ifndef __metadata_h__
#define __metadata_h__
#include "extender.h"

class Metadata : public Extender {
public:
	Metadata ();

private:
	bool getFormInfo ( tVariant* Params, tVariant* Result );
	bool getFormDataPaths ( tVariant* Params, tVariant* Result );
};
#endif
