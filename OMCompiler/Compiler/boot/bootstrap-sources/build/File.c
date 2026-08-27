#ifdef OMC_BASE_FILE
#define OMC_FILE OMC_BASE_FILE
#else
#define OMC_FILE "/home/mahge/dev/OpenModelica/OMCompiler/Compiler/boot/build/tmp/File.c"
#endif
#include "omc_simulation_settings.h"
#include "File.h"
#define _OMC_LIT0_data " "
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT0,1,_OMC_LIT0_data);
#define _OMC_LIT0 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT0)
#define _OMC_LIT1_data "%.15g"
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT1,5,_OMC_LIT1_data);
#define _OMC_LIT1 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT1)
#define _OMC_LIT2_data "%d"
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT2,2,_OMC_LIT2_data);
#define _OMC_LIT2 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT2)
#include "util/modelica.h"
#include "File_includes.h"
DLLExport
void omc_File_writeSpace(threadData_t *threadData, modelica_complex _file, modelica_integer _n)
{
modelica_integer tmp1;
modelica_integer tmp2;
modelica_integer tmp3;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
tmp1 = ((modelica_integer) 1); tmp2 = 1; tmp3 = _n;
if(!(((tmp2 > 0) && (tmp1 > tmp3)) || ((tmp2 < 0) && (tmp1 < tmp3))))
{
modelica_integer _i;
for(_i = ((modelica_integer) 1); in_range_integer(_i, tmp1, tmp3); _i += tmp2)
{
omc_File_write(threadData, _file, _OMC_LIT0);
}
}
_return: OMC_LABEL_UNUSED
return;
}
void boxptr_File_writeSpace(threadData_t *threadData, modelica_metatype _file, modelica_metatype _n)
{
modelica_integer tmp1;
tmp1 = mmc_unbox_integer(_n);
omc_File_writeSpace(threadData, _file, tmp1);
return;
}
void omc_File_releaseReference(threadData_t *threadData, modelica_complex _file)
{
void * _file_ext;
_file_ext = (void *)_file;
om_file_release_reference(_file_ext);
return;
}
void boxptr_File_releaseReference(threadData_t *threadData, modelica_metatype _file)
{
omc_File_releaseReference(threadData, _file);
return;
}
modelica_metatype omc_File_getReference(threadData_t *threadData, modelica_complex _file)
{
void * _file_ext;
modelica_metatype _reference_ext;
modelica_metatype _reference = NULL;
_file_ext = (void *)_file;
_reference_ext = om_file_get_reference(_file_ext);
_reference = (modelica_metatype)_reference_ext;
return _reference;
}
modelica_metatype boxptr_File_getReference(threadData_t *threadData, modelica_metatype _file)
{
modelica_metatype _reference = NULL;
_reference = omc_File_getReference(threadData, _file);
return _reference;
}
modelica_metatype omc_File_noReference(threadData_t *threadData)
{
modelica_metatype _reference_ext;
modelica_metatype _reference = NULL;
_reference_ext = om_file_no_reference();
_reference = (modelica_metatype)_reference_ext;
return _reference;
}
modelica_string omc_File_getFilename(threadData_t *threadData, modelica_metatype _file)
{
modelica_metatype _file_ext;
const char* _fileName2_ext;
modelica_string _fileName2 = NULL;
_file_ext = (modelica_metatype)_file;
_fileName2_ext = om_file_get_filename(_file_ext);
_fileName2 = (modelica_string)mmc_mk_scon(_fileName2_ext);
return _fileName2;
}
modelica_integer omc_File_tell(threadData_t *threadData, modelica_complex _file)
{
void * _file_ext;
int _pos_ext;
modelica_integer _pos;
_file_ext = (void *)_file;
_pos_ext = om_file_tell(_file_ext);
_pos = (modelica_integer)_pos_ext;
return _pos;
}
modelica_metatype boxptr_File_tell(threadData_t *threadData, modelica_metatype _file)
{
modelica_integer _pos;
modelica_metatype out_pos;
_pos = omc_File_tell(threadData, _file);
out_pos = mmc_mk_icon(_pos);
return out_pos;
}
modelica_boolean omc_File_seek(threadData_t *threadData, modelica_complex _file, modelica_integer _offset, modelica_integer _whence)
{
void * _file_ext;
int _offset_ext;
int _whence_ext;
int _success_ext;
modelica_boolean _success;
_file_ext = (void *)_file;
_offset_ext = (int)_offset;
_whence_ext = (int)_whence;
_success_ext = om_file_seek(_file_ext, _offset_ext, _whence_ext);
_success = (modelica_boolean)_success_ext;
return _success;
}
modelica_metatype boxptr_File_seek(threadData_t *threadData, modelica_metatype _file, modelica_metatype _offset, modelica_metatype _whence)
{
modelica_integer tmp1;
modelica_integer tmp2;
modelica_boolean _success;
modelica_metatype out_success;
tmp1 = mmc_unbox_integer(_offset);
tmp2 = mmc_unbox_integer(_whence);
_success = omc_File_seek(threadData, _file, tmp1, tmp2);
out_success = mmc_mk_icon(_success);
return out_success;
}
void omc_File_writeEscape(threadData_t *threadData, modelica_complex _file, modelica_string _data, modelica_integer _escape)
{
void * _file_ext;
int _escape_ext;
_file_ext = (void *)_file;
_escape_ext = (int)_escape;
om_file_write_escape(_file_ext, MMC_STRINGDATA(_data), _escape_ext);
return;
}
void boxptr_File_writeEscape(threadData_t *threadData, modelica_metatype _file, modelica_metatype _data, modelica_metatype _escape)
{
modelica_integer tmp1;
tmp1 = mmc_unbox_integer(_escape);
omc_File_writeEscape(threadData, _file, _data, tmp1);
return;
}
void omc_File_writeReal(threadData_t *threadData, modelica_complex _file, modelica_real _data, modelica_string _format)
{
void * _file_ext;
double _data_ext;
_file_ext = (void *)_file;
_data_ext = (double)_data;
om_file_write_real(_file_ext, _data_ext, MMC_STRINGDATA(_format));
return;
}
void boxptr_File_writeReal(threadData_t *threadData, modelica_metatype _file, modelica_metatype _data, modelica_metatype _format)
{
modelica_real tmp1;
tmp1 = mmc_unbox_real(_data);
omc_File_writeReal(threadData, _file, tmp1, _format);
return;
}
void omc_File_writeInt(threadData_t *threadData, modelica_complex _file, modelica_integer _data, modelica_string _format)
{
void * _file_ext;
int _data_ext;
_file_ext = (void *)_file;
_data_ext = (int)_data;
om_file_write_int(_file_ext, _data_ext, MMC_STRINGDATA(_format));
return;
}
void boxptr_File_writeInt(threadData_t *threadData, modelica_metatype _file, modelica_metatype _data, modelica_metatype _format)
{
modelica_integer tmp1;
tmp1 = mmc_unbox_integer(_data);
omc_File_writeInt(threadData, _file, tmp1, _format);
return;
}
void omc_File_write(threadData_t *threadData, modelica_complex _file, modelica_string _data)
{
void * _file_ext;
_file_ext = (void *)_file;
om_file_write(_file_ext, MMC_STRINGDATA(_data));
return;
}
void boxptr_File_write(threadData_t *threadData, modelica_metatype _file, modelica_metatype _data)
{
omc_File_write(threadData, _file, _data);
return;
}
void omc_File_open(threadData_t *threadData, modelica_complex _file, modelica_string _filename, modelica_integer _mode)
{
void * _file_ext;
int _mode_ext;
_file_ext = (void *)_file;
_mode_ext = (int)_mode;
om_file_open(_file_ext, MMC_STRINGDATA(_filename), _mode_ext);
return;
}
void boxptr_File_open(threadData_t *threadData, modelica_metatype _file, modelica_metatype _filename, modelica_metatype _mode)
{
modelica_integer tmp1;
tmp1 = mmc_unbox_integer(_mode);
omc_File_open(threadData, _file, _filename, tmp1);
return;
}
modelica_complex omc_File_File_constructor(threadData_t *threadData, modelica_metatype _fromID)
{
modelica_metatype _fromID_ext;
void * _file_ext;
modelica_complex _file;
_fromID_ext = (modelica_metatype)_fromID;
_file_ext = om_file_new(_fromID_ext);
_file = (modelica_complex)_file_ext;
return _file;
}
modelica_metatype boxptr_File_File_constructor(threadData_t *threadData, modelica_metatype _fromID)
{
modelica_complex _file;
_file = omc_File_File_constructor(threadData, _fromID);
return _file;
}
void omc_File_File_destructor(threadData_t *threadData, modelica_complex _file)
{
void * _file_ext;
_file_ext = (void *)_file;
om_file_free(_file_ext);
return;
}
void boxptr_File_File_destructor(threadData_t *threadData, modelica_metatype _file)
{
omc_File_File_destructor(threadData, _file);
return;
}
