#include <windows.h>
#include "xml_parser.h"
#include "fmuWrapper.h"

static char* getDecompPath(const char * omPath, const char* mid);
static char* getDllPath(const char* decompPath,const char* mid);
static char* getXMLfile(const char * decompPath, const char * modeldes);
static int decompress(const char* fmuPath, const char* decompPath);
static char* getFMUname(const char* fmupath);
void tmpcodegen(size_t , size_t , const char* , const char*, const char* );
void blockcodegen(ModelDescription*, size_t , size_t , const char* , const char* , const char* , const char* );
