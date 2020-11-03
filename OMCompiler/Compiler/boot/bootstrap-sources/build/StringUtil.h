#ifndef StringUtil__H
#define StringUtil__H
#include "meta/meta_modelica.h"
#include "util/modelica.h"
#include <stdio.h>
#include <stdlib.h>
#include <errno.h>
#ifdef __cplusplus
extern "C" {
#endif
DLLExport
modelica_boolean omc_StringUtil_endsWithNewline(threadData_t *threadData, modelica_string _str);
DLLExport
modelica_metatype boxptr_StringUtil_endsWithNewline(threadData_t *threadData, modelica_metatype _str);
static const MMC_DEFSTRUCTLIT(boxvar_lit_StringUtil_endsWithNewline,2,0) {(void*) boxptr_StringUtil_endsWithNewline,0}};
#define boxvar_StringUtil_endsWithNewline MMC_REFSTRUCTLIT(boxvar_lit_StringUtil_endsWithNewline)
DLLExport
modelica_string omc_StringUtil_stringAppend9(threadData_t *threadData, modelica_string _str1, modelica_string _str2, modelica_string _str3, modelica_string _str4, modelica_string _str5, modelica_string _str6, modelica_string _str7, modelica_string _str8, modelica_string _str9);
#define boxptr_StringUtil_stringAppend9 omc_StringUtil_stringAppend9
static const MMC_DEFSTRUCTLIT(boxvar_lit_StringUtil_stringAppend9,2,0) {(void*) boxptr_StringUtil_stringAppend9,0}};
#define boxvar_StringUtil_stringAppend9 MMC_REFSTRUCTLIT(boxvar_lit_StringUtil_stringAppend9)
DLLExport
modelica_integer omc_StringUtil_stringHashDjb2Work(threadData_t *threadData, modelica_string _str, modelica_integer _hash);
DLLExport
modelica_metatype boxptr_StringUtil_stringHashDjb2Work(threadData_t *threadData, modelica_metatype _str, modelica_metatype _hash);
static const MMC_DEFSTRUCTLIT(boxvar_lit_StringUtil_stringHashDjb2Work,2,0) {(void*) boxptr_StringUtil_stringHashDjb2Work,0}};
#define boxvar_StringUtil_stringHashDjb2Work MMC_REFSTRUCTLIT(boxvar_lit_StringUtil_stringHashDjb2Work)
DLLExport
modelica_string omc_StringUtil_bytesToReadableUnit(threadData_t *threadData, modelica_real _bytes, modelica_integer _significantDigits, modelica_real _maxSizeInUnit);
DLLExport
modelica_metatype boxptr_StringUtil_bytesToReadableUnit(threadData_t *threadData, modelica_metatype _bytes, modelica_metatype _significantDigits, modelica_metatype _maxSizeInUnit);
static const MMC_DEFSTRUCTLIT(boxvar_lit_StringUtil_bytesToReadableUnit,2,0) {(void*) boxptr_StringUtil_bytesToReadableUnit,0}};
#define boxvar_StringUtil_bytesToReadableUnit MMC_REFSTRUCTLIT(boxvar_lit_StringUtil_bytesToReadableUnit)
DLLExport
modelica_boolean omc_StringUtil_equalIgnoreSpace(threadData_t *threadData, modelica_string _s1, modelica_string _s2);
DLLExport
modelica_metatype boxptr_StringUtil_equalIgnoreSpace(threadData_t *threadData, modelica_metatype _s1, modelica_metatype _s2);
static const MMC_DEFSTRUCTLIT(boxvar_lit_StringUtil_equalIgnoreSpace,2,0) {(void*) boxptr_StringUtil_equalIgnoreSpace,0}};
#define boxvar_StringUtil_equalIgnoreSpace MMC_REFSTRUCTLIT(boxvar_lit_StringUtil_equalIgnoreSpace)
DLLExport
modelica_string omc_StringUtil_quote(threadData_t *threadData, modelica_string _inString);
#define boxptr_StringUtil_quote omc_StringUtil_quote
static const MMC_DEFSTRUCTLIT(boxvar_lit_StringUtil_quote,2,0) {(void*) boxptr_StringUtil_quote,0}};
#define boxvar_StringUtil_quote MMC_REFSTRUCTLIT(boxvar_lit_StringUtil_quote)
DLLExport
modelica_string omc_StringUtil_repeat(threadData_t *threadData, modelica_string _str, modelica_integer _n);
DLLExport
modelica_metatype boxptr_StringUtil_repeat(threadData_t *threadData, modelica_metatype _str, modelica_metatype _n);
static const MMC_DEFSTRUCTLIT(boxvar_lit_StringUtil_repeat,2,0) {(void*) boxptr_StringUtil_repeat,0}};
#define boxvar_StringUtil_repeat MMC_REFSTRUCTLIT(boxvar_lit_StringUtil_repeat)
DLLExport
modelica_metatype omc_StringUtil_wordWrap(threadData_t *threadData, modelica_string _inString, modelica_integer _inWrapLength, modelica_string _inDelimiter, modelica_real _inRaggedness);
DLLExport
modelica_metatype boxptr_StringUtil_wordWrap(threadData_t *threadData, modelica_metatype _inString, modelica_metatype _inWrapLength, modelica_metatype _inDelimiter, modelica_metatype _inRaggedness);
static const MMC_DEFSTRUCTLIT(boxvar_lit_StringUtil_wordWrap,2,0) {(void*) boxptr_StringUtil_wordWrap,0}};
#define boxvar_StringUtil_wordWrap MMC_REFSTRUCTLIT(boxvar_lit_StringUtil_wordWrap)
DLLExport
modelica_boolean omc_StringUtil_isAlpha(threadData_t *threadData, modelica_integer _inChar);
DLLExport
modelica_metatype boxptr_StringUtil_isAlpha(threadData_t *threadData, modelica_metatype _inChar);
static const MMC_DEFSTRUCTLIT(boxvar_lit_StringUtil_isAlpha,2,0) {(void*) boxptr_StringUtil_isAlpha,0}};
#define boxvar_StringUtil_isAlpha MMC_REFSTRUCTLIT(boxvar_lit_StringUtil_isAlpha)
DLLExport
modelica_integer omc_StringUtil_rfindCharNot(threadData_t *threadData, modelica_string _inString, modelica_integer _inChar, modelica_integer _inStartPos, modelica_integer _inEndPos);
DLLExport
modelica_metatype boxptr_StringUtil_rfindCharNot(threadData_t *threadData, modelica_metatype _inString, modelica_metatype _inChar, modelica_metatype _inStartPos, modelica_metatype _inEndPos);
static const MMC_DEFSTRUCTLIT(boxvar_lit_StringUtil_rfindCharNot,2,0) {(void*) boxptr_StringUtil_rfindCharNot,0}};
#define boxvar_StringUtil_rfindCharNot MMC_REFSTRUCTLIT(boxvar_lit_StringUtil_rfindCharNot)
DLLExport
modelica_integer omc_StringUtil_findCharNot(threadData_t *threadData, modelica_string _inString, modelica_integer _inChar, modelica_integer _inStartPos, modelica_integer _inEndPos);
DLLExport
modelica_metatype boxptr_StringUtil_findCharNot(threadData_t *threadData, modelica_metatype _inString, modelica_metatype _inChar, modelica_metatype _inStartPos, modelica_metatype _inEndPos);
static const MMC_DEFSTRUCTLIT(boxvar_lit_StringUtil_findCharNot,2,0) {(void*) boxptr_StringUtil_findCharNot,0}};
#define boxvar_StringUtil_findCharNot MMC_REFSTRUCTLIT(boxvar_lit_StringUtil_findCharNot)
DLLExport
modelica_integer omc_StringUtil_rfindChar(threadData_t *threadData, modelica_string _inString, modelica_integer _inChar, modelica_integer _inStartPos, modelica_integer _inEndPos);
DLLExport
modelica_metatype boxptr_StringUtil_rfindChar(threadData_t *threadData, modelica_metatype _inString, modelica_metatype _inChar, modelica_metatype _inStartPos, modelica_metatype _inEndPos);
static const MMC_DEFSTRUCTLIT(boxvar_lit_StringUtil_rfindChar,2,0) {(void*) boxptr_StringUtil_rfindChar,0}};
#define boxvar_StringUtil_rfindChar MMC_REFSTRUCTLIT(boxvar_lit_StringUtil_rfindChar)
DLLExport
modelica_integer omc_StringUtil_findChar(threadData_t *threadData, modelica_string _inString, modelica_integer _inChar, modelica_integer _inStartPos, modelica_integer _inEndPos);
DLLExport
modelica_metatype boxptr_StringUtil_findChar(threadData_t *threadData, modelica_metatype _inString, modelica_metatype _inChar, modelica_metatype _inStartPos, modelica_metatype _inEndPos);
static const MMC_DEFSTRUCTLIT(boxvar_lit_StringUtil_findChar,2,0) {(void*) boxptr_StringUtil_findChar,0}};
#define boxvar_StringUtil_findChar MMC_REFSTRUCTLIT(boxvar_lit_StringUtil_findChar)
#ifdef __cplusplus
}
#endif
#endif
