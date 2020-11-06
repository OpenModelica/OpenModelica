#ifdef OMC_BASE_FILE
#define OMC_FILE OMC_BASE_FILE
#else
#define OMC_FILE "/home/mahge/dev/OpenModelica/OMCompiler/Compiler/boot/build/tmp/Flags.c"
#endif
#include "omc_simulation_settings.h"
#include "Flags.h"
#include "util/modelica.h"
#include "Flags_includes.h"
DLLExport
modelica_integer omc_Flags_getConfigEnum(threadData_t *threadData, modelica_metatype _inFlag)
{
modelica_integer _outValue;
modelica_integer tmp1;
modelica_metatype tmpMeta[2] __attribute__((unused)) = {0};
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
tmpMeta[0] = omc_Flags_getConfigValue(threadData, _inFlag);
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta[0],7,2) == 0) MMC_THROW_INTERNAL();
tmpMeta[1] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[0]), 2));
tmp1 = mmc_unbox_integer(tmpMeta[1]);
_outValue = tmp1;
_return: OMC_LABEL_UNUSED
return _outValue;
}
modelica_metatype boxptr_Flags_getConfigEnum(threadData_t *threadData, modelica_metatype _inFlag)
{
modelica_integer _outValue;
modelica_metatype out_outValue;
_outValue = omc_Flags_getConfigEnum(threadData, _inFlag);
out_outValue = mmc_mk_icon(_outValue);
return out_outValue;
}
DLLExport
modelica_metatype omc_Flags_getConfigStringList(threadData_t *threadData, modelica_metatype _inFlag)
{
modelica_metatype _outValue = NULL;
modelica_metatype tmpMeta[2] __attribute__((unused)) = {0};
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
tmpMeta[0] = omc_Flags_getConfigValue(threadData, _inFlag);
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta[0],6,1) == 0) MMC_THROW_INTERNAL();
tmpMeta[1] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[0]), 2));
_outValue = tmpMeta[1];
_return: OMC_LABEL_UNUSED
return _outValue;
}
DLLExport
modelica_string omc_Flags_getConfigString(threadData_t *threadData, modelica_metatype _inFlag)
{
modelica_string _outValue = NULL;
modelica_metatype tmpMeta[2] __attribute__((unused)) = {0};
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
tmpMeta[0] = omc_Flags_getConfigValue(threadData, _inFlag);
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta[0],5,1) == 0) MMC_THROW_INTERNAL();
tmpMeta[1] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[0]), 2));
_outValue = tmpMeta[1];
_return: OMC_LABEL_UNUSED
return _outValue;
}
DLLExport
modelica_real omc_Flags_getConfigReal(threadData_t *threadData, modelica_metatype _inFlag)
{
modelica_real _outValue;
modelica_real tmp1;
modelica_metatype tmpMeta[2] __attribute__((unused)) = {0};
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
tmpMeta[0] = omc_Flags_getConfigValue(threadData, _inFlag);
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta[0],4,1) == 0) MMC_THROW_INTERNAL();
tmpMeta[1] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[0]), 2));
tmp1 = mmc_unbox_real(tmpMeta[1]);
_outValue = tmp1;
_return: OMC_LABEL_UNUSED
return _outValue;
}
modelica_metatype boxptr_Flags_getConfigReal(threadData_t *threadData, modelica_metatype _inFlag)
{
modelica_real _outValue;
modelica_metatype out_outValue;
_outValue = omc_Flags_getConfigReal(threadData, _inFlag);
out_outValue = mmc_mk_rcon(_outValue);
return out_outValue;
}
DLLExport
modelica_metatype omc_Flags_getConfigIntList(threadData_t *threadData, modelica_metatype _inFlag)
{
modelica_metatype _outValue = NULL;
modelica_metatype tmpMeta[2] __attribute__((unused)) = {0};
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
tmpMeta[0] = omc_Flags_getConfigValue(threadData, _inFlag);
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta[0],3,1) == 0) MMC_THROW_INTERNAL();
tmpMeta[1] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[0]), 2));
_outValue = tmpMeta[1];
_return: OMC_LABEL_UNUSED
return _outValue;
}
DLLExport
modelica_integer omc_Flags_getConfigInt(threadData_t *threadData, modelica_metatype _inFlag)
{
modelica_integer _outValue;
modelica_integer tmp1;
modelica_metatype tmpMeta[2] __attribute__((unused)) = {0};
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
tmpMeta[0] = omc_Flags_getConfigValue(threadData, _inFlag);
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta[0],2,1) == 0) MMC_THROW_INTERNAL();
tmpMeta[1] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[0]), 2));
tmp1 = mmc_unbox_integer(tmpMeta[1]);
_outValue = tmp1;
_return: OMC_LABEL_UNUSED
return _outValue;
}
modelica_metatype boxptr_Flags_getConfigInt(threadData_t *threadData, modelica_metatype _inFlag)
{
modelica_integer _outValue;
modelica_metatype out_outValue;
_outValue = omc_Flags_getConfigInt(threadData, _inFlag);
out_outValue = mmc_mk_icon(_outValue);
return out_outValue;
}
DLLExport
modelica_boolean omc_Flags_getConfigBool(threadData_t *threadData, modelica_metatype _inFlag)
{
modelica_boolean _outValue;
modelica_integer tmp1;
modelica_metatype tmpMeta[2] __attribute__((unused)) = {0};
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
tmpMeta[0] = omc_Flags_getConfigValue(threadData, _inFlag);
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta[0],1,1) == 0) MMC_THROW_INTERNAL();
tmpMeta[1] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[0]), 2));
tmp1 = mmc_unbox_integer(tmpMeta[1]);
_outValue = tmp1;
_return: OMC_LABEL_UNUSED
return _outValue;
}
modelica_metatype boxptr_Flags_getConfigBool(threadData_t *threadData, modelica_metatype _inFlag)
{
modelica_boolean _outValue;
modelica_metatype out_outValue;
_outValue = omc_Flags_getConfigBool(threadData, _inFlag);
out_outValue = mmc_mk_icon(_outValue);
return out_outValue;
}
DLLExport
modelica_metatype omc_Flags_getConfigValue(threadData_t *threadData, modelica_metatype _inFlag)
{
modelica_metatype _outValue = NULL;
modelica_metatype _config_flags = NULL;
modelica_integer _index;
modelica_metatype _flags = NULL;
modelica_string _name = NULL;
modelica_integer tmp1;
modelica_metatype tmpMeta[3] __attribute__((unused)) = {0};
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
tmpMeta[0] = _inFlag;
tmpMeta[1] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[0]), 2));
tmp1 = mmc_unbox_integer(tmpMeta[1]);
tmpMeta[2] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[0]), 3));
_index = tmp1;
_name = tmpMeta[2];
_flags = omc_Flags_getFlags(threadData, 1);
tmpMeta[0] = _flags;
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta[0],0,2) == 0) MMC_THROW_INTERNAL();
tmpMeta[1] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[0]), 3));
_config_flags = tmpMeta[1];
_outValue = arrayGet(_config_flags, _index);
_return: OMC_LABEL_UNUSED
return _outValue;
}
DLLExport
modelica_boolean omc_Flags_isSet(threadData_t *threadData, modelica_metatype _inFlag)
{
modelica_boolean _outValue;
modelica_metatype _debug_flags = NULL;
modelica_metatype _flags = NULL;
modelica_integer _index;
modelica_integer tmp1;
modelica_metatype tmpMeta[2] __attribute__((unused)) = {0};
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
tmpMeta[0] = _inFlag;
tmpMeta[1] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[0]), 2));
tmp1 = mmc_unbox_integer(tmpMeta[1]);
_index = tmp1;
_flags = omc_Flags_getFlags(threadData, 1);
tmpMeta[0] = _flags;
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta[0],0,2) == 0) MMC_THROW_INTERNAL();
tmpMeta[1] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[0]), 2));
_debug_flags = tmpMeta[1];
_outValue = mmc_unbox_boolean(arrayGet(_debug_flags, _index));
_return: OMC_LABEL_UNUSED
return _outValue;
}
modelica_metatype boxptr_Flags_isSet(threadData_t *threadData, modelica_metatype _inFlag)
{
modelica_boolean _outValue;
modelica_metatype out_outValue;
_outValue = omc_Flags_isSet(threadData, _inFlag);
out_outValue = mmc_mk_icon(_outValue);
return out_outValue;
}
DLLExport
modelica_metatype omc_Flags_getFlags(threadData_t *threadData, modelica_boolean _initialize)
{
modelica_metatype _flags = NULL;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
_flags = getGlobalRoot(((modelica_integer) 17));
_return: OMC_LABEL_UNUSED
return _flags;
}
modelica_metatype boxptr_Flags_getFlags(threadData_t *threadData, modelica_metatype _initialize)
{
modelica_integer tmp1;
modelica_metatype _flags = NULL;
tmp1 = mmc_unbox_integer(_initialize);
_flags = omc_Flags_getFlags(threadData, tmp1);
return _flags;
}
