#ifndef Util__H
#define Util__H
#include "meta/meta_modelica.h"
#include "util/modelica.h"
#include <stdio.h>
#include <stdlib.h>
#include <errno.h>
#ifdef __cplusplus
extern "C" {
#endif
extern struct record_description Util_DateTime_DATETIME__desc;
DLLExport
modelica_metatype omc_Util_foldcallN(threadData_t *threadData, modelica_integer _n, modelica_fnptr _inFoldFunc, modelica_metatype _inStartValue);
DLLExport
modelica_metatype boxptr_Util_foldcallN(threadData_t *threadData, modelica_metatype _n, modelica_fnptr _inFoldFunc, modelica_metatype _inStartValue);
static const MMC_DEFSTRUCTLIT(boxvar_lit_Util_foldcallN,2,0) {(void*) boxptr_Util_foldcallN,0}};
#define boxvar_Util_foldcallN MMC_REFSTRUCTLIT(boxvar_lit_Util_foldcallN)
DLLExport
modelica_integer omc_Util_msb(threadData_t *threadData, modelica_integer _n);
DLLExport
modelica_metatype boxptr_Util_msb(threadData_t *threadData, modelica_metatype _n);
static const MMC_DEFSTRUCTLIT(boxvar_lit_Util_msb,2,0) {(void*) boxptr_Util_msb,0}};
#define boxvar_Util_msb MMC_REFSTRUCTLIT(boxvar_lit_Util_msb)
DLLExport
modelica_integer omc_Util_lcm(threadData_t *threadData, modelica_integer _a, modelica_integer _b);
DLLExport
modelica_metatype boxptr_Util_lcm(threadData_t *threadData, modelica_metatype _a, modelica_metatype _b);
static const MMC_DEFSTRUCTLIT(boxvar_lit_Util_lcm,2,0) {(void*) boxptr_Util_lcm,0}};
#define boxvar_Util_lcm MMC_REFSTRUCTLIT(boxvar_lit_Util_lcm)
DLLExport
modelica_integer omc_Util_gcd(threadData_t *threadData, modelica_integer _a, modelica_integer _b);
DLLExport
modelica_metatype boxptr_Util_gcd(threadData_t *threadData, modelica_metatype _a, modelica_metatype _b);
static const MMC_DEFSTRUCTLIT(boxvar_lit_Util_gcd,2,0) {(void*) boxptr_Util_gcd,0}};
#define boxvar_Util_gcd MMC_REFSTRUCTLIT(boxvar_lit_Util_gcd)
DLLExport
modelica_integer omc_Util_referenceCompare(threadData_t *threadData, modelica_metatype _ref1, modelica_metatype _ref2);
DLLExport
modelica_metatype boxptr_Util_referenceCompare(threadData_t *threadData, modelica_metatype _ref1, modelica_metatype _ref2);
static const MMC_DEFSTRUCTLIT(boxvar_lit_Util_referenceCompare,2,0) {(void*) boxptr_Util_referenceCompare,0}};
#define boxvar_Util_referenceCompare MMC_REFSTRUCTLIT(boxvar_lit_Util_referenceCompare)
/*
* The function has annotation(Include=...>) or is builtin
* the external function definition should be present
* in one of these files and have this prototype:
* extern int referenceCompareExt(modelica_metatype (*_ref1*), modelica_metatype (*_ref2*));
*/
DLLExport
modelica_metatype omc_Util_applyTuple31(threadData_t *threadData, modelica_metatype _inTuple, modelica_fnptr _func);
#define boxptr_Util_applyTuple31 omc_Util_applyTuple31
static const MMC_DEFSTRUCTLIT(boxvar_lit_Util_applyTuple31,2,0) {(void*) boxptr_Util_applyTuple31,0}};
#define boxvar_Util_applyTuple31 MMC_REFSTRUCTLIT(boxvar_lit_Util_applyTuple31)
DLLExport
modelica_real omc_Util_profilertock2(threadData_t *threadData);
DLLExport
modelica_metatype boxptr_Util_profilertock2(threadData_t *threadData);
static const MMC_DEFSTRUCTLIT(boxvar_lit_Util_profilertock2,2,0) {(void*) boxptr_Util_profilertock2,0}};
#define boxvar_Util_profilertock2 MMC_REFSTRUCTLIT(boxvar_lit_Util_profilertock2)
DLLExport
modelica_real omc_Util_profilertock1(threadData_t *threadData);
DLLExport
modelica_metatype boxptr_Util_profilertock1(threadData_t *threadData);
static const MMC_DEFSTRUCTLIT(boxvar_lit_Util_profilertock1,2,0) {(void*) boxptr_Util_profilertock1,0}};
#define boxvar_Util_profilertock1 MMC_REFSTRUCTLIT(boxvar_lit_Util_profilertock1)
DLLExport
void omc_Util_profilerreset2(threadData_t *threadData);
#define boxptr_Util_profilerreset2 omc_Util_profilerreset2
static const MMC_DEFSTRUCTLIT(boxvar_lit_Util_profilerreset2,2,0) {(void*) boxptr_Util_profilerreset2,0}};
#define boxvar_Util_profilerreset2 MMC_REFSTRUCTLIT(boxvar_lit_Util_profilerreset2)
DLLExport
void omc_Util_profilerreset1(threadData_t *threadData);
#define boxptr_Util_profilerreset1 omc_Util_profilerreset1
static const MMC_DEFSTRUCTLIT(boxvar_lit_Util_profilerreset1,2,0) {(void*) boxptr_Util_profilerreset1,0}};
#define boxvar_Util_profilerreset1 MMC_REFSTRUCTLIT(boxvar_lit_Util_profilerreset1)
DLLExport
void omc_Util_profilerstop2(threadData_t *threadData);
#define boxptr_Util_profilerstop2 omc_Util_profilerstop2
static const MMC_DEFSTRUCTLIT(boxvar_lit_Util_profilerstop2,2,0) {(void*) boxptr_Util_profilerstop2,0}};
#define boxvar_Util_profilerstop2 MMC_REFSTRUCTLIT(boxvar_lit_Util_profilerstop2)
DLLExport
void omc_Util_profilerstop1(threadData_t *threadData);
#define boxptr_Util_profilerstop1 omc_Util_profilerstop1
static const MMC_DEFSTRUCTLIT(boxvar_lit_Util_profilerstop1,2,0) {(void*) boxptr_Util_profilerstop1,0}};
#define boxvar_Util_profilerstop1 MMC_REFSTRUCTLIT(boxvar_lit_Util_profilerstop1)
DLLExport
void omc_Util_profilerstart2(threadData_t *threadData);
#define boxptr_Util_profilerstart2 omc_Util_profilerstart2
static const MMC_DEFSTRUCTLIT(boxvar_lit_Util_profilerstart2,2,0) {(void*) boxptr_Util_profilerstart2,0}};
#define boxvar_Util_profilerstart2 MMC_REFSTRUCTLIT(boxvar_lit_Util_profilerstart2)
DLLExport
void omc_Util_profilerstart1(threadData_t *threadData);
#define boxptr_Util_profilerstart1 omc_Util_profilerstart1
static const MMC_DEFSTRUCTLIT(boxvar_lit_Util_profilerstart1,2,0) {(void*) boxptr_Util_profilerstart1,0}};
#define boxvar_Util_profilerstart1 MMC_REFSTRUCTLIT(boxvar_lit_Util_profilerstart1)
DLLExport
modelica_real omc_Util_profilertime2(threadData_t *threadData);
DLLExport
modelica_metatype boxptr_Util_profilertime2(threadData_t *threadData);
static const MMC_DEFSTRUCTLIT(boxvar_lit_Util_profilertime2,2,0) {(void*) boxptr_Util_profilertime2,0}};
#define boxvar_Util_profilertime2 MMC_REFSTRUCTLIT(boxvar_lit_Util_profilertime2)
DLLExport
modelica_real omc_Util_profilertime1(threadData_t *threadData);
DLLExport
modelica_metatype boxptr_Util_profilertime1(threadData_t *threadData);
static const MMC_DEFSTRUCTLIT(boxvar_lit_Util_profilertime1,2,0) {(void*) boxptr_Util_profilertime1,0}};
#define boxvar_Util_profilertime1 MMC_REFSTRUCTLIT(boxvar_lit_Util_profilertime1)
DLLExport
void omc_Util_profilerresults(threadData_t *threadData);
#define boxptr_Util_profilerresults omc_Util_profilerresults
static const MMC_DEFSTRUCTLIT(boxvar_lit_Util_profilerresults,2,0) {(void*) boxptr_Util_profilerresults,0}};
#define boxvar_Util_profilerresults MMC_REFSTRUCTLIT(boxvar_lit_Util_profilerresults)
DLLExport
void omc_Util_profilerinit(threadData_t *threadData);
#define boxptr_Util_profilerinit omc_Util_profilerinit
static const MMC_DEFSTRUCTLIT(boxvar_lit_Util_profilerinit,2,0) {(void*) boxptr_Util_profilerinit,0}};
#define boxvar_Util_profilerinit MMC_REFSTRUCTLIT(boxvar_lit_Util_profilerinit)
DLLExport
modelica_boolean omc_Util_sourceInfoIsEqual(threadData_t *threadData, modelica_metatype _inInfo1, modelica_metatype _inInfo2);
DLLExport
modelica_metatype boxptr_Util_sourceInfoIsEqual(threadData_t *threadData, modelica_metatype _inInfo1, modelica_metatype _inInfo2);
static const MMC_DEFSTRUCTLIT(boxvar_lit_Util_sourceInfoIsEqual,2,0) {(void*) boxptr_Util_sourceInfoIsEqual,0}};
#define boxvar_Util_sourceInfoIsEqual MMC_REFSTRUCTLIT(boxvar_lit_Util_sourceInfoIsEqual)
DLLExport
modelica_boolean omc_Util_sourceInfoIsEmpty(threadData_t *threadData, modelica_metatype _inInfo);
DLLExport
modelica_metatype boxptr_Util_sourceInfoIsEmpty(threadData_t *threadData, modelica_metatype _inInfo);
static const MMC_DEFSTRUCTLIT(boxvar_lit_Util_sourceInfoIsEmpty,2,0) {(void*) boxptr_Util_sourceInfoIsEmpty,0}};
#define boxvar_Util_sourceInfoIsEmpty MMC_REFSTRUCTLIT(boxvar_lit_Util_sourceInfoIsEmpty)
DLLExport
modelica_string omc_Util_intLstString(threadData_t *threadData, modelica_metatype _lst);
#define boxptr_Util_intLstString omc_Util_intLstString
static const MMC_DEFSTRUCTLIT(boxvar_lit_Util_intLstString,2,0) {(void*) boxptr_Util_intLstString,0}};
#define boxvar_Util_intLstString MMC_REFSTRUCTLIT(boxvar_lit_Util_intLstString)
DLLExport
modelica_string omc_Util_absoluteOrRelative(threadData_t *threadData, modelica_string _inFileName);
#define boxptr_Util_absoluteOrRelative omc_Util_absoluteOrRelative
static const MMC_DEFSTRUCTLIT(boxvar_lit_Util_absoluteOrRelative,2,0) {(void*) boxptr_Util_absoluteOrRelative,0}};
#define boxvar_Util_absoluteOrRelative MMC_REFSTRUCTLIT(boxvar_lit_Util_absoluteOrRelative)
DLLExport
modelica_boolean omc_Util_anyReturnTrue(threadData_t *threadData, modelica_metatype _a);
DLLExport
modelica_metatype boxptr_Util_anyReturnTrue(threadData_t *threadData, modelica_metatype _a);
static const MMC_DEFSTRUCTLIT(boxvar_lit_Util_anyReturnTrue,2,0) {(void*) boxptr_Util_anyReturnTrue,0}};
#define boxvar_Util_anyReturnTrue MMC_REFSTRUCTLIT(boxvar_lit_Util_anyReturnTrue)
DLLExport
modelica_string omc_Util_getTempVariableIndex(threadData_t *threadData);
#define boxptr_Util_getTempVariableIndex omc_Util_getTempVariableIndex
static const MMC_DEFSTRUCTLIT(boxvar_lit_Util_getTempVariableIndex,2,0) {(void*) boxptr_Util_getTempVariableIndex,0}};
#define boxvar_Util_getTempVariableIndex MMC_REFSTRUCTLIT(boxvar_lit_Util_getTempVariableIndex)
DLLExport
modelica_string omc_Util_stringTrunc(threadData_t *threadData, modelica_string _str, modelica_integer _len);
DLLExport
modelica_metatype boxptr_Util_stringTrunc(threadData_t *threadData, modelica_metatype _str, modelica_metatype _len);
static const MMC_DEFSTRUCTLIT(boxvar_lit_Util_stringTrunc,2,0) {(void*) boxptr_Util_stringTrunc,0}};
#define boxvar_Util_stringTrunc MMC_REFSTRUCTLIT(boxvar_lit_Util_stringTrunc)
DLLExport
modelica_boolean omc_Util_isIntegerString(threadData_t *threadData, modelica_string _str);
DLLExport
modelica_metatype boxptr_Util_isIntegerString(threadData_t *threadData, modelica_metatype _str);
static const MMC_DEFSTRUCTLIT(boxvar_lit_Util_isIntegerString,2,0) {(void*) boxptr_Util_isIntegerString,0}};
#define boxvar_Util_isIntegerString MMC_REFSTRUCTLIT(boxvar_lit_Util_isIntegerString)
DLLExport
modelica_boolean omc_Util_isCIdentifier(threadData_t *threadData, modelica_string _str);
DLLExport
modelica_metatype boxptr_Util_isCIdentifier(threadData_t *threadData, modelica_metatype _str);
static const MMC_DEFSTRUCTLIT(boxvar_lit_Util_isCIdentifier,2,0) {(void*) boxptr_Util_isCIdentifier,0}};
#define boxvar_Util_isCIdentifier MMC_REFSTRUCTLIT(boxvar_lit_Util_isCIdentifier)
DLLExport
modelica_boolean omc_Util_endsWith(threadData_t *threadData, modelica_string _inString, modelica_string _inSuffix);
DLLExport
modelica_metatype boxptr_Util_endsWith(threadData_t *threadData, modelica_metatype _inString, modelica_metatype _inSuffix);
static const MMC_DEFSTRUCTLIT(boxvar_lit_Util_endsWith,2,0) {(void*) boxptr_Util_endsWith,0}};
#define boxvar_Util_endsWith MMC_REFSTRUCTLIT(boxvar_lit_Util_endsWith)
DLLExport
modelica_integer omc_Util_nextPowerOf2(threadData_t *threadData, modelica_integer _i);
DLLExport
modelica_metatype boxptr_Util_nextPowerOf2(threadData_t *threadData, modelica_metatype _i);
static const MMC_DEFSTRUCTLIT(boxvar_lit_Util_nextPowerOf2,2,0) {(void*) boxptr_Util_nextPowerOf2,0}};
#define boxvar_Util_nextPowerOf2 MMC_REFSTRUCTLIT(boxvar_lit_Util_nextPowerOf2)
DLLExport
modelica_boolean omc_Util_createDirectoryTree(threadData_t *threadData, modelica_string _inString);
DLLExport
modelica_metatype boxptr_Util_createDirectoryTree(threadData_t *threadData, modelica_metatype _inString);
static const MMC_DEFSTRUCTLIT(boxvar_lit_Util_createDirectoryTree,2,0) {(void*) boxptr_Util_createDirectoryTree,0}};
#define boxvar_Util_createDirectoryTree MMC_REFSTRUCTLIT(boxvar_lit_Util_createDirectoryTree)
DLLExport
modelica_integer omc_Util_realRangeSize(threadData_t *threadData, modelica_real _inStart, modelica_real _inStep, modelica_real _inStop);
DLLExport
modelica_metatype boxptr_Util_realRangeSize(threadData_t *threadData, modelica_metatype _inStart, modelica_metatype _inStep, modelica_metatype _inStop);
static const MMC_DEFSTRUCTLIT(boxvar_lit_Util_realRangeSize,2,0) {(void*) boxptr_Util_realRangeSize,0}};
#define boxvar_Util_realRangeSize MMC_REFSTRUCTLIT(boxvar_lit_Util_realRangeSize)
DLLExport
modelica_metatype omc_Util_replace(threadData_t *threadData, modelica_metatype _replaced, modelica_metatype _arg);
#define boxptr_Util_replace omc_Util_replace
static const MMC_DEFSTRUCTLIT(boxvar_lit_Util_replace,2,0) {(void*) boxptr_Util_replace,0}};
#define boxvar_Util_replace MMC_REFSTRUCTLIT(boxvar_lit_Util_replace)
DLLExport
modelica_metatype omc_Util_swap(threadData_t *threadData, modelica_boolean _cond, modelica_metatype _in1, modelica_metatype _in2, modelica_metatype *out_out2);
DLLExport
modelica_metatype boxptr_Util_swap(threadData_t *threadData, modelica_metatype _cond, modelica_metatype _in1, modelica_metatype _in2, modelica_metatype *out_out2);
static const MMC_DEFSTRUCTLIT(boxvar_lit_Util_swap,2,0) {(void*) boxptr_Util_swap,0}};
#define boxvar_Util_swap MMC_REFSTRUCTLIT(boxvar_lit_Util_swap)
DLLExport
modelica_boolean omc_Util_stringNotEqual(threadData_t *threadData, modelica_string _str1, modelica_string _str2);
DLLExport
modelica_metatype boxptr_Util_stringNotEqual(threadData_t *threadData, modelica_metatype _str1, modelica_metatype _str2);
static const MMC_DEFSTRUCTLIT(boxvar_lit_Util_stringNotEqual,2,0) {(void*) boxptr_Util_stringNotEqual,0}};
#define boxvar_Util_stringNotEqual MMC_REFSTRUCTLIT(boxvar_lit_Util_stringNotEqual)
DLLExport
modelica_string omc_Util_removeLastNChar(threadData_t *threadData, modelica_string _str, modelica_integer _n);
DLLExport
modelica_metatype boxptr_Util_removeLastNChar(threadData_t *threadData, modelica_metatype _str, modelica_metatype _n);
static const MMC_DEFSTRUCTLIT(boxvar_lit_Util_removeLastNChar,2,0) {(void*) boxptr_Util_removeLastNChar,0}};
#define boxvar_Util_removeLastNChar MMC_REFSTRUCTLIT(boxvar_lit_Util_removeLastNChar)
DLLExport
modelica_string omc_Util_removeLast4Char(threadData_t *threadData, modelica_string _str);
#define boxptr_Util_removeLast4Char omc_Util_removeLast4Char
static const MMC_DEFSTRUCTLIT(boxvar_lit_Util_removeLast4Char,2,0) {(void*) boxptr_Util_removeLast4Char,0}};
#define boxvar_Util_removeLast4Char MMC_REFSTRUCTLIT(boxvar_lit_Util_removeLast4Char)
DLLExport
modelica_string omc_Util_removeLast3Char(threadData_t *threadData, modelica_string _str);
#define boxptr_Util_removeLast3Char omc_Util_removeLast3Char
static const MMC_DEFSTRUCTLIT(boxvar_lit_Util_removeLast3Char,2,0) {(void*) boxptr_Util_removeLast3Char,0}};
#define boxvar_Util_removeLast3Char MMC_REFSTRUCTLIT(boxvar_lit_Util_removeLast3Char)
DLLExport
modelica_string omc_Util_anyToEmptyString(threadData_t *threadData, modelica_metatype _a);
#define boxptr_Util_anyToEmptyString omc_Util_anyToEmptyString
static const MMC_DEFSTRUCTLIT(boxvar_lit_Util_anyToEmptyString,2,0) {(void*) boxptr_Util_anyToEmptyString,0}};
#define boxvar_Util_anyToEmptyString MMC_REFSTRUCTLIT(boxvar_lit_Util_anyToEmptyString)
DLLExport
modelica_integer omc_Util_nextPrime(threadData_t *threadData, modelica_integer _inN);
DLLExport
modelica_metatype boxptr_Util_nextPrime(threadData_t *threadData, modelica_metatype _inN);
static const MMC_DEFSTRUCTLIT(boxvar_lit_Util_nextPrime,2,0) {(void*) boxptr_Util_nextPrime,0}};
#define boxvar_Util_nextPrime MMC_REFSTRUCTLIT(boxvar_lit_Util_nextPrime)
DLLExport
modelica_integer omc_Util_intProduct(threadData_t *threadData, modelica_metatype _lst);
DLLExport
modelica_metatype boxptr_Util_intProduct(threadData_t *threadData, modelica_metatype _lst);
static const MMC_DEFSTRUCTLIT(boxvar_lit_Util_intProduct,2,0) {(void*) boxptr_Util_intProduct,0}};
#define boxvar_Util_intProduct MMC_REFSTRUCTLIT(boxvar_lit_Util_intProduct)
DLLExport
modelica_string omc_Util_stringRest(threadData_t *threadData, modelica_string _inString);
#define boxptr_Util_stringRest omc_Util_stringRest
static const MMC_DEFSTRUCTLIT(boxvar_lit_Util_stringRest,2,0) {(void*) boxptr_Util_stringRest,0}};
#define boxvar_Util_stringRest MMC_REFSTRUCTLIT(boxvar_lit_Util_stringRest)
DLLExport
modelica_string omc_Util_stringPadLeft(threadData_t *threadData, modelica_string _inString, modelica_integer _inPadWidth, modelica_string _inPadString);
DLLExport
modelica_metatype boxptr_Util_stringPadLeft(threadData_t *threadData, modelica_metatype _inString, modelica_metatype _inPadWidth, modelica_metatype _inPadString);
static const MMC_DEFSTRUCTLIT(boxvar_lit_Util_stringPadLeft,2,0) {(void*) boxptr_Util_stringPadLeft,0}};
#define boxvar_Util_stringPadLeft MMC_REFSTRUCTLIT(boxvar_lit_Util_stringPadLeft)
DLLExport
modelica_string omc_Util_stringPadRight(threadData_t *threadData, modelica_string _inString, modelica_integer _inPadWidth, modelica_string _inPadString);
DLLExport
modelica_metatype boxptr_Util_stringPadRight(threadData_t *threadData, modelica_metatype _inString, modelica_metatype _inPadWidth, modelica_metatype _inPadString);
static const MMC_DEFSTRUCTLIT(boxvar_lit_Util_stringPadRight,2,0) {(void*) boxptr_Util_stringPadRight,0}};
#define boxvar_Util_stringPadRight MMC_REFSTRUCTLIT(boxvar_lit_Util_stringPadRight)
DLLExport
modelica_metatype omc_Util_optionList(threadData_t *threadData, modelica_metatype _inOption);
#define boxptr_Util_optionList omc_Util_optionList
static const MMC_DEFSTRUCTLIT(boxvar_lit_Util_optionList,2,0) {(void*) boxptr_Util_optionList,0}};
#define boxvar_Util_optionList MMC_REFSTRUCTLIT(boxvar_lit_Util_optionList)
DLLExport
modelica_boolean omc_Util_stringEqCaseInsensitive(threadData_t *threadData, modelica_string _str1, modelica_string _str2);
DLLExport
modelica_metatype boxptr_Util_stringEqCaseInsensitive(threadData_t *threadData, modelica_metatype _str1, modelica_metatype _str2);
static const MMC_DEFSTRUCTLIT(boxvar_lit_Util_stringEqCaseInsensitive,2,0) {(void*) boxptr_Util_stringEqCaseInsensitive,0}};
#define boxvar_Util_stringEqCaseInsensitive MMC_REFSTRUCTLIT(boxvar_lit_Util_stringEqCaseInsensitive)
DLLExport
modelica_boolean omc_Util_stringBool(threadData_t *threadData, modelica_string _inString);
DLLExport
modelica_metatype boxptr_Util_stringBool(threadData_t *threadData, modelica_metatype _inString);
static const MMC_DEFSTRUCTLIT(boxvar_lit_Util_stringBool,2,0) {(void*) boxptr_Util_stringBool,0}};
#define boxvar_Util_stringBool MMC_REFSTRUCTLIT(boxvar_lit_Util_stringBool)
DLLExport
modelica_boolean omc_Util_intBool(threadData_t *threadData, modelica_integer _inInteger);
DLLExport
modelica_metatype boxptr_Util_intBool(threadData_t *threadData, modelica_metatype _inInteger);
static const MMC_DEFSTRUCTLIT(boxvar_lit_Util_intBool,2,0) {(void*) boxptr_Util_intBool,0}};
#define boxvar_Util_intBool MMC_REFSTRUCTLIT(boxvar_lit_Util_intBool)
DLLExport
modelica_integer omc_Util_boolInt(threadData_t *threadData, modelica_boolean _inBoolean);
DLLExport
modelica_metatype boxptr_Util_boolInt(threadData_t *threadData, modelica_metatype _inBoolean);
static const MMC_DEFSTRUCTLIT(boxvar_lit_Util_boolInt,2,0) {(void*) boxptr_Util_boolInt,0}};
#define boxvar_Util_boolInt MMC_REFSTRUCTLIT(boxvar_lit_Util_boolInt)
DLLExport
modelica_metatype omc_Util_assoc(threadData_t *threadData, modelica_metatype _inKey, modelica_metatype _inList);
#define boxptr_Util_assoc omc_Util_assoc
static const MMC_DEFSTRUCTLIT(boxvar_lit_Util_assoc,2,0) {(void*) boxptr_Util_assoc,0}};
#define boxvar_Util_assoc MMC_REFSTRUCTLIT(boxvar_lit_Util_assoc)
DLLExport
modelica_string omc_Util_buildMapStr(threadData_t *threadData, modelica_metatype _inLst1, modelica_metatype _inLst2, modelica_string _inMiddleDelimiter, modelica_string _inEndDelimiter);
#define boxptr_Util_buildMapStr omc_Util_buildMapStr
static const MMC_DEFSTRUCTLIT(boxvar_lit_Util_buildMapStr,2,0) {(void*) boxptr_Util_buildMapStr,0}};
#define boxvar_Util_buildMapStr MMC_REFSTRUCTLIT(boxvar_lit_Util_buildMapStr)
DLLExport
modelica_metatype omc_Util_id(threadData_t *threadData, modelica_metatype _inValue);
#define boxptr_Util_id omc_Util_id
static const MMC_DEFSTRUCTLIT(boxvar_lit_Util_id,2,0) {(void*) boxptr_Util_id,0}};
#define boxvar_Util_id MMC_REFSTRUCTLIT(boxvar_lit_Util_id)
DLLExport
modelica_boolean omc_Util_isSuccess(threadData_t *threadData, modelica_metatype _status);
DLLExport
modelica_metatype boxptr_Util_isSuccess(threadData_t *threadData, modelica_metatype _status);
static const MMC_DEFSTRUCTLIT(boxvar_lit_Util_isSuccess,2,0) {(void*) boxptr_Util_isSuccess,0}};
#define boxvar_Util_isSuccess MMC_REFSTRUCTLIT(boxvar_lit_Util_isSuccess)
DLLExport
modelica_metatype omc_Util_getCurrentDateTime(threadData_t *threadData);
#define boxptr_Util_getCurrentDateTime omc_Util_getCurrentDateTime
static const MMC_DEFSTRUCTLIT(boxvar_lit_Util_getCurrentDateTime,2,0) {(void*) boxptr_Util_getCurrentDateTime,0}};
#define boxvar_Util_getCurrentDateTime MMC_REFSTRUCTLIT(boxvar_lit_Util_getCurrentDateTime)
DLLExport
modelica_string omc_Util_stringAppendNonEmpty(threadData_t *threadData, modelica_string _inString1, modelica_string _inString2);
#define boxptr_Util_stringAppendNonEmpty omc_Util_stringAppendNonEmpty
static const MMC_DEFSTRUCTLIT(boxvar_lit_Util_stringAppendNonEmpty,2,0) {(void*) boxptr_Util_stringAppendNonEmpty,0}};
#define boxvar_Util_stringAppendNonEmpty MMC_REFSTRUCTLIT(boxvar_lit_Util_stringAppendNonEmpty)
DLLExport
modelica_string omc_Util_stringAppendReverse(threadData_t *threadData, modelica_string _str1, modelica_string _str2);
#define boxptr_Util_stringAppendReverse omc_Util_stringAppendReverse
static const MMC_DEFSTRUCTLIT(boxvar_lit_Util_stringAppendReverse,2,0) {(void*) boxptr_Util_stringAppendReverse,0}};
#define boxvar_Util_stringAppendReverse MMC_REFSTRUCTLIT(boxvar_lit_Util_stringAppendReverse)
DLLExport
modelica_boolean omc_Util_strcmpBool(threadData_t *threadData, modelica_string _s1, modelica_string _s2);
DLLExport
modelica_metatype boxptr_Util_strcmpBool(threadData_t *threadData, modelica_metatype _s1, modelica_metatype _s2);
static const MMC_DEFSTRUCTLIT(boxvar_lit_Util_strcmpBool,2,0) {(void*) boxptr_Util_strcmpBool,0}};
#define boxvar_Util_strcmpBool MMC_REFSTRUCTLIT(boxvar_lit_Util_strcmpBool)
DLLExport
modelica_string omc_Util_xmlEscape(threadData_t *threadData, modelica_string _s1);
#define boxptr_Util_xmlEscape omc_Util_xmlEscape
static const MMC_DEFSTRUCTLIT(boxvar_lit_Util_xmlEscape,2,0) {(void*) boxptr_Util_xmlEscape,0}};
#define boxvar_Util_xmlEscape MMC_REFSTRUCTLIT(boxvar_lit_Util_xmlEscape)
DLLExport
modelica_metatype omc_Util_makeValueOrDefault(threadData_t *threadData, modelica_fnptr _inFunc, modelica_metatype _inArg, modelica_metatype _inDefaultValue);
#define boxptr_Util_makeValueOrDefault omc_Util_makeValueOrDefault
static const MMC_DEFSTRUCTLIT(boxvar_lit_Util_makeValueOrDefault,2,0) {(void*) boxptr_Util_makeValueOrDefault,0}};
#define boxvar_Util_makeValueOrDefault MMC_REFSTRUCTLIT(boxvar_lit_Util_makeValueOrDefault)
DLLExport
modelica_boolean omc_Util_optionEqual(threadData_t *threadData, modelica_metatype _inOption1, modelica_metatype _inOption2, modelica_fnptr _inFunc);
DLLExport
modelica_metatype boxptr_Util_optionEqual(threadData_t *threadData, modelica_metatype _inOption1, modelica_metatype _inOption2, modelica_fnptr _inFunc);
static const MMC_DEFSTRUCTLIT(boxvar_lit_Util_optionEqual,2,0) {(void*) boxptr_Util_optionEqual,0}};
#define boxvar_Util_optionEqual MMC_REFSTRUCTLIT(boxvar_lit_Util_optionEqual)
DLLExport
void omc_Util_setStatefulBoolean(threadData_t *threadData, modelica_metatype _sb, modelica_boolean _b);
DLLExport
void boxptr_Util_setStatefulBoolean(threadData_t *threadData, modelica_metatype _sb, modelica_metatype _b);
static const MMC_DEFSTRUCTLIT(boxvar_lit_Util_setStatefulBoolean,2,0) {(void*) boxptr_Util_setStatefulBoolean,0}};
#define boxvar_Util_setStatefulBoolean MMC_REFSTRUCTLIT(boxvar_lit_Util_setStatefulBoolean)
DLLExport
modelica_boolean omc_Util_getStatefulBoolean(threadData_t *threadData, modelica_metatype _sb);
DLLExport
modelica_metatype boxptr_Util_getStatefulBoolean(threadData_t *threadData, modelica_metatype _sb);
static const MMC_DEFSTRUCTLIT(boxvar_lit_Util_getStatefulBoolean,2,0) {(void*) boxptr_Util_getStatefulBoolean,0}};
#define boxvar_Util_getStatefulBoolean MMC_REFSTRUCTLIT(boxvar_lit_Util_getStatefulBoolean)
DLLExport
modelica_metatype omc_Util_makeStatefulBoolean(threadData_t *threadData, modelica_boolean _b);
DLLExport
modelica_metatype boxptr_Util_makeStatefulBoolean(threadData_t *threadData, modelica_metatype _b);
static const MMC_DEFSTRUCTLIT(boxvar_lit_Util_makeStatefulBoolean,2,0) {(void*) boxptr_Util_makeStatefulBoolean,0}};
#define boxvar_Util_makeStatefulBoolean MMC_REFSTRUCTLIT(boxvar_lit_Util_makeStatefulBoolean)
DLLExport
modelica_integer omc_Util_mulListIntegerOpt(threadData_t *threadData, modelica_metatype _inList, modelica_integer _inAccum);
DLLExport
modelica_metatype boxptr_Util_mulListIntegerOpt(threadData_t *threadData, modelica_metatype _inList, modelica_metatype _inAccum);
static const MMC_DEFSTRUCTLIT(boxvar_lit_Util_mulListIntegerOpt,2,0) {(void*) boxptr_Util_mulListIntegerOpt,0}};
#define boxvar_Util_mulListIntegerOpt MMC_REFSTRUCTLIT(boxvar_lit_Util_mulListIntegerOpt)
DLLExport
modelica_metatype omc_Util_make3Tuple(threadData_t *threadData, modelica_metatype _inValue1, modelica_metatype _inValue2, modelica_metatype _inValue3);
#define boxptr_Util_make3Tuple omc_Util_make3Tuple
static const MMC_DEFSTRUCTLIT(boxvar_lit_Util_make3Tuple,2,0) {(void*) boxptr_Util_make3Tuple,0}};
#define boxvar_Util_make3Tuple MMC_REFSTRUCTLIT(boxvar_lit_Util_make3Tuple)
DLLExport
modelica_metatype omc_Util_makeTupleR(threadData_t *threadData, modelica_metatype _inValue1, modelica_metatype _inValue2);
#define boxptr_Util_makeTupleR omc_Util_makeTupleR
static const MMC_DEFSTRUCTLIT(boxvar_lit_Util_makeTupleR,2,0) {(void*) boxptr_Util_makeTupleR,0}};
#define boxvar_Util_makeTupleR MMC_REFSTRUCTLIT(boxvar_lit_Util_makeTupleR)
DLLExport
modelica_metatype omc_Util_makeTuple(threadData_t *threadData, modelica_metatype _inValue1, modelica_metatype _inValue2);
#define boxptr_Util_makeTuple omc_Util_makeTuple
static const MMC_DEFSTRUCTLIT(boxvar_lit_Util_makeTuple,2,0) {(void*) boxptr_Util_makeTuple,0}};
#define boxvar_Util_makeTuple MMC_REFSTRUCTLIT(boxvar_lit_Util_makeTuple)
DLLExport
modelica_string omc_Util_escapeQuotes(threadData_t *threadData, modelica_string _str);
#define boxptr_Util_escapeQuotes omc_Util_escapeQuotes
static const MMC_DEFSTRUCTLIT(boxvar_lit_Util_escapeQuotes,2,0) {(void*) boxptr_Util_escapeQuotes,0}};
#define boxvar_Util_escapeQuotes MMC_REFSTRUCTLIT(boxvar_lit_Util_escapeQuotes)
DLLExport
modelica_string omc_Util_makeQuotedIdentifier(threadData_t *threadData, modelica_string _str);
#define boxptr_Util_makeQuotedIdentifier omc_Util_makeQuotedIdentifier
static const MMC_DEFSTRUCTLIT(boxvar_lit_Util_makeQuotedIdentifier,2,0) {(void*) boxptr_Util_makeQuotedIdentifier,0}};
#define boxvar_Util_makeQuotedIdentifier MMC_REFSTRUCTLIT(boxvar_lit_Util_makeQuotedIdentifier)
DLLExport
modelica_string omc_Util_escapeModelicaStringToXmlString(threadData_t *threadData, modelica_string _modelicaString);
#define boxptr_Util_escapeModelicaStringToXmlString omc_Util_escapeModelicaStringToXmlString
static const MMC_DEFSTRUCTLIT(boxvar_lit_Util_escapeModelicaStringToXmlString,2,0) {(void*) boxptr_Util_escapeModelicaStringToXmlString,0}};
#define boxvar_Util_escapeModelicaStringToXmlString MMC_REFSTRUCTLIT(boxvar_lit_Util_escapeModelicaStringToXmlString)
DLLExport
modelica_string omc_Util_escapeModelicaStringToJLString(threadData_t *threadData, modelica_string _modelicaString);
#define boxptr_Util_escapeModelicaStringToJLString omc_Util_escapeModelicaStringToJLString
static const MMC_DEFSTRUCTLIT(boxvar_lit_Util_escapeModelicaStringToJLString,2,0) {(void*) boxptr_Util_escapeModelicaStringToJLString,0}};
#define boxvar_Util_escapeModelicaStringToJLString MMC_REFSTRUCTLIT(boxvar_lit_Util_escapeModelicaStringToJLString)
DLLExport
modelica_string omc_Util_escapeModelicaStringToCString(threadData_t *threadData, modelica_string _modelicaString);
#define boxptr_Util_escapeModelicaStringToCString omc_Util_escapeModelicaStringToCString
static const MMC_DEFSTRUCTLIT(boxvar_lit_Util_escapeModelicaStringToCString,2,0) {(void*) boxptr_Util_escapeModelicaStringToCString,0}};
#define boxvar_Util_escapeModelicaStringToCString MMC_REFSTRUCTLIT(boxvar_lit_Util_escapeModelicaStringToCString)
DLLExport
modelica_string omc_Util_rawStringToInputString(threadData_t *threadData, modelica_string _inString);
#define boxptr_Util_rawStringToInputString omc_Util_rawStringToInputString
static const MMC_DEFSTRUCTLIT(boxvar_lit_Util_rawStringToInputString,2,0) {(void*) boxptr_Util_rawStringToInputString,0}};
#define boxvar_Util_rawStringToInputString MMC_REFSTRUCTLIT(boxvar_lit_Util_rawStringToInputString)
DLLExport
modelica_string omc_Util_getAbsoluteDirectoryAndFile(threadData_t *threadData, modelica_string _filename, modelica_string *out_basename);
#define boxptr_Util_getAbsoluteDirectoryAndFile omc_Util_getAbsoluteDirectoryAndFile
static const MMC_DEFSTRUCTLIT(boxvar_lit_Util_getAbsoluteDirectoryAndFile,2,0) {(void*) boxptr_Util_getAbsoluteDirectoryAndFile,0}};
#define boxvar_Util_getAbsoluteDirectoryAndFile MMC_REFSTRUCTLIT(boxvar_lit_Util_getAbsoluteDirectoryAndFile)
DLLExport
modelica_string omc_Util_replaceWindowsBackSlashWithPathDelimiter(threadData_t *threadData, modelica_string _inPath);
#define boxptr_Util_replaceWindowsBackSlashWithPathDelimiter omc_Util_replaceWindowsBackSlashWithPathDelimiter
static const MMC_DEFSTRUCTLIT(boxvar_lit_Util_replaceWindowsBackSlashWithPathDelimiter,2,0) {(void*) boxptr_Util_replaceWindowsBackSlashWithPathDelimiter,0}};
#define boxvar_Util_replaceWindowsBackSlashWithPathDelimiter MMC_REFSTRUCTLIT(boxvar_lit_Util_replaceWindowsBackSlashWithPathDelimiter)
DLLExport
modelica_string omc_Util_tickStr(threadData_t *threadData);
#define boxptr_Util_tickStr omc_Util_tickStr
static const MMC_DEFSTRUCTLIT(boxvar_lit_Util_tickStr,2,0) {(void*) boxptr_Util_tickStr,0}};
#define boxvar_Util_tickStr MMC_REFSTRUCTLIT(boxvar_lit_Util_tickStr)
DLLExport
modelica_boolean omc_Util_notStrncmp(threadData_t *threadData, modelica_string _inString1, modelica_string _inString2, modelica_integer _inLength);
DLLExport
modelica_metatype boxptr_Util_notStrncmp(threadData_t *threadData, modelica_metatype _inString1, modelica_metatype _inString2, modelica_metatype _inLength);
static const MMC_DEFSTRUCTLIT(boxvar_lit_Util_notStrncmp,2,0) {(void*) boxptr_Util_notStrncmp,0}};
#define boxvar_Util_notStrncmp MMC_REFSTRUCTLIT(boxvar_lit_Util_notStrncmp)
DLLExport
modelica_boolean omc_Util_strncmp(threadData_t *threadData, modelica_string _inString1, modelica_string _inString2, modelica_integer _inLength);
DLLExport
modelica_metatype boxptr_Util_strncmp(threadData_t *threadData, modelica_metatype _inString1, modelica_metatype _inString2, modelica_metatype _inLength);
static const MMC_DEFSTRUCTLIT(boxvar_lit_Util_strncmp,2,0) {(void*) boxptr_Util_strncmp,0}};
#define boxvar_Util_strncmp MMC_REFSTRUCTLIT(boxvar_lit_Util_strncmp)
DLLExport
modelica_boolean omc_Util_stringStartsWith(threadData_t *threadData, modelica_string _inString1, modelica_string _inString2);
DLLExport
modelica_metatype boxptr_Util_stringStartsWith(threadData_t *threadData, modelica_metatype _inString1, modelica_metatype _inString2);
static const MMC_DEFSTRUCTLIT(boxvar_lit_Util_stringStartsWith,2,0) {(void*) boxptr_Util_stringStartsWith,0}};
#define boxvar_Util_stringStartsWith MMC_REFSTRUCTLIT(boxvar_lit_Util_stringStartsWith)
DLLExport
void omc_Util_writeFileOrErrorMsg(threadData_t *threadData, modelica_string _inFilename, modelica_string _inString);
#define boxptr_Util_writeFileOrErrorMsg omc_Util_writeFileOrErrorMsg
static const MMC_DEFSTRUCTLIT(boxvar_lit_Util_writeFileOrErrorMsg,2,0) {(void*) boxptr_Util_writeFileOrErrorMsg,0}};
#define boxvar_Util_writeFileOrErrorMsg MMC_REFSTRUCTLIT(boxvar_lit_Util_writeFileOrErrorMsg)
DLLExport
modelica_boolean omc_Util_isNotEmptyString(threadData_t *threadData, modelica_string _inString);
DLLExport
modelica_metatype boxptr_Util_isNotEmptyString(threadData_t *threadData, modelica_metatype _inString);
static const MMC_DEFSTRUCTLIT(boxvar_lit_Util_isNotEmptyString,2,0) {(void*) boxptr_Util_isNotEmptyString,0}};
#define boxvar_Util_isNotEmptyString MMC_REFSTRUCTLIT(boxvar_lit_Util_isNotEmptyString)
DLLExport
modelica_integer omc_Util_boolCompare(threadData_t *threadData, modelica_boolean _inN, modelica_boolean _inM);
DLLExport
modelica_metatype boxptr_Util_boolCompare(threadData_t *threadData, modelica_metatype _inN, modelica_metatype _inM);
static const MMC_DEFSTRUCTLIT(boxvar_lit_Util_boolCompare,2,0) {(void*) boxptr_Util_boolCompare,0}};
#define boxvar_Util_boolCompare MMC_REFSTRUCTLIT(boxvar_lit_Util_boolCompare)
DLLExport
modelica_integer omc_Util_realCompare(threadData_t *threadData, modelica_real _inN, modelica_real _inM);
DLLExport
modelica_metatype boxptr_Util_realCompare(threadData_t *threadData, modelica_metatype _inN, modelica_metatype _inM);
static const MMC_DEFSTRUCTLIT(boxvar_lit_Util_realCompare,2,0) {(void*) boxptr_Util_realCompare,0}};
#define boxvar_Util_realCompare MMC_REFSTRUCTLIT(boxvar_lit_Util_realCompare)
DLLExport
modelica_boolean omc_Util_realNegative(threadData_t *threadData, modelica_real _v);
DLLExport
modelica_metatype boxptr_Util_realNegative(threadData_t *threadData, modelica_metatype _v);
static const MMC_DEFSTRUCTLIT(boxvar_lit_Util_realNegative,2,0) {(void*) boxptr_Util_realNegative,0}};
#define boxvar_Util_realNegative MMC_REFSTRUCTLIT(boxvar_lit_Util_realNegative)
DLLExport
modelica_integer omc_Util_intPow(threadData_t *threadData, modelica_integer _base, modelica_integer _exponent);
DLLExport
modelica_metatype boxptr_Util_intPow(threadData_t *threadData, modelica_metatype _base, modelica_metatype _exponent);
static const MMC_DEFSTRUCTLIT(boxvar_lit_Util_intPow,2,0) {(void*) boxptr_Util_intPow,0}};
#define boxvar_Util_intPow MMC_REFSTRUCTLIT(boxvar_lit_Util_intPow)
DLLExport
modelica_integer omc_Util_intCompare(threadData_t *threadData, modelica_integer _inN, modelica_integer _inM);
DLLExport
modelica_metatype boxptr_Util_intCompare(threadData_t *threadData, modelica_metatype _inN, modelica_metatype _inM);
static const MMC_DEFSTRUCTLIT(boxvar_lit_Util_intCompare,2,0) {(void*) boxptr_Util_intCompare,0}};
#define boxvar_Util_intCompare MMC_REFSTRUCTLIT(boxvar_lit_Util_intCompare)
DLLExport
modelica_integer omc_Util_intSign(threadData_t *threadData, modelica_integer _i);
DLLExport
modelica_metatype boxptr_Util_intSign(threadData_t *threadData, modelica_metatype _i);
static const MMC_DEFSTRUCTLIT(boxvar_lit_Util_intSign,2,0) {(void*) boxptr_Util_intSign,0}};
#define boxvar_Util_intSign MMC_REFSTRUCTLIT(boxvar_lit_Util_intSign)
DLLExport
modelica_boolean omc_Util_intNegative(threadData_t *threadData, modelica_integer _v);
DLLExport
modelica_metatype boxptr_Util_intNegative(threadData_t *threadData, modelica_metatype _v);
static const MMC_DEFSTRUCTLIT(boxvar_lit_Util_intNegative,2,0) {(void*) boxptr_Util_intNegative,0}};
#define boxvar_Util_intNegative MMC_REFSTRUCTLIT(boxvar_lit_Util_intNegative)
DLLExport
modelica_boolean omc_Util_intPositive(threadData_t *threadData, modelica_integer _v);
DLLExport
modelica_metatype boxptr_Util_intPositive(threadData_t *threadData, modelica_metatype _v);
static const MMC_DEFSTRUCTLIT(boxvar_lit_Util_intPositive,2,0) {(void*) boxptr_Util_intPositive,0}};
#define boxvar_Util_intPositive MMC_REFSTRUCTLIT(boxvar_lit_Util_intPositive)
DLLExport
modelica_boolean omc_Util_intGreaterZero(threadData_t *threadData, modelica_integer _v);
DLLExport
modelica_metatype boxptr_Util_intGreaterZero(threadData_t *threadData, modelica_metatype _v);
static const MMC_DEFSTRUCTLIT(boxvar_lit_Util_intGreaterZero,2,0) {(void*) boxptr_Util_intGreaterZero,0}};
#define boxvar_Util_intGreaterZero MMC_REFSTRUCTLIT(boxvar_lit_Util_intGreaterZero)
DLLExport
modelica_metatype omc_Util_getOptionOrDefault(threadData_t *threadData, modelica_metatype _inOption, modelica_metatype _inDefault);
#define boxptr_Util_getOptionOrDefault omc_Util_getOptionOrDefault
static const MMC_DEFSTRUCTLIT(boxvar_lit_Util_getOptionOrDefault,2,0) {(void*) boxptr_Util_getOptionOrDefault,0}};
#define boxvar_Util_getOptionOrDefault MMC_REFSTRUCTLIT(boxvar_lit_Util_getOptionOrDefault)
DLLExport
modelica_metatype omc_Util_getOption(threadData_t *threadData, modelica_metatype _inOption);
#define boxptr_Util_getOption omc_Util_getOption
static const MMC_DEFSTRUCTLIT(boxvar_lit_Util_getOption,2,0) {(void*) boxptr_Util_getOption,0}};
#define boxvar_Util_getOption MMC_REFSTRUCTLIT(boxvar_lit_Util_getOption)
DLLExport
modelica_string omc_Util_stringOption(threadData_t *threadData, modelica_metatype _inStringOption);
#define boxptr_Util_stringOption omc_Util_stringOption
static const MMC_DEFSTRUCTLIT(boxvar_lit_Util_stringOption,2,0) {(void*) boxptr_Util_stringOption,0}};
#define boxvar_Util_stringOption MMC_REFSTRUCTLIT(boxvar_lit_Util_stringOption)
DLLExport
modelica_metatype omc_Util_makeOptionOnTrue(threadData_t *threadData, modelica_boolean _inCondition, modelica_metatype _inValue);
DLLExport
modelica_metatype boxptr_Util_makeOptionOnTrue(threadData_t *threadData, modelica_metatype _inCondition, modelica_metatype _inValue);
static const MMC_DEFSTRUCTLIT(boxvar_lit_Util_makeOptionOnTrue,2,0) {(void*) boxptr_Util_makeOptionOnTrue,0}};
#define boxvar_Util_makeOptionOnTrue MMC_REFSTRUCTLIT(boxvar_lit_Util_makeOptionOnTrue)
DLLExport
modelica_metatype omc_Util_makeOption(threadData_t *threadData, modelica_metatype _inValue);
#define boxptr_Util_makeOption omc_Util_makeOption
static const MMC_DEFSTRUCTLIT(boxvar_lit_Util_makeOption,2,0) {(void*) boxptr_Util_makeOption,0}};
#define boxvar_Util_makeOption MMC_REFSTRUCTLIT(boxvar_lit_Util_makeOption)
DLLExport
modelica_metatype omc_Util_applyOption__2(threadData_t *threadData, modelica_metatype _inValue1, modelica_metatype _inValue2, modelica_fnptr _inFunc);
#define boxptr_Util_applyOption__2 omc_Util_applyOption__2
static const MMC_DEFSTRUCTLIT(boxvar_lit_Util_applyOption__2,2,0) {(void*) boxptr_Util_applyOption__2,0}};
#define boxvar_Util_applyOption__2 MMC_REFSTRUCTLIT(boxvar_lit_Util_applyOption__2)
DLLExport
modelica_metatype omc_Util_applyOptionOrDefault2(threadData_t *threadData, modelica_metatype _inValue, modelica_fnptr _inFunc, modelica_metatype _inArg1, modelica_metatype _inArg2, modelica_metatype _inDefaultValue);
#define boxptr_Util_applyOptionOrDefault2 omc_Util_applyOptionOrDefault2
static const MMC_DEFSTRUCTLIT(boxvar_lit_Util_applyOptionOrDefault2,2,0) {(void*) boxptr_Util_applyOptionOrDefault2,0}};
#define boxvar_Util_applyOptionOrDefault2 MMC_REFSTRUCTLIT(boxvar_lit_Util_applyOptionOrDefault2)
DLLExport
modelica_metatype omc_Util_applyOptionOrDefault1(threadData_t *threadData, modelica_metatype _inValue, modelica_fnptr _inFunc, modelica_metatype _inArg, modelica_metatype _inDefaultValue);
#define boxptr_Util_applyOptionOrDefault1 omc_Util_applyOptionOrDefault1
static const MMC_DEFSTRUCTLIT(boxvar_lit_Util_applyOptionOrDefault1,2,0) {(void*) boxptr_Util_applyOptionOrDefault1,0}};
#define boxvar_Util_applyOptionOrDefault1 MMC_REFSTRUCTLIT(boxvar_lit_Util_applyOptionOrDefault1)
DLLExport
modelica_metatype omc_Util_applyOptionOrDefault(threadData_t *threadData, modelica_metatype _inValue, modelica_fnptr _inFunc, modelica_metatype _inDefaultValue);
#define boxptr_Util_applyOptionOrDefault omc_Util_applyOptionOrDefault
static const MMC_DEFSTRUCTLIT(boxvar_lit_Util_applyOptionOrDefault,2,0) {(void*) boxptr_Util_applyOptionOrDefault,0}};
#define boxvar_Util_applyOptionOrDefault MMC_REFSTRUCTLIT(boxvar_lit_Util_applyOptionOrDefault)
DLLExport
modelica_metatype omc_Util_applyOption1(threadData_t *threadData, modelica_metatype _inOption, modelica_fnptr _inFunc, modelica_metatype _inArg);
#define boxptr_Util_applyOption1 omc_Util_applyOption1
static const MMC_DEFSTRUCTLIT(boxvar_lit_Util_applyOption1,2,0) {(void*) boxptr_Util_applyOption1,0}};
#define boxvar_Util_applyOption1 MMC_REFSTRUCTLIT(boxvar_lit_Util_applyOption1)
DLLExport
modelica_metatype omc_Util_applyOption(threadData_t *threadData, modelica_metatype _inOption, modelica_fnptr _inFunc);
#define boxptr_Util_applyOption omc_Util_applyOption
static const MMC_DEFSTRUCTLIT(boxvar_lit_Util_applyOption,2,0) {(void*) boxptr_Util_applyOption,0}};
#define boxvar_Util_applyOption MMC_REFSTRUCTLIT(boxvar_lit_Util_applyOption)
DLLExport
modelica_boolean omc_Util_boolAndList(threadData_t *threadData, modelica_metatype _inBooleanLst);
DLLExport
modelica_metatype boxptr_Util_boolAndList(threadData_t *threadData, modelica_metatype _inBooleanLst);
static const MMC_DEFSTRUCTLIT(boxvar_lit_Util_boolAndList,2,0) {(void*) boxptr_Util_boolAndList,0}};
#define boxvar_Util_boolAndList MMC_REFSTRUCTLIT(boxvar_lit_Util_boolAndList)
DLLExport
modelica_boolean omc_Util_boolOrList(threadData_t *threadData, modelica_metatype _inBooleanLst);
DLLExport
modelica_metatype boxptr_Util_boolOrList(threadData_t *threadData, modelica_metatype _inBooleanLst);
static const MMC_DEFSTRUCTLIT(boxvar_lit_Util_boolOrList,2,0) {(void*) boxptr_Util_boolOrList,0}};
#define boxvar_Util_boolOrList MMC_REFSTRUCTLIT(boxvar_lit_Util_boolOrList)
DLLExport
modelica_metatype omc_Util_stringSplitAtChar(threadData_t *threadData, modelica_string _string, modelica_string _token);
#define boxptr_Util_stringSplitAtChar omc_Util_stringSplitAtChar
static const MMC_DEFSTRUCTLIT(boxvar_lit_Util_stringSplitAtChar,2,0) {(void*) boxptr_Util_stringSplitAtChar,0}};
#define boxvar_Util_stringSplitAtChar MMC_REFSTRUCTLIT(boxvar_lit_Util_stringSplitAtChar)
DLLExport
modelica_string omc_Util_stringReplaceChar(threadData_t *threadData, modelica_string _inString1, modelica_string _inString2, modelica_string _inString3);
#define boxptr_Util_stringReplaceChar omc_Util_stringReplaceChar
static const MMC_DEFSTRUCTLIT(boxvar_lit_Util_stringReplaceChar,2,0) {(void*) boxptr_Util_stringReplaceChar,0}};
#define boxvar_Util_stringReplaceChar MMC_REFSTRUCTLIT(boxvar_lit_Util_stringReplaceChar)
DLLExport
modelica_integer omc_Util_mulStringDelimit2Int(threadData_t *threadData, modelica_string _inString, modelica_string _delim);
DLLExport
modelica_metatype boxptr_Util_mulStringDelimit2Int(threadData_t *threadData, modelica_metatype _inString, modelica_metatype _delim);
static const MMC_DEFSTRUCTLIT(boxvar_lit_Util_mulStringDelimit2Int,2,0) {(void*) boxptr_Util_mulStringDelimit2Int,0}};
#define boxvar_Util_mulStringDelimit2Int MMC_REFSTRUCTLIT(boxvar_lit_Util_mulStringDelimit2Int)
DLLExport
modelica_string omc_Util_stringDelimitListNonEmptyElts(threadData_t *threadData, modelica_metatype _lst, modelica_string _delim);
#define boxptr_Util_stringDelimitListNonEmptyElts omc_Util_stringDelimitListNonEmptyElts
static const MMC_DEFSTRUCTLIT(boxvar_lit_Util_stringDelimitListNonEmptyElts,2,0) {(void*) boxptr_Util_stringDelimitListNonEmptyElts,0}};
#define boxvar_Util_stringDelimitListNonEmptyElts MMC_REFSTRUCTLIT(boxvar_lit_Util_stringDelimitListNonEmptyElts)
DLLExport
modelica_string omc_Util_stringDelimitListAndSeparate(threadData_t *threadData, modelica_metatype _str, modelica_string _sep1, modelica_string _sep2, modelica_integer _n);
DLLExport
modelica_metatype boxptr_Util_stringDelimitListAndSeparate(threadData_t *threadData, modelica_metatype _str, modelica_metatype _sep1, modelica_metatype _sep2, modelica_metatype _n);
static const MMC_DEFSTRUCTLIT(boxvar_lit_Util_stringDelimitListAndSeparate,2,0) {(void*) boxptr_Util_stringDelimitListAndSeparate,0}};
#define boxvar_Util_stringDelimitListAndSeparate MMC_REFSTRUCTLIT(boxvar_lit_Util_stringDelimitListAndSeparate)
DLLExport
void omc_Util_stringDelimitListPrintBuf(threadData_t *threadData, modelica_metatype _inStringLst, modelica_string _inDelimiter);
#define boxptr_Util_stringDelimitListPrintBuf omc_Util_stringDelimitListPrintBuf
static const MMC_DEFSTRUCTLIT(boxvar_lit_Util_stringDelimitListPrintBuf,2,0) {(void*) boxptr_Util_stringDelimitListPrintBuf,0}};
#define boxvar_Util_stringDelimitListPrintBuf MMC_REFSTRUCTLIT(boxvar_lit_Util_stringDelimitListPrintBuf)
DLLExport
modelica_boolean omc_Util_stringContainsChar(threadData_t *threadData, modelica_string _str, modelica_string _char);
DLLExport
modelica_metatype boxptr_Util_stringContainsChar(threadData_t *threadData, modelica_metatype _str, modelica_metatype _char);
static const MMC_DEFSTRUCTLIT(boxvar_lit_Util_stringContainsChar,2,0) {(void*) boxptr_Util_stringContainsChar,0}};
#define boxvar_Util_stringContainsChar MMC_REFSTRUCTLIT(boxvar_lit_Util_stringContainsChar)
DLLExport
modelica_metatype omc_Util_tuple62(threadData_t *threadData, modelica_metatype _inTuple);
#define boxptr_Util_tuple62 omc_Util_tuple62
static const MMC_DEFSTRUCTLIT(boxvar_lit_Util_tuple62,2,0) {(void*) boxptr_Util_tuple62,0}};
#define boxvar_Util_tuple62 MMC_REFSTRUCTLIT(boxvar_lit_Util_tuple62)
DLLExport
modelica_metatype omc_Util_tuple61(threadData_t *threadData, modelica_metatype _inTuple);
#define boxptr_Util_tuple61 omc_Util_tuple61
static const MMC_DEFSTRUCTLIT(boxvar_lit_Util_tuple61,2,0) {(void*) boxptr_Util_tuple61,0}};
#define boxvar_Util_tuple61 MMC_REFSTRUCTLIT(boxvar_lit_Util_tuple61)
DLLExport
modelica_metatype omc_Util_tuple55(threadData_t *threadData, modelica_metatype _inTuple);
#define boxptr_Util_tuple55 omc_Util_tuple55
static const MMC_DEFSTRUCTLIT(boxvar_lit_Util_tuple55,2,0) {(void*) boxptr_Util_tuple55,0}};
#define boxvar_Util_tuple55 MMC_REFSTRUCTLIT(boxvar_lit_Util_tuple55)
DLLExport
modelica_metatype omc_Util_tuple54(threadData_t *threadData, modelica_metatype _inTuple);
#define boxptr_Util_tuple54 omc_Util_tuple54
static const MMC_DEFSTRUCTLIT(boxvar_lit_Util_tuple54,2,0) {(void*) boxptr_Util_tuple54,0}};
#define boxvar_Util_tuple54 MMC_REFSTRUCTLIT(boxvar_lit_Util_tuple54)
DLLExport
modelica_metatype omc_Util_tuple53(threadData_t *threadData, modelica_metatype _inTuple);
#define boxptr_Util_tuple53 omc_Util_tuple53
static const MMC_DEFSTRUCTLIT(boxvar_lit_Util_tuple53,2,0) {(void*) boxptr_Util_tuple53,0}};
#define boxvar_Util_tuple53 MMC_REFSTRUCTLIT(boxvar_lit_Util_tuple53)
DLLExport
modelica_metatype omc_Util_tuple52(threadData_t *threadData, modelica_metatype _inTuple);
#define boxptr_Util_tuple52 omc_Util_tuple52
static const MMC_DEFSTRUCTLIT(boxvar_lit_Util_tuple52,2,0) {(void*) boxptr_Util_tuple52,0}};
#define boxvar_Util_tuple52 MMC_REFSTRUCTLIT(boxvar_lit_Util_tuple52)
DLLExport
modelica_metatype omc_Util_tuple51(threadData_t *threadData, modelica_metatype _inTuple);
#define boxptr_Util_tuple51 omc_Util_tuple51
static const MMC_DEFSTRUCTLIT(boxvar_lit_Util_tuple51,2,0) {(void*) boxptr_Util_tuple51,0}};
#define boxvar_Util_tuple51 MMC_REFSTRUCTLIT(boxvar_lit_Util_tuple51)
DLLExport
modelica_metatype omc_Util_tuple44(threadData_t *threadData, modelica_metatype _inTuple);
#define boxptr_Util_tuple44 omc_Util_tuple44
static const MMC_DEFSTRUCTLIT(boxvar_lit_Util_tuple44,2,0) {(void*) boxptr_Util_tuple44,0}};
#define boxvar_Util_tuple44 MMC_REFSTRUCTLIT(boxvar_lit_Util_tuple44)
DLLExport
modelica_metatype omc_Util_tuple43(threadData_t *threadData, modelica_metatype _inTuple);
#define boxptr_Util_tuple43 omc_Util_tuple43
static const MMC_DEFSTRUCTLIT(boxvar_lit_Util_tuple43,2,0) {(void*) boxptr_Util_tuple43,0}};
#define boxvar_Util_tuple43 MMC_REFSTRUCTLIT(boxvar_lit_Util_tuple43)
DLLExport
modelica_metatype omc_Util_tuple42(threadData_t *threadData, modelica_metatype _inTuple);
#define boxptr_Util_tuple42 omc_Util_tuple42
static const MMC_DEFSTRUCTLIT(boxvar_lit_Util_tuple42,2,0) {(void*) boxptr_Util_tuple42,0}};
#define boxvar_Util_tuple42 MMC_REFSTRUCTLIT(boxvar_lit_Util_tuple42)
DLLExport
modelica_metatype omc_Util_tuple41(threadData_t *threadData, modelica_metatype _inTuple);
#define boxptr_Util_tuple41 omc_Util_tuple41
static const MMC_DEFSTRUCTLIT(boxvar_lit_Util_tuple41,2,0) {(void*) boxptr_Util_tuple41,0}};
#define boxvar_Util_tuple41 MMC_REFSTRUCTLIT(boxvar_lit_Util_tuple41)
DLLExport
modelica_metatype omc_Util_tuple33(threadData_t *threadData, modelica_metatype _inValue);
#define boxptr_Util_tuple33 omc_Util_tuple33
static const MMC_DEFSTRUCTLIT(boxvar_lit_Util_tuple33,2,0) {(void*) boxptr_Util_tuple33,0}};
#define boxvar_Util_tuple33 MMC_REFSTRUCTLIT(boxvar_lit_Util_tuple33)
DLLExport
modelica_metatype omc_Util_tuple32(threadData_t *threadData, modelica_metatype _inValue);
#define boxptr_Util_tuple32 omc_Util_tuple32
static const MMC_DEFSTRUCTLIT(boxvar_lit_Util_tuple32,2,0) {(void*) boxptr_Util_tuple32,0}};
#define boxvar_Util_tuple32 MMC_REFSTRUCTLIT(boxvar_lit_Util_tuple32)
DLLExport
modelica_metatype omc_Util_tuple31(threadData_t *threadData, modelica_metatype _inValue);
#define boxptr_Util_tuple31 omc_Util_tuple31
static const MMC_DEFSTRUCTLIT(boxvar_lit_Util_tuple31,2,0) {(void*) boxptr_Util_tuple31,0}};
#define boxvar_Util_tuple31 MMC_REFSTRUCTLIT(boxvar_lit_Util_tuple31)
DLLExport
modelica_metatype omc_Util_tuple312(threadData_t *threadData, modelica_metatype _inTuple);
#define boxptr_Util_tuple312 omc_Util_tuple312
static const MMC_DEFSTRUCTLIT(boxvar_lit_Util_tuple312,2,0) {(void*) boxptr_Util_tuple312,0}};
#define boxvar_Util_tuple312 MMC_REFSTRUCTLIT(boxvar_lit_Util_tuple312)
DLLExport
modelica_metatype omc_Util_optTuple22(threadData_t *threadData, modelica_metatype _inTuple);
#define boxptr_Util_optTuple22 omc_Util_optTuple22
static const MMC_DEFSTRUCTLIT(boxvar_lit_Util_optTuple22,2,0) {(void*) boxptr_Util_optTuple22,0}};
#define boxvar_Util_optTuple22 MMC_REFSTRUCTLIT(boxvar_lit_Util_optTuple22)
DLLExport
modelica_metatype omc_Util_tuple22(threadData_t *threadData, modelica_metatype _inTuple);
#define boxptr_Util_tuple22 omc_Util_tuple22
static const MMC_DEFSTRUCTLIT(boxvar_lit_Util_tuple22,2,0) {(void*) boxptr_Util_tuple22,0}};
#define boxvar_Util_tuple22 MMC_REFSTRUCTLIT(boxvar_lit_Util_tuple22)
DLLExport
modelica_metatype omc_Util_tuple21(threadData_t *threadData, modelica_metatype _inTuple);
#define boxptr_Util_tuple21 omc_Util_tuple21
static const MMC_DEFSTRUCTLIT(boxvar_lit_Util_tuple21,2,0) {(void*) boxptr_Util_tuple21,0}};
#define boxvar_Util_tuple21 MMC_REFSTRUCTLIT(boxvar_lit_Util_tuple21)
DLLExport
modelica_boolean omc_Util_compareTuple2IntLt(threadData_t *threadData, modelica_metatype _inTplA, modelica_metatype _inTplB);
DLLExport
modelica_metatype boxptr_Util_compareTuple2IntLt(threadData_t *threadData, modelica_metatype _inTplA, modelica_metatype _inTplB);
static const MMC_DEFSTRUCTLIT(boxvar_lit_Util_compareTuple2IntLt,2,0) {(void*) boxptr_Util_compareTuple2IntLt,0}};
#define boxvar_Util_compareTuple2IntLt MMC_REFSTRUCTLIT(boxvar_lit_Util_compareTuple2IntLt)
DLLExport
modelica_boolean omc_Util_compareTuple2IntGt(threadData_t *threadData, modelica_metatype _inTplA, modelica_metatype _inTplB);
DLLExport
modelica_metatype boxptr_Util_compareTuple2IntGt(threadData_t *threadData, modelica_metatype _inTplA, modelica_metatype _inTplB);
static const MMC_DEFSTRUCTLIT(boxvar_lit_Util_compareTuple2IntGt,2,0) {(void*) boxptr_Util_compareTuple2IntGt,0}};
#define boxvar_Util_compareTuple2IntGt MMC_REFSTRUCTLIT(boxvar_lit_Util_compareTuple2IntGt)
DLLExport
modelica_boolean omc_Util_compareTupleIntLt(threadData_t *threadData, modelica_metatype _inTplA, modelica_metatype _inTplB);
DLLExport
modelica_metatype boxptr_Util_compareTupleIntLt(threadData_t *threadData, modelica_metatype _inTplA, modelica_metatype _inTplB);
static const MMC_DEFSTRUCTLIT(boxvar_lit_Util_compareTupleIntLt,2,0) {(void*) boxptr_Util_compareTupleIntLt,0}};
#define boxvar_Util_compareTupleIntLt MMC_REFSTRUCTLIT(boxvar_lit_Util_compareTupleIntLt)
DLLExport
modelica_boolean omc_Util_compareTupleIntGt(threadData_t *threadData, modelica_metatype _inTplA, modelica_metatype _inTplB);
DLLExport
modelica_metatype boxptr_Util_compareTupleIntGt(threadData_t *threadData, modelica_metatype _inTplA, modelica_metatype _inTplB);
static const MMC_DEFSTRUCTLIT(boxvar_lit_Util_compareTupleIntGt,2,0) {(void*) boxptr_Util_compareTupleIntGt,0}};
#define boxvar_Util_compareTupleIntGt MMC_REFSTRUCTLIT(boxvar_lit_Util_compareTupleIntGt)
DLLExport
modelica_string omc_Util_selectFirstNonEmptyString(threadData_t *threadData, modelica_metatype _inStrings);
#define boxptr_Util_selectFirstNonEmptyString omc_Util_selectFirstNonEmptyString
static const MMC_DEFSTRUCTLIT(boxvar_lit_Util_selectFirstNonEmptyString,2,0) {(void*) boxptr_Util_selectFirstNonEmptyString,0}};
#define boxvar_Util_selectFirstNonEmptyString MMC_REFSTRUCTLIT(boxvar_lit_Util_selectFirstNonEmptyString)
DLLExport
modelica_string omc_Util_flagValue(threadData_t *threadData, modelica_string _flag, modelica_metatype _arguments);
#define boxptr_Util_flagValue omc_Util_flagValue
static const MMC_DEFSTRUCTLIT(boxvar_lit_Util_flagValue,2,0) {(void*) boxptr_Util_flagValue,0}};
#define boxvar_Util_flagValue MMC_REFSTRUCTLIT(boxvar_lit_Util_flagValue)
DLLExport
modelica_string omc_Util_linuxDotSlash(threadData_t *threadData);
#define boxptr_Util_linuxDotSlash omc_Util_linuxDotSlash
static const MMC_DEFSTRUCTLIT(boxvar_lit_Util_linuxDotSlash,2,0) {(void*) boxptr_Util_linuxDotSlash,0}};
#define boxvar_Util_linuxDotSlash MMC_REFSTRUCTLIT(boxvar_lit_Util_linuxDotSlash)
DLLExport
modelica_boolean omc_Util_isRealGreater(threadData_t *threadData, modelica_real _lhs, modelica_real _rhs);
DLLExport
modelica_metatype boxptr_Util_isRealGreater(threadData_t *threadData, modelica_metatype _lhs, modelica_metatype _rhs);
static const MMC_DEFSTRUCTLIT(boxvar_lit_Util_isRealGreater,2,0) {(void*) boxptr_Util_isRealGreater,0}};
#define boxvar_Util_isRealGreater MMC_REFSTRUCTLIT(boxvar_lit_Util_isRealGreater)
DLLExport
modelica_boolean omc_Util_isIntGreater(threadData_t *threadData, modelica_integer _lhs, modelica_integer _rhs);
DLLExport
modelica_metatype boxptr_Util_isIntGreater(threadData_t *threadData, modelica_metatype _lhs, modelica_metatype _rhs);
static const MMC_DEFSTRUCTLIT(boxvar_lit_Util_isIntGreater,2,0) {(void*) boxptr_Util_isIntGreater,0}};
#define boxvar_Util_isIntGreater MMC_REFSTRUCTLIT(boxvar_lit_Util_isIntGreater)
#ifdef __cplusplus
}
#endif
#endif
