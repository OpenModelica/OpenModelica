#ifdef OMC_BASE_FILE
#define OMC_FILE OMC_BASE_FILE
#else
#define OMC_FILE "/home/mahge/dev/OpenModelica/OMCompiler/Compiler/boot/build/tmp/ModelicaExternalC.c"
#endif
#include "omc_simulation_settings.h"
#include "ModelicaExternalC.h"
#include "util/modelica.h"
#include "ModelicaExternalC_includes.h"
real_array omc_ModelicaExternalC_ModelicaIO__readRealMatrix(threadData_t *threadData, modelica_string _fileName, modelica_string _matrixName, modelica_integer _nrow, modelica_integer _ncol, modelica_boolean _verboseRead)
{
int _nrow_ext;
int _ncol_ext;
int _verboseRead_ext;
void *_matrix_c89;
real_array _matrix;
alloc_real_array(&(_matrix), 2, _nrow, _ncol); // _matrix has no default value.
_nrow_ext = (int)_nrow;
_ncol_ext = (int)_ncol;
_verboseRead_ext = (int)_verboseRead;
_matrix_c89 = (void*) data_of_real_c89_array(_matrix);
ModelicaIO_readRealMatrix(MMC_STRINGDATA(_fileName), MMC_STRINGDATA(_matrixName), (double*) _matrix_c89, _nrow_ext, _ncol_ext, _verboseRead_ext);
return _matrix;
}
modelica_metatype boxptr_ModelicaExternalC_ModelicaIO__readRealMatrix(threadData_t *threadData, modelica_metatype _fileName, modelica_metatype _matrixName, modelica_metatype _nrow, modelica_metatype _ncol, modelica_metatype _verboseRead)
{
modelica_integer tmp1;
modelica_integer tmp2;
modelica_integer tmp3;
real_array _matrix;
modelica_metatype out_matrix;
tmp1 = mmc_unbox_integer(_nrow);
tmp2 = mmc_unbox_integer(_ncol);
tmp3 = mmc_unbox_integer(_verboseRead);
_matrix = omc_ModelicaExternalC_ModelicaIO__readRealMatrix(threadData, _fileName, _matrixName, tmp1, tmp2, tmp3);
out_matrix = mmc_mk_modelica_array(_matrix);
return out_matrix;
}
integer_array omc_ModelicaExternalC_ModelicaIO__readMatrixSizes(threadData_t *threadData, modelica_string _fileName, modelica_string _matrixName)
{
void *_dim_c89;
integer_array _dim;
alloc_integer_array(&(_dim), 1, 2); // _dim has no default value.
_dim_c89 = (void*) data_of_integer_c89_array(_dim);
ModelicaIO_readMatrixSizes(MMC_STRINGDATA(_fileName), MMC_STRINGDATA(_matrixName), (int*) _dim_c89);
unpack_integer_array(&_dim);
return _dim;
}
modelica_metatype boxptr_ModelicaExternalC_ModelicaIO__readMatrixSizes(threadData_t *threadData, modelica_metatype _fileName, modelica_metatype _matrixName)
{
integer_array _dim;
modelica_metatype out_dim;
_dim = omc_ModelicaExternalC_ModelicaIO__readMatrixSizes(threadData, _fileName, _matrixName);
out_dim = mmc_mk_modelica_array(_dim);
return out_dim;
}
modelica_integer omc_ModelicaExternalC_Strings__hashString(threadData_t *threadData, modelica_string _string)
{
int _hash_ext;
modelica_integer _hash;
_hash_ext = ModelicaStrings_hashString(MMC_STRINGDATA(_string));
_hash = (modelica_integer)_hash_ext;
return _hash;
}
modelica_metatype boxptr_ModelicaExternalC_Strings__hashString(threadData_t *threadData, modelica_metatype _string)
{
modelica_integer _hash;
modelica_metatype out_hash;
_hash = omc_ModelicaExternalC_Strings__hashString(threadData, _string);
out_hash = mmc_mk_icon(_hash);
return out_hash;
}
modelica_integer omc_ModelicaExternalC_Strings__skipWhiteSpace(threadData_t *threadData, modelica_string _string, modelica_integer _startIndex)
{
int _startIndex_ext;
int _nextIndex_ext;
modelica_integer _nextIndex;
_startIndex_ext = (int)_startIndex;
_nextIndex_ext = ModelicaStrings_skipWhiteSpace(MMC_STRINGDATA(_string), _startIndex_ext);
_nextIndex = (modelica_integer)_nextIndex_ext;
return _nextIndex;
}
modelica_metatype boxptr_ModelicaExternalC_Strings__skipWhiteSpace(threadData_t *threadData, modelica_metatype _string, modelica_metatype _startIndex)
{
modelica_integer tmp1;
modelica_integer _nextIndex;
modelica_metatype out_nextIndex;
tmp1 = mmc_unbox_integer(_startIndex);
_nextIndex = omc_ModelicaExternalC_Strings__skipWhiteSpace(threadData, _string, tmp1);
out_nextIndex = mmc_mk_icon(_nextIndex);
return out_nextIndex;
}
modelica_integer omc_ModelicaExternalC_Strings__scanIdentifier(threadData_t *threadData, modelica_string _string, modelica_integer _startIndex, modelica_string *out_identifier)
{
int _startIndex_ext;
int _nextIndex_ext;
const char* _identifier_ext;
modelica_integer _nextIndex;
modelica_string _identifier = NULL;
_startIndex_ext = (int)_startIndex;
ModelicaStrings_scanIdentifier(MMC_STRINGDATA(_string), _startIndex_ext, &_nextIndex_ext, &_identifier_ext);
_nextIndex = (modelica_integer)_nextIndex_ext;
_identifier = (modelica_string)mmc_mk_scon(_identifier_ext);
if (out_identifier) { *out_identifier = _identifier; }
return _nextIndex;
}
modelica_metatype boxptr_ModelicaExternalC_Strings__scanIdentifier(threadData_t *threadData, modelica_metatype _string, modelica_metatype _startIndex, modelica_metatype *out_identifier)
{
modelica_integer tmp1;
modelica_integer _nextIndex;
modelica_metatype out_nextIndex;
tmp1 = mmc_unbox_integer(_startIndex);
_nextIndex = omc_ModelicaExternalC_Strings__scanIdentifier(threadData, _string, tmp1, out_identifier);
out_nextIndex = mmc_mk_icon(_nextIndex);
return out_nextIndex;
}
modelica_integer omc_ModelicaExternalC_Strings__scanString(threadData_t *threadData, modelica_string _string, modelica_integer _startIndex, modelica_string *out_string2)
{
int _startIndex_ext;
int _nextIndex_ext;
const char* _string2_ext;
modelica_integer _nextIndex;
modelica_string _string2 = NULL;
_startIndex_ext = (int)_startIndex;
ModelicaStrings_scanString(MMC_STRINGDATA(_string), _startIndex_ext, &_nextIndex_ext, &_string2_ext);
_nextIndex = (modelica_integer)_nextIndex_ext;
_string2 = (modelica_string)mmc_mk_scon(_string2_ext);
if (out_string2) { *out_string2 = _string2; }
return _nextIndex;
}
modelica_metatype boxptr_ModelicaExternalC_Strings__scanString(threadData_t *threadData, modelica_metatype _string, modelica_metatype _startIndex, modelica_metatype *out_string2)
{
modelica_integer tmp1;
modelica_integer _nextIndex;
modelica_metatype out_nextIndex;
tmp1 = mmc_unbox_integer(_startIndex);
_nextIndex = omc_ModelicaExternalC_Strings__scanString(threadData, _string, tmp1, out_string2);
out_nextIndex = mmc_mk_icon(_nextIndex);
return out_nextIndex;
}
modelica_integer omc_ModelicaExternalC_Strings__scanInteger(threadData_t *threadData, modelica_string _string, modelica_integer _startIndex, modelica_boolean _unsigned, modelica_integer *out_number)
{
int _startIndex_ext;
int _unsigned_ext;
int _nextIndex_ext;
int _number_ext;
modelica_integer _nextIndex;
modelica_integer _number;
_startIndex_ext = (int)_startIndex;
_unsigned_ext = (int)_unsigned;
ModelicaStrings_scanInteger(MMC_STRINGDATA(_string), _startIndex_ext, _unsigned_ext, &_nextIndex_ext, &_number_ext);
_nextIndex = (modelica_integer)_nextIndex_ext;
_number = (modelica_integer)_number_ext;
if (out_number) { *out_number = _number; }
return _nextIndex;
}
modelica_metatype boxptr_ModelicaExternalC_Strings__scanInteger(threadData_t *threadData, modelica_metatype _string, modelica_metatype _startIndex, modelica_metatype _unsigned, modelica_metatype *out_number)
{
modelica_integer tmp1;
modelica_integer tmp2;
modelica_integer _number;
modelica_integer _nextIndex;
modelica_metatype out_nextIndex;
tmp1 = mmc_unbox_integer(_startIndex);
tmp2 = mmc_unbox_integer(_unsigned);
_nextIndex = omc_ModelicaExternalC_Strings__scanInteger(threadData, _string, tmp1, tmp2, &_number);
out_nextIndex = mmc_mk_icon(_nextIndex);
if (out_number) { *out_number = mmc_mk_icon(_number); }
return out_nextIndex;
}
modelica_integer omc_ModelicaExternalC_Strings__scanReal(threadData_t *threadData, modelica_string _string, modelica_integer _startIndex, modelica_boolean _unsigned, modelica_real *out_number)
{
int _startIndex_ext;
int _unsigned_ext;
int _nextIndex_ext;
double _number_ext;
modelica_integer _nextIndex;
modelica_real _number;
_startIndex_ext = (int)_startIndex;
_unsigned_ext = (int)_unsigned;
ModelicaStrings_scanReal(MMC_STRINGDATA(_string), _startIndex_ext, _unsigned_ext, &_nextIndex_ext, &_number_ext);
_nextIndex = (modelica_integer)_nextIndex_ext;
_number = (modelica_real)_number_ext;
if (out_number) { *out_number = _number; }
return _nextIndex;
}
modelica_metatype boxptr_ModelicaExternalC_Strings__scanReal(threadData_t *threadData, modelica_metatype _string, modelica_metatype _startIndex, modelica_metatype _unsigned, modelica_metatype *out_number)
{
modelica_integer tmp1;
modelica_integer tmp2;
modelica_real _number;
modelica_integer _nextIndex;
modelica_metatype out_nextIndex;
tmp1 = mmc_unbox_integer(_startIndex);
tmp2 = mmc_unbox_integer(_unsigned);
_nextIndex = omc_ModelicaExternalC_Strings__scanReal(threadData, _string, tmp1, tmp2, &_number);
out_nextIndex = mmc_mk_icon(_nextIndex);
if (out_number) { *out_number = mmc_mk_rcon(_number); }
return out_nextIndex;
}
modelica_integer omc_ModelicaExternalC_Strings__compare(threadData_t *threadData, modelica_string _string1, modelica_string _string2, modelica_boolean _caseSensitive)
{
int _caseSensitive_ext;
int _result_ext;
modelica_integer _result;
_caseSensitive_ext = (int)_caseSensitive;
_result_ext = ModelicaStrings_compare(MMC_STRINGDATA(_string1), MMC_STRINGDATA(_string2), _caseSensitive_ext);
_result = (modelica_integer)_result_ext;
return _result;
}
modelica_metatype boxptr_ModelicaExternalC_Strings__compare(threadData_t *threadData, modelica_metatype _string1, modelica_metatype _string2, modelica_metatype _caseSensitive)
{
modelica_integer tmp1;
modelica_integer _result;
modelica_metatype out_result;
tmp1 = mmc_unbox_integer(_caseSensitive);
_result = omc_ModelicaExternalC_Strings__compare(threadData, _string1, _string2, tmp1);
out_result = mmc_mk_icon(_result);
return out_result;
}
void omc_ModelicaExternalC_Streams__close(threadData_t *threadData, modelica_string _fileName)
{
ModelicaStreams_closeFile(MMC_STRINGDATA(_fileName));
return;
}
modelica_integer omc_ModelicaExternalC_File__stat(threadData_t *threadData, modelica_string _name)
{
int _fileType_ext;
modelica_integer _fileType;
_fileType_ext = ModelicaInternal_stat(MMC_STRINGDATA(_name));
_fileType = (modelica_integer)_fileType_ext;
return _fileType;
}
modelica_metatype boxptr_ModelicaExternalC_File__stat(threadData_t *threadData, modelica_metatype _name)
{
modelica_integer _fileType;
modelica_metatype out_fileType;
_fileType = omc_ModelicaExternalC_File__stat(threadData, _name);
out_fileType = mmc_mk_icon(_fileType);
return out_fileType;
}
modelica_string omc_ModelicaExternalC_File__fullPathName(threadData_t *threadData, modelica_string _fileName)
{
const char* _outName_ext;
modelica_string _outName = NULL;
_outName_ext = ModelicaInternal_fullPathName(MMC_STRINGDATA(_fileName));
_outName = (modelica_string)mmc_mk_scon(_outName_ext);
return _outName;
}
modelica_integer omc_ModelicaExternalC_Streams__countLines(threadData_t *threadData, modelica_string _fileName)
{
int _numberOfLines_ext;
modelica_integer _numberOfLines;
_numberOfLines_ext = ModelicaInternal_countLines(MMC_STRINGDATA(_fileName));
_numberOfLines = (modelica_integer)_numberOfLines_ext;
return _numberOfLines;
}
modelica_metatype boxptr_ModelicaExternalC_Streams__countLines(threadData_t *threadData, modelica_metatype _fileName)
{
modelica_integer _numberOfLines;
modelica_metatype out_numberOfLines;
_numberOfLines = omc_ModelicaExternalC_Streams__countLines(threadData, _fileName);
out_numberOfLines = mmc_mk_icon(_numberOfLines);
return out_numberOfLines;
}
modelica_string omc_ModelicaExternalC_Streams__readLine(threadData_t *threadData, modelica_string _fileName, modelica_integer _lineNumber, modelica_boolean *out_endOfFile)
{
int _lineNumber_ext;
int _endOfFile_ext;
const char* _string_ext;
modelica_string _string = NULL;
modelica_boolean _endOfFile;
_lineNumber_ext = (int)_lineNumber;
_string_ext = ModelicaInternal_readLine(MMC_STRINGDATA(_fileName), _lineNumber_ext, &_endOfFile_ext);
_endOfFile = (modelica_boolean)_endOfFile_ext;
_string = (modelica_string)mmc_mk_scon(_string_ext);
if (out_endOfFile) { *out_endOfFile = _endOfFile; }
return _string;
}
modelica_metatype boxptr_ModelicaExternalC_Streams__readLine(threadData_t *threadData, modelica_metatype _fileName, modelica_metatype _lineNumber, modelica_metatype *out_endOfFile)
{
modelica_integer tmp1;
modelica_boolean _endOfFile;
modelica_string _string = NULL;
tmp1 = mmc_unbox_integer(_lineNumber);
_string = omc_ModelicaExternalC_Streams__readLine(threadData, _fileName, tmp1, &_endOfFile);
if (out_endOfFile) { *out_endOfFile = mmc_mk_icon(_endOfFile); }
return _string;
}
void omc_ModelicaExternalC_Streams__print(threadData_t *threadData, modelica_string _string, modelica_string _fileName)
{
ModelicaInternal_print(MMC_STRINGDATA(_string), MMC_STRINGDATA(_fileName));
return;
}
