#ifdef OMC_BASE_FILE
#define OMC_FILE OMC_BASE_FILE
#else
#define OMC_FILE "/home/mahge/dev/OpenModelica/OMCompiler/Compiler/boot/build/tmp/ParserExt.c"
#endif
#include "omc_simulation_settings.h"
#include "ParserExt.h"
#define _OMC_LIT0_data "<interactive>"
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT0,13,_OMC_LIT0_data);
#define _OMC_LIT0 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT0)
#include "util/modelica.h"
#include "ParserExt_includes.h"
void omc_ParserExt_stopLibraryVendorExecutable(threadData_t *threadData, modelica_metatype _lveInstance)
{
modelica_metatype _lveInstance_ext;
_lveInstance_ext = (modelica_metatype)_lveInstance;
ParserExt_stopLibraryVendorExecutable(_lveInstance_ext);
return;
}
void omc_ParserExt_checkLVEToolFeature(threadData_t *threadData, modelica_metatype _lveInstance, modelica_string _feature)
{
modelica_metatype _lveInstance_ext;
_lveInstance_ext = (modelica_metatype)_lveInstance;
ParserExt_checkLVEToolFeature(_lveInstance_ext, MMC_STRINGDATA(_feature));
return;
}
modelica_boolean omc_ParserExt_checkLVEToolLicense(threadData_t *threadData, modelica_metatype _lveInstance, modelica_string _packageName)
{
modelica_metatype _lveInstance_ext;
int _status_ext;
modelica_boolean _status;
_lveInstance_ext = (modelica_metatype)_lveInstance;
_status_ext = ParserExt_checkLVEToolLicense(_lveInstance_ext, MMC_STRINGDATA(_packageName));
_status = (modelica_boolean)_status_ext;
return _status;
}
modelica_metatype boxptr_ParserExt_checkLVEToolLicense(threadData_t *threadData, modelica_metatype _lveInstance, modelica_metatype _packageName)
{
modelica_boolean _status;
modelica_metatype out_status;
_status = omc_ParserExt_checkLVEToolLicense(threadData, _lveInstance, _packageName);
out_status = mmc_mk_icon(_status);
return out_status;
}
modelica_boolean omc_ParserExt_startLibraryVendorExecutable(threadData_t *threadData, modelica_string _lvePath, modelica_metatype *out_lveInstance)
{
modelica_metatype _lveInstance_ext;
int _success_ext;
modelica_boolean _success;
modelica_metatype _lveInstance = NULL;
_success_ext = ParserExt_startLibraryVendorExecutable(MMC_STRINGDATA(_lvePath), &_lveInstance_ext);
_lveInstance = (modelica_metatype)_lveInstance_ext;
_success = (modelica_boolean)_success_ext;
if (out_lveInstance) { *out_lveInstance = _lveInstance; }
return _success;
}
modelica_metatype boxptr_ParserExt_startLibraryVendorExecutable(threadData_t *threadData, modelica_metatype _lvePath, modelica_metatype *out_lveInstance)
{
modelica_boolean _success;
modelica_metatype out_success;
_success = omc_ParserExt_startLibraryVendorExecutable(threadData, _lvePath, out_lveInstance);
out_success = mmc_mk_icon(_success);
return out_success;
}
modelica_metatype omc_ParserExt_stringCref(threadData_t *threadData, modelica_string _str, modelica_string _infoFilename, modelica_integer _acceptedGram, modelica_integer _languageStandardInt, modelica_boolean _runningTestsuite)
{
int _acceptedGram_ext;
int _languageStandardInt_ext;
int _runningTestsuite_ext;
modelica_metatype _cref_ext;
modelica_metatype _cref = NULL;
_acceptedGram_ext = (int)_acceptedGram;
_languageStandardInt_ext = (int)_languageStandardInt;
_runningTestsuite_ext = (int)_runningTestsuite;
_cref_ext = ParserExt_stringCref(MMC_STRINGDATA(_str), MMC_STRINGDATA(_infoFilename), _acceptedGram_ext, _languageStandardInt_ext, _runningTestsuite_ext);
_cref = (modelica_metatype)_cref_ext;
return _cref;
}
modelica_metatype boxptr_ParserExt_stringCref(threadData_t *threadData, modelica_metatype _str, modelica_metatype _infoFilename, modelica_metatype _acceptedGram, modelica_metatype _languageStandardInt, modelica_metatype _runningTestsuite)
{
modelica_integer tmp1;
modelica_integer tmp2;
modelica_integer tmp3;
modelica_metatype _cref = NULL;
tmp1 = mmc_unbox_integer(_acceptedGram);
tmp2 = mmc_unbox_integer(_languageStandardInt);
tmp3 = mmc_unbox_integer(_runningTestsuite);
_cref = omc_ParserExt_stringCref(threadData, _str, _infoFilename, tmp1, tmp2, tmp3);
return _cref;
}
modelica_metatype omc_ParserExt_stringPath(threadData_t *threadData, modelica_string _str, modelica_string _infoFilename, modelica_integer _acceptedGram, modelica_integer _languageStandardInt, modelica_boolean _runningTestsuite)
{
int _acceptedGram_ext;
int _languageStandardInt_ext;
int _runningTestsuite_ext;
modelica_metatype _path_ext;
modelica_metatype _path = NULL;
_acceptedGram_ext = (int)_acceptedGram;
_languageStandardInt_ext = (int)_languageStandardInt;
_runningTestsuite_ext = (int)_runningTestsuite;
_path_ext = ParserExt_stringPath(MMC_STRINGDATA(_str), MMC_STRINGDATA(_infoFilename), _acceptedGram_ext, _languageStandardInt_ext, _runningTestsuite_ext);
_path = (modelica_metatype)_path_ext;
return _path;
}
modelica_metatype boxptr_ParserExt_stringPath(threadData_t *threadData, modelica_metatype _str, modelica_metatype _infoFilename, modelica_metatype _acceptedGram, modelica_metatype _languageStandardInt, modelica_metatype _runningTestsuite)
{
modelica_integer tmp1;
modelica_integer tmp2;
modelica_integer tmp3;
modelica_metatype _path = NULL;
tmp1 = mmc_unbox_integer(_acceptedGram);
tmp2 = mmc_unbox_integer(_languageStandardInt);
tmp3 = mmc_unbox_integer(_runningTestsuite);
_path = omc_ParserExt_stringPath(threadData, _str, _infoFilename, tmp1, tmp2, tmp3);
return _path;
}
modelica_metatype omc_ParserExt_parsestringexp(threadData_t *threadData, modelica_string _str, modelica_string _infoFilename, modelica_integer _acceptedGram, modelica_integer _languageStandardInt, modelica_boolean _runningTestsuite)
{
int _acceptedGram_ext;
int _languageStandardInt_ext;
int _runningTestsuite_ext;
modelica_metatype _outStatements_ext;
modelica_metatype _outStatements = NULL;
_acceptedGram_ext = (int)_acceptedGram;
_languageStandardInt_ext = (int)_languageStandardInt;
_runningTestsuite_ext = (int)_runningTestsuite;
_outStatements_ext = ParserExt_parsestringexp(MMC_STRINGDATA(_str), MMC_STRINGDATA(_infoFilename), _acceptedGram_ext, _languageStandardInt_ext, _runningTestsuite_ext);
_outStatements = (modelica_metatype)_outStatements_ext;
return _outStatements;
}
modelica_metatype boxptr_ParserExt_parsestringexp(threadData_t *threadData, modelica_metatype _str, modelica_metatype _infoFilename, modelica_metatype _acceptedGram, modelica_metatype _languageStandardInt, modelica_metatype _runningTestsuite)
{
modelica_integer tmp1;
modelica_integer tmp2;
modelica_integer tmp3;
modelica_metatype _outStatements = NULL;
tmp1 = mmc_unbox_integer(_acceptedGram);
tmp2 = mmc_unbox_integer(_languageStandardInt);
tmp3 = mmc_unbox_integer(_runningTestsuite);
_outStatements = omc_ParserExt_parsestringexp(threadData, _str, _infoFilename, tmp1, tmp2, tmp3);
return _outStatements;
}
modelica_metatype omc_ParserExt_parsestring(threadData_t *threadData, modelica_string _str, modelica_string _infoFilename, modelica_integer _acceptedGram, modelica_integer _languageStandardInt, modelica_boolean _runningTestsuite)
{
int _acceptedGram_ext;
int _languageStandardInt_ext;
int _runningTestsuite_ext;
modelica_metatype _outProgram_ext;
modelica_metatype _outProgram = NULL;
_acceptedGram_ext = (int)_acceptedGram;
_languageStandardInt_ext = (int)_languageStandardInt;
_runningTestsuite_ext = (int)_runningTestsuite;
_outProgram_ext = ParserExt_parsestring(MMC_STRINGDATA(_str), MMC_STRINGDATA(_infoFilename), _acceptedGram_ext, _languageStandardInt_ext, 0, _runningTestsuite_ext);
_outProgram = (modelica_metatype)_outProgram_ext;
return _outProgram;
}
modelica_metatype boxptr_ParserExt_parsestring(threadData_t *threadData, modelica_metatype _str, modelica_metatype _infoFilename, modelica_metatype _acceptedGram, modelica_metatype _languageStandardInt, modelica_metatype _runningTestsuite)
{
modelica_integer tmp1;
modelica_integer tmp2;
modelica_integer tmp3;
modelica_metatype _outProgram = NULL;
tmp1 = mmc_unbox_integer(_acceptedGram);
tmp2 = mmc_unbox_integer(_languageStandardInt);
tmp3 = mmc_unbox_integer(_runningTestsuite);
_outProgram = omc_ParserExt_parsestring(threadData, _str, _infoFilename, tmp1, tmp2, tmp3);
return _outProgram;
}
modelica_metatype omc_ParserExt_parseexp(threadData_t *threadData, modelica_string _filename, modelica_string _infoFilename, modelica_integer _acceptedGram, modelica_integer _languageStandardInt, modelica_boolean _runningTestsuite)
{
int _acceptedGram_ext;
int _languageStandardInt_ext;
int _runningTestsuite_ext;
modelica_metatype _outStatements_ext;
modelica_metatype _outStatements = NULL;
_acceptedGram_ext = (int)_acceptedGram;
_languageStandardInt_ext = (int)_languageStandardInt;
_runningTestsuite_ext = (int)_runningTestsuite;
_outStatements_ext = ParserExt_parseexp(MMC_STRINGDATA(_filename), MMC_STRINGDATA(_infoFilename), _acceptedGram_ext, _languageStandardInt_ext, _runningTestsuite_ext);
_outStatements = (modelica_metatype)_outStatements_ext;
return _outStatements;
}
modelica_metatype boxptr_ParserExt_parseexp(threadData_t *threadData, modelica_metatype _filename, modelica_metatype _infoFilename, modelica_metatype _acceptedGram, modelica_metatype _languageStandardInt, modelica_metatype _runningTestsuite)
{
modelica_integer tmp1;
modelica_integer tmp2;
modelica_integer tmp3;
modelica_metatype _outStatements = NULL;
tmp1 = mmc_unbox_integer(_acceptedGram);
tmp2 = mmc_unbox_integer(_languageStandardInt);
tmp3 = mmc_unbox_integer(_runningTestsuite);
_outStatements = omc_ParserExt_parseexp(threadData, _filename, _infoFilename, tmp1, tmp2, tmp3);
return _outStatements;
}
modelica_metatype omc_ParserExt_parse(threadData_t *threadData, modelica_string _filename, modelica_string _infoFilename, modelica_integer _acceptedGram, modelica_string _encoding, modelica_integer _languageStandardInt, modelica_boolean _runningTestsuite, modelica_string _libraryPath, modelica_metatype _lveInstance)
{
int _acceptedGram_ext;
int _languageStandardInt_ext;
int _runningTestsuite_ext;
modelica_metatype _lveInstance_ext;
modelica_metatype _outProgram_ext;
modelica_metatype _outProgram = NULL;
_acceptedGram_ext = (int)_acceptedGram;
_languageStandardInt_ext = (int)_languageStandardInt;
_runningTestsuite_ext = (int)_runningTestsuite;
_lveInstance_ext = (modelica_metatype)_lveInstance;
_outProgram_ext = ParserExt_parse(MMC_STRINGDATA(_filename), MMC_STRINGDATA(_infoFilename), _acceptedGram_ext, _languageStandardInt_ext, 0, MMC_STRINGDATA(_encoding), _runningTestsuite_ext, MMC_STRINGDATA(_libraryPath), _lveInstance_ext);
_outProgram = (modelica_metatype)_outProgram_ext;
return _outProgram;
}
modelica_metatype boxptr_ParserExt_parse(threadData_t *threadData, modelica_metatype _filename, modelica_metatype _infoFilename, modelica_metatype _acceptedGram, modelica_metatype _encoding, modelica_metatype _languageStandardInt, modelica_metatype _runningTestsuite, modelica_metatype _libraryPath, modelica_metatype _lveInstance)
{
modelica_integer tmp1;
modelica_integer tmp2;
modelica_integer tmp3;
modelica_metatype _outProgram = NULL;
tmp1 = mmc_unbox_integer(_acceptedGram);
tmp2 = mmc_unbox_integer(_languageStandardInt);
tmp3 = mmc_unbox_integer(_runningTestsuite);
_outProgram = omc_ParserExt_parse(threadData, _filename, _infoFilename, tmp1, _encoding, tmp2, tmp3, _libraryPath, _lveInstance);
return _outProgram;
}
