#ifdef OMC_BASE_FILE
#define OMC_FILE OMC_BASE_FILE
#else
#define OMC_FILE "StringUtil.c"
#endif
#include "omc_simulation_settings.h"
#include "StringUtil.h"
#define _OMC_LIT0_data ""
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT0,0,_OMC_LIT0_data);
#define _OMC_LIT0 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT0)
#define _OMC_LIT1_data "0"
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT1,1,_OMC_LIT1_data);
#define _OMC_LIT1 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT1)
#define _OMC_LIT2_data "1"
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT2,1,_OMC_LIT2_data);
#define _OMC_LIT2 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT2)
#define _OMC_LIT3_data "2"
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT3,1,_OMC_LIT3_data);
#define _OMC_LIT3 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT3)
#define _OMC_LIT4_data "3"
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT4,1,_OMC_LIT4_data);
#define _OMC_LIT4 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT4)
#define _OMC_LIT5_data "4"
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT5,1,_OMC_LIT5_data);
#define _OMC_LIT5 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT5)
#define _OMC_LIT6_data "5"
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT6,1,_OMC_LIT6_data);
#define _OMC_LIT6 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT6)
#define _OMC_LIT7_data "6"
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT7,1,_OMC_LIT7_data);
#define _OMC_LIT7 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT7)
#define _OMC_LIT8_data "7"
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT8,1,_OMC_LIT8_data);
#define _OMC_LIT8 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT8)
#define _OMC_LIT9_data "8"
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT9,1,_OMC_LIT9_data);
#define _OMC_LIT9 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT9)
#define _OMC_LIT10_data "9"
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT10,1,_OMC_LIT10_data);
#define _OMC_LIT10 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT10)
#define _OMC_LIT11_data "A"
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT11,1,_OMC_LIT11_data);
#define _OMC_LIT11 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT11)
#define _OMC_LIT12_data "B"
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT12,1,_OMC_LIT12_data);
#define _OMC_LIT12 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT12)
#define _OMC_LIT13_data "C"
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT13,1,_OMC_LIT13_data);
#define _OMC_LIT13 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT13)
#define _OMC_LIT14_data "D"
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT14,1,_OMC_LIT14_data);
#define _OMC_LIT14 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT14)
#define _OMC_LIT15_data "E"
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT15,1,_OMC_LIT15_data);
#define _OMC_LIT15 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT15)
#define _OMC_LIT16_data "F"
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT16,1,_OMC_LIT16_data);
#define _OMC_LIT16 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT16)
static _index_t _OMC_LIT17_dims[1] = {16};
static const modelica_string _OMC_LIT17_data[] = {_OMC_LIT1, _OMC_LIT2, _OMC_LIT3, _OMC_LIT4, _OMC_LIT5, _OMC_LIT6, _OMC_LIT7, _OMC_LIT8, _OMC_LIT9, _OMC_LIT10, _OMC_LIT11, _OMC_LIT12, _OMC_LIT13, _OMC_LIT14, _OMC_LIT15, _OMC_LIT16};
static string_array const _OMC_LIT17 = {
1, _OMC_LIT17_dims, (void*) _OMC_LIT17_data, (modelica_boolean) 0
};
#define _OMC_LIT18_data "0x"
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT18,2,_OMC_LIT18_data);
#define _OMC_LIT18 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT18)
#define _OMC_LIT19_data " kB"
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT19,3,_OMC_LIT19_data);
#define _OMC_LIT19 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT19)
#define _OMC_LIT20_data " MB"
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT20,3,_OMC_LIT20_data);
#define _OMC_LIT20 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT20)
#define _OMC_LIT21_data " GB"
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT21,3,_OMC_LIT21_data);
#define _OMC_LIT21 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT21)
#define _OMC_LIT22_data " TB"
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT22,3,_OMC_LIT22_data);
#define _OMC_LIT22 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT22)
#define _OMC_LIT23_data "\""
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT23,1,_OMC_LIT23_data);
#define _OMC_LIT23 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT23)
#define _OMC_LIT24_data "\n"
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT24,1,_OMC_LIT24_data);
#define _OMC_LIT24 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT24)
#define _OMC_LIT25_data "-"
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT25,1,_OMC_LIT25_data);
#define _OMC_LIT25 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT25)
#define _OMC_LIT26_data "****************************************"
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT26,40,_OMC_LIT26_data);
#define _OMC_LIT26 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT26)
#define _OMC_LIT27_data "----------------------------------------"
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT27,40,_OMC_LIT27_data);
#define _OMC_LIT27 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT27)
#define _OMC_LIT28_data "========================================\n"
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT28,41,_OMC_LIT28_data);
#define _OMC_LIT28 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT28)
#define _OMC_LIT29_data "========================================"
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT29,40,_OMC_LIT29_data);
#define _OMC_LIT29 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT29)
#define _OMC_LIT30_data "################################################################################\n\n	"
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT30,83,_OMC_LIT30_data);
#define _OMC_LIT30 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT30)
#define _OMC_LIT31_data "\n\n"
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT31,2,_OMC_LIT31_data);
#define _OMC_LIT31 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT31)
#define _OMC_LIT32_data "################################################################################"
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT32,80,_OMC_LIT32_data);
#define _OMC_LIT32 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT32)
#include "util/modelica.h"
#include "StringUtil_includes.h"
DLLExport
modelica_string omc_StringUtil_stripFileExtension(threadData_t *threadData, modelica_string __omcQ_24in_5Ffilename)
{
modelica_string _filename = NULL;
modelica_integer _pos;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
_filename = __omcQ_24in_5Ffilename;
_pos = omc_StringUtil_rfindChar(threadData, _filename, ((modelica_integer) 46), ((modelica_integer) 0), ((modelica_integer) 1));
if((_pos != ((modelica_integer) 0)))
{
_filename = substring(_filename, ((modelica_integer) 1), ((modelica_integer) -1) + _pos);
}
_return: OMC_LABEL_UNUSED
return _filename;
}
DLLExport
modelica_string omc_StringUtil_stripBOM(threadData_t *threadData, modelica_string __omcQ_24in_5Fs, modelica_string *out_bom)
{
modelica_string _s = NULL;
modelica_string _bom = NULL;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
_s = __omcQ_24in_5Fs;
_bom = _OMC_LIT0;
if((stringLength(_s) < ((modelica_integer) 3)))
{
goto _return;
}
if((((stringGet(_s, ((modelica_integer) 1)) == ((modelica_integer) 239)) && (stringGet(_s, ((modelica_integer) 2)) == ((modelica_integer) 187))) && (stringGet(_s, ((modelica_integer) 3)) == ((modelica_integer) 191))))
{
_s = substring(_s, ((modelica_integer) 4), stringLength(_s));
_bom = substring(_s, ((modelica_integer) 1), ((modelica_integer) 3));
}
_return: OMC_LABEL_UNUSED
if (out_bom) { *out_bom = _bom; }
return _s;
}
DLLExport
modelica_string omc_StringUtil_convertCharNonAsciiToHex(threadData_t *threadData, modelica_string __omcQ_24in_5Fs)
{
modelica_string _s = NULL;
modelica_integer _i;
string_array _hex;
modelica_integer tmp1;
modelica_metatype tmpMeta2;
modelica_metatype tmpMeta3;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
_s = __omcQ_24in_5Fs;
alloc_string_array(&(_hex), 1, (_index_t)16);
string_array_copy_data(_OMC_LIT17, _hex);
_i = stringCharInt(_s);
if((_i < ((modelica_integer) 128)))
{
goto _return;
}
tmp1 = ((modelica_integer) 16);
if (tmp1 == 0) {MMC_THROW_INTERNAL();}
tmpMeta2 = stringAppend(_OMC_LIT18,string_get(_OMC_LIT17, (((modelica_integer) 1) + modelica_div_integer(_i,tmp1).quot)-1));
tmpMeta3 = stringAppend(tmpMeta2,string_get(_OMC_LIT17, (((modelica_integer) 1) + modelica_integer_mod(_i, ((modelica_integer) 16)))-1));
_s = tmpMeta3;
_return: OMC_LABEL_UNUSED
return _s;
}
DLLExport
modelica_boolean omc_StringUtil_endsWithNewline(threadData_t *threadData, modelica_string _str)
{
modelica_boolean _b;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
_b = (((modelica_integer) 10) == stringGetNoBoundsChecking(_str, stringLength(_str)));
_return: OMC_LABEL_UNUSED
return _b;
}
modelica_metatype boxptr_StringUtil_endsWithNewline(threadData_t *threadData, modelica_metatype _str)
{
modelica_boolean _b;
modelica_metatype out_b;
_b = omc_StringUtil_endsWithNewline(threadData, _str);
out_b = mmc_mk_icon(_b);
return out_b;
}
DLLExport
modelica_string omc_StringUtil_stringAppend9(threadData_t *threadData, modelica_string _str1, modelica_string _str2, modelica_string _str3, modelica_string _str4, modelica_string _str5, modelica_string _str6, modelica_string _str7, modelica_string _str8, modelica_string _str9)
{
modelica_string _str = NULL;
modelica_complex _sb;
modelica_integer _c;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
_sb = omc_System_StringAllocator_constructor(threadData, stringLength(_str1) + stringLength(_str2) + stringLength(_str3) + stringLength(_str4) + stringLength(_str5) + stringLength(_str6) + stringLength(_str7) + stringLength(_str8) + stringLength(_str9));
_c = ((modelica_integer) 0);
omc_System_stringAllocatorStringCopy(threadData, _sb, _str1, _c);
_c = _c + stringLength(_str1);
omc_System_stringAllocatorStringCopy(threadData, _sb, _str2, _c);
_c = _c + stringLength(_str2);
omc_System_stringAllocatorStringCopy(threadData, _sb, _str3, _c);
_c = _c + stringLength(_str3);
omc_System_stringAllocatorStringCopy(threadData, _sb, _str4, _c);
_c = _c + stringLength(_str4);
omc_System_stringAllocatorStringCopy(threadData, _sb, _str5, _c);
_c = _c + stringLength(_str5);
omc_System_stringAllocatorStringCopy(threadData, _sb, _str6, _c);
_c = _c + stringLength(_str6);
omc_System_stringAllocatorStringCopy(threadData, _sb, _str7, _c);
_c = _c + stringLength(_str7);
omc_System_stringAllocatorStringCopy(threadData, _sb, _str8, _c);
_c = _c + stringLength(_str8);
omc_System_stringAllocatorStringCopy(threadData, _sb, _str9, _c);
_c = _c + stringLength(_str9);
_str = omc_System_stringAllocatorResult(threadData, _sb, _str1);
_return: OMC_LABEL_UNUSED
omc_System_StringAllocator_destructor(threadData,_sb);
return _str;
}
DLLExport
modelica_integer omc_StringUtil_stringHashDjb2Work(threadData_t *threadData, modelica_string _str, modelica_integer _hash)
{
modelica_integer _ohash;
modelica_integer tmp1;
modelica_integer tmp2;
modelica_integer tmp3;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
_ohash = _hash;
tmp1 = ((modelica_integer) 1); tmp2 = 1; tmp3 = stringLength(_str);
if(!(((tmp2 > 0) && (tmp1 > tmp3)) || ((tmp2 < 0) && (tmp1 < tmp3))))
{
modelica_integer _i;
for(_i = ((modelica_integer) 1); in_range_integer(_i, tmp1, tmp3); _i += tmp2)
{
_ohash = (((modelica_integer) 31)) * (_ohash) + stringGetNoBoundsChecking(_str, _i);
}
}
_return: OMC_LABEL_UNUSED
return _ohash;
}
modelica_metatype boxptr_StringUtil_stringHashDjb2Work(threadData_t *threadData, modelica_metatype _str, modelica_metatype _hash)
{
modelica_integer tmp1;
modelica_integer _ohash;
modelica_metatype out_ohash;
tmp1 = mmc_unbox_integer(_hash);
_ohash = omc_StringUtil_stringHashDjb2Work(threadData, _str, tmp1);
out_ohash = mmc_mk_icon(_ohash);
return out_ohash;
}
DLLExport
modelica_string omc_StringUtil_bytesToReadableUnit(threadData_t *threadData, modelica_real _bytes, modelica_integer _significantDigits, modelica_real _maxSizeInUnit)
{
modelica_string _str = NULL;
modelica_real _TB;
modelica_real _GB;
modelica_real _MB;
modelica_real _kB;
modelica_string tmp1;
modelica_metatype tmpMeta2;
modelica_string tmp3;
modelica_metatype tmpMeta4;
modelica_string tmp5;
modelica_metatype tmpMeta6;
modelica_string tmp7;
modelica_metatype tmpMeta8;
modelica_string tmp9;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
_TB = 1099511627776.0;
_GB = 1073741824.0;
_MB = 1048576.0;
_kB = 1024.0;
if((_bytes > (1073741824.0) * (_maxSizeInUnit)))
{
tmp1 = modelica_real_to_modelica_string((9.094947017729282e-13) * (_bytes), _significantDigits, ((modelica_integer) 0), 1);
tmpMeta2 = stringAppend(tmp1,_OMC_LIT22);
_str = tmpMeta2;
}
else
{
if((_bytes > (1048576.0) * (_maxSizeInUnit)))
{
tmp3 = modelica_real_to_modelica_string((9.313225746154785e-10) * (_bytes), _significantDigits, ((modelica_integer) 0), 1);
tmpMeta4 = stringAppend(tmp3,_OMC_LIT21);
_str = tmpMeta4;
}
else
{
if((_bytes > (1024.0) * (_maxSizeInUnit)))
{
tmp5 = modelica_real_to_modelica_string((9.5367431640625e-07) * (_bytes), _significantDigits, ((modelica_integer) 0), 1);
tmpMeta6 = stringAppend(tmp5,_OMC_LIT20);
_str = tmpMeta6;
}
else
{
if((_bytes > _maxSizeInUnit))
{
tmp7 = modelica_real_to_modelica_string((0.0009765625) * (_bytes), _significantDigits, ((modelica_integer) 0), 1);
tmpMeta8 = stringAppend(tmp7,_OMC_LIT19);
_str = tmpMeta8;
}
else
{
tmp9 = modelica_integer_to_modelica_string(((modelica_integer)floor(_bytes)), ((modelica_integer) 0), 1);
_str = tmp9;
}
}
}
}
_return: OMC_LABEL_UNUSED
return _str;
}
modelica_metatype boxptr_StringUtil_bytesToReadableUnit(threadData_t *threadData, modelica_metatype _bytes, modelica_metatype _significantDigits, modelica_metatype _maxSizeInUnit)
{
modelica_real tmp1;
modelica_integer tmp2;
modelica_real tmp3;
modelica_string _str = NULL;
tmp1 = mmc_unbox_real(_bytes);
tmp2 = mmc_unbox_integer(_significantDigits);
tmp3 = mmc_unbox_real(_maxSizeInUnit);
_str = omc_StringUtil_bytesToReadableUnit(threadData, tmp1, tmp2, tmp3);
return _str;
}
DLLExport
modelica_boolean omc_StringUtil_equalIgnoreSpace(threadData_t *threadData, modelica_string _s1, modelica_string _s2)
{
modelica_boolean _b;
modelica_integer _j;
modelica_integer tmp1;
modelica_integer tmp2;
modelica_integer tmp3;
modelica_integer tmp4;
modelica_integer tmp5;
modelica_integer tmp6;
modelica_integer tmp7;
modelica_integer tmp8;
modelica_integer tmp9;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
_j = ((modelica_integer) 1);
_b = 1;
tmp4 = ((modelica_integer) 1); tmp5 = 1; tmp6 = stringLength(_s1);
if(!(((tmp5 > 0) && (tmp4 > tmp6)) || ((tmp5 < 0) && (tmp4 < tmp6))))
{
modelica_integer _i;
for(_i = ((modelica_integer) 1); in_range_integer(_i, tmp4, tmp6); _i += tmp5)
{
if((stringGetNoBoundsChecking(_s1, _i) != ((modelica_integer) 32)))
{
_b = 0;
tmp1 = _j; tmp2 = 1; tmp3 = stringLength(_s2);
if(!(((tmp2 > 0) && (tmp1 > tmp3)) || ((tmp2 < 0) && (tmp1 < tmp3))))
{
modelica_integer _j2;
for(_j2 = _j; in_range_integer(_j2, tmp1, tmp3); _j2 += tmp2)
{
if((stringGetNoBoundsChecking(_s2, _j2) != ((modelica_integer) 32)))
{
_j = ((modelica_integer) 1) + _j2;
_b = 1;
break;
}
}
}
if((!_b))
{
goto _return;
}
}
}
}
tmp7 = _j; tmp8 = 1; tmp9 = stringLength(_s2);
if(!(((tmp8 > 0) && (tmp7 > tmp9)) || ((tmp8 < 0) && (tmp7 < tmp9))))
{
modelica_integer _j2;
for(_j2 = _j; in_range_integer(_j2, tmp7, tmp9); _j2 += tmp8)
{
if((stringGetNoBoundsChecking(_s2, _j2) != ((modelica_integer) 32)))
{
_b = 0;
goto _return;
}
}
}
_return: OMC_LABEL_UNUSED
return _b;
}
modelica_metatype boxptr_StringUtil_equalIgnoreSpace(threadData_t *threadData, modelica_metatype _s1, modelica_metatype _s2)
{
modelica_boolean _b;
modelica_metatype out_b;
_b = omc_StringUtil_equalIgnoreSpace(threadData, _s1, _s2);
out_b = mmc_mk_icon(_b);
return out_b;
}
DLLExport
modelica_string omc_StringUtil_quote(threadData_t *threadData, modelica_string _inString)
{
modelica_string _outString = NULL;
modelica_metatype tmpMeta1;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
tmpMeta1 = mmc_mk_cons(_OMC_LIT23, mmc_mk_cons(_inString, mmc_mk_cons(_OMC_LIT23, MMC_REFSTRUCTLIT(mmc_nil))));
_outString = stringAppendList(tmpMeta1);
_return: OMC_LABEL_UNUSED
return _outString;
}
DLLExport
modelica_string omc_StringUtil_repeat(threadData_t *threadData, modelica_string _str, modelica_integer _n)
{
modelica_string _res = NULL;
modelica_integer _len;
modelica_complex _ext;
modelica_integer tmp1;
modelica_integer tmp2;
modelica_integer tmp3;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
_res = _OMC_LIT0;
_len = stringLength(_str);
_ext = omc_System_StringAllocator_constructor(threadData, (_len) * (_n));
tmp1 = ((modelica_integer) 0); tmp2 = 1; tmp3 = ((modelica_integer) -1) + _n;
if(!(((tmp2 > 0) && (tmp1 > tmp3)) || ((tmp2 < 0) && (tmp1 < tmp3))))
{
modelica_integer _i;
for(_i = ((modelica_integer) 0); in_range_integer(_i, tmp1, tmp3); _i += tmp2)
{
omc_System_stringAllocatorStringCopy(threadData, _ext, _str, (_len) * (_i));
}
}
_res = omc_System_stringAllocatorResult(threadData, _ext, _res);
_return: OMC_LABEL_UNUSED
omc_System_StringAllocator_destructor(threadData,_ext);
return _res;
}
modelica_metatype boxptr_StringUtil_repeat(threadData_t *threadData, modelica_metatype _str, modelica_metatype _n)
{
modelica_integer tmp1;
modelica_string _res = NULL;
tmp1 = mmc_unbox_integer(_n);
_res = omc_StringUtil_repeat(threadData, _str, tmp1);
return _res;
}
DLLExport
modelica_metatype omc_StringUtil_wordWrap(threadData_t *threadData, modelica_string _inString, modelica_integer _inWrapLength, modelica_string _inDelimiter, modelica_real _inRaggedness)
{
modelica_metatype _outStrings = NULL;
modelica_metatype tmpMeta1;
modelica_integer _start_pos;
modelica_integer _end_pos;
modelica_integer _line_len;
modelica_integer _pos;
modelica_integer _next_char;
modelica_integer _char;
modelica_integer _gap_size;
modelica_integer _next_gap_size;
modelica_string _str = NULL;
modelica_string _delim = NULL;
modelica_metatype _lines = NULL;
modelica_metatype tmpMeta2;
modelica_metatype tmpMeta3;
modelica_metatype tmpMeta4;
modelica_metatype tmpMeta5;
modelica_metatype tmpMeta6;
modelica_metatype tmpMeta7;
modelica_metatype tmpMeta8;
modelica_metatype tmpMeta9;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
tmpMeta1 = MMC_REFSTRUCTLIT(mmc_nil);
_outStrings = tmpMeta1;
_start_pos = ((modelica_integer) 1);
_end_pos = _inWrapLength;
_delim = _OMC_LIT0;
if((stringLength(_inDelimiter) >= ((modelica_integer) -1) + _inWrapLength))
{
tmpMeta2 = mmc_mk_cons(_inString, MMC_REFSTRUCTLIT(mmc_nil));
_outStrings = tmpMeta2;
goto _return;
}
_lines = omc_System_strtok(threadData, _inString, _OMC_LIT24);
_line_len = ((modelica_integer) -1) + _inWrapLength - stringLength(_inDelimiter);
_gap_size = modelica_integer_max((modelica_integer)(((modelica_integer)floor((((modelica_real)_line_len)) * (_inRaggedness)))),(modelica_integer)(((modelica_integer) 0)));
{
modelica_metatype _line;
for (tmpMeta3 = _lines; !listEmpty(tmpMeta3); tmpMeta3=MMC_CDR(tmpMeta3))
{
_line = MMC_CAR(tmpMeta3);
while(1)
{
if(!(_end_pos < stringLength(_line))) break;
_next_char = stringGetNoBoundsChecking(_line, ((modelica_integer) 1) + _end_pos);
if(((_next_char != ((modelica_integer) 32)) && (_next_char != ((modelica_integer) 45))))
{
_pos = omc_StringUtil_rfindChar(threadData, _line, ((modelica_integer) 32), _end_pos, _end_pos - _gap_size);
if((_pos != ((modelica_integer) 0)))
{
_str = substring(_line, _start_pos, ((modelica_integer) -1) + _pos);
_start_pos = ((modelica_integer) 1) + _pos;
}
else
{
_pos = omc_StringUtil_rfindChar(threadData, _line, ((modelica_integer) 45), _end_pos, _start_pos + _gap_size);
if((_pos > ((modelica_integer) 1)))
{
_char = stringGetNoBoundsChecking(_line, ((modelica_integer) -1) + _pos);
_pos = ((omc_StringUtil_isAlpha(threadData, _char) && omc_StringUtil_isAlpha(threadData, _next_char))?_pos:((modelica_integer) 0));
}
if((_pos != ((modelica_integer) 0)))
{
_str = substring(_line, _start_pos, _pos);
_start_pos = ((modelica_integer) 1) + _pos;
}
else
{
tmpMeta4 = stringAppend(substring(_line, _start_pos, ((modelica_integer) -1) + _end_pos),_OMC_LIT25);
_str = tmpMeta4;
_start_pos = _end_pos;
}
}
}
else
{
_str = substring(_line, _start_pos, _end_pos);
_start_pos = _end_pos + ((_next_char == ((modelica_integer) 32))?((modelica_integer) 2):((modelica_integer) 1));
}
tmpMeta6 = stringAppend(_delim,_str);
tmpMeta5 = mmc_mk_cons(tmpMeta6, _outStrings);
_outStrings = tmpMeta5;
_end_pos = _start_pos + _line_len;
_delim = _inDelimiter;
}
if((_start_pos < stringLength(_line)))
{
tmpMeta7 = stringAppend(_delim,substring(_line, _start_pos, stringLength(_line)));
_str = tmpMeta7;
tmpMeta8 = mmc_mk_cons(_str, _outStrings);
_outStrings = tmpMeta8;
}
_start_pos = ((modelica_integer) 1);
_end_pos = _line_len;
_delim = _inDelimiter;
}
}
_outStrings = listReverseInPlace(_outStrings);
_return: OMC_LABEL_UNUSED
return _outStrings;
}
modelica_metatype boxptr_StringUtil_wordWrap(threadData_t *threadData, modelica_metatype _inString, modelica_metatype _inWrapLength, modelica_metatype _inDelimiter, modelica_metatype _inRaggedness)
{
modelica_integer tmp1;
modelica_real tmp2;
modelica_metatype _outStrings = NULL;
modelica_metatype tmpMeta3;
tmp1 = mmc_unbox_integer(_inWrapLength);
tmp2 = mmc_unbox_real(_inRaggedness);
_outStrings = omc_StringUtil_wordWrap(threadData, _inString, tmp1, _inDelimiter, tmp2);
return _outStrings;
}
DLLExport
modelica_boolean omc_StringUtil_isAlpha(threadData_t *threadData, modelica_integer _inChar)
{
modelica_boolean _outIsAlpha;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
_outIsAlpha = (((_inChar >= ((modelica_integer) 65)) && (_inChar <= ((modelica_integer) 90))) || ((_inChar >= ((modelica_integer) 97)) && (_inChar <= ((modelica_integer) 122))));
_return: OMC_LABEL_UNUSED
return _outIsAlpha;
}
modelica_metatype boxptr_StringUtil_isAlpha(threadData_t *threadData, modelica_metatype _inChar)
{
modelica_integer tmp1;
modelica_boolean _outIsAlpha;
modelica_metatype out_outIsAlpha;
tmp1 = mmc_unbox_integer(_inChar);
_outIsAlpha = omc_StringUtil_isAlpha(threadData, tmp1);
out_outIsAlpha = mmc_mk_icon(_outIsAlpha);
return out_outIsAlpha;
}
DLLExport
modelica_integer omc_StringUtil_rfindCharNot(threadData_t *threadData, modelica_string _inString, modelica_integer _inChar, modelica_integer _inStartPos, modelica_integer _inEndPos)
{
modelica_integer _outIndex;
modelica_integer _len;
modelica_integer _start_pos;
modelica_integer _end_pos;
modelica_integer tmp1;
modelica_integer tmp2;
modelica_integer tmp3;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
_outIndex = ((modelica_integer) 0);
_len = stringLength(_inString);
_start_pos = ((_inStartPos > ((modelica_integer) 0))?modelica_integer_min((modelica_integer)(_inStartPos),(modelica_integer)(stringLength(_inString))):stringLength(_inString));
_end_pos = modelica_integer_max((modelica_integer)(_inEndPos),(modelica_integer)(((modelica_integer) 1)));
tmp1 = _start_pos; tmp2 = ((modelica_integer) -1); tmp3 = _end_pos;
if(!(((tmp2 > 0) && (tmp1 > tmp3)) || ((tmp2 < 0) && (tmp1 < tmp3))))
{
modelica_integer _i;
for(_i = _start_pos; in_range_integer(_i, tmp1, tmp3); _i += tmp2)
{
if((stringGetNoBoundsChecking(_inString, _i) != _inChar))
{
_outIndex = _i;
break;
}
}
}
_return: OMC_LABEL_UNUSED
return _outIndex;
}
modelica_metatype boxptr_StringUtil_rfindCharNot(threadData_t *threadData, modelica_metatype _inString, modelica_metatype _inChar, modelica_metatype _inStartPos, modelica_metatype _inEndPos)
{
modelica_integer tmp1;
modelica_integer tmp2;
modelica_integer tmp3;
modelica_integer _outIndex;
modelica_metatype out_outIndex;
tmp1 = mmc_unbox_integer(_inChar);
tmp2 = mmc_unbox_integer(_inStartPos);
tmp3 = mmc_unbox_integer(_inEndPos);
_outIndex = omc_StringUtil_rfindCharNot(threadData, _inString, tmp1, tmp2, tmp3);
out_outIndex = mmc_mk_icon(_outIndex);
return out_outIndex;
}
DLLExport
modelica_integer omc_StringUtil_findCharNot(threadData_t *threadData, modelica_string _inString, modelica_integer _inChar, modelica_integer _inStartPos, modelica_integer _inEndPos)
{
modelica_integer _outIndex;
modelica_integer _len;
modelica_integer _start_pos;
modelica_integer _end_pos;
modelica_integer tmp1;
modelica_integer tmp2;
modelica_integer tmp3;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
_outIndex = ((modelica_integer) 0);
_len = stringLength(_inString);
_start_pos = modelica_integer_max((modelica_integer)(_inStartPos),(modelica_integer)(((modelica_integer) 1)));
_end_pos = ((_inEndPos > ((modelica_integer) 0))?modelica_integer_min((modelica_integer)(_inEndPos),(modelica_integer)(stringLength(_inString))):stringLength(_inString));
tmp1 = _start_pos; tmp2 = 1; tmp3 = _end_pos;
if(!(((tmp2 > 0) && (tmp1 > tmp3)) || ((tmp2 < 0) && (tmp1 < tmp3))))
{
modelica_integer _i;
for(_i = _start_pos; in_range_integer(_i, tmp1, tmp3); _i += tmp2)
{
if((stringGetNoBoundsChecking(_inString, _i) != _inChar))
{
_outIndex = _i;
break;
}
}
}
_return: OMC_LABEL_UNUSED
return _outIndex;
}
modelica_metatype boxptr_StringUtil_findCharNot(threadData_t *threadData, modelica_metatype _inString, modelica_metatype _inChar, modelica_metatype _inStartPos, modelica_metatype _inEndPos)
{
modelica_integer tmp1;
modelica_integer tmp2;
modelica_integer tmp3;
modelica_integer _outIndex;
modelica_metatype out_outIndex;
tmp1 = mmc_unbox_integer(_inChar);
tmp2 = mmc_unbox_integer(_inStartPos);
tmp3 = mmc_unbox_integer(_inEndPos);
_outIndex = omc_StringUtil_findCharNot(threadData, _inString, tmp1, tmp2, tmp3);
out_outIndex = mmc_mk_icon(_outIndex);
return out_outIndex;
}
DLLExport
modelica_integer omc_StringUtil_rfindChar(threadData_t *threadData, modelica_string _inString, modelica_integer _inChar, modelica_integer _inStartPos, modelica_integer _inEndPos)
{
modelica_integer _outIndex;
modelica_integer _len;
modelica_integer _start_pos;
modelica_integer _end_pos;
modelica_integer tmp1;
modelica_integer tmp2;
modelica_integer tmp3;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
_outIndex = ((modelica_integer) 0);
_len = stringLength(_inString);
_start_pos = ((_inStartPos > ((modelica_integer) 0))?modelica_integer_min((modelica_integer)(_inStartPos),(modelica_integer)(stringLength(_inString))):stringLength(_inString));
_end_pos = modelica_integer_max((modelica_integer)(_inEndPos),(modelica_integer)(((modelica_integer) 1)));
tmp1 = _start_pos; tmp2 = ((modelica_integer) -1); tmp3 = _end_pos;
if(!(((tmp2 > 0) && (tmp1 > tmp3)) || ((tmp2 < 0) && (tmp1 < tmp3))))
{
modelica_integer _i;
for(_i = _start_pos; in_range_integer(_i, tmp1, tmp3); _i += tmp2)
{
if((stringGetNoBoundsChecking(_inString, _i) == _inChar))
{
_outIndex = _i;
break;
}
}
}
_return: OMC_LABEL_UNUSED
return _outIndex;
}
modelica_metatype boxptr_StringUtil_rfindChar(threadData_t *threadData, modelica_metatype _inString, modelica_metatype _inChar, modelica_metatype _inStartPos, modelica_metatype _inEndPos)
{
modelica_integer tmp1;
modelica_integer tmp2;
modelica_integer tmp3;
modelica_integer _outIndex;
modelica_metatype out_outIndex;
tmp1 = mmc_unbox_integer(_inChar);
tmp2 = mmc_unbox_integer(_inStartPos);
tmp3 = mmc_unbox_integer(_inEndPos);
_outIndex = omc_StringUtil_rfindChar(threadData, _inString, tmp1, tmp2, tmp3);
out_outIndex = mmc_mk_icon(_outIndex);
return out_outIndex;
}
DLLExport
modelica_integer omc_StringUtil_findChar(threadData_t *threadData, modelica_string _inString, modelica_integer _inChar, modelica_integer _inStartPos, modelica_integer _inEndPos)
{
modelica_integer _outIndex;
modelica_integer _len;
modelica_integer _start_pos;
modelica_integer _end_pos;
modelica_integer tmp1;
modelica_integer tmp2;
modelica_integer tmp3;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
_outIndex = ((modelica_integer) 0);
_len = stringLength(_inString);
_start_pos = modelica_integer_max((modelica_integer)(_inStartPos),(modelica_integer)(((modelica_integer) 1)));
_end_pos = ((_inEndPos > ((modelica_integer) 0))?modelica_integer_min((modelica_integer)(_inEndPos),(modelica_integer)(stringLength(_inString))):stringLength(_inString));
tmp1 = _start_pos; tmp2 = 1; tmp3 = _end_pos;
if(!(((tmp2 > 0) && (tmp1 > tmp3)) || ((tmp2 < 0) && (tmp1 < tmp3))))
{
modelica_integer _i;
for(_i = _start_pos; in_range_integer(_i, tmp1, tmp3); _i += tmp2)
{
if((stringGetNoBoundsChecking(_inString, _i) == _inChar))
{
_outIndex = _i;
break;
}
}
}
_return: OMC_LABEL_UNUSED
return _outIndex;
}
modelica_metatype boxptr_StringUtil_findChar(threadData_t *threadData, modelica_metatype _inString, modelica_metatype _inChar, modelica_metatype _inStartPos, modelica_metatype _inEndPos)
{
modelica_integer tmp1;
modelica_integer tmp2;
modelica_integer tmp3;
modelica_integer _outIndex;
modelica_metatype out_outIndex;
tmp1 = mmc_unbox_integer(_inChar);
tmp2 = mmc_unbox_integer(_inStartPos);
tmp3 = mmc_unbox_integer(_inEndPos);
_outIndex = omc_StringUtil_findChar(threadData, _inString, tmp1, tmp2, tmp3);
out_outIndex = mmc_mk_icon(_outIndex);
return out_outIndex;
}
DLLExport
modelica_string omc_StringUtil_headline__4(threadData_t *threadData, modelica_string _title)
{
modelica_string _header = NULL;
modelica_metatype tmpMeta1;
modelica_metatype tmpMeta2;
modelica_metatype tmpMeta3;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
tmpMeta1 = stringAppend(_title,_OMC_LIT24);
tmpMeta2 = stringAppend(tmpMeta1,_OMC_LIT26);
tmpMeta3 = stringAppend(tmpMeta2,_OMC_LIT24);
_header = tmpMeta3;
_return: OMC_LABEL_UNUSED
return _header;
}
DLLExport
modelica_string omc_StringUtil_headline__3(threadData_t *threadData, modelica_string _title)
{
modelica_string _header = NULL;
modelica_metatype tmpMeta1;
modelica_metatype tmpMeta2;
modelica_metatype tmpMeta3;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
tmpMeta1 = stringAppend(_title,_OMC_LIT24);
tmpMeta2 = stringAppend(tmpMeta1,_OMC_LIT27);
tmpMeta3 = stringAppend(tmpMeta2,_OMC_LIT24);
_header = tmpMeta3;
_return: OMC_LABEL_UNUSED
return _header;
}
DLLExport
modelica_string omc_StringUtil_headline__2(threadData_t *threadData, modelica_string _title)
{
modelica_string _header = NULL;
modelica_metatype tmpMeta1;
modelica_metatype tmpMeta2;
modelica_metatype tmpMeta3;
modelica_metatype tmpMeta4;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
tmpMeta1 = stringAppend(_OMC_LIT28,_title);
tmpMeta2 = stringAppend(tmpMeta1,_OMC_LIT24);
tmpMeta3 = stringAppend(tmpMeta2,_OMC_LIT29);
tmpMeta4 = stringAppend(tmpMeta3,_OMC_LIT24);
_header = tmpMeta4;
_return: OMC_LABEL_UNUSED
return _header;
}
DLLExport
modelica_string omc_StringUtil_headline__1(threadData_t *threadData, modelica_string _title)
{
modelica_string _header = NULL;
modelica_metatype tmpMeta1;
modelica_metatype tmpMeta2;
modelica_metatype tmpMeta3;
modelica_metatype tmpMeta4;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
tmpMeta1 = stringAppend(_OMC_LIT30,_title);
tmpMeta2 = stringAppend(tmpMeta1,_OMC_LIT31);
tmpMeta3 = stringAppend(tmpMeta2,_OMC_LIT32);
tmpMeta4 = stringAppend(tmpMeta3,_OMC_LIT24);
_header = tmpMeta4;
_return: OMC_LABEL_UNUSED
return _header;
}
