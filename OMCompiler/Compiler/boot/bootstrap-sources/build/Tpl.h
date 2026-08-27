#ifndef Tpl__H
#define Tpl__H
#include "meta/meta_modelica.h"
#include "util/modelica.h"
#include <stdio.h>
#include <stdlib.h>
#include <errno.h>
#ifdef __cplusplus
extern "C" {
#endif
extern struct record_description ErrorTypes_Message_MESSAGE__desc;
extern struct record_description ErrorTypes_MessageType_TRANSLATION__desc;
extern struct record_description ErrorTypes_Severity_ERROR__desc;
extern struct record_description Flags_DebugFlag_DEBUG__FLAG__desc;
extern struct record_description Gettext_TranslatableContent_gettext__desc;
extern struct record_description SourceInfo_SOURCEINFO__desc;
extern struct record_description Tpl_BlockType_BT__ITER__desc;
extern struct record_description Tpl_BlockType_BT__TEXT__desc;
extern struct record_description Tpl_BlockTypeFileText_BT__FILE__TEXT__desc;
extern struct record_description Tpl_StringToken_ST__BLOCK__desc;
extern struct record_description Tpl_StringToken_ST__LINE__desc;
extern struct record_description Tpl_StringToken_ST__NEW__LINE__desc;
extern struct record_description Tpl_StringToken_ST__STRING__desc;
extern struct record_description Tpl_Text_FILE__TEXT__desc;
extern struct record_description Tpl_Text_MEM__TEXT__desc;
DLLExport
void omc_Tpl_fakeStackOverflow(threadData_t *threadData);
#define boxptr_Tpl_fakeStackOverflow omc_Tpl_fakeStackOverflow
static const MMC_DEFSTRUCTLIT(boxvar_lit_Tpl_fakeStackOverflow,2,0) {(void*) boxptr_Tpl_fakeStackOverflow,0}};
#define boxvar_Tpl_fakeStackOverflow MMC_REFSTRUCTLIT(boxvar_lit_Tpl_fakeStackOverflow)
DLLExport
modelica_boolean omc_Tpl_debugSusan(threadData_t *threadData);
DLLExport
modelica_metatype boxptr_Tpl_debugSusan(threadData_t *threadData);
static const MMC_DEFSTRUCTLIT(boxvar_lit_Tpl_debugSusan,2,0) {(void*) boxptr_Tpl_debugSusan,0}};
#define boxvar_Tpl_debugSusan MMC_REFSTRUCTLIT(boxvar_lit_Tpl_debugSusan)
#define boxptr_Tpl_handleTok omc_Tpl_handleTok
#define boxptr_Tpl_newlineFile omc_Tpl_newlineFile
#define boxptr_Tpl_getTextOpaqueFile omc_Tpl_getTextOpaqueFile
DLLExport
modelica_string omc_Tpl_booleanString(threadData_t *threadData, modelica_boolean _b);
DLLExport
modelica_metatype boxptr_Tpl_booleanString(threadData_t *threadData, modelica_metatype _b);
static const MMC_DEFSTRUCTLIT(boxvar_lit_Tpl_booleanString,2,0) {(void*) boxptr_Tpl_booleanString,0}};
#define boxvar_Tpl_booleanString MMC_REFSTRUCTLIT(boxvar_lit_Tpl_booleanString)
DLLExport
modelica_metatype omc_Tpl_closeFile(threadData_t *threadData, modelica_metatype __omcQ_24in_5Ftext);
#define boxptr_Tpl_closeFile omc_Tpl_closeFile
static const MMC_DEFSTRUCTLIT(boxvar_lit_Tpl_closeFile,2,0) {(void*) boxptr_Tpl_closeFile,0}};
#define boxvar_Tpl_closeFile MMC_REFSTRUCTLIT(boxvar_lit_Tpl_closeFile)
DLLExport
modelica_metatype omc_Tpl_redirectToFile(threadData_t *threadData, modelica_metatype __omcQ_24in_5Ftext, modelica_string _fileName);
#define boxptr_Tpl_redirectToFile omc_Tpl_redirectToFile
static const MMC_DEFSTRUCTLIT(boxvar_lit_Tpl_redirectToFile,2,0) {(void*) boxptr_Tpl_redirectToFile,0}};
#define boxvar_Tpl_redirectToFile MMC_REFSTRUCTLIT(boxvar_lit_Tpl_redirectToFile)
DLLExport
void omc_Tpl_addTemplateError(threadData_t *threadData, modelica_string _msg);
#define boxptr_Tpl_addTemplateError omc_Tpl_addTemplateError
static const MMC_DEFSTRUCTLIT(boxvar_lit_Tpl_addTemplateError,2,0) {(void*) boxptr_Tpl_addTemplateError,0}};
#define boxvar_Tpl_addTemplateError MMC_REFSTRUCTLIT(boxvar_lit_Tpl_addTemplateError)
#define boxptr_Tpl_addTemplateErrorFunc omc_Tpl_addTemplateErrorFunc
DLLExport
void omc_Tpl_addSourceTemplateError(threadData_t *threadData, modelica_string _inErrMsg, modelica_metatype _inInfo);
#define boxptr_Tpl_addSourceTemplateError omc_Tpl_addSourceTemplateError
static const MMC_DEFSTRUCTLIT(boxvar_lit_Tpl_addSourceTemplateError,2,0) {(void*) boxptr_Tpl_addSourceTemplateError,0}};
#define boxvar_Tpl_addSourceTemplateError MMC_REFSTRUCTLIT(boxvar_lit_Tpl_addSourceTemplateError)
DLLExport
modelica_metatype omc_Tpl_sourceInfo(threadData_t *threadData, modelica_string _inFileName, modelica_integer _inLineNum, modelica_integer _inColumnNum);
DLLExport
modelica_metatype boxptr_Tpl_sourceInfo(threadData_t *threadData, modelica_metatype _inFileName, modelica_metatype _inLineNum, modelica_metatype _inColumnNum);
static const MMC_DEFSTRUCTLIT(boxvar_lit_Tpl_sourceInfo,2,0) {(void*) boxptr_Tpl_sourceInfo,0}};
#define boxvar_Tpl_sourceInfo MMC_REFSTRUCTLIT(boxvar_lit_Tpl_sourceInfo)
DLLExport
void omc_Tpl_textFileConvertLines(threadData_t *threadData, modelica_metatype _inText, modelica_string _inFileName);
#define boxptr_Tpl_textFileConvertLines omc_Tpl_textFileConvertLines
static const MMC_DEFSTRUCTLIT(boxvar_lit_Tpl_textFileConvertLines,2,0) {(void*) boxptr_Tpl_textFileConvertLines,0}};
#define boxvar_Tpl_textFileConvertLines MMC_REFSTRUCTLIT(boxvar_lit_Tpl_textFileConvertLines)
DLLExport
void omc_Tpl_textFile(threadData_t *threadData, modelica_metatype _inText, modelica_string _inFileName);
#define boxptr_Tpl_textFile omc_Tpl_textFile
static const MMC_DEFSTRUCTLIT(boxvar_lit_Tpl_textFile,2,0) {(void*) boxptr_Tpl_textFile,0}};
#define boxvar_Tpl_textFile MMC_REFSTRUCTLIT(boxvar_lit_Tpl_textFile)
DLLExport
void omc_Tpl_tplNoret(threadData_t *threadData, modelica_fnptr _inFun, modelica_metatype _inArg);
#define boxptr_Tpl_tplNoret omc_Tpl_tplNoret
static const MMC_DEFSTRUCTLIT(boxvar_lit_Tpl_tplNoret,2,0) {(void*) boxptr_Tpl_tplNoret,0}};
#define boxvar_Tpl_tplNoret MMC_REFSTRUCTLIT(boxvar_lit_Tpl_tplNoret)
DLLExport
void omc_Tpl_tplNoret2(threadData_t *threadData, modelica_fnptr _inFun, modelica_metatype _inArg, modelica_metatype _inArg2);
#define boxptr_Tpl_tplNoret2 omc_Tpl_tplNoret2
static const MMC_DEFSTRUCTLIT(boxvar_lit_Tpl_tplNoret2,2,0) {(void*) boxptr_Tpl_tplNoret2,0}};
#define boxvar_Tpl_tplNoret2 MMC_REFSTRUCTLIT(boxvar_lit_Tpl_tplNoret2)
DLLExport
void omc_Tpl_tplNoret3(threadData_t *threadData, modelica_fnptr _inFun, modelica_metatype _inArg, modelica_metatype _inArg2, modelica_metatype _inArg3);
#define boxptr_Tpl_tplNoret3 omc_Tpl_tplNoret3
static const MMC_DEFSTRUCTLIT(boxvar_lit_Tpl_tplNoret3,2,0) {(void*) boxptr_Tpl_tplNoret3,0}};
#define boxvar_Tpl_tplNoret3 MMC_REFSTRUCTLIT(boxvar_lit_Tpl_tplNoret3)
DLLExport
void omc_Tpl_tplPrint3(threadData_t *threadData, modelica_fnptr _inFun, modelica_metatype _inArgA, modelica_metatype _inArgB, modelica_metatype _inArgC);
#define boxptr_Tpl_tplPrint3 omc_Tpl_tplPrint3
static const MMC_DEFSTRUCTLIT(boxvar_lit_Tpl_tplPrint3,2,0) {(void*) boxptr_Tpl_tplPrint3,0}};
#define boxvar_Tpl_tplPrint3 MMC_REFSTRUCTLIT(boxvar_lit_Tpl_tplPrint3)
DLLExport
void omc_Tpl_tplPrint2(threadData_t *threadData, modelica_fnptr _inFun, modelica_metatype _inArgA, modelica_metatype _inArgB);
#define boxptr_Tpl_tplPrint2 omc_Tpl_tplPrint2
static const MMC_DEFSTRUCTLIT(boxvar_lit_Tpl_tplPrint2,2,0) {(void*) boxptr_Tpl_tplPrint2,0}};
#define boxvar_Tpl_tplPrint2 MMC_REFSTRUCTLIT(boxvar_lit_Tpl_tplPrint2)
DLLExport
void omc_Tpl_tplPrint(threadData_t *threadData, modelica_fnptr _inFun, modelica_metatype _inArg);
#define boxptr_Tpl_tplPrint omc_Tpl_tplPrint
static const MMC_DEFSTRUCTLIT(boxvar_lit_Tpl_tplPrint,2,0) {(void*) boxptr_Tpl_tplPrint,0}};
#define boxvar_Tpl_tplPrint MMC_REFSTRUCTLIT(boxvar_lit_Tpl_tplPrint)
DLLExport
modelica_string omc_Tpl_tplString3(threadData_t *threadData, modelica_fnptr _inFun, modelica_metatype _inArgA, modelica_metatype _inArgB, modelica_metatype _inArgC);
#define boxptr_Tpl_tplString3 omc_Tpl_tplString3
static const MMC_DEFSTRUCTLIT(boxvar_lit_Tpl_tplString3,2,0) {(void*) boxptr_Tpl_tplString3,0}};
#define boxvar_Tpl_tplString3 MMC_REFSTRUCTLIT(boxvar_lit_Tpl_tplString3)
DLLExport
modelica_string omc_Tpl_tplString2(threadData_t *threadData, modelica_fnptr _inFun, modelica_metatype _inArgA, modelica_metatype _inArgB);
#define boxptr_Tpl_tplString2 omc_Tpl_tplString2
static const MMC_DEFSTRUCTLIT(boxvar_lit_Tpl_tplString2,2,0) {(void*) boxptr_Tpl_tplString2,0}};
#define boxvar_Tpl_tplString2 MMC_REFSTRUCTLIT(boxvar_lit_Tpl_tplString2)
DLLExport
modelica_string omc_Tpl_tplString(threadData_t *threadData, modelica_fnptr _inFun, modelica_metatype _inArg);
#define boxptr_Tpl_tplString omc_Tpl_tplString
static const MMC_DEFSTRUCTLIT(boxvar_lit_Tpl_tplString,2,0) {(void*) boxptr_Tpl_tplString,0}};
#define boxvar_Tpl_tplString MMC_REFSTRUCTLIT(boxvar_lit_Tpl_tplString)
DLLExport
modelica_metatype omc_Tpl_tplCallWithFailError3(threadData_t *threadData, modelica_fnptr _inFun, modelica_metatype _inArgA, modelica_metatype _inArgB, modelica_metatype _inArgC, modelica_metatype __omcQ_24in_5Ftxt);
#define boxptr_Tpl_tplCallWithFailError3 omc_Tpl_tplCallWithFailError3
static const MMC_DEFSTRUCTLIT(boxvar_lit_Tpl_tplCallWithFailError3,2,0) {(void*) boxptr_Tpl_tplCallWithFailError3,0}};
#define boxvar_Tpl_tplCallWithFailError3 MMC_REFSTRUCTLIT(boxvar_lit_Tpl_tplCallWithFailError3)
DLLExport
modelica_metatype omc_Tpl_tplCallWithFailError2(threadData_t *threadData, modelica_fnptr _inFun, modelica_metatype _inArgA, modelica_metatype _inArgB, modelica_metatype __omcQ_24in_5Ftxt);
#define boxptr_Tpl_tplCallWithFailError2 omc_Tpl_tplCallWithFailError2
static const MMC_DEFSTRUCTLIT(boxvar_lit_Tpl_tplCallWithFailError2,2,0) {(void*) boxptr_Tpl_tplCallWithFailError2,0}};
#define boxvar_Tpl_tplCallWithFailError2 MMC_REFSTRUCTLIT(boxvar_lit_Tpl_tplCallWithFailError2)
DLLExport
modelica_metatype omc_Tpl_tplCallWithFailError(threadData_t *threadData, modelica_fnptr _inFun, modelica_metatype _inArg, modelica_metatype __omcQ_24in_5Ftxt);
#define boxptr_Tpl_tplCallWithFailError omc_Tpl_tplCallWithFailError
static const MMC_DEFSTRUCTLIT(boxvar_lit_Tpl_tplCallWithFailError,2,0) {(void*) boxptr_Tpl_tplCallWithFailError,0}};
#define boxvar_Tpl_tplCallWithFailError MMC_REFSTRUCTLIT(boxvar_lit_Tpl_tplCallWithFailError)
DLLExport
modelica_metatype omc_Tpl_tplCallWithFailErrorNoArg(threadData_t *threadData, modelica_fnptr _inFun, modelica_metatype __omcQ_24in_5Ftxt);
#define boxptr_Tpl_tplCallWithFailErrorNoArg omc_Tpl_tplCallWithFailErrorNoArg
static const MMC_DEFSTRUCTLIT(boxvar_lit_Tpl_tplCallWithFailErrorNoArg,2,0) {(void*) boxptr_Tpl_tplCallWithFailErrorNoArg,0}};
#define boxvar_Tpl_tplCallWithFailErrorNoArg MMC_REFSTRUCTLIT(boxvar_lit_Tpl_tplCallWithFailErrorNoArg)
#define boxptr_Tpl_tplCallHandleErrors omc_Tpl_tplCallHandleErrors
DLLExport
void omc_Tpl_failIfTrue(threadData_t *threadData, modelica_boolean _istrue);
DLLExport
void boxptr_Tpl_failIfTrue(threadData_t *threadData, modelica_metatype _istrue);
static const MMC_DEFSTRUCTLIT(boxvar_lit_Tpl_failIfTrue,2,0) {(void*) boxptr_Tpl_failIfTrue,0}};
#define boxvar_Tpl_failIfTrue MMC_REFSTRUCTLIT(boxvar_lit_Tpl_failIfTrue)
DLLExport
modelica_string omc_Tpl_strTokString(threadData_t *threadData, modelica_metatype _inStringToken);
#define boxptr_Tpl_strTokString omc_Tpl_strTokString
static const MMC_DEFSTRUCTLIT(boxvar_lit_Tpl_strTokString,2,0) {(void*) boxptr_Tpl_strTokString,0}};
#define boxvar_Tpl_strTokString MMC_REFSTRUCTLIT(boxvar_lit_Tpl_strTokString)
DLLExport
modelica_metatype omc_Tpl_stringText(threadData_t *threadData, modelica_string _inString);
#define boxptr_Tpl_stringText omc_Tpl_stringText
static const MMC_DEFSTRUCTLIT(boxvar_lit_Tpl_stringText,2,0) {(void*) boxptr_Tpl_stringText,0}};
#define boxvar_Tpl_stringText MMC_REFSTRUCTLIT(boxvar_lit_Tpl_stringText)
DLLExport
modelica_metatype omc_Tpl_textStrTok(threadData_t *threadData, modelica_metatype _inText);
#define boxptr_Tpl_textStrTok omc_Tpl_textStrTok
static const MMC_DEFSTRUCTLIT(boxvar_lit_Tpl_textStrTok,2,0) {(void*) boxptr_Tpl_textStrTok,0}};
#define boxvar_Tpl_textStrTok MMC_REFSTRUCTLIT(boxvar_lit_Tpl_textStrTok)
DLLExport
modelica_metatype omc_Tpl_strTokText(threadData_t *threadData, modelica_metatype _inStringToken);
#define boxptr_Tpl_strTokText omc_Tpl_strTokText
static const MMC_DEFSTRUCTLIT(boxvar_lit_Tpl_strTokText,2,0) {(void*) boxptr_Tpl_strTokText,0}};
#define boxvar_Tpl_strTokText MMC_REFSTRUCTLIT(boxvar_lit_Tpl_strTokText)
DLLExport
void omc_Tpl_textStringBuf(threadData_t *threadData, modelica_metatype _inText);
#define boxptr_Tpl_textStringBuf omc_Tpl_textStringBuf
static const MMC_DEFSTRUCTLIT(boxvar_lit_Tpl_textStringBuf,2,0) {(void*) boxptr_Tpl_textStringBuf,0}};
#define boxvar_Tpl_textStringBuf MMC_REFSTRUCTLIT(boxvar_lit_Tpl_textStringBuf)
DLLExport
modelica_string omc_Tpl_textString(threadData_t *threadData, modelica_metatype _inText);
#define boxptr_Tpl_textString omc_Tpl_textString
static const MMC_DEFSTRUCTLIT(boxvar_lit_Tpl_textString,2,0) {(void*) boxptr_Tpl_textString,0}};
#define boxvar_Tpl_textString MMC_REFSTRUCTLIT(boxvar_lit_Tpl_textString)
DLLExport
modelica_integer omc_Tpl_getIteri__i0(threadData_t *threadData, modelica_metatype _inText);
DLLExport
modelica_metatype boxptr_Tpl_getIteri__i0(threadData_t *threadData, modelica_metatype _inText);
static const MMC_DEFSTRUCTLIT(boxvar_lit_Tpl_getIteri__i0,2,0) {(void*) boxptr_Tpl_getIteri__i0,0}};
#define boxvar_Tpl_getIteri__i0 MMC_REFSTRUCTLIT(boxvar_lit_Tpl_getIteri__i0)
DLLExport
modelica_metatype omc_Tpl_nextIter(threadData_t *threadData, modelica_metatype __omcQ_24in_5Ftxt);
#define boxptr_Tpl_nextIter omc_Tpl_nextIter
static const MMC_DEFSTRUCTLIT(boxvar_lit_Tpl_nextIter,2,0) {(void*) boxptr_Tpl_nextIter,0}};
#define boxvar_Tpl_nextIter MMC_REFSTRUCTLIT(boxvar_lit_Tpl_nextIter)
DLLExport
modelica_metatype omc_Tpl_popIter(threadData_t *threadData, modelica_metatype __omcQ_24in_5Ftxt);
#define boxptr_Tpl_popIter omc_Tpl_popIter
static const MMC_DEFSTRUCTLIT(boxvar_lit_Tpl_popIter,2,0) {(void*) boxptr_Tpl_popIter,0}};
#define boxvar_Tpl_popIter MMC_REFSTRUCTLIT(boxvar_lit_Tpl_popIter)
DLLExport
modelica_metatype omc_Tpl_pushIter(threadData_t *threadData, modelica_metatype __omcQ_24in_5Ftxt, modelica_metatype _inIterOptions);
#define boxptr_Tpl_pushIter omc_Tpl_pushIter
static const MMC_DEFSTRUCTLIT(boxvar_lit_Tpl_pushIter,2,0) {(void*) boxptr_Tpl_pushIter,0}};
#define boxvar_Tpl_pushIter MMC_REFSTRUCTLIT(boxvar_lit_Tpl_pushIter)
DLLExport
modelica_metatype omc_Tpl_popBlock(threadData_t *threadData, modelica_metatype __omcQ_24in_5Ftxt);
#define boxptr_Tpl_popBlock omc_Tpl_popBlock
static const MMC_DEFSTRUCTLIT(boxvar_lit_Tpl_popBlock,2,0) {(void*) boxptr_Tpl_popBlock,0}};
#define boxvar_Tpl_popBlock MMC_REFSTRUCTLIT(boxvar_lit_Tpl_popBlock)
DLLExport
modelica_metatype omc_Tpl_pushBlock(threadData_t *threadData, modelica_metatype __omcQ_24in_5Ftxt, modelica_metatype _inBlockType);
#define boxptr_Tpl_pushBlock omc_Tpl_pushBlock
static const MMC_DEFSTRUCTLIT(boxvar_lit_Tpl_pushBlock,2,0) {(void*) boxptr_Tpl_pushBlock,0}};
#define boxvar_Tpl_pushBlock MMC_REFSTRUCTLIT(boxvar_lit_Tpl_pushBlock)
DLLExport
modelica_metatype omc_Tpl_newLine(threadData_t *threadData, modelica_metatype _inText);
#define boxptr_Tpl_newLine omc_Tpl_newLine
static const MMC_DEFSTRUCTLIT(boxvar_lit_Tpl_newLine,2,0) {(void*) boxptr_Tpl_newLine,0}};
#define boxvar_Tpl_newLine MMC_REFSTRUCTLIT(boxvar_lit_Tpl_newLine)
DLLExport
modelica_metatype omc_Tpl_softNewLine(threadData_t *threadData, modelica_metatype _inText);
#define boxptr_Tpl_softNewLine omc_Tpl_softNewLine
static const MMC_DEFSTRUCTLIT(boxvar_lit_Tpl_softNewLine,2,0) {(void*) boxptr_Tpl_softNewLine,0}};
#define boxvar_Tpl_softNewLine MMC_REFSTRUCTLIT(boxvar_lit_Tpl_softNewLine)
#define boxptr_Tpl_writeChars omc_Tpl_writeChars
DLLExport
modelica_metatype omc_Tpl_writeText(threadData_t *threadData, modelica_metatype _inText, modelica_metatype _inTextToWrite);
#define boxptr_Tpl_writeText omc_Tpl_writeText
static const MMC_DEFSTRUCTLIT(boxvar_lit_Tpl_writeText,2,0) {(void*) boxptr_Tpl_writeText,0}};
#define boxvar_Tpl_writeText MMC_REFSTRUCTLIT(boxvar_lit_Tpl_writeText)
DLLExport
modelica_metatype omc_Tpl_writeTok(threadData_t *threadData, modelica_metatype _inText, modelica_metatype _inToken);
#define boxptr_Tpl_writeTok omc_Tpl_writeTok
static const MMC_DEFSTRUCTLIT(boxvar_lit_Tpl_writeTok,2,0) {(void*) boxptr_Tpl_writeTok,0}};
#define boxvar_Tpl_writeTok MMC_REFSTRUCTLIT(boxvar_lit_Tpl_writeTok)
DLLExport
modelica_metatype omc_Tpl_writeStr(threadData_t *threadData, modelica_metatype _inText, modelica_string _inStr);
#define boxptr_Tpl_writeStr omc_Tpl_writeStr
static const MMC_DEFSTRUCTLIT(boxvar_lit_Tpl_writeStr,2,0) {(void*) boxptr_Tpl_writeStr,0}};
#define boxvar_Tpl_writeStr MMC_REFSTRUCTLIT(boxvar_lit_Tpl_writeStr)
#ifdef __cplusplus
}
#endif
#endif
