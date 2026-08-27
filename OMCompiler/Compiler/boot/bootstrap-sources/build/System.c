#ifdef OMC_BASE_FILE
#define OMC_FILE OMC_BASE_FILE
#else
#define OMC_FILE "/home/mahge/dev/OpenModelica/OMCompiler/Compiler/boot/build/tmp/System.c"
#endif
#include "omc_simulation_settings.h"
#include "System.h"
#define _OMC_LIT0_data ": "
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT0,2,_OMC_LIT0_data);
#define _OMC_LIT0 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT0)
#define _OMC_LIT1_data "MB"
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT1,2,_OMC_LIT1_data);
#define _OMC_LIT1 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT1)
#define _OMC_LIT2_data ""
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT2,0,_OMC_LIT2_data);
#define _OMC_LIT2 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT2)
#define _OMC_LIT3_data " \f\n\r	\v"
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT3,6,_OMC_LIT3_data);
#define _OMC_LIT3 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT3)
#include "util/modelica.h"
#include "System_includes.h"
#if !defined(PROTECTED_FUNCTION_STATIC)
#define PROTECTED_FUNCTION_STATIC
#endif
PROTECTED_FUNCTION_STATIC modelica_string omc_System_dladdr___dladdr(threadData_t *threadData, modelica_metatype _symbol, modelica_string *out_name);
static const MMC_DEFSTRUCTLIT(boxvar_lit_System_dladdr___dladdr,2,0) {(void*) boxptr_System_dladdr___dladdr,0}};
#define boxvar_System_dladdr___dladdr MMC_REFSTRUCTLIT(boxvar_lit_System_dladdr___dladdr)
PROTECTED_FUNCTION_STATIC modelica_integer omc_System_intRandom0(threadData_t *threadData);
PROTECTED_FUNCTION_STATIC modelica_metatype boxptr_System_intRandom0(threadData_t *threadData);
static const MMC_DEFSTRUCTLIT(boxvar_lit_System_intRandom0,2,0) {(void*) boxptr_System_intRandom0,0}};
#define boxvar_System_intRandom0 MMC_REFSTRUCTLIT(boxvar_lit_System_intRandom0)
PROTECTED_FUNCTION_STATIC modelica_boolean omc_System_removeDirectory__dispatch(threadData_t *threadData, modelica_string _inString);
PROTECTED_FUNCTION_STATIC modelica_metatype boxptr_System_removeDirectory__dispatch(threadData_t *threadData, modelica_metatype _inString);
static const MMC_DEFSTRUCTLIT(boxvar_lit_System_removeDirectory__dispatch,2,0) {(void*) boxptr_System_removeDirectory__dispatch,0}};
#define boxvar_System_removeDirectory__dispatch MMC_REFSTRUCTLIT(boxvar_lit_System_removeDirectory__dispatch)
modelica_real omc_System_getSizeOfData(threadData_t *threadData, modelica_metatype _data, modelica_real *out_raw_sz, modelica_real *out_nonSharedStringSize)
{
modelica_metatype _data_ext;
double _raw_sz_ext;
double _nonSharedStringSize_ext;
double _sz_ext;
modelica_real _sz;
modelica_real _raw_sz;
modelica_real _nonSharedStringSize;
_data_ext = (modelica_metatype)_data;
_sz_ext = SystemImpl__getSizeOfData(_data_ext, &_raw_sz_ext, &_nonSharedStringSize_ext);
_raw_sz = (modelica_real)_raw_sz_ext;
_nonSharedStringSize = (modelica_real)_nonSharedStringSize_ext;
_sz = (modelica_real)_sz_ext;
if (out_raw_sz) { *out_raw_sz = _raw_sz; }
if (out_nonSharedStringSize) { *out_nonSharedStringSize = _nonSharedStringSize; }
return _sz;
}
modelica_metatype boxptr_System_getSizeOfData(threadData_t *threadData, modelica_metatype _data, modelica_metatype *out_raw_sz, modelica_metatype *out_nonSharedStringSize)
{
modelica_real _raw_sz;
modelica_real _nonSharedStringSize;
modelica_real _sz;
modelica_metatype out_sz;
_sz = omc_System_getSizeOfData(threadData, _data, &_raw_sz, &_nonSharedStringSize);
out_sz = mmc_mk_rcon(_sz);
if (out_raw_sz) { *out_raw_sz = mmc_mk_rcon(_raw_sz); }
if (out_nonSharedStringSize) { *out_nonSharedStringSize = mmc_mk_rcon(_nonSharedStringSize); }
return out_sz;
}
void omc_System_updateUriMapping(threadData_t *threadData, modelica_metatype _namesAndDirs)
{
modelica_metatype _namesAndDirs_ext;
_namesAndDirs_ext = (modelica_metatype)_namesAndDirs;
OpenModelica_updateUriMapping(threadData, _namesAndDirs_ext);
return;
}
void omc_System_fflush(threadData_t *threadData)
{
SystemImpl__fflush();
return;
}
modelica_boolean omc_System_relocateFunctions(threadData_t *threadData, modelica_string _fileName, modelica_metatype _names)
{
modelica_metatype _names_ext;
int _res_ext;
modelica_boolean _res;
_names_ext = (modelica_metatype)_names;
_res_ext = SystemImpl__relocateFunctions(MMC_STRINGDATA(_fileName), _names_ext);
_res = (modelica_boolean)_res_ext;
return _res;
}
modelica_metatype boxptr_System_relocateFunctions(threadData_t *threadData, modelica_metatype _fileName, modelica_metatype _names)
{
modelica_boolean _res;
modelica_metatype out_res;
_res = omc_System_relocateFunctions(threadData, _fileName, _names);
out_res = mmc_mk_icon(_res);
return out_res;
}
modelica_metatype omc_System_stringAllocatorResult(threadData_t *threadData, modelica_complex _sa, modelica_metatype _dummy)
{
void * _sa_ext;
modelica_metatype _res_ext;
modelica_metatype _res = NULL;
_sa_ext = (void *)_sa;
_res_ext = om_stringAllocatorResult(_sa_ext);
_res = (modelica_metatype)_res_ext;
return _res;
}
modelica_metatype boxptr_System_stringAllocatorResult(threadData_t *threadData, modelica_metatype _sa, modelica_metatype _dummy)
{
modelica_metatype _res = NULL;
_res = omc_System_stringAllocatorResult(threadData, _sa, _dummy);
return _res;
}
void omc_System_stringAllocatorStringCopy(threadData_t *threadData, modelica_complex _dest, modelica_string _source, modelica_integer _destOffset)
{
void * _dest_ext;
int _destOffset_ext;
_dest_ext = (void *)_dest;
_destOffset_ext = (int)_destOffset;
om_stringAllocatorStringCopy(_dest_ext, MMC_STRINGDATA(_source), _destOffset_ext);
return;
}
void boxptr_System_stringAllocatorStringCopy(threadData_t *threadData, modelica_metatype _dest, modelica_metatype _source, modelica_metatype _destOffset)
{
modelica_integer tmp1;
tmp1 = mmc_unbox_integer(_destOffset);
omc_System_stringAllocatorStringCopy(threadData, _dest, _source, tmp1);
return;
}
modelica_complex omc_System_StringAllocator_constructor(threadData_t *threadData, modelica_integer _sz)
{
int _sz_ext;
void * _str_ext;
modelica_complex _str;
_sz_ext = (int)_sz;
_str_ext = StringAllocator_constructor(_sz_ext);
_str = (modelica_complex)_str_ext;
return _str;
}
modelica_metatype boxptr_System_StringAllocator_constructor(threadData_t *threadData, modelica_metatype _sz)
{
modelica_integer tmp1;
modelica_complex _str;
tmp1 = mmc_unbox_integer(_sz);
_str = omc_System_StringAllocator_constructor(threadData, tmp1);
return _str;
}
DLLExport
void omc_System_StringAllocator_destructor(threadData_t *threadData, modelica_complex _str)
{
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
_return: OMC_LABEL_UNUSED
return;
}
void boxptr_System_StringAllocator_destructor(threadData_t *threadData, modelica_metatype _str)
{
omc_System_StringAllocator_destructor(threadData, _str);
return;
}
PROTECTED_FUNCTION_STATIC modelica_string omc_System_dladdr___dladdr(threadData_t *threadData, modelica_metatype _symbol, modelica_string *out_name)
{
modelica_metatype _symbol_ext;
const char* _file_ext;
const char* _name_ext;
modelica_string _file = NULL;
modelica_string _name = NULL;
_symbol_ext = (modelica_metatype)_symbol;
SystemImpl__dladdr(_symbol_ext, &_file_ext, &_name_ext);
_file = (modelica_string)mmc_mk_scon(_file_ext);
_name = (modelica_string)mmc_mk_scon(_name_ext);
if (out_name) { *out_name = _name; }
return _file;
}
DLLExport
modelica_string omc_System_dladdr(threadData_t *threadData, modelica_metatype _symbol, modelica_string *out_file, modelica_string *out_name)
{
modelica_string _info = NULL;
modelica_string _file = NULL;
modelica_string _name = NULL;
modelica_metatype tmpMeta[2] __attribute__((unused)) = {0};
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
_file = omc_System_dladdr___dladdr(threadData, _symbol ,&_name);
tmpMeta[0] = stringAppend(_file,_OMC_LIT0);
tmpMeta[1] = stringAppend(tmpMeta[0],_name);
_info = tmpMeta[1];
_return: OMC_LABEL_UNUSED
if (out_file) { *out_file = _file; }
if (out_name) { *out_name = _name; }
return _info;
}
modelica_boolean omc_System_covertTextFileToCLiteral(threadData_t *threadData, modelica_string _textFile, modelica_string _outFile, modelica_string _target)
{
int _success_ext;
modelica_boolean _success;
_success_ext = SystemImpl__covertTextFileToCLiteral(MMC_STRINGDATA(_textFile), MMC_STRINGDATA(_outFile), MMC_STRINGDATA(_target));
_success = (modelica_boolean)_success_ext;
return _success;
}
modelica_metatype boxptr_System_covertTextFileToCLiteral(threadData_t *threadData, modelica_metatype _textFile, modelica_metatype _outFile, modelica_metatype _target)
{
modelica_boolean _success;
modelica_metatype out_success;
_success = omc_System_covertTextFileToCLiteral(threadData, _textFile, _outFile, _target);
out_success = mmc_mk_icon(_success);
return out_success;
}
modelica_integer omc_System_alarm(threadData_t *threadData, modelica_integer _seconds)
{
int _seconds_ext;
int _previousAlarm_ext;
modelica_integer _previousAlarm;
_seconds_ext = (int)_seconds;
_previousAlarm_ext = SystemImpl__alarm(_seconds_ext);
_previousAlarm = (modelica_integer)_previousAlarm_ext;
return _previousAlarm;
}
modelica_metatype boxptr_System_alarm(threadData_t *threadData, modelica_metatype _seconds)
{
modelica_integer tmp1;
modelica_integer _previousAlarm;
modelica_metatype out_previousAlarm;
tmp1 = mmc_unbox_integer(_seconds);
_previousAlarm = omc_System_alarm(threadData, tmp1);
out_previousAlarm = mmc_mk_icon(_previousAlarm);
return out_previousAlarm;
}
modelica_boolean omc_System_stat(threadData_t *threadData, modelica_string _filename, modelica_real *out_st_size, modelica_real *out_st_mtime)
{
double _st_size_ext;
double _st_mtime_ext;
int _success_ext;
modelica_boolean _success;
modelica_real _st_size;
modelica_real _st_mtime;
_success_ext = SystemImpl__stat(MMC_STRINGDATA(_filename), &_st_size_ext, &_st_mtime_ext);
_st_size = (modelica_real)_st_size_ext;
_st_mtime = (modelica_real)_st_mtime_ext;
_success = (modelica_boolean)_success_ext;
if (out_st_size) { *out_st_size = _st_size; }
if (out_st_mtime) { *out_st_mtime = _st_mtime; }
return _success;
}
modelica_metatype boxptr_System_stat(threadData_t *threadData, modelica_metatype _filename, modelica_metatype *out_st_size, modelica_metatype *out_st_mtime)
{
modelica_real _st_size;
modelica_real _st_mtime;
modelica_boolean _success;
modelica_metatype out_success;
_success = omc_System_stat(threadData, _filename, &_st_size, &_st_mtime);
out_success = mmc_mk_icon(_success);
if (out_st_size) { *out_st_size = mmc_mk_rcon(_st_size); }
if (out_st_mtime) { *out_st_mtime = mmc_mk_rcon(_st_mtime); }
return out_success;
}
modelica_string omc_System_ctime(threadData_t *threadData, modelica_real _t)
{
double _t_ext;
const char* _str_ext;
modelica_string _str = NULL;
_t_ext = (double)_t;
_str_ext = SystemImpl__ctime(_t_ext);
_str = (modelica_string)mmc_mk_scon(_str_ext);
return _str;
}
modelica_metatype boxptr_System_ctime(threadData_t *threadData, modelica_metatype _t)
{
modelica_real tmp1;
modelica_string _str = NULL;
tmp1 = mmc_unbox_real(_t);
_str = omc_System_ctime(threadData, tmp1);
return _str;
}
void omc_System_initGarbageCollector(threadData_t *threadData)
{
System_initGarbageCollector();
return;
}
modelica_real omc_System_getMemorySize(threadData_t *threadData)
{
double _memory_ext;
modelica_real _memory;
_memory_ext = System_getMemorySize();
_memory = (modelica_real)_memory_ext;
return _memory;
}
modelica_metatype boxptr_System_getMemorySize(threadData_t *threadData)
{
modelica_real _memory;
modelica_metatype out_memory;
_memory = omc_System_getMemorySize(threadData);
out_memory = mmc_mk_rcon(_memory);
return out_memory;
}
void omc_System_threadWorkFailed(threadData_t *threadData)
{
System_threadFail(threadData);
return;
}
void omc_System_exit(threadData_t *threadData, modelica_integer _status)
{
int _status_ext;
_status_ext = (int)_status;
exit(_status_ext);
return;
}
void boxptr_System_exit(threadData_t *threadData, modelica_metatype _status)
{
modelica_integer tmp1;
tmp1 = mmc_unbox_integer(_status);
omc_System_exit(threadData, tmp1);
return;
}
modelica_metatype omc_System_launchParallelTasks(threadData_t *threadData, modelica_integer _numThreads, modelica_metatype _inData, modelica_fnptr _func)
{
int _numThreads_ext;
modelica_metatype _inData_ext;
modelica_fnptr _func_ext;
modelica_metatype _result_ext;
modelica_metatype _result = NULL;
_numThreads_ext = (int)_numThreads;
_inData_ext = (modelica_metatype)_inData;
if (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_func), 2))) {
MMC_THROW_INTERNAL()
}
_func_ext = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_func), 1));
_result_ext = System_launchParallelTasks(threadData, _numThreads_ext, _inData_ext, _func_ext);
_result = (modelica_metatype)_result_ext;
return _result;
}
modelica_metatype boxptr_System_launchParallelTasks(threadData_t *threadData, modelica_metatype _numThreads, modelica_metatype _inData, modelica_fnptr _func)
{
modelica_integer tmp1;
modelica_metatype _result = NULL;
tmp1 = mmc_unbox_integer(_numThreads);
_result = omc_System_launchParallelTasks(threadData, tmp1, _inData, _func);
return _result;
}
modelica_integer omc_System_numProcessors(threadData_t *threadData)
{
int _result_ext;
modelica_integer _result;
_result_ext = System_numProcessors();
_result = (modelica_integer)_result_ext;
return _result;
}
modelica_metatype boxptr_System_numProcessors(threadData_t *threadData)
{
modelica_integer _result;
modelica_metatype out_result;
_result = omc_System_numProcessors(threadData);
out_result = mmc_mk_icon(_result);
return out_result;
}
modelica_boolean omc_System_rename(threadData_t *threadData, modelica_string _source, modelica_string _dest)
{
int _result_ext;
modelica_boolean _result;
_result_ext = SystemImpl__rename(MMC_STRINGDATA(_source), MMC_STRINGDATA(_dest));
_result = (modelica_boolean)_result_ext;
return _result;
}
modelica_metatype boxptr_System_rename(threadData_t *threadData, modelica_metatype _source, modelica_metatype _dest)
{
modelica_boolean _result;
modelica_metatype out_result;
_result = omc_System_rename(threadData, _source, _dest);
out_result = mmc_mk_icon(_result);
return out_result;
}
modelica_boolean omc_System_fileContentsEqual(threadData_t *threadData, modelica_string _file1, modelica_string _file2)
{
int _result_ext;
modelica_boolean _result;
_result_ext = SystemImpl__fileContentsEqual(MMC_STRINGDATA(_file1), MMC_STRINGDATA(_file2));
_result = (modelica_boolean)_result_ext;
return _result;
}
modelica_metatype boxptr_System_fileContentsEqual(threadData_t *threadData, modelica_metatype _file1, modelica_metatype _file2)
{
modelica_boolean _result;
modelica_metatype out_result;
_result = omc_System_fileContentsEqual(threadData, _file1, _file2);
out_result = mmc_mk_icon(_result);
return out_result;
}
modelica_boolean omc_System_fileIsNewerThan(threadData_t *threadData, modelica_string _file1, modelica_string _file2)
{
int _result_ext;
modelica_boolean _result;
_result_ext = System_fileIsNewerThan(MMC_STRINGDATA(_file1), MMC_STRINGDATA(_file2));
_result = (modelica_boolean)_result_ext;
return _result;
}
modelica_metatype boxptr_System_fileIsNewerThan(threadData_t *threadData, modelica_metatype _file1, modelica_metatype _file2)
{
modelica_boolean _result;
modelica_metatype out_result;
_result = omc_System_fileIsNewerThan(threadData, _file1, _file2);
out_result = mmc_mk_icon(_result);
return out_result;
}
modelica_integer omc_System_getTerminalWidth(threadData_t *threadData)
{
int _width_ext;
modelica_integer _width;
_width_ext = System_getTerminalWidth();
_width = (modelica_integer)_width_ext;
return _width;
}
modelica_metatype boxptr_System_getTerminalWidth(threadData_t *threadData)
{
modelica_integer _width;
modelica_metatype out_width;
_width = omc_System_getTerminalWidth(threadData);
out_width = mmc_mk_icon(_width);
return out_width;
}
modelica_string omc_System_getSimulationHelpText(threadData_t *threadData, modelica_boolean _detailed, modelica_boolean _sphinx)
{
int _detailed_ext;
int _sphinx_ext;
const char* _text_ext;
modelica_string _text = NULL;
_detailed_ext = (int)_detailed;
_sphinx_ext = (int)_sphinx;
_text_ext = System_getSimulationHelpTextSphinx(_detailed_ext, _sphinx_ext);
_text = (modelica_string)mmc_mk_scon(_text_ext);
return _text;
}
modelica_metatype boxptr_System_getSimulationHelpText(threadData_t *threadData, modelica_metatype _detailed, modelica_metatype _sphinx)
{
modelica_integer tmp1;
modelica_integer tmp2;
modelica_string _text = NULL;
tmp1 = mmc_unbox_integer(_detailed);
tmp2 = mmc_unbox_integer(_sphinx);
_text = omc_System_getSimulationHelpText(threadData, tmp1, tmp2);
return _text;
}
modelica_string omc_System_realpath(threadData_t *threadData, modelica_string _path)
{
const char* _fullpath_ext;
modelica_string _fullpath = NULL;
_fullpath_ext = System_realpath(MMC_STRINGDATA(_path));
_fullpath = (modelica_string)mmc_mk_scon(_fullpath_ext);
return _fullpath;
}
modelica_integer omc_System_numBits(threadData_t *threadData)
{
int _n_ext;
modelica_integer _n;
_n_ext = architecture_numbits();
_n = (modelica_integer)_n_ext;
return _n;
}
modelica_metatype boxptr_System_numBits(threadData_t *threadData)
{
modelica_integer _n;
modelica_metatype out_n;
_n = omc_System_numBits(threadData);
out_n = mmc_mk_icon(_n);
return out_n;
}
modelica_string omc_System_anyStringCode(threadData_t *threadData, modelica_metatype _any)
{
modelica_metatype _any_ext;
const char* _str_ext;
modelica_string _str = NULL;
_any_ext = (modelica_metatype)_any;
_str_ext = anyStringCode(_any_ext);
_str = (modelica_string)mmc_mk_scon(_str_ext);
return _str;
}
modelica_string omc_System_gettext(threadData_t *threadData, modelica_string _msgid)
{
const char* _msgstr_ext;
modelica_string _msgstr = NULL;
_msgstr_ext = SystemImpl__gettext(MMC_STRINGDATA(_msgid));
_msgstr = (modelica_string)mmc_mk_scon(_msgstr_ext);
return _msgstr;
}
void omc_System_gettextInit(threadData_t *threadData, modelica_string _locale)
{
SystemImpl__gettextInit(MMC_STRINGDATA(_locale));
return;
}
PROTECTED_FUNCTION_STATIC modelica_integer omc_System_intRandom0(threadData_t *threadData)
{
int _ret_ext;
modelica_integer _ret;
_ret_ext = rand();
_ret = (modelica_integer)_ret_ext;
return _ret;
}
PROTECTED_FUNCTION_STATIC modelica_metatype boxptr_System_intRandom0(threadData_t *threadData)
{
modelica_integer _ret;
modelica_metatype out_ret;
_ret = omc_System_intRandom0(threadData);
out_ret = mmc_mk_icon(_ret);
return out_ret;
}
DLLExport
modelica_integer omc_System_intRandom(threadData_t *threadData, modelica_integer _n)
{
modelica_integer _ret;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
_ret = modelica_integer_mod(omc_System_intRandom0(threadData), _n);
_return: OMC_LABEL_UNUSED
return _ret;
}
modelica_metatype boxptr_System_intRandom(threadData_t *threadData, modelica_metatype _n)
{
modelica_integer tmp1;
modelica_integer _ret;
modelica_metatype out_ret;
tmp1 = mmc_unbox_integer(_n);
_ret = omc_System_intRandom(threadData, tmp1);
out_ret = mmc_mk_icon(_ret);
return out_ret;
}
DLLExport
modelica_integer omc_System_intRand(threadData_t *threadData, modelica_integer _n)
{
modelica_integer _i;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
_i = ((modelica_integer)floor((omc_System_realRand(threadData)) * (((modelica_real)_n))));
_return: OMC_LABEL_UNUSED
return _i;
}
modelica_metatype boxptr_System_intRand(threadData_t *threadData, modelica_metatype _n)
{
modelica_integer tmp1;
modelica_integer _i;
modelica_metatype out_i;
tmp1 = mmc_unbox_integer(_n);
_i = omc_System_intRand(threadData, tmp1);
out_i = mmc_mk_icon(_i);
return out_i;
}
modelica_real omc_System_realRand(threadData_t *threadData)
{
double _r_ext;
modelica_real _r;
_r_ext = SystemImpl__realRand();
_r = (modelica_real)_r_ext;
return _r;
}
modelica_metatype boxptr_System_realRand(threadData_t *threadData)
{
modelica_real _r;
modelica_metatype out_r;
_r = omc_System_realRand(threadData);
out_r = mmc_mk_rcon(_r);
return out_r;
}
modelica_string omc_System_sprintff(threadData_t *threadData, modelica_string _format, modelica_real _val)
{
double _val_ext;
const char* _str_ext;
modelica_string _str = NULL;
_val_ext = (double)_val;
_str_ext = System_sprintff(MMC_STRINGDATA(_format), _val_ext);
_str = (modelica_string)mmc_mk_scon(_str_ext);
return _str;
}
modelica_metatype boxptr_System_sprintff(threadData_t *threadData, modelica_metatype _format, modelica_metatype _val)
{
modelica_real tmp1;
modelica_string _str = NULL;
tmp1 = mmc_unbox_real(_val);
_str = omc_System_sprintff(threadData, _format, tmp1);
return _str;
}
modelica_string omc_System_snprintff(threadData_t *threadData, modelica_string _format, modelica_integer _maxlen, modelica_real _val)
{
int _maxlen_ext;
double _val_ext;
const char* _str_ext;
modelica_string _str = NULL;
_maxlen_ext = (int)_maxlen;
_val_ext = (double)_val;
_str_ext = System_snprintff(MMC_STRINGDATA(_format), _maxlen_ext, _val_ext);
_str = (modelica_string)mmc_mk_scon(_str_ext);
return _str;
}
modelica_metatype boxptr_System_snprintff(threadData_t *threadData, modelica_metatype _format, modelica_metatype _maxlen, modelica_metatype _val)
{
modelica_integer tmp1;
modelica_real tmp2;
modelica_string _str = NULL;
tmp1 = mmc_unbox_integer(_maxlen);
tmp2 = mmc_unbox_real(_val);
_str = omc_System_snprintff(threadData, _format, tmp1, tmp2);
return _str;
}
modelica_string omc_System_iconv(threadData_t *threadData, modelica_string _string, modelica_string _from, modelica_string _to)
{
const char* _result_ext;
modelica_string _result = NULL;
_result_ext = SystemImpl__iconv(MMC_STRINGDATA(_string), MMC_STRINGDATA(_from), MMC_STRINGDATA(_to), 1);
_result = (modelica_string)mmc_mk_scon(_result_ext);
return _result;
}
modelica_boolean omc_System_reopenStandardStream(threadData_t *threadData, modelica_integer __stream, modelica_string _filename)
{
int __stream_ext;
int _success_ext;
modelica_boolean _success;
__stream_ext = (int)__stream;
_success_ext = SystemImpl__reopenStandardStream(__stream_ext, MMC_STRINGDATA(_filename));
_success = (modelica_boolean)_success_ext;
return _success;
}
modelica_metatype boxptr_System_reopenStandardStream(threadData_t *threadData, modelica_metatype __stream, modelica_metatype _filename)
{
modelica_integer tmp1;
modelica_boolean _success;
modelica_metatype out_success;
tmp1 = mmc_unbox_integer(__stream);
_success = omc_System_reopenStandardStream(threadData, tmp1, _filename);
out_success = mmc_mk_icon(_success);
return out_success;
}
modelica_metatype omc_System_dgesv(threadData_t *threadData, modelica_metatype _A, modelica_metatype _B, modelica_integer *out_info)
{
modelica_metatype _A_ext;
modelica_metatype _B_ext;
modelica_metatype _X_ext;
int _info_ext;
modelica_metatype _X = NULL;
modelica_integer _info;
_A_ext = (modelica_metatype)_A;
_B_ext = (modelica_metatype)_B;
_info_ext = SystemImpl__dgesv(_A_ext, _B_ext, &_X_ext);
_X = (modelica_metatype)_X_ext;
_info = (modelica_integer)_info_ext;
if (out_info) { *out_info = _info; }
return _X;
}
modelica_metatype boxptr_System_dgesv(threadData_t *threadData, modelica_metatype _A, modelica_metatype _B, modelica_metatype *out_info)
{
modelica_integer _info;
modelica_metatype _X = NULL;
_X = omc_System_dgesv(threadData, _A, _B, &_info);
if (out_info) { *out_info = mmc_mk_icon(_info); }
return _X;
}
modelica_string omc_System_gccVersion(threadData_t *threadData)
{
const char* _version_ext;
modelica_string _version = NULL;
_version_ext = System_gccVersion();
_version = (modelica_string)mmc_mk_scon(_version_ext);
return _version;
}
modelica_string omc_System_gccDumpMachine(threadData_t *threadData)
{
const char* _machine_ext;
modelica_string _machine = NULL;
_machine_ext = System_gccDumpMachine();
_machine = (modelica_string)mmc_mk_scon(_machine_ext);
return _machine;
}
modelica_string omc_System_openModelicaPlatform(threadData_t *threadData)
{
const char* _platform_ext;
modelica_string _platform = NULL;
_platform_ext = System_openModelicaPlatform();
_platform = (modelica_string)mmc_mk_scon(_platform_ext);
return _platform;
}
modelica_string omc_System_modelicaPlatform(threadData_t *threadData)
{
const char* _platform_ext;
modelica_string _platform = NULL;
_platform_ext = System_modelicaPlatform();
_platform = (modelica_string)mmc_mk_scon(_platform_ext);
return _platform;
}
modelica_string omc_System_uriToClassAndPath(threadData_t *threadData, modelica_string _uri, modelica_string *out_classname, modelica_string *out_pathname)
{
const char* _scheme_ext;
const char* _classname_ext;
const char* _pathname_ext;
modelica_string _scheme = NULL;
modelica_string _classname = NULL;
modelica_string _pathname = NULL;
System_uriToClassAndPath(MMC_STRINGDATA(_uri), &_scheme_ext, &_classname_ext, &_pathname_ext);
_scheme = (modelica_string)mmc_mk_scon(_scheme_ext);
_classname = (modelica_string)mmc_mk_scon(_classname_ext);
_pathname = (modelica_string)mmc_mk_scon(_pathname_ext);
if (out_classname) { *out_classname = _classname; }
if (out_pathname) { *out_pathname = _pathname; }
return _scheme;
}
modelica_real omc_System_realMaxLit(threadData_t *threadData)
{
double _outReal_ext;
modelica_real _outReal;
_outReal_ext = realMaxLit();
_outReal = (modelica_real)_outReal_ext;
return _outReal;
}
modelica_metatype boxptr_System_realMaxLit(threadData_t *threadData)
{
modelica_real _outReal;
modelica_metatype out_outReal;
_outReal = omc_System_realMaxLit(threadData);
out_outReal = mmc_mk_rcon(_outReal);
return out_outReal;
}
modelica_integer omc_System_intMaxLit(threadData_t *threadData)
{
int _outInt_ext;
modelica_integer _outInt;
_outInt_ext = intMaxLit();
_outInt = (modelica_integer)_outInt_ext;
return _outInt;
}
modelica_metatype boxptr_System_intMaxLit(threadData_t *threadData)
{
modelica_integer _outInt;
modelica_metatype out_outInt;
_outInt = omc_System_intMaxLit(threadData);
out_outInt = mmc_mk_icon(_outInt);
return out_outInt;
}
modelica_string omc_System_unquoteIdentifier(threadData_t *threadData, modelica_string _str)
{
const char* _outStr_ext;
modelica_string _outStr = NULL;
_outStr_ext = System_unquoteIdentifier(MMC_STRINGDATA(_str));
_outStr = (modelica_string)mmc_mk_scon(_outStr_ext);
return _outStr;
}
modelica_integer omc_System_unescapedStringLength(threadData_t *threadData, modelica_string _unescapedString)
{
int _length_ext;
modelica_integer _length;
_length_ext = SystemImpl__unescapedStringLength(MMC_STRINGDATA(_unescapedString));
_length = (modelica_integer)_length_ext;
return _length;
}
modelica_metatype boxptr_System_unescapedStringLength(threadData_t *threadData, modelica_metatype _unescapedString)
{
modelica_integer _length;
modelica_metatype out_length;
_length = omc_System_unescapedStringLength(threadData, _unescapedString);
out_length = mmc_mk_icon(_length);
return out_length;
}
modelica_string omc_System_unescapedString(threadData_t *threadData, modelica_string _escapedString)
{
const char* _unescapedString_ext;
modelica_string _unescapedString = NULL;
_unescapedString_ext = System_unescapedString(MMC_STRINGDATA(_escapedString));
_unescapedString = (modelica_string)mmc_mk_scon(_unescapedString_ext);
return _unescapedString;
}
modelica_string omc_System_escapedString(threadData_t *threadData, modelica_string _unescapedString, modelica_boolean _unescapeNewline)
{
int _unescapeNewline_ext;
const char* _escapedString_ext;
modelica_string _escapedString = NULL;
_unescapeNewline_ext = (int)_unescapeNewline;
_escapedString_ext = System_escapedString(MMC_STRINGDATA(_unescapedString), _unescapeNewline_ext);
_escapedString = (modelica_string)mmc_mk_scon(_escapedString_ext);
return _escapedString;
}
modelica_metatype boxptr_System_escapedString(threadData_t *threadData, modelica_metatype _unescapedString, modelica_metatype _unescapeNewline)
{
modelica_integer tmp1;
modelica_string _escapedString = NULL;
tmp1 = mmc_unbox_integer(_unescapeNewline);
_escapedString = omc_System_escapedString(threadData, _unescapedString, tmp1);
return _escapedString;
}
modelica_string omc_System_dirname(threadData_t *threadData, modelica_string _filename)
{
const char* _base_ext;
modelica_string _base = NULL;
_base_ext = System_dirname(MMC_STRINGDATA(_filename));
_base = (modelica_string)mmc_mk_scon(_base_ext);
return _base;
}
modelica_string omc_System_basename(threadData_t *threadData, modelica_string _filename)
{
const char* _base_ext;
modelica_string _base = NULL;
_base_ext = System_basename(MMC_STRINGDATA(_filename));
_base = (modelica_string)mmc_mk_scon(_base_ext);
return _base;
}
modelica_string omc_System_getUUIDStr(threadData_t *threadData)
{
const char* _uuidStr_ext;
modelica_string _uuidStr = NULL;
_uuidStr_ext = System_getUUIDStr();
_uuidStr = (modelica_string)mmc_mk_scon(_uuidStr_ext);
return _uuidStr;
}
modelica_integer omc_System_getTimerStackIndex(threadData_t *threadData)
{
int _stackIndex_ext;
modelica_integer _stackIndex;
_stackIndex_ext = System_getTimerStackIndex();
_stackIndex = (modelica_integer)_stackIndex_ext;
return _stackIndex;
}
modelica_metatype boxptr_System_getTimerStackIndex(threadData_t *threadData)
{
modelica_integer _stackIndex;
modelica_metatype out_stackIndex;
_stackIndex = omc_System_getTimerStackIndex(threadData);
out_stackIndex = mmc_mk_icon(_stackIndex);
return out_stackIndex;
}
modelica_real omc_System_getTimerElapsedTime(threadData_t *threadData)
{
double _timerElapsedTime_ext;
modelica_real _timerElapsedTime;
_timerElapsedTime_ext = System_getTimerElapsedTime();
_timerElapsedTime = (modelica_real)_timerElapsedTime_ext;
return _timerElapsedTime;
}
modelica_metatype boxptr_System_getTimerElapsedTime(threadData_t *threadData)
{
modelica_real _timerElapsedTime;
modelica_metatype out_timerElapsedTime;
_timerElapsedTime = omc_System_getTimerElapsedTime(threadData);
out_timerElapsedTime = mmc_mk_rcon(_timerElapsedTime);
return out_timerElapsedTime;
}
modelica_real omc_System_getTimerCummulatedTime(threadData_t *threadData)
{
double _timerCummulatedTime_ext;
modelica_real _timerCummulatedTime;
_timerCummulatedTime_ext = System_getTimerCummulatedTime();
_timerCummulatedTime = (modelica_real)_timerCummulatedTime_ext;
return _timerCummulatedTime;
}
modelica_metatype boxptr_System_getTimerCummulatedTime(threadData_t *threadData)
{
modelica_real _timerCummulatedTime;
modelica_metatype out_timerCummulatedTime;
_timerCummulatedTime = omc_System_getTimerCummulatedTime(threadData);
out_timerCummulatedTime = mmc_mk_rcon(_timerCummulatedTime);
return out_timerCummulatedTime;
}
modelica_real omc_System_getTimerIntervalTime(threadData_t *threadData)
{
double _timerIntervalTime_ext;
modelica_real _timerIntervalTime;
_timerIntervalTime_ext = System_getTimerIntervalTime();
_timerIntervalTime = (modelica_real)_timerIntervalTime_ext;
return _timerIntervalTime;
}
modelica_metatype boxptr_System_getTimerIntervalTime(threadData_t *threadData)
{
modelica_real _timerIntervalTime;
modelica_metatype out_timerIntervalTime;
_timerIntervalTime = omc_System_getTimerIntervalTime(threadData);
out_timerIntervalTime = mmc_mk_rcon(_timerIntervalTime);
return out_timerIntervalTime;
}
void omc_System_stopTimer(threadData_t *threadData)
{
System_stopTimer();
return;
}
void omc_System_startTimer(threadData_t *threadData)
{
System_startTimer();
return;
}
void omc_System_resetTimer(threadData_t *threadData)
{
System_resetTimer();
return;
}
modelica_integer omc_System_realtimeNtick(threadData_t *threadData, modelica_integer _clockIndex)
{
int _clockIndex_ext;
int _n_ext;
modelica_integer _n;
_clockIndex_ext = (int)_clockIndex;
_n_ext = System_realtimeNtick(_clockIndex_ext);
_n = (modelica_integer)_n_ext;
return _n;
}
modelica_metatype boxptr_System_realtimeNtick(threadData_t *threadData, modelica_metatype _clockIndex)
{
modelica_integer tmp1;
modelica_integer _n;
modelica_metatype out_n;
tmp1 = mmc_unbox_integer(_clockIndex);
_n = omc_System_realtimeNtick(threadData, tmp1);
out_n = mmc_mk_icon(_n);
return out_n;
}
void omc_System_realtimeClear(threadData_t *threadData, modelica_integer _clockIndex)
{
int _clockIndex_ext;
_clockIndex_ext = (int)_clockIndex;
System_realtimeClear(_clockIndex_ext);
return;
}
void boxptr_System_realtimeClear(threadData_t *threadData, modelica_metatype _clockIndex)
{
modelica_integer tmp1;
tmp1 = mmc_unbox_integer(_clockIndex);
omc_System_realtimeClear(threadData, tmp1);
return;
}
modelica_real omc_System_realtimeTock(threadData_t *threadData, modelica_integer _clockIndex)
{
int _clockIndex_ext;
double _outTime_ext;
modelica_real _outTime;
_clockIndex_ext = (int)_clockIndex;
_outTime_ext = System_realtimeTock(_clockIndex_ext);
_outTime = (modelica_real)_outTime_ext;
return _outTime;
}
modelica_metatype boxptr_System_realtimeTock(threadData_t *threadData, modelica_metatype _clockIndex)
{
modelica_integer tmp1;
modelica_real _outTime;
modelica_metatype out_outTime;
tmp1 = mmc_unbox_integer(_clockIndex);
_outTime = omc_System_realtimeTock(threadData, tmp1);
out_outTime = mmc_mk_rcon(_outTime);
return out_outTime;
}
void omc_System_realtimeTick(threadData_t *threadData, modelica_integer _clockIndex)
{
int _clockIndex_ext;
_clockIndex_ext = (int)_clockIndex;
System_realtimeTick(_clockIndex_ext);
return;
}
void boxptr_System_realtimeTick(threadData_t *threadData, modelica_metatype _clockIndex)
{
modelica_integer tmp1;
tmp1 = mmc_unbox_integer(_clockIndex);
omc_System_realtimeTick(threadData, tmp1);
return;
}
modelica_integer omc_System_getuid(threadData_t *threadData)
{
int _uid_ext;
modelica_integer _uid;
_uid_ext = System_getuid();
_uid = (modelica_integer)_uid_ext;
return _uid;
}
modelica_metatype boxptr_System_getuid(threadData_t *threadData)
{
modelica_integer _uid;
modelica_metatype out_uid;
_uid = omc_System_getuid(threadData);
out_uid = mmc_mk_icon(_uid);
return out_uid;
}
modelica_boolean omc_System_userIsRoot(threadData_t *threadData)
{
int _isRoot_ext;
modelica_boolean _isRoot;
_isRoot_ext = System_userIsRoot();
_isRoot = (modelica_boolean)_isRoot_ext;
return _isRoot;
}
modelica_metatype boxptr_System_userIsRoot(threadData_t *threadData)
{
modelica_boolean _isRoot;
modelica_metatype out_isRoot;
_isRoot = omc_System_userIsRoot(threadData);
out_isRoot = mmc_mk_icon(_isRoot);
return out_isRoot;
}
modelica_integer omc_System_tmpTickMaximum(threadData_t *threadData, modelica_integer _index)
{
int _index_ext;
int _maxIndex_ext;
modelica_integer _maxIndex;
_index_ext = (int)_index;
_maxIndex_ext = SystemImpl_tmpTickMaximum(threadData, _index_ext);
_maxIndex = (modelica_integer)_maxIndex_ext;
return _maxIndex;
}
modelica_metatype boxptr_System_tmpTickMaximum(threadData_t *threadData, modelica_metatype _index)
{
modelica_integer tmp1;
modelica_integer _maxIndex;
modelica_metatype out_maxIndex;
tmp1 = mmc_unbox_integer(_index);
_maxIndex = omc_System_tmpTickMaximum(threadData, tmp1);
out_maxIndex = mmc_mk_icon(_maxIndex);
return out_maxIndex;
}
void omc_System_tmpTickSetIndex(threadData_t *threadData, modelica_integer _start, modelica_integer _index)
{
int _start_ext;
int _index_ext;
_start_ext = (int)_start;
_index_ext = (int)_index;
SystemImpl_tmpTickSetIndex(threadData, _start_ext, _index_ext);
return;
}
void boxptr_System_tmpTickSetIndex(threadData_t *threadData, modelica_metatype _start, modelica_metatype _index)
{
modelica_integer tmp1;
modelica_integer tmp2;
tmp1 = mmc_unbox_integer(_start);
tmp2 = mmc_unbox_integer(_index);
omc_System_tmpTickSetIndex(threadData, tmp1, tmp2);
return;
}
void omc_System_tmpTickResetIndex(threadData_t *threadData, modelica_integer _start, modelica_integer _index)
{
int _start_ext;
int _index_ext;
_start_ext = (int)_start;
_index_ext = (int)_index;
SystemImpl_tmpTickResetIndex(threadData, _start_ext, _index_ext);
return;
}
void boxptr_System_tmpTickResetIndex(threadData_t *threadData, modelica_metatype _start, modelica_metatype _index)
{
modelica_integer tmp1;
modelica_integer tmp2;
tmp1 = mmc_unbox_integer(_start);
tmp2 = mmc_unbox_integer(_index);
omc_System_tmpTickResetIndex(threadData, tmp1, tmp2);
return;
}
modelica_integer omc_System_tmpTickIndexReserve(threadData_t *threadData, modelica_integer _index, modelica_integer _reserve)
{
int _index_ext;
int _reserve_ext;
int _tickNo_ext;
modelica_integer _tickNo;
_index_ext = (int)_index;
_reserve_ext = (int)_reserve;
_tickNo_ext = SystemImpl_tmpTickIndexReserve(threadData, _index_ext, _reserve_ext);
_tickNo = (modelica_integer)_tickNo_ext;
return _tickNo;
}
modelica_metatype boxptr_System_tmpTickIndexReserve(threadData_t *threadData, modelica_metatype _index, modelica_metatype _reserve)
{
modelica_integer tmp1;
modelica_integer tmp2;
modelica_integer _tickNo;
modelica_metatype out_tickNo;
tmp1 = mmc_unbox_integer(_index);
tmp2 = mmc_unbox_integer(_reserve);
_tickNo = omc_System_tmpTickIndexReserve(threadData, tmp1, tmp2);
out_tickNo = mmc_mk_icon(_tickNo);
return out_tickNo;
}
modelica_integer omc_System_tmpTickIndex(threadData_t *threadData, modelica_integer _index)
{
int _index_ext;
int _tickNo_ext;
modelica_integer _tickNo;
_index_ext = (int)_index;
_tickNo_ext = SystemImpl_tmpTickIndex(threadData, _index_ext);
_tickNo = (modelica_integer)_tickNo_ext;
return _tickNo;
}
modelica_metatype boxptr_System_tmpTickIndex(threadData_t *threadData, modelica_metatype _index)
{
modelica_integer tmp1;
modelica_integer _tickNo;
modelica_metatype out_tickNo;
tmp1 = mmc_unbox_integer(_index);
_tickNo = omc_System_tmpTickIndex(threadData, tmp1);
out_tickNo = mmc_mk_icon(_tickNo);
return out_tickNo;
}
void omc_System_tmpTickReset(threadData_t *threadData, modelica_integer _start)
{
int _start_ext;
_start_ext = (int)_start;
SystemImpl_tmpTickReset(threadData, _start_ext);
return;
}
void boxptr_System_tmpTickReset(threadData_t *threadData, modelica_metatype _start)
{
modelica_integer tmp1;
tmp1 = mmc_unbox_integer(_start);
omc_System_tmpTickReset(threadData, tmp1);
return;
}
DLLExport
modelica_integer omc_System_tmpTick(threadData_t *threadData)
{
modelica_integer _tickNo;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
_tickNo = omc_System_tmpTickIndex(threadData, ((modelica_integer) 0));
_return: OMC_LABEL_UNUSED
return _tickNo;
}
modelica_metatype boxptr_System_tmpTick(threadData_t *threadData)
{
modelica_integer _tickNo;
modelica_metatype out_tickNo;
_tickNo = omc_System_tmpTick(threadData);
out_tickNo = mmc_mk_icon(_tickNo);
return out_tickNo;
}
modelica_boolean omc_System_getHasInnerOuterDefinitions(threadData_t *threadData)
{
int _hasInnerOuterDefinitions_ext;
modelica_boolean _hasInnerOuterDefinitions;
_hasInnerOuterDefinitions_ext = System_getHasInnerOuterDefinitions();
_hasInnerOuterDefinitions = (modelica_boolean)_hasInnerOuterDefinitions_ext;
return _hasInnerOuterDefinitions;
}
modelica_metatype boxptr_System_getHasInnerOuterDefinitions(threadData_t *threadData)
{
modelica_boolean _hasInnerOuterDefinitions;
modelica_metatype out_hasInnerOuterDefinitions;
_hasInnerOuterDefinitions = omc_System_getHasInnerOuterDefinitions(threadData);
out_hasInnerOuterDefinitions = mmc_mk_icon(_hasInnerOuterDefinitions);
return out_hasInnerOuterDefinitions;
}
void omc_System_setHasInnerOuterDefinitions(threadData_t *threadData, modelica_boolean _hasInnerOuterDefinitions)
{
int _hasInnerOuterDefinitions_ext;
_hasInnerOuterDefinitions_ext = (int)_hasInnerOuterDefinitions;
System_setHasInnerOuterDefinitions(_hasInnerOuterDefinitions_ext);
return;
}
void boxptr_System_setHasInnerOuterDefinitions(threadData_t *threadData, modelica_metatype _hasInnerOuterDefinitions)
{
modelica_integer tmp1;
tmp1 = mmc_unbox_integer(_hasInnerOuterDefinitions);
omc_System_setHasInnerOuterDefinitions(threadData, tmp1);
return;
}
modelica_boolean omc_System_getUsesCardinality(threadData_t *threadData)
{
int _outUses_ext;
modelica_boolean _outUses;
_outUses_ext = System_getUsesCardinality();
_outUses = (modelica_boolean)_outUses_ext;
return _outUses;
}
modelica_metatype boxptr_System_getUsesCardinality(threadData_t *threadData)
{
modelica_boolean _outUses;
modelica_metatype out_outUses;
_outUses = omc_System_getUsesCardinality(threadData);
out_outUses = mmc_mk_icon(_outUses);
return out_outUses;
}
void omc_System_setUsesCardinality(threadData_t *threadData, modelica_boolean _inUses)
{
int _inUses_ext;
_inUses_ext = (int)_inUses;
System_setUsesCardinality(_inUses_ext);
return;
}
void boxptr_System_setUsesCardinality(threadData_t *threadData, modelica_metatype _inUses)
{
modelica_integer tmp1;
tmp1 = mmc_unbox_integer(_inUses);
omc_System_setUsesCardinality(threadData, tmp1);
return;
}
modelica_boolean omc_System_getHasStreamConnectors(threadData_t *threadData)
{
int _hasStream_ext;
modelica_boolean _hasStream;
_hasStream_ext = System_getHasStreamConnectors();
_hasStream = (modelica_boolean)_hasStream_ext;
return _hasStream;
}
modelica_metatype boxptr_System_getHasStreamConnectors(threadData_t *threadData)
{
modelica_boolean _hasStream;
modelica_metatype out_hasStream;
_hasStream = omc_System_getHasStreamConnectors(threadData);
out_hasStream = mmc_mk_icon(_hasStream);
return out_hasStream;
}
void omc_System_setHasStreamConnectors(threadData_t *threadData, modelica_boolean _hasStream)
{
int _hasStream_ext;
_hasStream_ext = (int)_hasStream;
System_setHasStreamConnectors(_hasStream_ext);
return;
}
void boxptr_System_setHasStreamConnectors(threadData_t *threadData, modelica_metatype _hasStream)
{
modelica_integer tmp1;
tmp1 = mmc_unbox_integer(_hasStream);
omc_System_setHasStreamConnectors(threadData, tmp1);
return;
}
modelica_boolean omc_System_getPartialInstantiation(threadData_t *threadData)
{
int _isPartialInstantiation_ext;
modelica_boolean _isPartialInstantiation;
_isPartialInstantiation_ext = System_getPartialInstantiation();
_isPartialInstantiation = (modelica_boolean)_isPartialInstantiation_ext;
return _isPartialInstantiation;
}
modelica_metatype boxptr_System_getPartialInstantiation(threadData_t *threadData)
{
modelica_boolean _isPartialInstantiation;
modelica_metatype out_isPartialInstantiation;
_isPartialInstantiation = omc_System_getPartialInstantiation(threadData);
out_isPartialInstantiation = mmc_mk_icon(_isPartialInstantiation);
return out_isPartialInstantiation;
}
void omc_System_setPartialInstantiation(threadData_t *threadData, modelica_boolean _isPartialInstantiation)
{
int _isPartialInstantiation_ext;
_isPartialInstantiation_ext = (int)_isPartialInstantiation;
System_setPartialInstantiation(_isPartialInstantiation_ext);
return;
}
void boxptr_System_setPartialInstantiation(threadData_t *threadData, modelica_metatype _isPartialInstantiation)
{
modelica_integer tmp1;
tmp1 = mmc_unbox_integer(_isPartialInstantiation);
omc_System_setPartialInstantiation(threadData, tmp1);
return;
}
modelica_boolean omc_System_getHasOverconstrainedConnectors(threadData_t *threadData)
{
int _hasOverconstrained_ext;
modelica_boolean _hasOverconstrained;
_hasOverconstrained_ext = System_getHasOverconstrainedConnectors();
_hasOverconstrained = (modelica_boolean)_hasOverconstrained_ext;
return _hasOverconstrained;
}
modelica_metatype boxptr_System_getHasOverconstrainedConnectors(threadData_t *threadData)
{
modelica_boolean _hasOverconstrained;
modelica_metatype out_hasOverconstrained;
_hasOverconstrained = omc_System_getHasOverconstrainedConnectors(threadData);
out_hasOverconstrained = mmc_mk_icon(_hasOverconstrained);
return out_hasOverconstrained;
}
void omc_System_setHasOverconstrainedConnectors(threadData_t *threadData, modelica_boolean _hasOverconstrained)
{
int _hasOverconstrained_ext;
_hasOverconstrained_ext = (int)_hasOverconstrained;
System_setHasOverconstrainedConnectors(_hasOverconstrained_ext);
return;
}
void boxptr_System_setHasOverconstrainedConnectors(threadData_t *threadData, modelica_metatype _hasOverconstrained)
{
modelica_integer tmp1;
tmp1 = mmc_unbox_integer(_hasOverconstrained);
omc_System_setHasOverconstrainedConnectors(threadData, tmp1);
return;
}
modelica_boolean omc_System_getHasExpandableConnectors(threadData_t *threadData)
{
int _hasExpandable_ext;
modelica_boolean _hasExpandable;
_hasExpandable_ext = System_getHasExpandableConnectors();
_hasExpandable = (modelica_boolean)_hasExpandable_ext;
return _hasExpandable;
}
modelica_metatype boxptr_System_getHasExpandableConnectors(threadData_t *threadData)
{
modelica_boolean _hasExpandable;
modelica_metatype out_hasExpandable;
_hasExpandable = omc_System_getHasExpandableConnectors(threadData);
out_hasExpandable = mmc_mk_icon(_hasExpandable);
return out_hasExpandable;
}
void omc_System_setHasExpandableConnectors(threadData_t *threadData, modelica_boolean _hasExpandable)
{
int _hasExpandable_ext;
_hasExpandable_ext = (int)_hasExpandable;
System_setHasExpandableConnectors(_hasExpandable_ext);
return;
}
void boxptr_System_setHasExpandableConnectors(threadData_t *threadData, modelica_metatype _hasExpandable)
{
modelica_integer tmp1;
tmp1 = mmc_unbox_integer(_hasExpandable);
omc_System_setHasExpandableConnectors(threadData, tmp1);
return;
}
modelica_string omc_System_readFileNoNumeric(threadData_t *threadData, modelica_string _inString)
{
const char* _outString_ext;
modelica_string _outString = NULL;
_outString_ext = SystemImpl__readFileNoNumeric(MMC_STRINGDATA(_inString));
_outString = (modelica_string)mmc_mk_scon(_outString_ext);
return _outString;
}
modelica_string omc_System_getCurrentTimeStr(threadData_t *threadData)
{
const char* _timeStr_ext;
modelica_string _timeStr = NULL;
_timeStr_ext = System_getCurrentTimeStr();
_timeStr = (modelica_string)mmc_mk_scon(_timeStr_ext);
return _timeStr;
}
modelica_integer omc_System_getCurrentDateTime(threadData_t *threadData, modelica_integer *out_min, modelica_integer *out_hour, modelica_integer *out_mday, modelica_integer *out_mon, modelica_integer *out_year)
{
int _sec_ext;
int _min_ext;
int _hour_ext;
int _mday_ext;
int _mon_ext;
int _year_ext;
modelica_integer _sec;
modelica_integer _min;
modelica_integer _hour;
modelica_integer _mday;
modelica_integer _mon;
modelica_integer _year;
System_getCurrentDateTime(&_sec_ext, &_min_ext, &_hour_ext, &_mday_ext, &_mon_ext, &_year_ext);
_sec = (modelica_integer)_sec_ext;
_min = (modelica_integer)_min_ext;
_hour = (modelica_integer)_hour_ext;
_mday = (modelica_integer)_mday_ext;
_mon = (modelica_integer)_mon_ext;
_year = (modelica_integer)_year_ext;
if (out_min) { *out_min = _min; }
if (out_hour) { *out_hour = _hour; }
if (out_mday) { *out_mday = _mday; }
if (out_mon) { *out_mon = _mon; }
if (out_year) { *out_year = _year; }
return _sec;
}
modelica_metatype boxptr_System_getCurrentDateTime(threadData_t *threadData, modelica_metatype *out_min, modelica_metatype *out_hour, modelica_metatype *out_mday, modelica_metatype *out_mon, modelica_metatype *out_year)
{
modelica_integer _min;
modelica_integer _hour;
modelica_integer _mday;
modelica_integer _mon;
modelica_integer _year;
modelica_integer _sec;
modelica_metatype out_sec;
_sec = omc_System_getCurrentDateTime(threadData, &_min, &_hour, &_mday, &_mon, &_year);
out_sec = mmc_mk_icon(_sec);
if (out_min) { *out_min = mmc_mk_icon(_min); }
if (out_hour) { *out_hour = mmc_mk_icon(_hour); }
if (out_mday) { *out_mday = mmc_mk_icon(_mday); }
if (out_mon) { *out_mon = mmc_mk_icon(_mon); }
if (out_year) { *out_year = mmc_mk_icon(_year); }
return out_sec;
}
modelica_real omc_System_getCurrentTime(threadData_t *threadData)
{
double _outValue_ext;
modelica_real _outValue;
_outValue_ext = SystemImpl__getCurrentTime();
_outValue = (modelica_real)_outValue_ext;
return _outValue;
}
modelica_metatype boxptr_System_getCurrentTime(threadData_t *threadData)
{
modelica_real _outValue;
modelica_metatype out_outValue;
_outValue = omc_System_getCurrentTime(threadData);
out_outValue = mmc_mk_rcon(_outValue);
return out_outValue;
}
modelica_metatype omc_System_getFileModificationTime(threadData_t *threadData, modelica_string _fileName)
{
modelica_metatype _outValue_ext;
modelica_metatype _outValue = NULL;
_outValue_ext = System_getFileModificationTime(MMC_STRINGDATA(_fileName));
_outValue = (modelica_metatype)_outValue_ext;
return _outValue;
}
modelica_real omc_System_getVariableValue(threadData_t *threadData, modelica_real _timeStamp, modelica_metatype _timeValues, modelica_metatype _varValues)
{
double _timeStamp_ext;
modelica_metatype _timeValues_ext;
modelica_metatype _varValues_ext;
double _outValue_ext;
modelica_real _outValue;
_timeStamp_ext = (double)_timeStamp;
_timeValues_ext = (modelica_metatype)_timeValues;
_varValues_ext = (modelica_metatype)_varValues;
_outValue_ext = System_getVariableValue(_timeStamp_ext, _timeValues_ext, _varValues_ext);
_outValue = (modelica_real)_outValue_ext;
return _outValue;
}
modelica_metatype boxptr_System_getVariableValue(threadData_t *threadData, modelica_metatype _timeStamp, modelica_metatype _timeValues, modelica_metatype _varValues)
{
modelica_real tmp1;
modelica_real _outValue;
modelica_metatype out_outValue;
tmp1 = mmc_unbox_real(_timeStamp);
_outValue = omc_System_getVariableValue(threadData, tmp1, _timeValues, _varValues);
out_outValue = mmc_mk_rcon(_outValue);
return out_outValue;
}
void omc_System_setClassnamesForSimulation(threadData_t *threadData, modelica_string _inString)
{
System_setClassnamesForSimulation(MMC_STRINGDATA(_inString));
return;
}
modelica_string omc_System_getClassnamesForSimulation(threadData_t *threadData)
{
const char* _outString_ext;
modelica_string _outString = NULL;
_outString_ext = System_getClassnamesForSimulation();
_outString = (modelica_string)mmc_mk_scon(_outString_ext);
return _outString;
}
PROTECTED_FUNCTION_STATIC modelica_boolean omc_System_removeDirectory__dispatch(threadData_t *threadData, modelica_string _inString)
{
int _outBool_ext;
modelica_boolean _outBool;
_outBool_ext = SystemImpl__removeDirectory(MMC_STRINGDATA(_inString));
_outBool = (modelica_boolean)_outBool_ext;
return _outBool;
}
PROTECTED_FUNCTION_STATIC modelica_metatype boxptr_System_removeDirectory__dispatch(threadData_t *threadData, modelica_metatype _inString)
{
modelica_boolean _outBool;
modelica_metatype out_outBool;
_outBool = omc_System_removeDirectory__dispatch(threadData, _inString);
out_outBool = mmc_mk_icon(_outBool);
return out_outBool;
}
DLLExport
modelica_boolean omc_System_removeDirectory(threadData_t *threadData, modelica_string _inString)
{
modelica_boolean _outBool;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
_outBool = omc_System_removeDirectory__dispatch(threadData, _inString);
if((!_outBool))
{
}
_return: OMC_LABEL_UNUSED
return _outBool;
}
modelica_metatype boxptr_System_removeDirectory(threadData_t *threadData, modelica_metatype _inString)
{
modelica_boolean _outBool;
modelica_metatype out_outBool;
_outBool = omc_System_removeDirectory(threadData, _inString);
out_outBool = mmc_mk_icon(_outBool);
return out_outBool;
}
modelica_boolean omc_System_copyFile(threadData_t *threadData, modelica_string _source, modelica_string _destination)
{
int _outBool_ext;
modelica_boolean _outBool;
_outBool_ext = SystemImpl__copyFile(MMC_STRINGDATA(_source), MMC_STRINGDATA(_destination));
_outBool = (modelica_boolean)_outBool_ext;
return _outBool;
}
modelica_metatype boxptr_System_copyFile(threadData_t *threadData, modelica_metatype _source, modelica_metatype _destination)
{
modelica_boolean _outBool;
modelica_metatype out_outBool;
_outBool = omc_System_copyFile(threadData, _source, _destination);
out_outBool = mmc_mk_icon(_outBool);
return out_outBool;
}
modelica_boolean omc_System_directoryExists(threadData_t *threadData, modelica_string _inString)
{
int _outBool_ext;
modelica_boolean _outBool;
_outBool_ext = SystemImpl__directoryExists(MMC_STRINGDATA(_inString));
_outBool = (modelica_boolean)_outBool_ext;
return _outBool;
}
modelica_metatype boxptr_System_directoryExists(threadData_t *threadData, modelica_metatype _inString)
{
modelica_boolean _outBool;
modelica_metatype out_outBool;
_outBool = omc_System_directoryExists(threadData, _inString);
out_outBool = mmc_mk_icon(_outBool);
return out_outBool;
}
modelica_integer omc_System_removeFile(threadData_t *threadData, modelica_string _fileName)
{
int _res_ext;
modelica_integer _res;
_res_ext = SystemImpl__removeFile(MMC_STRINGDATA(_fileName));
_res = (modelica_integer)_res_ext;
return _res;
}
modelica_metatype boxptr_System_removeFile(threadData_t *threadData, modelica_metatype _fileName)
{
modelica_integer _res;
modelica_metatype out_res;
_res = omc_System_removeFile(threadData, _fileName);
out_res = mmc_mk_icon(_res);
return out_res;
}
modelica_boolean omc_System_regularFileExists(threadData_t *threadData, modelica_string _inString)
{
int _outBool_ext;
modelica_boolean _outBool;
_outBool_ext = SystemImpl__regularFileExists(MMC_STRINGDATA(_inString));
_outBool = (modelica_boolean)_outBool_ext;
return _outBool;
}
modelica_metatype boxptr_System_regularFileExists(threadData_t *threadData, modelica_metatype _inString)
{
modelica_boolean _outBool;
modelica_metatype out_outBool;
_outBool = omc_System_regularFileExists(threadData, _inString);
out_outBool = mmc_mk_icon(_outBool);
return out_outBool;
}
modelica_real omc_System_time(threadData_t *threadData)
{
double _outReal_ext;
modelica_real _outReal;
_outReal_ext = SystemImpl__time();
_outReal = (modelica_real)_outReal_ext;
return _outReal;
}
modelica_metatype boxptr_System_time(threadData_t *threadData)
{
modelica_real _outReal;
modelica_metatype out_outReal;
_outReal = omc_System_time(threadData);
out_outReal = mmc_mk_rcon(_outReal);
return out_outReal;
}
modelica_string omc_System_getLoadModelPath(threadData_t *threadData, modelica_string _className, modelica_metatype _prios, modelica_metatype _mps, modelica_boolean _requireExactVersion, modelica_string *out_name, modelica_boolean *out_isDir)
{
modelica_metatype _prios_ext;
modelica_metatype _mps_ext;
int _requireExactVersion_ext;
const char* _dir_ext;
const char* _name_ext;
int _isDir_ext;
modelica_string _dir = NULL;
modelica_string _name = NULL;
modelica_boolean _isDir;
_prios_ext = (modelica_metatype)_prios;
_mps_ext = (modelica_metatype)_mps;
_requireExactVersion_ext = (int)_requireExactVersion;
System_getLoadModelPath(MMC_STRINGDATA(_className), _prios_ext, _mps_ext, _requireExactVersion_ext, &_dir_ext, &_name_ext, &_isDir_ext);
_dir = (modelica_string)mmc_mk_scon(_dir_ext);
_name = (modelica_string)mmc_mk_scon(_name_ext);
_isDir = (modelica_boolean)_isDir_ext;
if (out_name) { *out_name = _name; }
if (out_isDir) { *out_isDir = _isDir; }
return _dir;
}
modelica_metatype boxptr_System_getLoadModelPath(threadData_t *threadData, modelica_metatype _className, modelica_metatype _prios, modelica_metatype _mps, modelica_metatype _requireExactVersion, modelica_metatype *out_name, modelica_metatype *out_isDir)
{
modelica_integer tmp1;
modelica_boolean _isDir;
modelica_string _dir = NULL;
tmp1 = mmc_unbox_integer(_requireExactVersion);
_dir = omc_System_getLoadModelPath(threadData, _className, _prios, _mps, tmp1, out_name, &_isDir);
if (out_isDir) { *out_isDir = mmc_mk_icon(_isDir); }
return _dir;
}
modelica_metatype omc_System_mocFiles(threadData_t *threadData, modelica_string _inString)
{
modelica_metatype _outStringLst_ext;
modelica_metatype _outStringLst = NULL;
_outStringLst_ext = System_mocFiles(MMC_STRINGDATA(_inString));
_outStringLst = (modelica_metatype)_outStringLst_ext;
return _outStringLst;
}
modelica_metatype omc_System_moFiles(threadData_t *threadData, modelica_string _inString)
{
modelica_metatype _outStringLst_ext;
modelica_metatype _outStringLst = NULL;
_outStringLst_ext = System_moFiles(MMC_STRINGDATA(_inString));
_outStringLst = (modelica_metatype)_outStringLst_ext;
return _outStringLst;
}
modelica_metatype omc_System_subDirectories(threadData_t *threadData, modelica_string _inString)
{
modelica_metatype _outStringLst_ext;
modelica_metatype _outStringLst = NULL;
_outStringLst_ext = System_subDirectories(MMC_STRINGDATA(_inString));
_outStringLst = (modelica_metatype)_outStringLst_ext;
return _outStringLst;
}
modelica_integer omc_System_setEnv(threadData_t *threadData, modelica_string _varName, modelica_string _value, modelica_boolean _overwrite)
{
int _overwrite_ext;
int _outInteger_ext;
modelica_integer _outInteger;
_overwrite_ext = (int)_overwrite;
_outInteger_ext = setenv(MMC_STRINGDATA(_varName), MMC_STRINGDATA(_value), _overwrite_ext);
_outInteger = (modelica_integer)_outInteger_ext;
return _outInteger;
}
modelica_metatype boxptr_System_setEnv(threadData_t *threadData, modelica_metatype _varName, modelica_metatype _value, modelica_metatype _overwrite)
{
modelica_integer tmp1;
modelica_integer _outInteger;
modelica_metatype out_outInteger;
tmp1 = mmc_unbox_integer(_overwrite);
_outInteger = omc_System_setEnv(threadData, _varName, _value, tmp1);
out_outInteger = mmc_mk_icon(_outInteger);
return out_outInteger;
}
modelica_string omc_System_readEnv(threadData_t *threadData, modelica_string _inString)
{
const char* _outString_ext;
modelica_string _outString = NULL;
_outString_ext = System_readEnv(MMC_STRINGDATA(_inString));
_outString = (modelica_string)mmc_mk_scon(_outString_ext);
return _outString;
}
modelica_string omc_System_pwd(threadData_t *threadData)
{
const char* _outString_ext;
modelica_string _outString = NULL;
_outString_ext = SystemImpl__pwd();
_outString = (modelica_string)mmc_mk_scon(_outString_ext);
return _outString;
}
modelica_string omc_System_createTemporaryDirectory(threadData_t *threadData, modelica_string _inPrefix)
{
const char* _outName_ext;
modelica_string _outName = NULL;
_outName_ext = SystemImpl__createTemporaryDirectory(MMC_STRINGDATA(_inPrefix));
_outName = (modelica_string)mmc_mk_scon(_outName_ext);
return _outName;
}
modelica_boolean omc_System_createDirectory(threadData_t *threadData, modelica_string _inString)
{
int _outBool_ext;
modelica_boolean _outBool;
_outBool_ext = SystemImpl__createDirectory(MMC_STRINGDATA(_inString));
_outBool = (modelica_boolean)_outBool_ext;
return _outBool;
}
modelica_metatype boxptr_System_createDirectory(threadData_t *threadData, modelica_metatype _inString)
{
modelica_boolean _outBool;
modelica_metatype out_outBool;
_outBool = omc_System_createDirectory(threadData, _inString);
out_outBool = mmc_mk_icon(_outBool);
return out_outBool;
}
modelica_integer omc_System_cd(threadData_t *threadData, modelica_string _inString)
{
int _outInteger_ext;
modelica_integer _outInteger;
_outInteger_ext = SystemImpl__chdir(MMC_STRINGDATA(_inString));
_outInteger = (modelica_integer)_outInteger_ext;
return _outInteger;
}
modelica_metatype boxptr_System_cd(threadData_t *threadData, modelica_metatype _inString)
{
modelica_integer _outInteger;
modelica_metatype out_outInteger;
_outInteger = omc_System_cd(threadData, _inString);
out_outInteger = mmc_mk_icon(_outInteger);
return out_outInteger;
}
void omc_System_plotCallBack(threadData_t *threadData, modelica_boolean _externalWindow, modelica_string _filename, modelica_string _title, modelica_string _grid, modelica_string _plotType, modelica_string _logX, modelica_string _logY, modelica_string _xLabel, modelica_string _yLabel, modelica_string _x1, modelica_string _x2, modelica_string _y1, modelica_string _y2, modelica_string _curveWidth, modelica_string _curveStyle, modelica_string _legendPosition, modelica_string _footer, modelica_string _autoScale, modelica_string _variables)
{
int _externalWindow_ext;
_externalWindow_ext = (int)_externalWindow;
SystemImpl__plotCallBack(threadData, _externalWindow_ext, MMC_STRINGDATA(_filename), MMC_STRINGDATA(_title), MMC_STRINGDATA(_grid), MMC_STRINGDATA(_plotType), MMC_STRINGDATA(_logX), MMC_STRINGDATA(_logY), MMC_STRINGDATA(_xLabel), MMC_STRINGDATA(_yLabel), MMC_STRINGDATA(_x1), MMC_STRINGDATA(_x2), MMC_STRINGDATA(_y1), MMC_STRINGDATA(_y2), MMC_STRINGDATA(_curveWidth), MMC_STRINGDATA(_curveStyle), MMC_STRINGDATA(_legendPosition), MMC_STRINGDATA(_footer), MMC_STRINGDATA(_autoScale), MMC_STRINGDATA(_variables));
return;
}
void boxptr_System_plotCallBack(threadData_t *threadData, modelica_metatype _externalWindow, modelica_metatype _filename, modelica_metatype _title, modelica_metatype _grid, modelica_metatype _plotType, modelica_metatype _logX, modelica_metatype _logY, modelica_metatype _xLabel, modelica_metatype _yLabel, modelica_metatype _x1, modelica_metatype _x2, modelica_metatype _y1, modelica_metatype _y2, modelica_metatype _curveWidth, modelica_metatype _curveStyle, modelica_metatype _legendPosition, modelica_metatype _footer, modelica_metatype _autoScale, modelica_metatype _variables)
{
modelica_integer tmp1;
tmp1 = mmc_unbox_integer(_externalWindow);
omc_System_plotCallBack(threadData, tmp1, _filename, _title, _grid, _plotType, _logX, _logY, _xLabel, _yLabel, _x1, _x2, _y1, _y2, _curveWidth, _curveStyle, _legendPosition, _footer, _autoScale, _variables);
return;
}
modelica_boolean omc_System_plotCallBackDefined(threadData_t *threadData)
{
int _outBoolean_ext;
modelica_boolean _outBoolean;
_outBoolean_ext = SystemImpl__plotCallBackDefined(threadData);
_outBoolean = (modelica_boolean)_outBoolean_ext;
return _outBoolean;
}
modelica_metatype boxptr_System_plotCallBackDefined(threadData_t *threadData)
{
modelica_boolean _outBoolean;
modelica_metatype out_outBoolean;
_outBoolean = omc_System_plotCallBackDefined(threadData);
out_outBoolean = mmc_mk_icon(_outBoolean);
return out_outBoolean;
}
modelica_integer omc_System_spawnCall(threadData_t *threadData, modelica_string _path, modelica_string _str)
{
int _outInteger_ext;
modelica_integer _outInteger;
_outInteger_ext = SystemImpl__spawnCall(MMC_STRINGDATA(_path), MMC_STRINGDATA(_str));
_outInteger = (modelica_integer)_outInteger_ext;
return _outInteger;
}
modelica_metatype boxptr_System_spawnCall(threadData_t *threadData, modelica_metatype _path, modelica_metatype _str)
{
modelica_integer _outInteger;
modelica_metatype out_outInteger;
_outInteger = omc_System_spawnCall(threadData, _path, _str);
out_outInteger = mmc_mk_icon(_outInteger);
return out_outInteger;
}
modelica_metatype omc_System_systemCallParallel(threadData_t *threadData, modelica_metatype _inStrings, modelica_integer _numThreads)
{
modelica_metatype _inStrings_ext;
int _numThreads_ext;
modelica_metatype _outIntegers_ext;
modelica_metatype _outIntegers = NULL;
_inStrings_ext = (modelica_metatype)_inStrings;
_numThreads_ext = (int)_numThreads;
_outIntegers_ext = SystemImpl__systemCallParallel(_inStrings_ext, _numThreads_ext);
_outIntegers = (modelica_metatype)_outIntegers_ext;
return _outIntegers;
}
modelica_metatype boxptr_System_systemCallParallel(threadData_t *threadData, modelica_metatype _inStrings, modelica_metatype _numThreads)
{
modelica_integer tmp1;
modelica_metatype _outIntegers = NULL;
tmp1 = mmc_unbox_integer(_numThreads);
_outIntegers = omc_System_systemCallParallel(threadData, _inStrings, tmp1);
return _outIntegers;
}
modelica_string omc_System_popen(threadData_t *threadData, modelica_string _command, modelica_integer *out_status)
{
int _status_ext;
const char* _contents_ext;
modelica_string _contents = NULL;
modelica_integer _status;
_contents_ext = System_popen(threadData, MMC_STRINGDATA(_command), &_status_ext);
_status = (modelica_integer)_status_ext;
_contents = (modelica_string)mmc_mk_scon(_contents_ext);
if (out_status) { *out_status = _status; }
return _contents;
}
modelica_metatype boxptr_System_popen(threadData_t *threadData, modelica_metatype _command, modelica_metatype *out_status)
{
modelica_integer _status;
modelica_string _contents = NULL;
_contents = omc_System_popen(threadData, _command, &_status);
if (out_status) { *out_status = mmc_mk_icon(_status); }
return _contents;
}
modelica_integer omc_System_systemCall(threadData_t *threadData, modelica_string _command, modelica_string _outFile)
{
int _outInteger_ext;
modelica_integer _outInteger;
_outInteger_ext = SystemImpl__systemCall(MMC_STRINGDATA(_command), MMC_STRINGDATA(_outFile));
_outInteger = (modelica_integer)_outInteger_ext;
return _outInteger;
}
modelica_metatype boxptr_System_systemCall(threadData_t *threadData, modelica_metatype _command, modelica_metatype _outFile)
{
modelica_integer _outInteger;
modelica_metatype out_outInteger;
_outInteger = omc_System_systemCall(threadData, _command, _outFile);
out_outInteger = mmc_mk_icon(_outInteger);
return out_outInteger;
}
modelica_string omc_System_readFile(threadData_t *threadData, modelica_string _inString)
{
const char* _outString_ext;
modelica_string _outString = NULL;
_outString_ext = System_readFile(MMC_STRINGDATA(_inString));
_outString = (modelica_string)mmc_mk_scon(_outString_ext);
return _outString;
}
void omc_System_appendFile(threadData_t *threadData, modelica_string _file, modelica_string _data)
{
System_appendFile(MMC_STRINGDATA(_file), MMC_STRINGDATA(_data));
return;
}
void omc_System_writeFile(threadData_t *threadData, modelica_string _fileNameToWrite, modelica_string _stringToBeWritten)
{
System_writeFile(MMC_STRINGDATA(_fileNameToWrite), MMC_STRINGDATA(_stringToBeWritten));
return;
}
void omc_System_freeLibrary(threadData_t *threadData, modelica_integer _inLibHandle, modelica_boolean _inPrintDebug)
{
int _inLibHandle_ext;
int _inPrintDebug_ext;
_inLibHandle_ext = (int)_inLibHandle;
_inPrintDebug_ext = (int)_inPrintDebug;
System_freeLibrary(_inLibHandle_ext, _inPrintDebug_ext);
return;
}
void boxptr_System_freeLibrary(threadData_t *threadData, modelica_metatype _inLibHandle, modelica_metatype _inPrintDebug)
{
modelica_integer tmp1;
modelica_integer tmp2;
tmp1 = mmc_unbox_integer(_inLibHandle);
tmp2 = mmc_unbox_integer(_inPrintDebug);
omc_System_freeLibrary(threadData, tmp1, tmp2);
return;
}
void omc_System_freeFunction(threadData_t *threadData, modelica_integer _inFuncHandle, modelica_boolean _inPrintDebug)
{
int _inFuncHandle_ext;
int _inPrintDebug_ext;
_inFuncHandle_ext = (int)_inFuncHandle;
_inPrintDebug_ext = (int)_inPrintDebug;
System_freeFunction(_inFuncHandle_ext, _inPrintDebug_ext);
return;
}
void boxptr_System_freeFunction(threadData_t *threadData, modelica_metatype _inFuncHandle, modelica_metatype _inPrintDebug)
{
modelica_integer tmp1;
modelica_integer tmp2;
tmp1 = mmc_unbox_integer(_inFuncHandle);
tmp2 = mmc_unbox_integer(_inPrintDebug);
omc_System_freeFunction(threadData, tmp1, tmp2);
return;
}
modelica_integer omc_System_lookupFunction(threadData_t *threadData, modelica_integer _inLibHandle, modelica_string _inFunc)
{
int _inLibHandle_ext;
int _outFuncHandle_ext;
modelica_integer _outFuncHandle;
_inLibHandle_ext = (int)_inLibHandle;
_outFuncHandle_ext = System_lookupFunction(_inLibHandle_ext, MMC_STRINGDATA(_inFunc));
_outFuncHandle = (modelica_integer)_outFuncHandle_ext;
return _outFuncHandle;
}
modelica_metatype boxptr_System_lookupFunction(threadData_t *threadData, modelica_metatype _inLibHandle, modelica_metatype _inFunc)
{
modelica_integer tmp1;
modelica_integer _outFuncHandle;
modelica_metatype out_outFuncHandle;
tmp1 = mmc_unbox_integer(_inLibHandle);
_outFuncHandle = omc_System_lookupFunction(threadData, tmp1, _inFunc);
out_outFuncHandle = mmc_mk_icon(_outFuncHandle);
return out_outFuncHandle;
}
modelica_integer omc_System_loadLibrary(threadData_t *threadData, modelica_string _inLib, modelica_boolean _inPrintDebug)
{
int _inPrintDebug_ext;
int _outLibHandle_ext;
modelica_integer _outLibHandle;
_inPrintDebug_ext = (int)_inPrintDebug;
_outLibHandle_ext = System_loadLibrary(MMC_STRINGDATA(_inLib), _inPrintDebug_ext);
_outLibHandle = (modelica_integer)_outLibHandle_ext;
return _outLibHandle;
}
modelica_metatype boxptr_System_loadLibrary(threadData_t *threadData, modelica_metatype _inLib, modelica_metatype _inPrintDebug)
{
modelica_integer tmp1;
modelica_integer _outLibHandle;
modelica_metatype out_outLibHandle;
tmp1 = mmc_unbox_integer(_inPrintDebug);
_outLibHandle = omc_System_loadLibrary(threadData, _inLib, tmp1);
out_outLibHandle = mmc_mk_icon(_outLibHandle);
return out_outLibHandle;
}
modelica_string omc_System_getLDFlags(threadData_t *threadData)
{
const char* _outString_ext;
modelica_string _outString = NULL;
_outString_ext = System_getLDFlags();
_outString = (modelica_string)mmc_mk_scon(_outString_ext);
return _outString;
}
void omc_System_setLDFlags(threadData_t *threadData, modelica_string _inString)
{
SystemImpl__setLDFlags(MMC_STRINGDATA(_inString));
return;
}
modelica_string omc_System_getLinker(threadData_t *threadData)
{
const char* _outString_ext;
modelica_string _outString = NULL;
_outString_ext = System_getLinker();
_outString = (modelica_string)mmc_mk_scon(_outString_ext);
return _outString;
}
void omc_System_setLinker(threadData_t *threadData, modelica_string _inString)
{
SystemImpl__setLinker(MMC_STRINGDATA(_inString));
return;
}
modelica_string omc_System_getOMPCCompiler(threadData_t *threadData)
{
const char* _outString_ext;
modelica_string _outString = NULL;
_outString_ext = System_getOMPCCompiler();
_outString = (modelica_string)mmc_mk_scon(_outString_ext);
return _outString;
}
modelica_string omc_System_getCXXCompiler(threadData_t *threadData)
{
const char* _outString_ext;
modelica_string _outString = NULL;
_outString_ext = System_getCXXCompiler();
_outString = (modelica_string)mmc_mk_scon(_outString_ext);
return _outString;
}
void omc_System_setCXXCompiler(threadData_t *threadData, modelica_string _inString)
{
SystemImpl__setCXXCompiler(MMC_STRINGDATA(_inString));
return;
}
modelica_string omc_System_getCFlags(threadData_t *threadData)
{
const char* _outString_ext;
modelica_string _outString = NULL;
_outString_ext = System_getCFlags();
_outString = (modelica_string)mmc_mk_scon(_outString_ext);
return _outString;
}
void omc_System_setCFlags(threadData_t *threadData, modelica_string _inString)
{
SystemImpl__setCFlags(MMC_STRINGDATA(_inString));
return;
}
modelica_string omc_System_getCCompiler(threadData_t *threadData)
{
const char* _outString_ext;
modelica_string _outString = NULL;
_outString_ext = System_getCCompiler();
_outString = (modelica_string)mmc_mk_scon(_outString_ext);
return _outString;
}
void omc_System_setCCompiler(threadData_t *threadData, modelica_string _inString)
{
SystemImpl__setCCompiler(MMC_STRINGDATA(_inString));
return;
}
modelica_metatype omc_System_strtokIncludingDelimiters(threadData_t *threadData, modelica_string _string, modelica_string _token)
{
modelica_metatype _strings_ext;
modelica_metatype _strings = NULL;
_strings_ext = System_strtokIncludingDelimiters(MMC_STRINGDATA(_string), MMC_STRINGDATA(_token));
_strings = (modelica_metatype)_strings_ext;
return _strings;
}
modelica_metatype omc_System_strtok(threadData_t *threadData, modelica_string _string, modelica_string _token)
{
modelica_metatype _strings_ext;
modelica_metatype _strings = NULL;
_strings_ext = System_strtok(MMC_STRINGDATA(_string), MMC_STRINGDATA(_token));
_strings = (modelica_metatype)_strings_ext;
return _strings;
}
modelica_string omc_System_tolower(threadData_t *threadData, modelica_string _inString)
{
const char* _outString_ext;
modelica_string _outString = NULL;
_outString_ext = System_tolower(MMC_STRINGDATA(_inString));
_outString = (modelica_string)mmc_mk_scon(_outString_ext);
return _outString;
}
modelica_string omc_System_toupper(threadData_t *threadData, modelica_string _inString)
{
const char* _outString_ext;
modelica_string _outString = NULL;
_outString_ext = System_toupper(MMC_STRINGDATA(_inString));
_outString = (modelica_string)mmc_mk_scon(_outString_ext);
return _outString;
}
modelica_string omc_System_makeC89Identifier(threadData_t *threadData, modelica_string _str)
{
const char* _res_ext;
modelica_string _res = NULL;
_res_ext = System_makeC89Identifier(MMC_STRINGDATA(_str));
_res = (modelica_string)mmc_mk_scon(_res_ext);
return _res;
}
modelica_string omc_System_stringReplace(threadData_t *threadData, modelica_string _str, modelica_string _source, modelica_string _target)
{
const char* _res_ext;
modelica_string _res = NULL;
_res_ext = System_stringReplace(MMC_STRINGDATA(_str), MMC_STRINGDATA(_source), MMC_STRINGDATA(_target));
_res = (modelica_string)mmc_mk_scon(_res_ext);
return _res;
}
modelica_integer omc_System_strncmp(threadData_t *threadData, modelica_string _inString1, modelica_string _inString2, modelica_integer _len)
{
int _len_ext;
int _outInteger_ext;
modelica_integer _outInteger;
_len_ext = (int)_len;
_outInteger_ext = System_strncmp(MMC_STRINGDATA(_inString1), MMC_STRINGDATA(_inString2), _len_ext);
_outInteger = (modelica_integer)_outInteger_ext;
return _outInteger;
}
modelica_metatype boxptr_System_strncmp(threadData_t *threadData, modelica_metatype _inString1, modelica_metatype _inString2, modelica_metatype _len)
{
modelica_integer tmp1;
modelica_integer _outInteger;
modelica_metatype out_outInteger;
tmp1 = mmc_unbox_integer(_len);
_outInteger = omc_System_strncmp(threadData, _inString1, _inString2, tmp1);
out_outInteger = mmc_mk_icon(_outInteger);
return out_outInteger;
}
modelica_integer omc_System_regex(threadData_t *threadData, modelica_string _str, modelica_string _re, modelica_integer _maxMatches, modelica_boolean _extended, modelica_boolean _ignoreCase, modelica_metatype *out_strs)
{
int _maxMatches_ext;
int _extended_ext;
int _ignoreCase_ext;
int _numMatches_ext;
modelica_metatype _strs_ext;
modelica_integer _numMatches;
modelica_metatype _strs = NULL;
_maxMatches_ext = (int)_maxMatches;
_extended_ext = (int)_extended;
_ignoreCase_ext = (int)_ignoreCase;
_strs_ext = System_regex(MMC_STRINGDATA(_str), MMC_STRINGDATA(_re), _maxMatches_ext, _extended_ext, _ignoreCase_ext, &_numMatches_ext);
_numMatches = (modelica_integer)_numMatches_ext;
_strs = (modelica_metatype)_strs_ext;
if (out_strs) { *out_strs = _strs; }
return _numMatches;
}
modelica_metatype boxptr_System_regex(threadData_t *threadData, modelica_metatype _str, modelica_metatype _re, modelica_metatype _maxMatches, modelica_metatype _extended, modelica_metatype _ignoreCase, modelica_metatype *out_strs)
{
modelica_integer tmp1;
modelica_integer tmp2;
modelica_integer tmp3;
modelica_integer _numMatches;
modelica_metatype out_numMatches;
tmp1 = mmc_unbox_integer(_maxMatches);
tmp2 = mmc_unbox_integer(_extended);
tmp3 = mmc_unbox_integer(_ignoreCase);
_numMatches = omc_System_regex(threadData, _str, _re, tmp1, tmp2, tmp3, out_strs);
out_numMatches = mmc_mk_icon(_numMatches);
return out_numMatches;
}
modelica_string omc_System_stringFindString(threadData_t *threadData, modelica_string _str, modelica_string _searchStr)
{
const char* _outString_ext;
modelica_string _outString = NULL;
_outString_ext = System_stringFindString(MMC_STRINGDATA(_str), MMC_STRINGDATA(_searchStr));
_outString = (modelica_string)mmc_mk_scon(_outString_ext);
return _outString;
}
modelica_integer omc_System_stringFind(threadData_t *threadData, modelica_string _str, modelica_string _searchStr)
{
int _outInteger_ext;
modelica_integer _outInteger;
_outInteger_ext = System_stringFind(MMC_STRINGDATA(_str), MMC_STRINGDATA(_searchStr));
_outInteger = (modelica_integer)_outInteger_ext;
return _outInteger;
}
modelica_metatype boxptr_System_stringFind(threadData_t *threadData, modelica_metatype _str, modelica_metatype _searchStr)
{
modelica_integer _outInteger;
modelica_metatype out_outInteger;
_outInteger = omc_System_stringFind(threadData, _str, _searchStr);
out_outInteger = mmc_mk_icon(_outInteger);
return out_outInteger;
}
modelica_integer omc_System_strcmp__offset(threadData_t *threadData, modelica_string _string1, modelica_integer _offset1, modelica_integer _length1, modelica_string _string2, modelica_integer _offset2, modelica_integer _length2)
{
int _offset1_ext;
int _length1_ext;
int _offset2_ext;
int _length2_ext;
int _outInteger_ext;
modelica_integer _outInteger;
_offset1_ext = (int)_offset1;
_length1_ext = (int)_length1;
_offset2_ext = (int)_offset2;
_length2_ext = (int)_length2;
_outInteger_ext = System_strcmp_offset(MMC_STRINGDATA(_string1), _offset1_ext, _length1_ext, MMC_STRINGDATA(_string2), _offset2_ext, _length2_ext);
_outInteger = (modelica_integer)_outInteger_ext;
return _outInteger;
}
modelica_metatype boxptr_System_strcmp__offset(threadData_t *threadData, modelica_metatype _string1, modelica_metatype _offset1, modelica_metatype _length1, modelica_metatype _string2, modelica_metatype _offset2, modelica_metatype _length2)
{
modelica_integer tmp1;
modelica_integer tmp2;
modelica_integer tmp3;
modelica_integer tmp4;
modelica_integer _outInteger;
modelica_metatype out_outInteger;
tmp1 = mmc_unbox_integer(_offset1);
tmp2 = mmc_unbox_integer(_length1);
tmp3 = mmc_unbox_integer(_offset2);
tmp4 = mmc_unbox_integer(_length2);
_outInteger = omc_System_strcmp__offset(threadData, _string1, tmp1, tmp2, _string2, tmp3, tmp4);
out_outInteger = mmc_mk_icon(_outInteger);
return out_outInteger;
}
modelica_integer omc_System_strcmp(threadData_t *threadData, modelica_string _inString1, modelica_string _inString2)
{
int _outInteger_ext;
modelica_integer _outInteger;
_outInteger_ext = System_strcmp(MMC_STRINGDATA(_inString1), MMC_STRINGDATA(_inString2));
_outInteger = (modelica_integer)_outInteger_ext;
return _outInteger;
}
modelica_metatype boxptr_System_strcmp(threadData_t *threadData, modelica_metatype _inString1, modelica_metatype _inString2)
{
modelica_integer _outInteger;
modelica_metatype out_outInteger;
_outInteger = omc_System_strcmp(threadData, _inString1, _inString2);
out_outInteger = mmc_mk_icon(_outInteger);
return out_outInteger;
}
modelica_string omc_System_trimChar(threadData_t *threadData, modelica_string _inString1, modelica_string _inString2)
{
const char* _outString_ext;
modelica_string _outString = NULL;
_outString_ext = System_trimChar(MMC_STRINGDATA(_inString1), MMC_STRINGDATA(_inString2));
_outString = (modelica_string)mmc_mk_scon(_outString_ext);
return _outString;
}
DLLExport
modelica_string omc_System_trimWhitespace(threadData_t *threadData, modelica_string _inString)
{
modelica_string _outString = NULL;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
_outString = omc_System_trim(threadData, _inString, _OMC_LIT3);
_return: OMC_LABEL_UNUSED
return _outString;
}
modelica_string omc_System_trim(threadData_t *threadData, modelica_string _inString, modelica_string _charsToRemove)
{
const char* _outString_ext;
modelica_string _outString = NULL;
_outString_ext = System_trim(MMC_STRINGDATA(_inString), MMC_STRINGDATA(_charsToRemove));
_outString = (modelica_string)mmc_mk_scon(_outString_ext);
return _outString;
}
