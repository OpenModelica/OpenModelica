#ifdef OMC_BASE_FILE
#define OMC_FILE OMC_BASE_FILE
#else
#define OMC_FILE "/home/mahge/dev/OpenModelica/OMCompiler/Compiler/boot/build/tmp/ErrorExt.c"
#endif
#include "omc_simulation_settings.h"
#include "ErrorExt.h"
#include "util/modelica.h"
#include "ErrorExt_includes.h"
void omc_ErrorExt_initAssertionFunctions(threadData_t *threadData)
{
Error_initAssertionFunctions();
return;
}
void omc_ErrorExt_moveMessagesToParentThread(threadData_t *threadData)
{
Error_moveMessagesToParentThread(threadData);
return;
}
void omc_ErrorExt_setShowErrorMessages(threadData_t *threadData, modelica_boolean _inShow)
{
int _inShow_ext;
_inShow_ext = (int)_inShow;
Error_setShowErrorMessages(threadData, _inShow_ext);
return;
}
void boxptr_ErrorExt_setShowErrorMessages(threadData_t *threadData, modelica_metatype _inShow)
{
modelica_integer tmp1;
tmp1 = mmc_unbox_integer(_inShow);
omc_ErrorExt_setShowErrorMessages(threadData, tmp1);
return;
}
modelica_boolean omc_ErrorExt_isTopCheckpoint(threadData_t *threadData, modelica_string _id)
{
int _isThere_ext;
modelica_boolean _isThere;
_isThere_ext = ErrorImpl__isTopCheckpoint(threadData, MMC_STRINGDATA(_id));
_isThere = (modelica_boolean)_isThere_ext;
return _isThere;
}
modelica_metatype boxptr_ErrorExt_isTopCheckpoint(threadData_t *threadData, modelica_metatype _id)
{
modelica_boolean _isThere;
modelica_metatype out_isThere;
_isThere = omc_ErrorExt_isTopCheckpoint(threadData, _id);
out_isThere = mmc_mk_icon(_isThere);
return out_isThere;
}
void omc_ErrorExt_freeMessages(threadData_t *threadData, modelica_metatype _handles)
{
modelica_metatype _handles_ext;
_handles_ext = (modelica_metatype)_handles;
ErrorImpl__freeMessages(threadData, _handles_ext);
return;
}
void omc_ErrorExt_pushMessages(threadData_t *threadData, modelica_metatype _handles)
{
modelica_metatype _handles_ext;
_handles_ext = (modelica_metatype)_handles;
ErrorImpl__pushMessages(threadData, _handles_ext);
return;
}
modelica_metatype omc_ErrorExt_popCheckPoint(threadData_t *threadData, modelica_string _id)
{
modelica_metatype _handles_ext;
modelica_metatype _handles = NULL;
_handles_ext = ErrorImpl__pop(threadData, MMC_STRINGDATA(_id));
_handles = (modelica_metatype)_handles_ext;
return _handles;
}
void omc_ErrorExt_rollBack(threadData_t *threadData, modelica_string _id)
{
ErrorImpl__rollBack(threadData, MMC_STRINGDATA(_id));
return;
}
modelica_string omc_ErrorExt_printErrorsNoWarning(threadData_t *threadData)
{
const char* _outString_ext;
modelica_string _outString = NULL;
_outString_ext = Error_printErrorsNoWarning(threadData);
_outString = (modelica_string)mmc_mk_scon(_outString_ext);
return _outString;
}
void omc_ErrorExt_delCheckpoint(threadData_t *threadData, modelica_string _id)
{
ErrorImpl__delCheckpoint(threadData, MMC_STRINGDATA(_id));
return;
}
void omc_ErrorExt_setCheckpoint(threadData_t *threadData, modelica_string _id)
{
ErrorImpl__setCheckpoint(threadData, MMC_STRINGDATA(_id));
return;
}
void omc_ErrorExt_deleteNumCheckpoints(threadData_t *threadData, modelica_integer _n)
{
int _n_ext;
_n_ext = (int)_n;
ErrorImpl__deleteNumCheckpoints(threadData, _n_ext);
return;
}
void boxptr_ErrorExt_deleteNumCheckpoints(threadData_t *threadData, modelica_metatype _n)
{
modelica_integer tmp1;
tmp1 = mmc_unbox_integer(_n);
omc_ErrorExt_deleteNumCheckpoints(threadData, tmp1);
return;
}
void omc_ErrorExt_rollbackNumCheckpoints(threadData_t *threadData, modelica_integer _n)
{
int _n_ext;
_n_ext = (int)_n;
ErrorImpl__rollbackNumCheckpoints(threadData, _n_ext);
return;
}
void boxptr_ErrorExt_rollbackNumCheckpoints(threadData_t *threadData, modelica_metatype _n)
{
modelica_integer tmp1;
tmp1 = mmc_unbox_integer(_n);
omc_ErrorExt_rollbackNumCheckpoints(threadData, tmp1);
return;
}
modelica_integer omc_ErrorExt_getNumCheckpoints(threadData_t *threadData)
{
int _n_ext;
modelica_integer _n;
_n_ext = ErrorImpl__getNumCheckpoints(threadData);
_n = (modelica_integer)_n_ext;
return _n;
}
modelica_metatype boxptr_ErrorExt_getNumCheckpoints(threadData_t *threadData)
{
modelica_integer _n;
modelica_metatype out_n;
_n = omc_ErrorExt_getNumCheckpoints(threadData);
out_n = mmc_mk_icon(_n);
return out_n;
}
void omc_ErrorExt_clearMessages(threadData_t *threadData)
{
ErrorImpl__clearMessages(threadData);
return;
}
modelica_metatype omc_ErrorExt_getCheckpointMessages(threadData_t *threadData)
{
modelica_metatype _res_ext;
modelica_metatype _res = NULL;
_res_ext = ErrorImpl__getCheckpointMessages(threadData);
_res = (modelica_metatype)_res_ext;
return _res;
}
modelica_metatype omc_ErrorExt_getMessages(threadData_t *threadData)
{
modelica_metatype _res_ext;
modelica_metatype _res = NULL;
_res_ext = Error_getMessages(threadData);
_res = (modelica_metatype)_res_ext;
return _res;
}
modelica_integer omc_ErrorExt_getNumWarningMessages(threadData_t *threadData)
{
int _num_ext;
modelica_integer _num;
_num_ext = ErrorImpl__getNumWarningMessages(threadData);
_num = (modelica_integer)_num_ext;
return _num;
}
modelica_metatype boxptr_ErrorExt_getNumWarningMessages(threadData_t *threadData)
{
modelica_integer _num;
modelica_metatype out_num;
_num = omc_ErrorExt_getNumWarningMessages(threadData);
out_num = mmc_mk_icon(_num);
return out_num;
}
modelica_integer omc_ErrorExt_getNumErrorMessages(threadData_t *threadData)
{
int _num_ext;
modelica_integer _num;
_num_ext = ErrorImpl__getNumErrorMessages(threadData);
_num = (modelica_integer)_num_ext;
return _num;
}
modelica_metatype boxptr_ErrorExt_getNumErrorMessages(threadData_t *threadData)
{
modelica_integer _num;
modelica_metatype out_num;
_num = omc_ErrorExt_getNumErrorMessages(threadData);
out_num = mmc_mk_icon(_num);
return out_num;
}
modelica_integer omc_ErrorExt_getNumMessages(threadData_t *threadData)
{
int _num_ext;
modelica_integer _num;
_num_ext = Error_getNumMessages(threadData);
_num = (modelica_integer)_num_ext;
return _num;
}
modelica_metatype boxptr_ErrorExt_getNumMessages(threadData_t *threadData)
{
modelica_integer _num;
modelica_metatype out_num;
_num = omc_ErrorExt_getNumMessages(threadData);
out_num = mmc_mk_icon(_num);
return out_num;
}
modelica_string omc_ErrorExt_printMessagesStr(threadData_t *threadData, modelica_boolean _warningsAsErrors)
{
int _warningsAsErrors_ext;
const char* _outString_ext;
modelica_string _outString = NULL;
_warningsAsErrors_ext = (int)_warningsAsErrors;
_outString_ext = Error_printMessagesStr(threadData, _warningsAsErrors_ext);
_outString = (modelica_string)mmc_mk_scon(_outString_ext);
return _outString;
}
modelica_metatype boxptr_ErrorExt_printMessagesStr(threadData_t *threadData, modelica_metatype _warningsAsErrors)
{
modelica_integer tmp1;
modelica_string _outString = NULL;
tmp1 = mmc_unbox_integer(_warningsAsErrors);
_outString = omc_ErrorExt_printMessagesStr(threadData, tmp1);
return _outString;
}
void omc_ErrorExt_addSourceMessage(threadData_t *threadData, modelica_integer _id, modelica_metatype _msg_type, modelica_metatype _msg_severity, modelica_integer _sline, modelica_integer _scol, modelica_integer _eline, modelica_integer _ecol, modelica_boolean _read_only, modelica_string _filename, modelica_string _msg, modelica_metatype _tokens)
{
int _id_ext;
modelica_metatype _msg_type_ext;
modelica_metatype _msg_severity_ext;
int _sline_ext;
int _scol_ext;
int _eline_ext;
int _ecol_ext;
int _read_only_ext;
modelica_metatype _tokens_ext;
_id_ext = (int)_id;
_msg_type_ext = (modelica_metatype)_msg_type;
_msg_severity_ext = (modelica_metatype)_msg_severity;
_sline_ext = (int)_sline;
_scol_ext = (int)_scol;
_eline_ext = (int)_eline;
_ecol_ext = (int)_ecol;
_read_only_ext = (int)_read_only;
_tokens_ext = (modelica_metatype)_tokens;
Error_addSourceMessage(threadData, _id_ext, _msg_type_ext, _msg_severity_ext, _sline_ext, _scol_ext, _eline_ext, _ecol_ext, _read_only_ext, MMC_STRINGDATA(_filename), MMC_STRINGDATA(_msg), _tokens_ext);
return;
}
void boxptr_ErrorExt_addSourceMessage(threadData_t *threadData, modelica_metatype _id, modelica_metatype _msg_type, modelica_metatype _msg_severity, modelica_metatype _sline, modelica_metatype _scol, modelica_metatype _eline, modelica_metatype _ecol, modelica_metatype _read_only, modelica_metatype _filename, modelica_metatype _msg, modelica_metatype _tokens)
{
modelica_integer tmp1;
modelica_integer tmp2;
modelica_integer tmp3;
modelica_integer tmp4;
modelica_integer tmp5;
modelica_integer tmp6;
tmp1 = mmc_unbox_integer(_id);
tmp2 = mmc_unbox_integer(_sline);
tmp3 = mmc_unbox_integer(_scol);
tmp4 = mmc_unbox_integer(_eline);
tmp5 = mmc_unbox_integer(_ecol);
tmp6 = mmc_unbox_integer(_read_only);
omc_ErrorExt_addSourceMessage(threadData, tmp1, _msg_type, _msg_severity, tmp2, tmp3, tmp4, tmp5, tmp6, _filename, _msg, _tokens);
return;
}
void omc_ErrorExt_registerModelicaFormatError(threadData_t *threadData)
{
Error_registerModelicaFormatError();
return;
}
