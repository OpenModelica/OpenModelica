#ifdef OMC_BASE_FILE
#define OMC_FILE OMC_BASE_FILE
#else
#define OMC_FILE "/home/mahge/dev/OpenModelica/OMCompiler/Compiler/boot/build/tmp/UnitParserExt.c"
#endif
#include "omc_simulation_settings.h"
#include "UnitParserExt.h"
#include "util/modelica.h"
#include "UnitParserExt_includes.h"
void omc_UnitParserExt_commit(threadData_t *threadData)
{
UnitParserExtImpl__commit();
return;
}
void omc_UnitParserExt_clear(threadData_t *threadData)
{
UnitParserExtImpl__clear();
return;
}
void omc_UnitParserExt_rollback(threadData_t *threadData)
{
UnitParserExtImpl__rollback();
return;
}
void omc_UnitParserExt_checkpoint(threadData_t *threadData)
{
UnitParserExtImpl__checkpoint();
return;
}
void omc_UnitParserExt_addDerivedWeight(threadData_t *threadData, modelica_string _name, modelica_string _exp, modelica_real _weight)
{
double _weight_ext;
_weight_ext = (double)_weight;
UnitParserExtImpl__addDerivedWeight(MMC_STRINGDATA(_name), MMC_STRINGDATA(_exp), _weight_ext);
return;
}
void boxptr_UnitParserExt_addDerivedWeight(threadData_t *threadData, modelica_metatype _name, modelica_metatype _exp, modelica_metatype _weight)
{
modelica_real tmp1;
tmp1 = mmc_unbox_real(_weight);
omc_UnitParserExt_addDerivedWeight(threadData, _name, _exp, tmp1);
return;
}
void omc_UnitParserExt_addDerived(threadData_t *threadData, modelica_string _name, modelica_string _exp)
{
UnitParserExtImpl__addDerived(MMC_STRINGDATA(_name), MMC_STRINGDATA(_exp));
return;
}
void omc_UnitParserExt_registerWeight(threadData_t *threadData, modelica_string _name, modelica_real _weight)
{
double _weight_ext;
_weight_ext = (double)_weight;
UnitParserExtImpl__registerWeight(MMC_STRINGDATA(_name), _weight_ext);
return;
}
void boxptr_UnitParserExt_registerWeight(threadData_t *threadData, modelica_metatype _name, modelica_metatype _weight)
{
modelica_real tmp1;
tmp1 = mmc_unbox_real(_weight);
omc_UnitParserExt_registerWeight(threadData, _name, tmp1);
return;
}
void omc_UnitParserExt_addBase(threadData_t *threadData, modelica_string _name)
{
UnitParserExtImpl__addBase(MMC_STRINGDATA(_name));
return;
}
modelica_metatype omc_UnitParserExt_allUnitSymbols(threadData_t *threadData)
{
modelica_metatype _unitSymbols_ext;
modelica_metatype _unitSymbols = NULL;
_unitSymbols_ext = UnitParserExtImpl__allUnitSymbols();
_unitSymbols = (modelica_metatype)_unitSymbols_ext;
return _unitSymbols;
}
modelica_metatype omc_UnitParserExt_str2unit(threadData_t *threadData, modelica_string _res, modelica_metatype *out_denoms, modelica_metatype *out_tpnoms, modelica_metatype *out_tpdenoms, modelica_metatype *out_tpstrs, modelica_real *out_scaleFactor, modelica_real *out_offset)
{
modelica_metatype _noms_ext;
modelica_metatype _denoms_ext;
modelica_metatype _tpnoms_ext;
modelica_metatype _tpdenoms_ext;
modelica_metatype _tpstrs_ext;
double _scaleFactor_ext;
double _offset_ext;
modelica_metatype _noms = NULL;
modelica_metatype _denoms = NULL;
modelica_metatype _tpnoms = NULL;
modelica_metatype _tpdenoms = NULL;
modelica_metatype _tpstrs = NULL;
modelica_real _scaleFactor;
modelica_real _offset;
UnitParserExt_str2unit(MMC_STRINGDATA(_res), &_noms_ext, &_denoms_ext, &_tpnoms_ext, &_tpdenoms_ext, &_tpstrs_ext, &_scaleFactor_ext, &_offset_ext);
_noms = (modelica_metatype)_noms_ext;
_denoms = (modelica_metatype)_denoms_ext;
_tpnoms = (modelica_metatype)_tpnoms_ext;
_tpdenoms = (modelica_metatype)_tpdenoms_ext;
_tpstrs = (modelica_metatype)_tpstrs_ext;
_scaleFactor = (modelica_real)_scaleFactor_ext;
_offset = (modelica_real)_offset_ext;
if (out_denoms) { *out_denoms = _denoms; }
if (out_tpnoms) { *out_tpnoms = _tpnoms; }
if (out_tpdenoms) { *out_tpdenoms = _tpdenoms; }
if (out_tpstrs) { *out_tpstrs = _tpstrs; }
if (out_scaleFactor) { *out_scaleFactor = _scaleFactor; }
if (out_offset) { *out_offset = _offset; }
return _noms;
}
modelica_metatype boxptr_UnitParserExt_str2unit(threadData_t *threadData, modelica_metatype _res, modelica_metatype *out_denoms, modelica_metatype *out_tpnoms, modelica_metatype *out_tpdenoms, modelica_metatype *out_tpstrs, modelica_metatype *out_scaleFactor, modelica_metatype *out_offset)
{
modelica_real _scaleFactor;
modelica_real _offset;
modelica_metatype _noms = NULL;
_noms = omc_UnitParserExt_str2unit(threadData, _res, out_denoms, out_tpnoms, out_tpdenoms, out_tpstrs, &_scaleFactor, &_offset);
if (out_scaleFactor) { *out_scaleFactor = mmc_mk_rcon(_scaleFactor); }
if (out_offset) { *out_offset = mmc_mk_rcon(_offset); }
return _noms;
}
modelica_string omc_UnitParserExt_unit2str(threadData_t *threadData, modelica_metatype _noms, modelica_metatype _denoms, modelica_metatype _tpnoms, modelica_metatype _tpdenoms, modelica_metatype _tpstrs, modelica_real _scaleFactor, modelica_real _offset)
{
modelica_metatype _noms_ext;
modelica_metatype _denoms_ext;
modelica_metatype _tpnoms_ext;
modelica_metatype _tpdenoms_ext;
modelica_metatype _tpstrs_ext;
double _scaleFactor_ext;
double _offset_ext;
const char* _res_ext;
modelica_string _res = NULL;
_noms_ext = (modelica_metatype)_noms;
_denoms_ext = (modelica_metatype)_denoms;
_tpnoms_ext = (modelica_metatype)_tpnoms;
_tpdenoms_ext = (modelica_metatype)_tpdenoms;
_tpstrs_ext = (modelica_metatype)_tpstrs;
_scaleFactor_ext = (double)_scaleFactor;
_offset_ext = (double)_offset;
_res_ext = UnitParserExt_unit2str(_noms_ext, _denoms_ext, _tpnoms_ext, _tpdenoms_ext, _tpstrs_ext, _scaleFactor_ext, _offset_ext);
_res = (modelica_string)mmc_mk_scon(_res_ext);
return _res;
}
modelica_metatype boxptr_UnitParserExt_unit2str(threadData_t *threadData, modelica_metatype _noms, modelica_metatype _denoms, modelica_metatype _tpnoms, modelica_metatype _tpdenoms, modelica_metatype _tpstrs, modelica_metatype _scaleFactor, modelica_metatype _offset)
{
modelica_real tmp1;
modelica_real tmp2;
modelica_string _res = NULL;
tmp1 = mmc_unbox_real(_scaleFactor);
tmp2 = mmc_unbox_real(_offset);
_res = omc_UnitParserExt_unit2str(threadData, _noms, _denoms, _tpnoms, _tpdenoms, _tpstrs, tmp1, tmp2);
return _res;
}
void omc_UnitParserExt_initSIUnits(threadData_t *threadData)
{
UnitParserExtImpl__initSIUnits();
return;
}
