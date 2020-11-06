#ifdef OMC_BASE_FILE
#define OMC_FILE OMC_BASE_FILE
#else
#define OMC_FILE "/home/mahge/dev/OpenModelica/OMCompiler/Compiler/boot/build/tmp/Print.c"
#endif
#include "omc_simulation_settings.h"
#include "Print.h"
#include "util/modelica.h"
#include "Print_includes.h"
modelica_boolean omc_Print_hasBufNewLineAtEnd(threadData_t *threadData)
{
int _outHasNewLineAtEnd_ext;
modelica_boolean _outHasNewLineAtEnd;
_outHasNewLineAtEnd_ext = Print_hasBufNewLineAtEnd(threadData);
_outHasNewLineAtEnd = (modelica_boolean)_outHasNewLineAtEnd_ext;
return _outHasNewLineAtEnd;
}
modelica_metatype boxptr_Print_hasBufNewLineAtEnd(threadData_t *threadData)
{
modelica_boolean _outHasNewLineAtEnd;
modelica_metatype out_outHasNewLineAtEnd;
_outHasNewLineAtEnd = omc_Print_hasBufNewLineAtEnd(threadData);
out_outHasNewLineAtEnd = mmc_mk_icon(_outHasNewLineAtEnd);
return out_outHasNewLineAtEnd;
}
void omc_Print_printBufNewLine(threadData_t *threadData)
{
Print_printBufNewLine(threadData);
return;
}
void omc_Print_printBufSpace(threadData_t *threadData, modelica_integer _inNumOfSpaces)
{
int _inNumOfSpaces_ext;
_inNumOfSpaces_ext = (int)_inNumOfSpaces;
Print_printBufSpace(threadData, _inNumOfSpaces_ext);
return;
}
void boxptr_Print_printBufSpace(threadData_t *threadData, modelica_metatype _inNumOfSpaces)
{
modelica_integer tmp1;
tmp1 = mmc_unbox_integer(_inNumOfSpaces);
omc_Print_printBufSpace(threadData, tmp1);
return;
}
modelica_integer omc_Print_getBufLength(threadData_t *threadData)
{
int _outBufFilledLength_ext;
modelica_integer _outBufFilledLength;
_outBufFilledLength_ext = Print_getBufLength(threadData);
_outBufFilledLength = (modelica_integer)_outBufFilledLength_ext;
return _outBufFilledLength;
}
modelica_metatype boxptr_Print_getBufLength(threadData_t *threadData)
{
modelica_integer _outBufFilledLength;
modelica_metatype out_outBufFilledLength;
_outBufFilledLength = omc_Print_getBufLength(threadData);
out_outBufFilledLength = mmc_mk_icon(_outBufFilledLength);
return out_outBufFilledLength;
}
void omc_Print_writeBufConvertLines(threadData_t *threadData, modelica_string _filename)
{
Print_writeBufConvertLines(threadData, MMC_STRINGDATA(_filename));
return;
}
void omc_Print_writeBuf(threadData_t *threadData, modelica_string _filename)
{
Print_writeBuf(threadData, MMC_STRINGDATA(_filename));
return;
}
modelica_string omc_Print_getString(threadData_t *threadData)
{
const char* _outString_ext;
modelica_string _outString = NULL;
_outString_ext = Print_getString(threadData);
_outString = (modelica_string)mmc_mk_scon(_outString_ext);
return _outString;
}
void omc_Print_clearBuf(threadData_t *threadData)
{
Print_clearBuf(threadData);
return;
}
void omc_Print_printBuf(threadData_t *threadData, modelica_string _inString)
{
Print_printBuf(threadData, MMC_STRINGDATA(_inString));
return;
}
modelica_string omc_Print_getErrorString(threadData_t *threadData)
{
const char* _outString_ext;
modelica_string _outString = NULL;
_outString_ext = Print_getErrorString(threadData);
_outString = (modelica_string)mmc_mk_scon(_outString_ext);
return _outString;
}
void omc_Print_clearErrorBuf(threadData_t *threadData)
{
Print_clearErrorBuf(threadData);
return;
}
void omc_Print_printErrorBuf(threadData_t *threadData, modelica_string _inString)
{
Print_printErrorBuf(threadData, MMC_STRINGDATA(_inString));
return;
}
void omc_Print_restoreBuf(threadData_t *threadData, modelica_integer _handle)
{
int _handle_ext;
_handle_ext = (int)_handle;
Print_restoreBuf(threadData, _handle_ext);
return;
}
void boxptr_Print_restoreBuf(threadData_t *threadData, modelica_metatype _handle)
{
modelica_integer tmp1;
tmp1 = mmc_unbox_integer(_handle);
omc_Print_restoreBuf(threadData, tmp1);
return;
}
modelica_integer omc_Print_saveAndClearBuf(threadData_t *threadData)
{
int _handle_ext;
modelica_integer _handle;
_handle_ext = Print_saveAndClearBuf(threadData);
_handle = (modelica_integer)_handle_ext;
return _handle;
}
modelica_metatype boxptr_Print_saveAndClearBuf(threadData_t *threadData)
{
modelica_integer _handle;
modelica_metatype out_handle;
_handle = omc_Print_saveAndClearBuf(threadData);
out_handle = mmc_mk_icon(_handle);
return out_handle;
}
