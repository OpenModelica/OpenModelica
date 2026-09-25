/* The generated literals take &SourceInfo_SOURCEINFO__desc in static
 * initializers, which MSVC cannot resolve against data in another DLL
 * (OpenModelicaRuntimeMMC), so the compiler DLL carries its own copy. */

#include "openmodelica_types.h"

static const char* SourceInfo_SOURCEINFO__desc__fields[7] = {"fileName","isReadOnly","lineNumberStart","columnNumberStart","lineNumberEnd","columnNumberEnd","lastEditTime"};
struct record_description SourceInfo_SOURCEINFO__desc = {
  "SourceInfo_SOURCEINFO",
  "SourceInfo.SOURCEINFO",
  SourceInfo_SOURCEINFO__desc__fields
};
