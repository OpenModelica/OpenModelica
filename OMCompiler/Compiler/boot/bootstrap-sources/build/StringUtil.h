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
DLLDirection
modelica_string omc_StringUtil_rest(threadData_t *threadData, modelica_string _str);
#define boxptr_StringUtil_rest omc_StringUtil_rest
static const MMC_DEFSTRUCTLIT(boxvar_lit_StringUtil_rest,2,0) {(void*) boxptr_StringUtil_rest,0}};
#define boxvar_StringUtil_rest MMC_REFSTRUCTLIT(boxvar_lit_StringUtil_rest)
DLLDirection
modelica_string omc_StringUtil_stripFileExtension(threadData_t *threadData, modelica_string __omcQ_24in_5Ffilename);
#define boxptr_StringUtil_stripFileExtension omc_StringUtil_stripFileExtension
static const MMC_DEFSTRUCTLIT(boxvar_lit_StringUtil_stripFileExtension,2,0) {(void*) boxptr_StringUtil_stripFileExtension,0}};
#define boxvar_StringUtil_stripFileExtension MMC_REFSTRUCTLIT(boxvar_lit_StringUtil_stripFileExtension)
DLLDirection
modelica_string omc_StringUtil_stripBOM(threadData_t *threadData, modelica_string __omcQ_24in_5Fs, modelica_string *out_bom);
#define boxptr_StringUtil_stripBOM omc_StringUtil_stripBOM
static const MMC_DEFSTRUCTLIT(boxvar_lit_StringUtil_stripBOM,2,0) {(void*) boxptr_StringUtil_stripBOM,0}};
#define boxvar_StringUtil_stripBOM MMC_REFSTRUCTLIT(boxvar_lit_StringUtil_stripBOM)
DLLDirection
modelica_string omc_StringUtil_convertCharNonAsciiToHex(threadData_t *threadData, modelica_string __omcQ_24in_5Fs);
#define boxptr_StringUtil_convertCharNonAsciiToHex omc_StringUtil_convertCharNonAsciiToHex
static const MMC_DEFSTRUCTLIT(boxvar_lit_StringUtil_convertCharNonAsciiToHex,2,0) {(void*) boxptr_StringUtil_convertCharNonAsciiToHex,0}};
#define boxvar_StringUtil_convertCharNonAsciiToHex MMC_REFSTRUCTLIT(boxvar_lit_StringUtil_convertCharNonAsciiToHex)
DLLDirection
modelica_boolean omc_StringUtil_endsWithNewline(threadData_t *threadData, modelica_string _str);
DLLDirection
modelica_metatype boxptr_StringUtil_endsWithNewline(threadData_t *threadData, modelica_metatype _str);
static const MMC_DEFSTRUCTLIT(boxvar_lit_StringUtil_endsWithNewline,2,0) {(void*) boxptr_StringUtil_endsWithNewline,0}};
#define boxvar_StringUtil_endsWithNewline MMC_REFSTRUCTLIT(boxvar_lit_StringUtil_endsWithNewline)
DLLDirection
modelica_boolean omc_StringUtil_endsWith(threadData_t *threadData, modelica_string _str, modelica_string _suffix);
DLLDirection
modelica_metatype boxptr_StringUtil_endsWith(threadData_t *threadData, modelica_metatype _str, modelica_metatype _suffix);
static const MMC_DEFSTRUCTLIT(boxvar_lit_StringUtil_endsWith,2,0) {(void*) boxptr_StringUtil_endsWith,0}};
#define boxvar_StringUtil_endsWith MMC_REFSTRUCTLIT(boxvar_lit_StringUtil_endsWith)
DLLDirection
modelica_boolean omc_StringUtil_startsWith(threadData_t *threadData, modelica_string _str, modelica_string _prefix);
DLLDirection
modelica_metatype boxptr_StringUtil_startsWith(threadData_t *threadData, modelica_metatype _str, modelica_metatype _prefix);
static const MMC_DEFSTRUCTLIT(boxvar_lit_StringUtil_startsWith,2,0) {(void*) boxptr_StringUtil_startsWith,0}};
#define boxvar_StringUtil_startsWith MMC_REFSTRUCTLIT(boxvar_lit_StringUtil_startsWith)
DLLDirection
modelica_string omc_StringUtil_bytesToReadableUnit(threadData_t *threadData, modelica_real _bytes, modelica_integer _significantDigits, modelica_real _maxSizeInUnit);
DLLDirection
modelica_metatype boxptr_StringUtil_bytesToReadableUnit(threadData_t *threadData, modelica_metatype _bytes, modelica_metatype _significantDigits, modelica_metatype _maxSizeInUnit);
static const MMC_DEFSTRUCTLIT(boxvar_lit_StringUtil_bytesToReadableUnit,2,0) {(void*) boxptr_StringUtil_bytesToReadableUnit,0}};
#define boxvar_StringUtil_bytesToReadableUnit MMC_REFSTRUCTLIT(boxvar_lit_StringUtil_bytesToReadableUnit)
DLLDirection
modelica_boolean omc_StringUtil_equalIgnoreSpace(threadData_t *threadData, modelica_string _s1, modelica_string _s2);
DLLDirection
modelica_metatype boxptr_StringUtil_equalIgnoreSpace(threadData_t *threadData, modelica_metatype _s1, modelica_metatype _s2);
static const MMC_DEFSTRUCTLIT(boxvar_lit_StringUtil_equalIgnoreSpace,2,0) {(void*) boxptr_StringUtil_equalIgnoreSpace,0}};
#define boxvar_StringUtil_equalIgnoreSpace MMC_REFSTRUCTLIT(boxvar_lit_StringUtil_equalIgnoreSpace)
DLLDirection
modelica_string omc_StringUtil_quote(threadData_t *threadData, modelica_string _inString);
#define boxptr_StringUtil_quote omc_StringUtil_quote
static const MMC_DEFSTRUCTLIT(boxvar_lit_StringUtil_quote,2,0) {(void*) boxptr_StringUtil_quote,0}};
#define boxvar_StringUtil_quote MMC_REFSTRUCTLIT(boxvar_lit_StringUtil_quote)
DLLDirection
modelica_string omc_StringUtil_repeat(threadData_t *threadData, modelica_string _str, modelica_integer _n);
DLLDirection
modelica_metatype boxptr_StringUtil_repeat(threadData_t *threadData, modelica_metatype _str, modelica_metatype _n);
static const MMC_DEFSTRUCTLIT(boxvar_lit_StringUtil_repeat,2,0) {(void*) boxptr_StringUtil_repeat,0}};
#define boxvar_StringUtil_repeat MMC_REFSTRUCTLIT(boxvar_lit_StringUtil_repeat)
DLLDirection
modelica_metatype omc_StringUtil_wordWrap(threadData_t *threadData, modelica_string _inString, modelica_integer _inWrapLength, modelica_string _inDelimiter, modelica_real _inRaggedness);
DLLDirection
modelica_metatype boxptr_StringUtil_wordWrap(threadData_t *threadData, modelica_metatype _inString, modelica_metatype _inWrapLength, modelica_metatype _inDelimiter, modelica_metatype _inRaggedness);
static const MMC_DEFSTRUCTLIT(boxvar_lit_StringUtil_wordWrap,2,0) {(void*) boxptr_StringUtil_wordWrap,0}};
#define boxvar_StringUtil_wordWrap MMC_REFSTRUCTLIT(boxvar_lit_StringUtil_wordWrap)
DLLDirection
modelica_boolean omc_StringUtil_isAlpha(threadData_t *threadData, modelica_integer _inChar);
DLLDirection
modelica_metatype boxptr_StringUtil_isAlpha(threadData_t *threadData, modelica_metatype _inChar);
static const MMC_DEFSTRUCTLIT(boxvar_lit_StringUtil_isAlpha,2,0) {(void*) boxptr_StringUtil_isAlpha,0}};
#define boxvar_StringUtil_isAlpha MMC_REFSTRUCTLIT(boxvar_lit_StringUtil_isAlpha)
DLLDirection
modelica_integer omc_StringUtil_rfindCharNot(threadData_t *threadData, modelica_string _inString, modelica_integer _inChar, modelica_integer _inStartPos, modelica_integer _inEndPos);
DLLDirection
modelica_metatype boxptr_StringUtil_rfindCharNot(threadData_t *threadData, modelica_metatype _inString, modelica_metatype _inChar, modelica_metatype _inStartPos, modelica_metatype _inEndPos);
static const MMC_DEFSTRUCTLIT(boxvar_lit_StringUtil_rfindCharNot,2,0) {(void*) boxptr_StringUtil_rfindCharNot,0}};
#define boxvar_StringUtil_rfindCharNot MMC_REFSTRUCTLIT(boxvar_lit_StringUtil_rfindCharNot)
DLLDirection
modelica_integer omc_StringUtil_findCharNot(threadData_t *threadData, modelica_string _inString, modelica_integer _inChar, modelica_integer _inStartPos, modelica_integer _inEndPos);
DLLDirection
modelica_metatype boxptr_StringUtil_findCharNot(threadData_t *threadData, modelica_metatype _inString, modelica_metatype _inChar, modelica_metatype _inStartPos, modelica_metatype _inEndPos);
static const MMC_DEFSTRUCTLIT(boxvar_lit_StringUtil_findCharNot,2,0) {(void*) boxptr_StringUtil_findCharNot,0}};
#define boxvar_StringUtil_findCharNot MMC_REFSTRUCTLIT(boxvar_lit_StringUtil_findCharNot)
DLLDirection
modelica_integer omc_StringUtil_rfindChar(threadData_t *threadData, modelica_string _inString, modelica_integer _inChar, modelica_integer _inStartPos, modelica_integer _inEndPos);
DLLDirection
modelica_metatype boxptr_StringUtil_rfindChar(threadData_t *threadData, modelica_metatype _inString, modelica_metatype _inChar, modelica_metatype _inStartPos, modelica_metatype _inEndPos);
static const MMC_DEFSTRUCTLIT(boxvar_lit_StringUtil_rfindChar,2,0) {(void*) boxptr_StringUtil_rfindChar,0}};
#define boxvar_StringUtil_rfindChar MMC_REFSTRUCTLIT(boxvar_lit_StringUtil_rfindChar)
DLLDirection
modelica_integer omc_StringUtil_findChar(threadData_t *threadData, modelica_string _inString, modelica_integer _inChar, modelica_integer _inStartPos, modelica_integer _inEndPos);
DLLDirection
modelica_metatype boxptr_StringUtil_findChar(threadData_t *threadData, modelica_metatype _inString, modelica_metatype _inChar, modelica_metatype _inStartPos, modelica_metatype _inEndPos);
static const MMC_DEFSTRUCTLIT(boxvar_lit_StringUtil_findChar,2,0) {(void*) boxptr_StringUtil_findChar,0}};
#define boxvar_StringUtil_findChar MMC_REFSTRUCTLIT(boxvar_lit_StringUtil_findChar)
DLLDirection
modelica_string omc_StringUtil_headline__4(threadData_t *threadData, modelica_string _title);
#define boxptr_StringUtil_headline__4 omc_StringUtil_headline__4
static const MMC_DEFSTRUCTLIT(boxvar_lit_StringUtil_headline__4,2,0) {(void*) boxptr_StringUtil_headline__4,0}};
#define boxvar_StringUtil_headline__4 MMC_REFSTRUCTLIT(boxvar_lit_StringUtil_headline__4)
DLLDirection
modelica_string omc_StringUtil_headline__3(threadData_t *threadData, modelica_string _title);
#define boxptr_StringUtil_headline__3 omc_StringUtil_headline__3
static const MMC_DEFSTRUCTLIT(boxvar_lit_StringUtil_headline__3,2,0) {(void*) boxptr_StringUtil_headline__3,0}};
#define boxvar_StringUtil_headline__3 MMC_REFSTRUCTLIT(boxvar_lit_StringUtil_headline__3)
DLLDirection
modelica_string omc_StringUtil_headline__2(threadData_t *threadData, modelica_string _title);
#define boxptr_StringUtil_headline__2 omc_StringUtil_headline__2
static const MMC_DEFSTRUCTLIT(boxvar_lit_StringUtil_headline__2,2,0) {(void*) boxptr_StringUtil_headline__2,0}};
#define boxvar_StringUtil_headline__2 MMC_REFSTRUCTLIT(boxvar_lit_StringUtil_headline__2)
DLLDirection
modelica_string omc_StringUtil_headline__1(threadData_t *threadData, modelica_string _title);
#define boxptr_StringUtil_headline__1 omc_StringUtil_headline__1
static const MMC_DEFSTRUCTLIT(boxvar_lit_StringUtil_headline__1,2,0) {(void*) boxptr_StringUtil_headline__1,0}};
#define boxvar_StringUtil_headline__1 MMC_REFSTRUCTLIT(boxvar_lit_StringUtil_headline__1)
#ifdef __cplusplus
}
#endif
#endif
