#ifdef OMC_BASE_FILE
#define OMC_FILE OMC_BASE_FILE
#else
#define OMC_FILE "Parser.c"
#endif
#include "omc_simulation_settings.h"
#include "Parser.h"
#define _OMC_LIT0_data ""
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT0,0,_OMC_LIT0_data);
#define _OMC_LIT0 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT0)
#define _OMC_LIT1_data "features"
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT1,8,_OMC_LIT1_data);
#define _OMC_LIT1 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT1)
#define _OMC_LIT2_data "Protection"
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT2,10,_OMC_LIT2_data);
#define _OMC_LIT2 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT2)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT3,2,4) {&Absyn_Path_IDENT__desc,_OMC_LIT2}};
#define _OMC_LIT3 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT3)
#define _OMC_LIT4_data "licenseFile"
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT4,11,_OMC_LIT4_data);
#define _OMC_LIT4 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT4)
#define _OMC_LIT5_data "libraryKey"
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT5,10,_OMC_LIT5_data);
#define _OMC_LIT5 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT5)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT6,2,0) {_OMC_LIT0,_OMC_LIT0}};
#define _OMC_LIT6 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT6)
#define _OMC_LIT7_data "License"
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT7,7,_OMC_LIT7_data);
#define _OMC_LIT7 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT7)
#define _OMC_LIT8_data " "
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT8,1,_OMC_LIT8_data);
#define _OMC_LIT8 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT8)
#define _OMC_LIT9_data "<internal>"
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT9,10,_OMC_LIT9_data);
#define _OMC_LIT9 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT9)
#define _OMC_LIT10_data "std"
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT10,3,_OMC_LIT10_data);
#define _OMC_LIT10 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT10)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT11,1,4) {&Flags_FlagVisibility_EXTERNAL__desc,}};
#define _OMC_LIT11 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT11)
#define _OMC_LIT12_data "1.x"
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT12,3,_OMC_LIT12_data);
#define _OMC_LIT12 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT12)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT13,2,0) {_OMC_LIT12,MMC_IMMEDIATE(MMC_TAGFIXNUM(10))}};
#define _OMC_LIT13 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT13)
#define _OMC_LIT14_data "2.x"
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT14,3,_OMC_LIT14_data);
#define _OMC_LIT14 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT14)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT15,2,0) {_OMC_LIT14,MMC_IMMEDIATE(MMC_TAGFIXNUM(20))}};
#define _OMC_LIT15 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT15)
#define _OMC_LIT16_data "3.0"
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT16,3,_OMC_LIT16_data);
#define _OMC_LIT16 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT16)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT17,2,0) {_OMC_LIT16,MMC_IMMEDIATE(MMC_TAGFIXNUM(30))}};
#define _OMC_LIT17 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT17)
#define _OMC_LIT18_data "3.1"
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT18,3,_OMC_LIT18_data);
#define _OMC_LIT18 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT18)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT19,2,0) {_OMC_LIT18,MMC_IMMEDIATE(MMC_TAGFIXNUM(31))}};
#define _OMC_LIT19 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT19)
#define _OMC_LIT20_data "3.2"
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT20,3,_OMC_LIT20_data);
#define _OMC_LIT20 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT20)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT21,2,0) {_OMC_LIT20,MMC_IMMEDIATE(MMC_TAGFIXNUM(32))}};
#define _OMC_LIT21 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT21)
#define _OMC_LIT22_data "3.3"
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT22,3,_OMC_LIT22_data);
#define _OMC_LIT22 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT22)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT23,2,0) {_OMC_LIT22,MMC_IMMEDIATE(MMC_TAGFIXNUM(33))}};
#define _OMC_LIT23 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT23)
#define _OMC_LIT24_data "3.4"
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT24,3,_OMC_LIT24_data);
#define _OMC_LIT24 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT24)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT25,2,0) {_OMC_LIT24,MMC_IMMEDIATE(MMC_TAGFIXNUM(34))}};
#define _OMC_LIT25 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT25)
#define _OMC_LIT26_data "3.5"
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT26,3,_OMC_LIT26_data);
#define _OMC_LIT26 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT26)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT27,2,0) {_OMC_LIT26,MMC_IMMEDIATE(MMC_TAGFIXNUM(35))}};
#define _OMC_LIT27 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT27)
#define _OMC_LIT28_data "latest"
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT28,6,_OMC_LIT28_data);
#define _OMC_LIT28 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT28)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT29,2,0) {_OMC_LIT28,MMC_IMMEDIATE(MMC_TAGFIXNUM(1000))}};
#define _OMC_LIT29 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT29)
#define _OMC_LIT30_data "experimental"
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT30,12,_OMC_LIT30_data);
#define _OMC_LIT30 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT30)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT31,2,0) {_OMC_LIT30,MMC_IMMEDIATE(MMC_TAGFIXNUM(9999))}};
#define _OMC_LIT31 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT31)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT32,2,1) {_OMC_LIT31,MMC_REFSTRUCTLIT(mmc_nil)}};
#define _OMC_LIT32 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT32)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT33,2,1) {_OMC_LIT29,_OMC_LIT32}};
#define _OMC_LIT33 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT33)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT34,2,1) {_OMC_LIT27,_OMC_LIT33}};
#define _OMC_LIT34 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT34)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT35,2,1) {_OMC_LIT25,_OMC_LIT34}};
#define _OMC_LIT35 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT35)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT36,2,1) {_OMC_LIT23,_OMC_LIT35}};
#define _OMC_LIT36 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT36)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT37,2,1) {_OMC_LIT21,_OMC_LIT36}};
#define _OMC_LIT37 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT37)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT38,2,1) {_OMC_LIT19,_OMC_LIT37}};
#define _OMC_LIT38 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT38)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT39,2,1) {_OMC_LIT17,_OMC_LIT38}};
#define _OMC_LIT39 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT39)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT40,2,1) {_OMC_LIT15,_OMC_LIT39}};
#define _OMC_LIT40 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT40)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT41,2,1) {_OMC_LIT13,_OMC_LIT40}};
#define _OMC_LIT41 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT41)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT42,3,10) {&Flags_FlagData_ENUM__FLAG__desc,MMC_IMMEDIATE(MMC_TAGFIXNUM(1000)),_OMC_LIT41}};
#define _OMC_LIT42 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT42)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT43,2,1) {_OMC_LIT30,MMC_REFSTRUCTLIT(mmc_nil)}};
#define _OMC_LIT43 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT43)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT44,2,1) {_OMC_LIT28,_OMC_LIT43}};
#define _OMC_LIT44 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT44)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT45,2,1) {_OMC_LIT26,_OMC_LIT44}};
#define _OMC_LIT45 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT45)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT46,2,1) {_OMC_LIT24,_OMC_LIT45}};
#define _OMC_LIT46 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT46)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT47,2,1) {_OMC_LIT22,_OMC_LIT46}};
#define _OMC_LIT47 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT47)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT48,2,1) {_OMC_LIT20,_OMC_LIT47}};
#define _OMC_LIT48 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT48)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT49,2,1) {_OMC_LIT18,_OMC_LIT48}};
#define _OMC_LIT49 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT49)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT50,2,1) {_OMC_LIT14,_OMC_LIT49}};
#define _OMC_LIT50 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT50)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT51,2,1) {_OMC_LIT12,_OMC_LIT50}};
#define _OMC_LIT51 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT51)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT52,2,3) {&Flags_ValidOptions_STRING__OPTION__desc,_OMC_LIT51}};
#define _OMC_LIT52 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT52)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT53,1,1) {_OMC_LIT52}};
#define _OMC_LIT53 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT53)
#define _OMC_LIT54_data "Sets the language standard that should be used."
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT54,47,_OMC_LIT54_data);
#define _OMC_LIT54 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT54)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT55,2,3) {&Gettext_TranslatableContent_gettext__desc,_OMC_LIT54}};
#define _OMC_LIT55 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT55)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT56,8,3) {&Flags_ConfigFlag_CONFIG__FLAG__desc,MMC_IMMEDIATE(MMC_TAGFIXNUM(8)),_OMC_LIT10,MMC_REFSTRUCTLIT(mmc_none),_OMC_LIT11,_OMC_LIT42,_OMC_LIT53,_OMC_LIT55}};
#define _OMC_LIT56 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT56)
#define _OMC_LIT57_data "<interactive>"
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT57,13,_OMC_LIT57_data);
#define _OMC_LIT57 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT57)
#include "util/modelica.h"
#include "Parser_includes.h"
#if !defined(PROTECTED_FUNCTION_STATIC)
#define PROTECTED_FUNCTION_STATIC
#endif
PROTECTED_FUNCTION_STATIC modelica_string omc_Parser_expToString(threadData_t *threadData, modelica_metatype _inExp);
static const MMC_DEFSTRUCTLIT(boxvar_lit_Parser_expToString,2,0) {(void*) boxptr_Parser_expToString,0}};
#define boxvar_Parser_expToString MMC_REFSTRUCTLIT(boxvar_lit_Parser_expToString)
PROTECTED_FUNCTION_STATIC modelica_metatype omc_Parser_getFeaturesAnnotationList2(threadData_t *threadData, modelica_metatype _eltArgs);
static const MMC_DEFSTRUCTLIT(boxvar_lit_Parser_getFeaturesAnnotationList2,2,0) {(void*) boxptr_Parser_getFeaturesAnnotationList2,0}};
#define boxvar_Parser_getFeaturesAnnotationList2 MMC_REFSTRUCTLIT(boxvar_lit_Parser_getFeaturesAnnotationList2)
PROTECTED_FUNCTION_STATIC modelica_metatype omc_Parser_getFeaturesAnnotationList(threadData_t *threadData, modelica_metatype _mod);
static const MMC_DEFSTRUCTLIT(boxvar_lit_Parser_getFeaturesAnnotationList,2,0) {(void*) boxptr_Parser_getFeaturesAnnotationList,0}};
#define boxvar_Parser_getFeaturesAnnotationList MMC_REFSTRUCTLIT(boxvar_lit_Parser_getFeaturesAnnotationList)
PROTECTED_FUNCTION_STATIC modelica_metatype omc_Parser_getFeaturesAnnotation(threadData_t *threadData, modelica_metatype _className);
static const MMC_DEFSTRUCTLIT(boxvar_lit_Parser_getFeaturesAnnotation,2,0) {(void*) boxptr_Parser_getFeaturesAnnotation,0}};
#define boxvar_Parser_getFeaturesAnnotation MMC_REFSTRUCTLIT(boxvar_lit_Parser_getFeaturesAnnotation)
PROTECTED_FUNCTION_STATIC modelica_string omc_Parser_getLicenseAnnotationLicenseFile(threadData_t *threadData, modelica_metatype _eltArgs);
static const MMC_DEFSTRUCTLIT(boxvar_lit_Parser_getLicenseAnnotationLicenseFile,2,0) {(void*) boxptr_Parser_getLicenseAnnotationLicenseFile,0}};
#define boxvar_Parser_getLicenseAnnotationLicenseFile MMC_REFSTRUCTLIT(boxvar_lit_Parser_getLicenseAnnotationLicenseFile)
PROTECTED_FUNCTION_STATIC modelica_string omc_Parser_getLicenseAnnotationLibraryKey(threadData_t *threadData, modelica_metatype _eltArgs);
static const MMC_DEFSTRUCTLIT(boxvar_lit_Parser_getLicenseAnnotationLibraryKey,2,0) {(void*) boxptr_Parser_getLicenseAnnotationLibraryKey,0}};
#define boxvar_Parser_getLicenseAnnotationLibraryKey MMC_REFSTRUCTLIT(boxvar_lit_Parser_getLicenseAnnotationLibraryKey)
PROTECTED_FUNCTION_STATIC modelica_metatype omc_Parser_getLicenseAnnotationTuple(threadData_t *threadData, modelica_metatype _mod);
static const MMC_DEFSTRUCTLIT(boxvar_lit_Parser_getLicenseAnnotationTuple,2,0) {(void*) boxptr_Parser_getLicenseAnnotationTuple,0}};
#define boxvar_Parser_getLicenseAnnotationTuple MMC_REFSTRUCTLIT(boxvar_lit_Parser_getLicenseAnnotationTuple)
PROTECTED_FUNCTION_STATIC modelica_metatype omc_Parser_getLicenseAnnotationWork2(threadData_t *threadData, modelica_metatype _eltArgs);
static const MMC_DEFSTRUCTLIT(boxvar_lit_Parser_getLicenseAnnotationWork2,2,0) {(void*) boxptr_Parser_getLicenseAnnotationWork2,0}};
#define boxvar_Parser_getLicenseAnnotationWork2 MMC_REFSTRUCTLIT(boxvar_lit_Parser_getLicenseAnnotationWork2)
PROTECTED_FUNCTION_STATIC modelica_metatype omc_Parser_getLicenseAnnotationWork1(threadData_t *threadData, modelica_metatype _mod);
static const MMC_DEFSTRUCTLIT(boxvar_lit_Parser_getLicenseAnnotationWork1,2,0) {(void*) boxptr_Parser_getLicenseAnnotationWork1,0}};
#define boxvar_Parser_getLicenseAnnotationWork1 MMC_REFSTRUCTLIT(boxvar_lit_Parser_getLicenseAnnotationWork1)
PROTECTED_FUNCTION_STATIC modelica_metatype omc_Parser_getLicenseAnnotation(threadData_t *threadData, modelica_metatype _className);
static const MMC_DEFSTRUCTLIT(boxvar_lit_Parser_getLicenseAnnotation,2,0) {(void*) boxptr_Parser_getLicenseAnnotation,0}};
#define boxvar_Parser_getLicenseAnnotation MMC_REFSTRUCTLIT(boxvar_lit_Parser_getLicenseAnnotation)
PROTECTED_FUNCTION_STATIC modelica_metatype omc_Parser_loadFileThread(threadData_t *threadData, modelica_metatype _inFileEncoding);
static const MMC_DEFSTRUCTLIT(boxvar_lit_Parser_loadFileThread,2,0) {(void*) boxptr_Parser_loadFileThread,0}};
#define boxvar_Parser_loadFileThread MMC_REFSTRUCTLIT(boxvar_lit_Parser_loadFileThread)
PROTECTED_FUNCTION_STATIC modelica_metatype omc_Parser_parallelParseFilesWork(threadData_t *threadData, modelica_metatype _filenames, modelica_string _encoding, modelica_integer _numThreads, modelica_string _libraryPath, modelica_metatype _lveInstance);
PROTECTED_FUNCTION_STATIC modelica_metatype boxptr_Parser_parallelParseFilesWork(threadData_t *threadData, modelica_metatype _filenames, modelica_metatype _encoding, modelica_metatype _numThreads, modelica_metatype _libraryPath, modelica_metatype _lveInstance);
static const MMC_DEFSTRUCTLIT(boxvar_lit_Parser_parallelParseFilesWork,2,0) {(void*) boxptr_Parser_parallelParseFilesWork,0}};
#define boxvar_Parser_parallelParseFilesWork MMC_REFSTRUCTLIT(boxvar_lit_Parser_parallelParseFilesWork)
PROTECTED_FUNCTION_STATIC modelica_string omc_Parser_expToString(threadData_t *threadData, modelica_metatype _inExp)
{
modelica_string _outExp = NULL;
modelica_string tmp1 = 0;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
modelica_metatype tmp4_1;
tmp4_1 = _inExp;
{
modelica_string _str = NULL;
volatile mmc_switch_type tmp4;
int tmp5;
tmp4 = 0;
for (; tmp4 < 2; tmp4++) {
switch (MMC_SWITCH_CAST(tmp4)) {
case 0: {
modelica_metatype tmpMeta6;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,3,1) == 0) goto tmp3_end;
tmpMeta6 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
_str = tmpMeta6;
tmp1 = _str;
goto tmp3_done;
}
case 1: {
tmp1 = _OMC_LIT0;
goto tmp3_done;
}
}
goto tmp3_end;
tmp3_end: ;
}
goto goto_2;
goto_2:;
MMC_THROW_INTERNAL();
goto tmp3_done;
tmp3_done:;
}
}
_outExp = tmp1;
_return: OMC_LABEL_UNUSED
return _outExp;
}
PROTECTED_FUNCTION_STATIC modelica_metatype omc_Parser_getFeaturesAnnotationList2(threadData_t *threadData, modelica_metatype _eltArgs)
{
modelica_metatype _features = NULL;
modelica_metatype tmpMeta1;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
modelica_metatype tmp4_1;
tmp4_1 = _eltArgs;
{
modelica_metatype _expList = NULL;
modelica_metatype _xs = NULL;
volatile mmc_switch_type tmp4;
int tmp5;
tmp4 = 0;
for (; tmp4 < 3; tmp4++) {
switch (MMC_SWITCH_CAST(tmp4)) {
case 0: {
modelica_metatype tmpMeta6;
if (!listEmpty(tmp4_1)) goto tmp3_end;
tmpMeta6 = MMC_REFSTRUCTLIT(mmc_nil);
tmpMeta1 = tmpMeta6;
goto tmp3_done;
}
case 1: {
modelica_metatype tmpMeta7;
modelica_metatype tmpMeta8;
modelica_metatype tmpMeta9;
modelica_metatype tmpMeta10;
modelica_metatype tmpMeta11;
modelica_metatype tmpMeta12;
modelica_metatype tmpMeta13;
modelica_metatype tmpMeta14;
modelica_metatype tmpMeta15;
if (listEmpty(tmp4_1)) goto tmp3_end;
tmpMeta7 = MMC_CAR(tmp4_1);
tmpMeta8 = MMC_CDR(tmp4_1);
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta7,0,6) == 0) goto tmp3_end;
tmpMeta9 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta7), 4));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta9,1,1) == 0) goto tmp3_end;
tmpMeta10 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta9), 2));
if (8 != MMC_STRLEN(tmpMeta10) || strcmp(MMC_STRINGDATA(_OMC_LIT1), MMC_STRINGDATA(tmpMeta10)) != 0) goto tmp3_end;
tmpMeta11 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta7), 5));
if (optionNone(tmpMeta11)) goto tmp3_end;
tmpMeta12 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta11), 1));
tmpMeta13 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta12), 3));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta13,1,2) == 0) goto tmp3_end;
tmpMeta14 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta13), 2));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta14,13,1) == 0) goto tmp3_end;
tmpMeta15 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta14), 2));
_expList = tmpMeta15;
tmpMeta1 = omc_List_map(threadData, _expList, boxvar_Parser_expToString);
goto tmp3_done;
}
case 2: {
modelica_metatype tmpMeta16;
modelica_metatype tmpMeta17;
if (listEmpty(tmp4_1)) goto tmp3_end;
tmpMeta16 = MMC_CAR(tmp4_1);
tmpMeta17 = MMC_CDR(tmp4_1);
_xs = tmpMeta17;
_eltArgs = _xs;
goto _tailrecursive;
goto tmp3_done;
}
}
goto tmp3_end;
tmp3_end: ;
}
goto goto_2;
goto_2:;
MMC_THROW_INTERNAL();
goto tmp3_done;
tmp3_done:;
}
}
_features = tmpMeta1;
_return: OMC_LABEL_UNUSED
return _features;
}
PROTECTED_FUNCTION_STATIC modelica_metatype omc_Parser_getFeaturesAnnotationList(threadData_t *threadData, modelica_metatype _mod)
{
modelica_metatype _features = NULL;
modelica_metatype tmpMeta1;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
modelica_metatype tmp4_1;
tmp4_1 = _mod;
{
modelica_metatype _arglst = NULL;
volatile mmc_switch_type tmp4;
int tmp5;
tmp4 = 0;
for (; tmp4 < 1; tmp4++) {
switch (MMC_SWITCH_CAST(tmp4)) {
case 0: {
modelica_metatype tmpMeta6;
modelica_metatype tmpMeta7;
if (optionNone(tmp4_1)) goto tmp3_end;
tmpMeta6 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 1));
tmpMeta7 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta6), 2));
_arglst = tmpMeta7;
tmpMeta1 = omc_Parser_getFeaturesAnnotationList2(threadData, _arglst);
goto tmp3_done;
}
}
goto tmp3_end;
tmp3_end: ;
}
goto goto_2;
goto_2:;
MMC_THROW_INTERNAL();
goto tmp3_done;
tmp3_done:;
}
}
_features = tmpMeta1;
_return: OMC_LABEL_UNUSED
return _features;
}
PROTECTED_FUNCTION_STATIC modelica_metatype omc_Parser_getFeaturesAnnotation(threadData_t *threadData, modelica_metatype _className)
{
modelica_metatype _features = NULL;
modelica_metatype _opt_featuresList = NULL;
modelica_metatype tmpMeta1;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
_opt_featuresList = omc_AbsynUtil_getNamedAnnotationInClass(threadData, _className, _OMC_LIT3, boxvar_Parser_getFeaturesAnnotationList);
tmpMeta1 = MMC_REFSTRUCTLIT(mmc_nil);
_features = omc_Util_getOptionOrDefault(threadData, _opt_featuresList, tmpMeta1);
_return: OMC_LABEL_UNUSED
return _features;
}
PROTECTED_FUNCTION_STATIC modelica_string omc_Parser_getLicenseAnnotationLicenseFile(threadData_t *threadData, modelica_metatype _eltArgs)
{
modelica_string _licenseFile = NULL;
modelica_string tmp1 = 0;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
modelica_metatype tmp4_1;
tmp4_1 = _eltArgs;
{
modelica_metatype _xs = NULL;
modelica_string _s = NULL;
volatile mmc_switch_type tmp4;
int tmp5;
tmp4 = 0;
for (; tmp4 < 3; tmp4++) {
switch (MMC_SWITCH_CAST(tmp4)) {
case 0: {
if (!listEmpty(tmp4_1)) goto tmp3_end;
tmp1 = _OMC_LIT0;
goto tmp3_done;
}
case 1: {
modelica_metatype tmpMeta6;
modelica_metatype tmpMeta7;
modelica_metatype tmpMeta8;
modelica_metatype tmpMeta9;
modelica_metatype tmpMeta10;
modelica_metatype tmpMeta11;
modelica_metatype tmpMeta12;
modelica_metatype tmpMeta13;
modelica_metatype tmpMeta14;
if (listEmpty(tmp4_1)) goto tmp3_end;
tmpMeta6 = MMC_CAR(tmp4_1);
tmpMeta7 = MMC_CDR(tmp4_1);
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta6,0,6) == 0) goto tmp3_end;
tmpMeta8 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta6), 4));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta8,1,1) == 0) goto tmp3_end;
tmpMeta9 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta8), 2));
if (11 != MMC_STRLEN(tmpMeta9) || strcmp(MMC_STRINGDATA(_OMC_LIT4), MMC_STRINGDATA(tmpMeta9)) != 0) goto tmp3_end;
tmpMeta10 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta6), 5));
if (optionNone(tmpMeta10)) goto tmp3_end;
tmpMeta11 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta10), 1));
tmpMeta12 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta11), 3));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta12,1,2) == 0) goto tmp3_end;
tmpMeta13 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta12), 2));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta13,3,1) == 0) goto tmp3_end;
tmpMeta14 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta13), 2));
_s = tmpMeta14;
tmp1 = _s;
goto tmp3_done;
}
case 2: {
modelica_metatype tmpMeta15;
modelica_metatype tmpMeta16;
if (listEmpty(tmp4_1)) goto tmp3_end;
tmpMeta15 = MMC_CAR(tmp4_1);
tmpMeta16 = MMC_CDR(tmp4_1);
_xs = tmpMeta16;
_eltArgs = _xs;
goto _tailrecursive;
goto tmp3_done;
}
}
goto tmp3_end;
tmp3_end: ;
}
goto goto_2;
goto_2:;
MMC_THROW_INTERNAL();
goto tmp3_done;
tmp3_done:;
}
}
_licenseFile = tmp1;
_return: OMC_LABEL_UNUSED
return _licenseFile;
}
PROTECTED_FUNCTION_STATIC modelica_string omc_Parser_getLicenseAnnotationLibraryKey(threadData_t *threadData, modelica_metatype _eltArgs)
{
modelica_string _libraryKey = NULL;
modelica_string tmp1 = 0;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
modelica_metatype tmp4_1;
tmp4_1 = _eltArgs;
{
modelica_metatype _xs = NULL;
modelica_string _s = NULL;
volatile mmc_switch_type tmp4;
int tmp5;
tmp4 = 0;
for (; tmp4 < 3; tmp4++) {
switch (MMC_SWITCH_CAST(tmp4)) {
case 0: {
if (!listEmpty(tmp4_1)) goto tmp3_end;
tmp1 = _OMC_LIT0;
goto tmp3_done;
}
case 1: {
modelica_metatype tmpMeta6;
modelica_metatype tmpMeta7;
modelica_metatype tmpMeta8;
modelica_metatype tmpMeta9;
modelica_metatype tmpMeta10;
modelica_metatype tmpMeta11;
modelica_metatype tmpMeta12;
modelica_metatype tmpMeta13;
modelica_metatype tmpMeta14;
if (listEmpty(tmp4_1)) goto tmp3_end;
tmpMeta6 = MMC_CAR(tmp4_1);
tmpMeta7 = MMC_CDR(tmp4_1);
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta6,0,6) == 0) goto tmp3_end;
tmpMeta8 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta6), 4));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta8,1,1) == 0) goto tmp3_end;
tmpMeta9 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta8), 2));
if (10 != MMC_STRLEN(tmpMeta9) || strcmp(MMC_STRINGDATA(_OMC_LIT5), MMC_STRINGDATA(tmpMeta9)) != 0) goto tmp3_end;
tmpMeta10 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta6), 5));
if (optionNone(tmpMeta10)) goto tmp3_end;
tmpMeta11 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta10), 1));
tmpMeta12 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta11), 3));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta12,1,2) == 0) goto tmp3_end;
tmpMeta13 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta12), 2));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta13,3,1) == 0) goto tmp3_end;
tmpMeta14 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta13), 2));
_s = tmpMeta14;
tmp1 = _s;
goto tmp3_done;
}
case 2: {
modelica_metatype tmpMeta15;
modelica_metatype tmpMeta16;
if (listEmpty(tmp4_1)) goto tmp3_end;
tmpMeta15 = MMC_CAR(tmp4_1);
tmpMeta16 = MMC_CDR(tmp4_1);
_xs = tmpMeta16;
_eltArgs = _xs;
goto _tailrecursive;
goto tmp3_done;
}
}
goto tmp3_end;
tmp3_end: ;
}
goto goto_2;
goto_2:;
MMC_THROW_INTERNAL();
goto tmp3_done;
tmp3_done:;
}
}
_libraryKey = tmp1;
_return: OMC_LABEL_UNUSED
return _libraryKey;
}
PROTECTED_FUNCTION_STATIC modelica_metatype omc_Parser_getLicenseAnnotationTuple(threadData_t *threadData, modelica_metatype _mod)
{
modelica_metatype _license = NULL;
modelica_metatype tmpMeta1;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
modelica_metatype tmp4_1;
tmp4_1 = _mod;
{
modelica_metatype _arglst = NULL;
modelica_string _libraryKey = NULL;
modelica_string _licenseFile = NULL;
volatile mmc_switch_type tmp4;
int tmp5;
tmp4 = 0;
for (; tmp4 < 1; tmp4++) {
switch (MMC_SWITCH_CAST(tmp4)) {
case 0: {
modelica_metatype tmpMeta6;
modelica_metatype tmpMeta7;
modelica_metatype tmpMeta8;
if (optionNone(tmp4_1)) goto tmp3_end;
tmpMeta6 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 1));
tmpMeta7 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta6), 2));
_arglst = tmpMeta7;
_libraryKey = omc_Parser_getLicenseAnnotationLibraryKey(threadData, _arglst);
_licenseFile = omc_Parser_getLicenseAnnotationLicenseFile(threadData, _arglst);
tmpMeta8 = mmc_mk_box2(0, _libraryKey, _licenseFile);
tmpMeta1 = tmpMeta8;
goto tmp3_done;
}
}
goto tmp3_end;
tmp3_end: ;
}
goto goto_2;
goto_2:;
MMC_THROW_INTERNAL();
goto tmp3_done;
tmp3_done:;
}
}
_license = tmpMeta1;
_return: OMC_LABEL_UNUSED
return _license;
}
PROTECTED_FUNCTION_STATIC modelica_metatype omc_Parser_getLicenseAnnotationWork2(threadData_t *threadData, modelica_metatype _eltArgs)
{
modelica_metatype _license = NULL;
modelica_metatype tmpMeta1;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
modelica_metatype tmp4_1;
tmp4_1 = _eltArgs;
{
modelica_metatype _mod = NULL;
modelica_metatype _xs = NULL;
modelica_string _libraryKey = NULL;
modelica_string _licenseFile = NULL;
volatile mmc_switch_type tmp4;
int tmp5;
tmp4 = 0;
for (; tmp4 < 3; tmp4++) {
switch (MMC_SWITCH_CAST(tmp4)) {
case 0: {
if (!listEmpty(tmp4_1)) goto tmp3_end;
tmpMeta1 = _OMC_LIT6;
goto tmp3_done;
}
case 1: {
modelica_metatype tmpMeta6;
modelica_metatype tmpMeta7;
modelica_metatype tmpMeta8;
modelica_metatype tmpMeta9;
modelica_metatype tmpMeta10;
modelica_metatype tmpMeta11;
modelica_metatype tmpMeta12;
modelica_metatype tmpMeta13;
modelica_metatype tmpMeta14;
if (listEmpty(tmp4_1)) goto tmp3_end;
tmpMeta6 = MMC_CAR(tmp4_1);
tmpMeta7 = MMC_CDR(tmp4_1);
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta6,0,6) == 0) goto tmp3_end;
tmpMeta8 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta6), 4));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta8,1,1) == 0) goto tmp3_end;
tmpMeta9 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta8), 2));
if (7 != MMC_STRLEN(tmpMeta9) || strcmp(MMC_STRINGDATA(_OMC_LIT7), MMC_STRINGDATA(tmpMeta9)) != 0) goto tmp3_end;
tmpMeta10 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta6), 5));
_mod = tmpMeta10;
tmpMeta11 = omc_Parser_getLicenseAnnotationTuple(threadData, _mod);
tmpMeta12 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta11), 1));
tmpMeta13 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta11), 2));
_libraryKey = tmpMeta12;
_licenseFile = tmpMeta13;
tmpMeta14 = mmc_mk_box2(0, _libraryKey, _licenseFile);
tmpMeta1 = tmpMeta14;
goto tmp3_done;
}
case 2: {
modelica_metatype tmpMeta15;
modelica_metatype tmpMeta16;
modelica_metatype tmpMeta17;
modelica_metatype tmpMeta18;
modelica_metatype tmpMeta19;
modelica_metatype tmpMeta20;
if (listEmpty(tmp4_1)) goto tmp3_end;
tmpMeta15 = MMC_CAR(tmp4_1);
tmpMeta16 = MMC_CDR(tmp4_1);
_xs = tmpMeta16;
tmpMeta17 = omc_Parser_getLicenseAnnotationWork2(threadData, _xs);
tmpMeta18 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta17), 1));
tmpMeta19 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta17), 2));
_libraryKey = tmpMeta18;
_licenseFile = tmpMeta19;
tmpMeta20 = mmc_mk_box2(0, _libraryKey, _licenseFile);
tmpMeta1 = tmpMeta20;
goto tmp3_done;
}
}
goto tmp3_end;
tmp3_end: ;
}
goto goto_2;
goto_2:;
MMC_THROW_INTERNAL();
goto tmp3_done;
tmp3_done:;
}
}
_license = tmpMeta1;
_return: OMC_LABEL_UNUSED
return _license;
}
PROTECTED_FUNCTION_STATIC modelica_metatype omc_Parser_getLicenseAnnotationWork1(threadData_t *threadData, modelica_metatype _mod)
{
modelica_metatype _license = NULL;
modelica_metatype tmpMeta1;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
modelica_metatype tmp4_1;
tmp4_1 = _mod;
{
modelica_metatype _arglst = NULL;
modelica_string _libraryKey = NULL;
modelica_string _licenseFile = NULL;
volatile mmc_switch_type tmp4;
int tmp5;
tmp4 = 0;
for (; tmp4 < 1; tmp4++) {
switch (MMC_SWITCH_CAST(tmp4)) {
case 0: {
modelica_metatype tmpMeta6;
modelica_metatype tmpMeta7;
modelica_metatype tmpMeta8;
modelica_metatype tmpMeta9;
modelica_metatype tmpMeta10;
modelica_metatype tmpMeta11;
if (optionNone(tmp4_1)) goto tmp3_end;
tmpMeta6 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 1));
tmpMeta7 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta6), 2));
_arglst = tmpMeta7;
tmpMeta8 = omc_Parser_getLicenseAnnotationWork2(threadData, _arglst);
tmpMeta9 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta8), 1));
tmpMeta10 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta8), 2));
_libraryKey = tmpMeta9;
_licenseFile = tmpMeta10;
tmpMeta11 = mmc_mk_box2(0, _libraryKey, _licenseFile);
tmpMeta1 = tmpMeta11;
goto tmp3_done;
}
}
goto tmp3_end;
tmp3_end: ;
}
goto goto_2;
goto_2:;
MMC_THROW_INTERNAL();
goto tmp3_done;
tmp3_done:;
}
}
_license = tmpMeta1;
_return: OMC_LABEL_UNUSED
return _license;
}
PROTECTED_FUNCTION_STATIC modelica_metatype omc_Parser_getLicenseAnnotation(threadData_t *threadData, modelica_metatype _className)
{
modelica_metatype _license = NULL;
modelica_metatype _opt_license = NULL;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
_opt_license = omc_AbsynUtil_getNamedAnnotationInClass(threadData, _className, _OMC_LIT3, boxvar_Parser_getLicenseAnnotationWork1);
_license = omc_Util_getOptionOrDefault(threadData, _opt_license, _OMC_LIT6);
_return: OMC_LABEL_UNUSED
return _license;
}
DLLExport
modelica_boolean omc_Parser_checkLicenseAndFeatures(threadData_t *threadData, modelica_metatype _c1, modelica_metatype _lveInstance)
{
modelica_boolean _result;
modelica_metatype _orFeatures = NULL;
modelica_metatype _andFeatures = NULL;
modelica_metatype tmpMeta1;
modelica_metatype tmpMeta2;
modelica_metatype tmpMeta3;
modelica_metatype tmpMeta4;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
_result = 1;
_orFeatures = omc_Parser_getFeaturesAnnotation(threadData, _c1);
{
modelica_metatype _orFeature;
for (tmpMeta1 = _orFeatures; !listEmpty(tmpMeta1); tmpMeta1=MMC_CDR(tmpMeta1))
{
_orFeature = MMC_CAR(tmpMeta1);
_andFeatures = omc_Util_stringSplitAtChar(threadData, _orFeature, _OMC_LIT8);
_result = 1;
{
modelica_metatype _andFeature;
for (tmpMeta2 = _andFeatures; !listEmpty(tmpMeta2); tmpMeta2=MMC_CDR(tmpMeta2))
{
_andFeature = MMC_CAR(tmpMeta2);
if((!omc_Parser_checkLVEToolFeature(threadData, _lveInstance, _andFeature)))
{
_result = 0;
break;
}
}
}
if(_result)
{
break;
}
}
}
_return: OMC_LABEL_UNUSED
return _result;
}
modelica_metatype boxptr_Parser_checkLicenseAndFeatures(threadData_t *threadData, modelica_metatype _c1, modelica_metatype _lveInstance)
{
modelica_boolean _result;
modelica_metatype out_result;
_result = omc_Parser_checkLicenseAndFeatures(threadData, _c1, _lveInstance);
out_result = mmc_mk_icon(_result);
return out_result;
}
PROTECTED_FUNCTION_STATIC modelica_metatype omc_Parser_loadFileThread(threadData_t *threadData, modelica_metatype _inFileEncoding)
{
modelica_metatype _result = NULL;
modelica_metatype tmpMeta1;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
volatile modelica_metatype tmp4_1;
tmp4_1 = _inFileEncoding;
{
modelica_string _filename = NULL;
modelica_string _encoding = NULL;
modelica_string _libraryPath = NULL;
modelica_metatype _lveInstance = NULL;
volatile mmc_switch_type tmp4;
int tmp5;
tmp4 = 0;
MMC_TRY_INTERNAL(mmc_jumper)
tmp3_top:
threadData->mmc_jumper = &new_mmc_jumper;
for (; tmp4 < 2; tmp4++) {
switch (MMC_SWITCH_CAST(tmp4)) {
case 0: {
modelica_metatype tmpMeta6;
modelica_metatype tmpMeta7;
modelica_metatype tmpMeta8;
modelica_metatype tmpMeta9;
modelica_metatype tmpMeta10;
tmpMeta6 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 1));
tmpMeta7 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
tmpMeta8 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 3));
tmpMeta9 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 4));
_filename = tmpMeta6;
_encoding = tmpMeta7;
_libraryPath = tmpMeta8;
_lveInstance = tmpMeta9;
tmpMeta10 = mmc_mk_box3(3, &Parser_ParserResult_PARSERRESULT__desc, _filename, mmc_mk_some(omc_Parser_parse(threadData, _filename, _encoding, _libraryPath, _lveInstance)));
tmpMeta1 = tmpMeta10;
goto tmp3_done;
}
case 1: {
modelica_metatype tmpMeta11;
modelica_metatype tmpMeta12;
tmpMeta11 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 1));
_filename = tmpMeta11;
tmpMeta12 = mmc_mk_box3(3, &Parser_ParserResult_PARSERRESULT__desc, _filename, mmc_mk_none());
tmpMeta1 = tmpMeta12;
goto tmp3_done;
}
}
goto tmp3_end;
tmp3_end: ;
}
goto goto_2;
tmp3_done:
(void)tmp4;
MMC_RESTORE_INTERNAL(mmc_jumper);
goto tmp3_done2;
goto_2:;
MMC_CATCH_INTERNAL(mmc_jumper);
if (++tmp4 < 2) {
goto tmp3_top;
}
MMC_THROW_INTERNAL();
tmp3_done2:;
}
}
_result = tmpMeta1;
if((omc_ErrorExt_getNumMessages(threadData) > ((modelica_integer) 0)))
{
omc_ErrorExt_moveMessagesToParentThread(threadData);
}
_return: OMC_LABEL_UNUSED
return _result;
}
PROTECTED_FUNCTION_STATIC modelica_metatype omc_Parser_parallelParseFilesWork(threadData_t *threadData, modelica_metatype _filenames, modelica_string _encoding, modelica_integer _numThreads, modelica_string _libraryPath, modelica_metatype _lveInstance)
{
modelica_metatype _partialResults = NULL;
modelica_metatype _workList = NULL;
modelica_metatype tmpMeta1;
modelica_metatype tmpMeta6;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
modelica_metatype __omcQ_24tmpVar1;
modelica_metatype* tmp2;
modelica_metatype tmpMeta3;
modelica_metatype tmpMeta4;
modelica_metatype __omcQ_24tmpVar0;
modelica_integer tmp5;
modelica_metatype _file_loopVar = 0;
modelica_metatype _file;
_file_loopVar = _filenames;
tmpMeta3 = MMC_REFSTRUCTLIT(mmc_nil);
__omcQ_24tmpVar1 = tmpMeta3;
tmp2 = &__omcQ_24tmpVar1;
while(1) {
tmp5 = 1;
if (!listEmpty(_file_loopVar)) {
_file = MMC_CAR(_file_loopVar);
_file_loopVar = MMC_CDR(_file_loopVar);
tmp5--;
}
if (tmp5 == 0) {
tmpMeta4 = mmc_mk_box4(0, _file, _encoding, _libraryPath, _lveInstance);
__omcQ_24tmpVar0 = tmpMeta4;
*tmp2 = mmc_mk_cons(__omcQ_24tmpVar0,0);
tmp2 = &MMC_CDR(*tmp2);
} else if (tmp5 == 1) {
break;
} else {
MMC_THROW_INTERNAL();
}
}
*tmp2 = mmc_mk_nil();
tmpMeta1 = __omcQ_24tmpVar1;
}
_workList = tmpMeta1;
if(((((omc_Testsuite_isRunning(threadData) || (omc_Config_noProc(threadData) == ((modelica_integer) 1))) || (_numThreads == ((modelica_integer) 1))) || (listLength(_filenames) < ((modelica_integer) 2))) || isSome(_lveInstance)))
{
{
modelica_metatype __omcQ_24tmpVar3;
modelica_metatype* tmp7;
modelica_metatype tmpMeta8;
modelica_metatype __omcQ_24tmpVar2;
modelica_integer tmp9;
modelica_metatype _t_loopVar = 0;
modelica_metatype _t;
_t_loopVar = _workList;
tmpMeta8 = MMC_REFSTRUCTLIT(mmc_nil);
__omcQ_24tmpVar3 = tmpMeta8;
tmp7 = &__omcQ_24tmpVar3;
while(1) {
tmp9 = 1;
if (!listEmpty(_t_loopVar)) {
_t = MMC_CAR(_t_loopVar);
_t_loopVar = MMC_CDR(_t_loopVar);
tmp9--;
}
if (tmp9 == 0) {
__omcQ_24tmpVar2 = omc_Parser_loadFileThread(threadData, _t);
*tmp7 = mmc_mk_cons(__omcQ_24tmpVar2,0);
tmp7 = &MMC_CDR(*tmp7);
} else if (tmp9 == 1) {
break;
} else {
MMC_THROW_INTERNAL();
}
}
*tmp7 = mmc_mk_nil();
tmpMeta6 = __omcQ_24tmpVar3;
}
_partialResults = tmpMeta6;
}
else
{
_partialResults = omc_System_launchParallelTasks(threadData, modelica_integer_min((modelica_integer)(((modelica_integer) 8)),(modelica_integer)(_numThreads)), _workList, boxvar_Parser_loadFileThread);
}
_return: OMC_LABEL_UNUSED
return _partialResults;
}
PROTECTED_FUNCTION_STATIC modelica_metatype boxptr_Parser_parallelParseFilesWork(threadData_t *threadData, modelica_metatype _filenames, modelica_metatype _encoding, modelica_metatype _numThreads, modelica_metatype _libraryPath, modelica_metatype _lveInstance)
{
modelica_integer tmp1;
modelica_metatype _partialResults = NULL;
tmp1 = mmc_unbox_integer(_numThreads);
_partialResults = omc_Parser_parallelParseFilesWork(threadData, _filenames, _encoding, tmp1, _libraryPath, _lveInstance);
return _partialResults;
}
DLLExport
void omc_Parser_stopLibraryVendorExecutable(threadData_t *threadData, modelica_metatype _lveInstance)
{
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
omc_ParserExt_stopLibraryVendorExecutable(threadData, _lveInstance);
_return: OMC_LABEL_UNUSED
return;
}
DLLExport
modelica_boolean omc_Parser_checkLVEToolFeature(threadData_t *threadData, modelica_metatype _lveInstance, modelica_string _feature)
{
modelica_boolean _status;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
_status = omc_ParserExt_checkLVEToolFeature(threadData, _lveInstance, _feature);
_return: OMC_LABEL_UNUSED
return _status;
}
modelica_metatype boxptr_Parser_checkLVEToolFeature(threadData_t *threadData, modelica_metatype _lveInstance, modelica_metatype _feature)
{
modelica_boolean _status;
modelica_metatype out_status;
_status = omc_Parser_checkLVEToolFeature(threadData, _lveInstance, _feature);
out_status = mmc_mk_icon(_status);
return out_status;
}
DLLExport
modelica_boolean omc_Parser_checkLVEToolLicense(threadData_t *threadData, modelica_metatype _lveInstance, modelica_string _packageName)
{
modelica_boolean _status;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
_status = omc_ParserExt_checkLVEToolLicense(threadData, _lveInstance, _packageName);
_return: OMC_LABEL_UNUSED
return _status;
}
modelica_metatype boxptr_Parser_checkLVEToolLicense(threadData_t *threadData, modelica_metatype _lveInstance, modelica_metatype _packageName)
{
modelica_boolean _status;
modelica_metatype out_status;
_status = omc_Parser_checkLVEToolLicense(threadData, _lveInstance, _packageName);
out_status = mmc_mk_icon(_status);
return out_status;
}
DLLExport
modelica_boolean omc_Parser_startLibraryVendorExecutable(threadData_t *threadData, modelica_string _lvePath, modelica_metatype *out_lveInstance)
{
modelica_boolean _success;
modelica_metatype _lveInstance = NULL;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
_success = omc_ParserExt_startLibraryVendorExecutable(threadData, _lvePath ,&_lveInstance);
_return: OMC_LABEL_UNUSED
if (out_lveInstance) { *out_lveInstance = _lveInstance; }
return _success;
}
modelica_metatype boxptr_Parser_startLibraryVendorExecutable(threadData_t *threadData, modelica_metatype _lvePath, modelica_metatype *out_lveInstance)
{
modelica_boolean _success;
modelica_metatype out_success;
_success = omc_Parser_startLibraryVendorExecutable(threadData, _lvePath, out_lveInstance);
out_success = mmc_mk_icon(_success);
return out_success;
}
DLLExport
modelica_metatype omc_Parser_parallelParseFilesToProgramList(threadData_t *threadData, modelica_metatype _filenames, modelica_string _encoding, modelica_integer _numThreads)
{
modelica_metatype _result = NULL;
modelica_metatype tmpMeta1;
modelica_metatype tmpMeta2;
modelica_metatype tmpMeta3;
modelica_metatype tmpMeta4;
modelica_metatype tmpMeta11;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
tmpMeta1 = MMC_REFSTRUCTLIT(mmc_nil);
_result = tmpMeta1;
{
modelica_metatype _r;
for (tmpMeta2 = omc_Parser_parallelParseFilesWork(threadData, _filenames, _encoding, _numThreads, _OMC_LIT0, mmc_mk_none()); !listEmpty(tmpMeta2); tmpMeta2=MMC_CDR(tmpMeta2))
{
_r = MMC_CAR(tmpMeta2);
{
modelica_metatype tmp7_1;
tmp7_1 = _r;
{
modelica_metatype _p = NULL;
volatile mmc_switch_type tmp7;
int tmp8;
tmp7 = 0;
for (; tmp7 < 1; tmp7++) {
switch (MMC_SWITCH_CAST(tmp7)) {
case 0: {
modelica_metatype tmpMeta9;
modelica_metatype tmpMeta10;
tmpMeta9 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp7_1), 3));
if (optionNone(tmpMeta9)) goto tmp6_end;
tmpMeta10 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta9), 1));
_p = tmpMeta10;
tmpMeta4 = _p;
goto tmp6_done;
}
}
goto tmp6_end;
tmp6_end: ;
}
goto goto_5;
goto_5:;
MMC_THROW_INTERNAL();
goto tmp6_done;
tmp6_done:;
}
}tmpMeta3 = mmc_mk_cons(tmpMeta4, _result);
_result = tmpMeta3;
}
}
_result = listReverseInPlace(_result);
_return: OMC_LABEL_UNUSED
return _result;
}
modelica_metatype boxptr_Parser_parallelParseFilesToProgramList(threadData_t *threadData, modelica_metatype _filenames, modelica_metatype _encoding, modelica_metatype _numThreads)
{
modelica_integer tmp1;
modelica_metatype _result = NULL;
modelica_metatype tmpMeta2;
tmp1 = mmc_unbox_integer(_numThreads);
_result = omc_Parser_parallelParseFilesToProgramList(threadData, _filenames, _encoding, tmp1);
return _result;
}
DLLExport
modelica_metatype omc_Parser_parallelParseFiles(threadData_t *threadData, modelica_metatype _filenames, modelica_string _encoding, modelica_integer _numThreads, modelica_string _libraryPath, modelica_metatype _lveInstance)
{
modelica_metatype _ht = NULL;
modelica_metatype _partialResults = NULL;
modelica_metatype tmpMeta1;
modelica_metatype tmpMeta2;
modelica_metatype tmpMeta10;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
_partialResults = omc_Parser_parallelParseFilesWork(threadData, _filenames, _encoding, _numThreads, _libraryPath, _lveInstance);
_ht = omc_HashTableStringToProgram_emptyHashTableSized(threadData, omc_Util_nextPrime(threadData, listLength(_partialResults)));
{
modelica_metatype _res;
for (tmpMeta1 = _partialResults; !listEmpty(tmpMeta1); tmpMeta1=MMC_CDR(tmpMeta1))
{
_res = MMC_CAR(tmpMeta1);
{
modelica_metatype tmp5_1;
tmp5_1 = _res;
{
modelica_metatype _p = NULL;
volatile mmc_switch_type tmp5;
int tmp6;
tmp5 = 0;
for (; tmp5 < 1; tmp5++) {
switch (MMC_SWITCH_CAST(tmp5)) {
case 0: {
modelica_metatype tmpMeta7;
modelica_metatype tmpMeta8;
modelica_metatype tmpMeta9;
tmpMeta7 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp5_1), 3));
if (optionNone(tmpMeta7)) goto tmp4_end;
tmpMeta8 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta7), 1));
_p = tmpMeta8;
tmpMeta9 = mmc_mk_box2(0, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_res), 2))), _p);
tmpMeta2 = omc_BaseHashTable_add(threadData, tmpMeta9, _ht);
goto tmp4_done;
}
}
goto tmp4_end;
tmp4_end: ;
}
goto goto_3;
goto_3:;
MMC_THROW_INTERNAL();
goto tmp4_done;
tmp4_done:;
}
}
_ht = tmpMeta2;
}
}
_return: OMC_LABEL_UNUSED
return _ht;
}
modelica_metatype boxptr_Parser_parallelParseFiles(threadData_t *threadData, modelica_metatype _filenames, modelica_metatype _encoding, modelica_metatype _numThreads, modelica_metatype _libraryPath, modelica_metatype _lveInstance)
{
modelica_integer tmp1;
modelica_metatype _ht = NULL;
tmp1 = mmc_unbox_integer(_numThreads);
_ht = omc_Parser_parallelParseFiles(threadData, _filenames, _encoding, tmp1, _libraryPath, _lveInstance);
return _ht;
}
DLLExport
modelica_metatype omc_Parser_stringMod(threadData_t *threadData, modelica_string _str, modelica_string _filename)
{
modelica_metatype _mod = NULL;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
_mod = omc_ParserExt_stringMod(threadData, _str, _filename, omc_Config_acceptedGrammar(threadData), omc_Flags_getConfigEnum(threadData, _OMC_LIT56), omc_Testsuite_isRunning(threadData));
_return: OMC_LABEL_UNUSED
return _mod;
}
DLLExport
modelica_metatype omc_Parser_stringCref(threadData_t *threadData, modelica_string _str)
{
modelica_metatype _cref = NULL;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
_cref = omc_ParserExt_stringCref(threadData, _str, _OMC_LIT9, omc_Config_acceptedGrammar(threadData), omc_Flags_getConfigEnum(threadData, _OMC_LIT56), omc_Testsuite_isRunning(threadData));
_return: OMC_LABEL_UNUSED
return _cref;
}
DLLExport
modelica_metatype omc_Parser_stringPath(threadData_t *threadData, modelica_string _str)
{
modelica_metatype _path = NULL;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
_path = omc_ParserExt_stringPath(threadData, _str, _OMC_LIT9, omc_Config_acceptedGrammar(threadData), omc_Flags_getConfigEnum(threadData, _OMC_LIT56), omc_Testsuite_isRunning(threadData));
_return: OMC_LABEL_UNUSED
return _path;
}
DLLExport
modelica_metatype omc_Parser_parsestringexp(threadData_t *threadData, modelica_string _str, modelica_string _infoFilename)
{
modelica_metatype _outStatements = NULL;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
_outStatements = omc_ParserExt_parsestringexp(threadData, _str, _infoFilename, omc_Config_acceptedGrammar(threadData), omc_Flags_getConfigEnum(threadData, _OMC_LIT56), omc_Testsuite_isRunning(threadData));
_return: OMC_LABEL_UNUSED
return _outStatements;
}
DLLExport
modelica_metatype omc_Parser_parsebuiltin(threadData_t *threadData, modelica_string _filename, modelica_string _encoding, modelica_string _libraryPath, modelica_metatype _lveInstance, modelica_integer _acceptedGram, modelica_integer _languageStandardInt)
{
modelica_metatype _outProgram = NULL;
modelica_string _realpath = NULL;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
_realpath = omc_Util_replaceWindowsBackSlashWithPathDelimiter(threadData, omc_System_realpath(threadData, _filename));
_outProgram = omc_ParserExt_parse(threadData, _realpath, omc_Testsuite_friendly(threadData, _realpath), _acceptedGram, _encoding, _languageStandardInt, omc_Testsuite_isRunning(threadData), _libraryPath, _lveInstance);
_return: OMC_LABEL_UNUSED
return _outProgram;
}
modelica_metatype boxptr_Parser_parsebuiltin(threadData_t *threadData, modelica_metatype _filename, modelica_metatype _encoding, modelica_metatype _libraryPath, modelica_metatype _lveInstance, modelica_metatype _acceptedGram, modelica_metatype _languageStandardInt)
{
modelica_integer tmp1;
modelica_integer tmp2;
modelica_metatype _outProgram = NULL;
tmp1 = mmc_unbox_integer(_acceptedGram);
tmp2 = mmc_unbox_integer(_languageStandardInt);
_outProgram = omc_Parser_parsebuiltin(threadData, _filename, _encoding, _libraryPath, _lveInstance, tmp1, tmp2);
return _outProgram;
}
DLLExport
modelica_metatype omc_Parser_parsestring(threadData_t *threadData, modelica_string _str, modelica_string _infoFilename, modelica_integer _grammar, modelica_integer _languageStd)
{
modelica_metatype _outProgram = NULL;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
_outProgram = omc_ParserExt_parsestring(threadData, _str, _infoFilename, _grammar, _languageStd, omc_Testsuite_isRunning(threadData));
omc_AbsynToSCode_translateAbsyn2SCode(threadData, _outProgram);
_return: OMC_LABEL_UNUSED
return _outProgram;
}
modelica_metatype boxptr_Parser_parsestring(threadData_t *threadData, modelica_metatype _str, modelica_metatype _infoFilename, modelica_metatype _grammar, modelica_metatype _languageStd)
{
modelica_integer tmp1;
modelica_integer tmp2;
modelica_metatype _outProgram = NULL;
tmp1 = mmc_unbox_integer(_grammar);
tmp2 = mmc_unbox_integer(_languageStd);
_outProgram = omc_Parser_parsestring(threadData, _str, _infoFilename, tmp1, tmp2);
return _outProgram;
}
DLLExport
modelica_metatype omc_Parser_parseexp(threadData_t *threadData, modelica_string _filename)
{
modelica_metatype _outStatements = NULL;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
_outStatements = omc_ParserExt_parseexp(threadData, omc_System_realpath(threadData, _filename), omc_Testsuite_friendly(threadData, omc_System_realpath(threadData, _filename)), omc_Config_acceptedGrammar(threadData), omc_Flags_getConfigEnum(threadData, _OMC_LIT56), omc_Testsuite_isRunning(threadData));
_return: OMC_LABEL_UNUSED
return _outStatements;
}
DLLExport
modelica_metatype omc_Parser_parse(threadData_t *threadData, modelica_string _filename, modelica_string _encoding, modelica_string _libraryPath, modelica_metatype _lveInstance)
{
modelica_metatype _outProgram = NULL;
modelica_metatype _classes = NULL;
modelica_metatype _classes1 = NULL;
modelica_metatype _w = NULL;
modelica_metatype _cs = NULL;
modelica_metatype tmpMeta1;
modelica_metatype tmpMeta2;
modelica_metatype tmpMeta3;
modelica_metatype tmpMeta4;
modelica_metatype tmpMeta5;
modelica_metatype tmpMeta6;
modelica_metatype tmpMeta7;
modelica_metatype tmpMeta8;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
_outProgram = omc_Parser_parsebuiltin(threadData, _filename, _encoding, _libraryPath, _lveInstance, omc_Config_acceptedGrammar(threadData), omc_Flags_getConfigEnum(threadData, _OMC_LIT56));
omc_AbsynToSCode_translateAbsyn2SCode(threadData, _outProgram);
if(isSome(_lveInstance))
{
tmpMeta1 = _outProgram;
tmpMeta2 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta1), 2));
tmpMeta3 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta1), 3));
_classes = tmpMeta2;
_w = tmpMeta3;
tmpMeta4 = MMC_REFSTRUCTLIT(mmc_nil);
_classes1 = tmpMeta4;
{
modelica_metatype _cs;
for (tmpMeta5 = _classes; !listEmpty(tmpMeta5); tmpMeta5=MMC_CDR(tmpMeta5))
{
_cs = MMC_CAR(tmpMeta5);
if(omc_Parser_checkLicenseAndFeatures(threadData, _cs, _lveInstance))
{
tmpMeta6 = mmc_mk_cons(_cs, _classes1);
_classes1 = tmpMeta6;
}
}
}
tmpMeta8 = mmc_mk_box3(3, &Absyn_Program_PROGRAM__desc, _classes1, _w);
_outProgram = tmpMeta8;
}
_return: OMC_LABEL_UNUSED
return _outProgram;
}
