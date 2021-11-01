#ifdef OMC_BASE_FILE
#define OMC_FILE OMC_BASE_FILE
#else
#define OMC_FILE "Tpl.c"
#endif
#include "omc_simulation_settings.h"
#include "Tpl.h"
#define _OMC_LIT0_data "Stack overflow:\n"
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT0,16,_OMC_LIT0_data);
#define _OMC_LIT0 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT0)
#define _OMC_LIT1_data "\n"
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT1,1,_OMC_LIT1_data);
#define _OMC_LIT1 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT1)
#define _OMC_LIT2_data "Tpl.mo"
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT2,6,_OMC_LIT2_data);
#define _OMC_LIT2 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT2)
static const MMC_DEFREALLIT(_OMC_LIT_STRUCT3_6,0.0);
#define _OMC_LIT3_6 MMC_REFREALLIT(_OMC_LIT_STRUCT3_6)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT3,8,3) {&SourceInfo_SOURCEINFO__desc,_OMC_LIT2,MMC_IMMEDIATE(MMC_TAGFIXNUM(0)),MMC_IMMEDIATE(MMC_TAGFIXNUM(2554)),MMC_IMMEDIATE(MMC_TAGFIXNUM(3)),MMC_IMMEDIATE(MMC_TAGFIXNUM(2554)),MMC_IMMEDIATE(MMC_TAGFIXNUM(102)),_OMC_LIT3_6}};
#define _OMC_LIT3 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT3)
#define _OMC_LIT4_data "susanDebug"
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT4,10,_OMC_LIT4_data);
#define _OMC_LIT4 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT4)
#define _OMC_LIT5_data "Makes Susan generate code using try/else to better debug which function broke the expected match semantics."
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT5,107,_OMC_LIT5_data);
#define _OMC_LIT5 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT5)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT6,2,3) {&Gettext_TranslatableContent_gettext__desc,_OMC_LIT5}};
#define _OMC_LIT6 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT6)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT7,5,3) {&Flags_DebugFlag_DEBUG__FLAG__desc,MMC_IMMEDIATE(MMC_TAGFIXNUM(165)),_OMC_LIT4,MMC_IMMEDIATE(MMC_TAGFIXNUM(0)),_OMC_LIT6}};
#define _OMC_LIT7 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT7)
#define _OMC_LIT8_data "tokFile got non-file text input"
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT8,31,_OMC_LIT8_data);
#define _OMC_LIT8 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT8)
static const MMC_DEFREALLIT(_OMC_LIT_STRUCT9_6,0.0);
#define _OMC_LIT9_6 MMC_REFREALLIT(_OMC_LIT_STRUCT9_6)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT9,8,3) {&SourceInfo_SOURCEINFO__desc,_OMC_LIT2,MMC_IMMEDIATE(MMC_TAGFIXNUM(0)),MMC_IMMEDIATE(MMC_TAGFIXNUM(2450)),MMC_IMMEDIATE(MMC_TAGFIXNUM(7)),MMC_IMMEDIATE(MMC_TAGFIXNUM(2450)),MMC_IMMEDIATE(MMC_TAGFIXNUM(78)),_OMC_LIT9_6}};
#define _OMC_LIT9 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT9)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT10,3,3) {&Tpl_Text_MEM__TEXT__desc,MMC_REFSTRUCTLIT(mmc_nil),MMC_REFSTRUCTLIT(mmc_nil)}};
#define _OMC_LIT10 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT10)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT11,1,5) {&ErrorTypes_MessageType_TRANSLATION__desc,}};
#define _OMC_LIT11 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT11)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT12,1,4) {&ErrorTypes_Severity_ERROR__desc,}};
#define _OMC_LIT12 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT12)
#define _OMC_LIT13_data "Template error: %s."
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT13,19,_OMC_LIT13_data);
#define _OMC_LIT13 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT13)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT14,2,3) {&Gettext_TranslatableContent_gettext__desc,_OMC_LIT13}};
#define _OMC_LIT14 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT14)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT15,5,3) {&ErrorTypes_Message_MESSAGE__desc,MMC_IMMEDIATE(MMC_TAGFIXNUM(7001)),_OMC_LIT11,_OMC_LIT12,_OMC_LIT14}};
#define _OMC_LIT15 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT15)
#define _OMC_LIT16_data "Template error: A template call failed (%s). One possible reason could be that a template imported function call failed (which should not happen for functions called from within template code; templates assert pure 'match'/non-failing semantics)."
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT16,246,_OMC_LIT16_data);
#define _OMC_LIT16 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT16)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT17,2,3) {&Gettext_TranslatableContent_gettext__desc,_OMC_LIT16}};
#define _OMC_LIT17 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT17)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT18,5,3) {&ErrorTypes_Message_MESSAGE__desc,MMC_IMMEDIATE(MMC_TAGFIXNUM(7014)),_OMC_LIT11,_OMC_LIT12,_OMC_LIT17}};
#define _OMC_LIT18 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT18)
static const MMC_DEFREALLIT(_OMC_LIT_STRUCT19,0.0);
#define _OMC_LIT19 MMC_REFREALLIT(_OMC_LIT_STRUCT19)
#define _OMC_LIT20_data ""
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT20,0,_OMC_LIT20_data);
#define _OMC_LIT20 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT20)
#define _OMC_LIT21_data "gendebugsymbols"
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT21,15,_OMC_LIT21_data);
#define _OMC_LIT21 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT21)
#define _OMC_LIT22_data "Generate code with debugging symbols."
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT22,37,_OMC_LIT22_data);
#define _OMC_LIT22 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT22)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT23,2,3) {&Gettext_TranslatableContent_gettext__desc,_OMC_LIT22}};
#define _OMC_LIT23 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT23)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT24,5,3) {&Flags_DebugFlag_DEBUG__FLAG__desc,MMC_IMMEDIATE(MMC_TAGFIXNUM(69)),_OMC_LIT21,MMC_IMMEDIATE(MMC_TAGFIXNUM(0)),_OMC_LIT23}};
#define _OMC_LIT24 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT24)
#define _OMC_LIT25_data "textFile "
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT25,9,_OMC_LIT25_data);
#define _OMC_LIT25 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT25)
#define _OMC_LIT26_data "\n    text:"
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT26,10,_OMC_LIT26_data);
#define _OMC_LIT26 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT26)
#define _OMC_LIT27_data "\n   write:"
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT27,10,_OMC_LIT27_data);
#define _OMC_LIT27 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT27)
#define _OMC_LIT28_data "tplPerfTimes"
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT28,12,_OMC_LIT28_data);
#define _OMC_LIT28 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT28)
#define _OMC_LIT29_data "Enables output of template performance data for rendering text to file."
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT29,71,_OMC_LIT29_data);
#define _OMC_LIT29 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT29)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT30,2,3) {&Gettext_TranslatableContent_gettext__desc,_OMC_LIT29}};
#define _OMC_LIT30 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT30)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT31,5,3) {&Flags_DebugFlag_DEBUG__FLAG__desc,MMC_IMMEDIATE(MMC_TAGFIXNUM(64)),_OMC_LIT28,MMC_IMMEDIATE(MMC_TAGFIXNUM(0)),_OMC_LIT30}};
#define _OMC_LIT31 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT31)
#define _OMC_LIT32_data "failtrace"
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT32,9,_OMC_LIT32_data);
#define _OMC_LIT32 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT32)
#define _OMC_LIT33_data "Sets whether to print a failtrace or not."
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT33,41,_OMC_LIT33_data);
#define _OMC_LIT33 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT33)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT34,2,3) {&Gettext_TranslatableContent_gettext__desc,_OMC_LIT33}};
#define _OMC_LIT34 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT34)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT35,5,3) {&Flags_DebugFlag_DEBUG__FLAG__desc,MMC_IMMEDIATE(MMC_TAGFIXNUM(1)),_OMC_LIT32,MMC_IMMEDIATE(MMC_TAGFIXNUM(0)),_OMC_LIT34}};
#define _OMC_LIT35 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT35)
#define _OMC_LIT36_data "-!!!Tpl.textFile failed - a system error ?\n"
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT36,43,_OMC_LIT36_data);
#define _OMC_LIT36 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT36)
#define _OMC_LIT37_data "Stack overflow when evaluating function:\n"
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT37,41,_OMC_LIT37_data);
#define _OMC_LIT37 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT37)
static const MMC_DEFREALLIT(_OMC_LIT_STRUCT38_6,0.0);
#define _OMC_LIT38_6 MMC_REFREALLIT(_OMC_LIT_STRUCT38_6)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT38,8,3) {&SourceInfo_SOURCEINFO__desc,_OMC_LIT2,MMC_IMMEDIATE(MMC_TAGFIXNUM(0)),MMC_IMMEDIATE(MMC_TAGFIXNUM(2027)),MMC_IMMEDIATE(MMC_TAGFIXNUM(8)),MMC_IMMEDIATE(MMC_TAGFIXNUM(2027)),MMC_IMMEDIATE(MMC_TAGFIXNUM(159)),_OMC_LIT38_6}};
#define _OMC_LIT38 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT38)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT39,2,4) {&Tpl_StringToken_ST__STRING__desc,_OMC_LIT20}};
#define _OMC_LIT39 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT39)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT40,1,3) {&Tpl_BlockType_BT__TEXT__desc,}};
#define _OMC_LIT40 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT40)
#define _OMC_LIT41_data "-!!!Tpl.textStrTok failed - incomplete text was passed to be converted.\n"
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT41,72,_OMC_LIT41_data);
#define _OMC_LIT41 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT41)
#define _OMC_LIT42_data "-!!!Tpl.iterAlignWrapString failed.\n"
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT42,36,_OMC_LIT42_data);
#define _OMC_LIT42 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT42)
#define _OMC_LIT43_data "-!!!Tpl.tokString failed.\n"
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT43,26,_OMC_LIT43_data);
#define _OMC_LIT43 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT43)
#define _OMC_LIT44_data "-!!!Tpl.stringListFile failed.\n"
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT44,31,_OMC_LIT44_data);
#define _OMC_LIT44 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT44)
#define _OMC_LIT45_data "-!!!Tpl.stringListString failed.\n"
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT45,33,_OMC_LIT45_data);
#define _OMC_LIT45 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT45)
#define _OMC_LIT46_data "-!!!Tpl.textString failed - a non-comlete text was given.\n"
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT46,58,_OMC_LIT46_data);
#define _OMC_LIT46 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT46)
#define _OMC_LIT47_data "-!!!Tpl.textString failed.\n"
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT47,27,_OMC_LIT47_data);
#define _OMC_LIT47 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT47)
#define _OMC_LIT48_data "-!!!Tpl.getIter_i0 failed - getIter_i0 was called in a non-iteration context ? \n"
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT48,80,_OMC_LIT48_data);
#define _OMC_LIT48 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT48)
#define _OMC_LIT49_data "-!!!Tpl.nextIter failed - nextIter was called in a non-iteration context?"
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT49,73,_OMC_LIT49_data);
#define _OMC_LIT49 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT49)
static const MMC_DEFREALLIT(_OMC_LIT_STRUCT50_6,0.0);
#define _OMC_LIT50_6 MMC_REFREALLIT(_OMC_LIT_STRUCT50_6)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT50,8,3) {&SourceInfo_SOURCEINFO__desc,_OMC_LIT2,MMC_IMMEDIATE(MMC_TAGFIXNUM(0)),MMC_IMMEDIATE(MMC_TAGFIXNUM(831)),MMC_IMMEDIATE(MMC_TAGFIXNUM(9)),MMC_IMMEDIATE(MMC_TAGFIXNUM(831)),MMC_IMMEDIATE(MMC_TAGFIXNUM(122)),_OMC_LIT50_6}};
#define _OMC_LIT50 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT50)
#define _OMC_LIT51_data "-!!!Tpl.popIter failed - probably pushIter and popIter are not well balanced or something was written between the last nextIter and popIter ?\n"
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT51,142,_OMC_LIT51_data);
#define _OMC_LIT51 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT51)
#define _OMC_LIT52_data "Tpl.mo FILE_TEXT does not support aligning or wrapping elements"
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT52,63,_OMC_LIT52_data);
#define _OMC_LIT52 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT52)
static const MMC_DEFREALLIT(_OMC_LIT_STRUCT53_6,0.0);
#define _OMC_LIT53_6 MMC_REFREALLIT(_OMC_LIT_STRUCT53_6)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT53,8,3) {&SourceInfo_SOURCEINFO__desc,_OMC_LIT2,MMC_IMMEDIATE(MMC_TAGFIXNUM(0)),MMC_IMMEDIATE(MMC_TAGFIXNUM(667)),MMC_IMMEDIATE(MMC_TAGFIXNUM(15)),MMC_IMMEDIATE(MMC_TAGFIXNUM(667)),MMC_IMMEDIATE(MMC_TAGFIXNUM(118)),_OMC_LIT53_6}};
#define _OMC_LIT53 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT53)
#define _OMC_LIT54_data "-!!!Tpl.pushIter failed \n"
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT54,25,_OMC_LIT54_data);
#define _OMC_LIT54 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT54)
#define _OMC_LIT55_data "-!!!Tpl.popBlock failed - probably pushBlock and popBlock are not well balanced !\n"
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT55,82,_OMC_LIT55_data);
#define _OMC_LIT55 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT55)
#define _OMC_LIT56_data "-!!!Tpl.pushBlock failed \n"
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT56,26,_OMC_LIT56_data);
#define _OMC_LIT56 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT56)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT57,1,3) {&Tpl_StringToken_ST__NEW__LINE__desc,}};
#define _OMC_LIT57 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT57)
#define _OMC_LIT58_data "-!!!Tpl.softNL failed. \n"
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT58,24,_OMC_LIT58_data);
#define _OMC_LIT58 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT58)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT59,2,1) {_OMC_LIT1,MMC_REFSTRUCTLIT(mmc_nil)}};
#define _OMC_LIT59 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT59)
#define _OMC_LIT60_data "-!!!Tpl.writeChars failed.\n"
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT60,27,_OMC_LIT60_data);
#define _OMC_LIT60 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT60)
#define _OMC_LIT61_data "-!!!Tpl.writeText failed - incomplete text was passed to be written\n"
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT61,68,_OMC_LIT61_data);
#define _OMC_LIT61 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT61)
#include "util/modelica.h"
#include "Tpl_includes.h"
#if !defined(PROTECTED_FUNCTION_STATIC)
#define PROTECTED_FUNCTION_STATIC
#endif
PROTECTED_FUNCTION_STATIC void omc_Tpl_handleTok(threadData_t *threadData, modelica_metatype _txt);
static const MMC_DEFSTRUCTLIT(boxvar_lit_Tpl_handleTok,2,0) {(void*) boxptr_Tpl_handleTok,0}};
#define boxvar_Tpl_handleTok MMC_REFSTRUCTLIT(boxvar_lit_Tpl_handleTok)
PROTECTED_FUNCTION_STATIC modelica_integer omc_Tpl_textFileTell(threadData_t *threadData, modelica_metatype _inText);
PROTECTED_FUNCTION_STATIC modelica_metatype boxptr_Tpl_textFileTell(threadData_t *threadData, modelica_metatype _inText);
static const MMC_DEFSTRUCTLIT(boxvar_lit_Tpl_textFileTell,2,0) {(void*) boxptr_Tpl_textFileTell,0}};
#define boxvar_Tpl_textFileTell MMC_REFSTRUCTLIT(boxvar_lit_Tpl_textFileTell)
PROTECTED_FUNCTION_STATIC void omc_Tpl_newlineFile(threadData_t *threadData, modelica_metatype _inText);
static const MMC_DEFSTRUCTLIT(boxvar_lit_Tpl_newlineFile,2,0) {(void*) boxptr_Tpl_newlineFile,0}};
#define boxvar_Tpl_newlineFile MMC_REFSTRUCTLIT(boxvar_lit_Tpl_newlineFile)
PROTECTED_FUNCTION_STATIC void omc_Tpl_stringFile(threadData_t *threadData, modelica_metatype _inText, modelica_string _str, modelica_boolean _line, modelica_boolean _recurseSeparator);
PROTECTED_FUNCTION_STATIC void boxptr_Tpl_stringFile(threadData_t *threadData, modelica_metatype _inText, modelica_metatype _str, modelica_metatype _line, modelica_metatype _recurseSeparator);
static const MMC_DEFSTRUCTLIT(boxvar_lit_Tpl_stringFile,2,0) {(void*) boxptr_Tpl_stringFile,0}};
#define boxvar_Tpl_stringFile MMC_REFSTRUCTLIT(boxvar_lit_Tpl_stringFile)
PROTECTED_FUNCTION_STATIC modelica_metatype omc_Tpl_getTextOpaqueFile(threadData_t *threadData, modelica_metatype _text);
static const MMC_DEFSTRUCTLIT(boxvar_lit_Tpl_getTextOpaqueFile,2,0) {(void*) boxptr_Tpl_getTextOpaqueFile,0}};
#define boxvar_Tpl_getTextOpaqueFile MMC_REFSTRUCTLIT(boxvar_lit_Tpl_getTextOpaqueFile)
PROTECTED_FUNCTION_STATIC void omc_Tpl_addTemplateErrorFunc(threadData_t *threadData, modelica_metatype _func);
static const MMC_DEFSTRUCTLIT(boxvar_lit_Tpl_addTemplateErrorFunc,2,0) {(void*) boxptr_Tpl_addTemplateErrorFunc,0}};
#define boxvar_Tpl_addTemplateErrorFunc MMC_REFSTRUCTLIT(boxvar_lit_Tpl_addTemplateErrorFunc)
PROTECTED_FUNCTION_STATIC modelica_metatype omc_Tpl_tplCallHandleErrors(threadData_t *threadData, modelica_fnptr _inFun, modelica_metatype __omcQ_24in_5Ftxt);
static const MMC_DEFSTRUCTLIT(boxvar_lit_Tpl_tplCallHandleErrors,2,0) {(void*) boxptr_Tpl_tplCallHandleErrors,0}};
#define boxvar_Tpl_tplCallHandleErrors MMC_REFSTRUCTLIT(boxvar_lit_Tpl_tplCallHandleErrors)
PROTECTED_FUNCTION_STATIC modelica_integer omc_Tpl_tryWrapFile(threadData_t *threadData, modelica_complex _file, modelica_integer _inWrapWidth, modelica_metatype _inWrapSeparator, modelica_integer _inActualPositionOnLine, modelica_boolean _inAtStartOfLine, modelica_integer _inAfterNewLineIndent, modelica_boolean *out_outAtStartOfLine, modelica_integer *out_outAfterNewLineIndent);
PROTECTED_FUNCTION_STATIC modelica_metatype boxptr_Tpl_tryWrapFile(threadData_t *threadData, modelica_metatype _file, modelica_metatype _inWrapWidth, modelica_metatype _inWrapSeparator, modelica_metatype _inActualPositionOnLine, modelica_metatype _inAtStartOfLine, modelica_metatype _inAfterNewLineIndent, modelica_metatype *out_outAtStartOfLine, modelica_metatype *out_outAfterNewLineIndent);
static const MMC_DEFSTRUCTLIT(boxvar_lit_Tpl_tryWrapFile,2,0) {(void*) boxptr_Tpl_tryWrapFile,0}};
#define boxvar_Tpl_tryWrapFile MMC_REFSTRUCTLIT(boxvar_lit_Tpl_tryWrapFile)
PROTECTED_FUNCTION_STATIC modelica_integer omc_Tpl_iterAlignWrapFile(threadData_t *threadData, modelica_complex _file, modelica_metatype _inTokens, modelica_integer _inActualIndex, modelica_integer _inAlignNum, modelica_metatype _inAlignSeparator, modelica_integer _inWrapWidth, modelica_metatype _inWrapSeparator, modelica_integer _inActualPositionOnLine, modelica_boolean _inAtStartOfLine, modelica_integer _inAfterNewLineIndent, modelica_boolean *out_outAtStartOfLine);
PROTECTED_FUNCTION_STATIC modelica_metatype boxptr_Tpl_iterAlignWrapFile(threadData_t *threadData, modelica_metatype _file, modelica_metatype _inTokens, modelica_metatype _inActualIndex, modelica_metatype _inAlignNum, modelica_metatype _inAlignSeparator, modelica_metatype _inWrapWidth, modelica_metatype _inWrapSeparator, modelica_metatype _inActualPositionOnLine, modelica_metatype _inAtStartOfLine, modelica_metatype _inAfterNewLineIndent, modelica_metatype *out_outAtStartOfLine);
static const MMC_DEFSTRUCTLIT(boxvar_lit_Tpl_iterAlignWrapFile,2,0) {(void*) boxptr_Tpl_iterAlignWrapFile,0}};
#define boxvar_Tpl_iterAlignWrapFile MMC_REFSTRUCTLIT(boxvar_lit_Tpl_iterAlignWrapFile)
PROTECTED_FUNCTION_STATIC modelica_integer omc_Tpl_iterSeparatorAlignWrapFile(threadData_t *threadData, modelica_complex _file, modelica_metatype _inTokens, modelica_metatype _inSeparator, modelica_integer _inActualIndex, modelica_integer _inAlignNum, modelica_metatype _inAlignSeparator, modelica_integer _inWrapWidth, modelica_metatype _inWrapSeparator, modelica_integer _inActualPositionOnLine, modelica_boolean _inAtStartOfLine, modelica_integer _inAfterNewLineIndent, modelica_boolean *out_outAtStartOfLine);
PROTECTED_FUNCTION_STATIC modelica_metatype boxptr_Tpl_iterSeparatorAlignWrapFile(threadData_t *threadData, modelica_metatype _file, modelica_metatype _inTokens, modelica_metatype _inSeparator, modelica_metatype _inActualIndex, modelica_metatype _inAlignNum, modelica_metatype _inAlignSeparator, modelica_metatype _inWrapWidth, modelica_metatype _inWrapSeparator, modelica_metatype _inActualPositionOnLine, modelica_metatype _inAtStartOfLine, modelica_metatype _inAfterNewLineIndent, modelica_metatype *out_outAtStartOfLine);
static const MMC_DEFSTRUCTLIT(boxvar_lit_Tpl_iterSeparatorAlignWrapFile,2,0) {(void*) boxptr_Tpl_iterSeparatorAlignWrapFile,0}};
#define boxvar_Tpl_iterSeparatorAlignWrapFile MMC_REFSTRUCTLIT(boxvar_lit_Tpl_iterSeparatorAlignWrapFile)
PROTECTED_FUNCTION_STATIC modelica_integer omc_Tpl_iterSeparatorFile(threadData_t *threadData, modelica_complex _file, modelica_metatype _inTokens, modelica_metatype _inSeparator, modelica_integer _inActualPositionOnLine, modelica_boolean _inAtStartOfLine, modelica_integer _inAfterNewLineIndent, modelica_boolean *out_outAtStartOfLine);
PROTECTED_FUNCTION_STATIC modelica_metatype boxptr_Tpl_iterSeparatorFile(threadData_t *threadData, modelica_metatype _file, modelica_metatype _inTokens, modelica_metatype _inSeparator, modelica_metatype _inActualPositionOnLine, modelica_metatype _inAtStartOfLine, modelica_metatype _inAfterNewLineIndent, modelica_metatype *out_outAtStartOfLine);
static const MMC_DEFSTRUCTLIT(boxvar_lit_Tpl_iterSeparatorFile,2,0) {(void*) boxptr_Tpl_iterSeparatorFile,0}};
#define boxvar_Tpl_iterSeparatorFile MMC_REFSTRUCTLIT(boxvar_lit_Tpl_iterSeparatorFile)
PROTECTED_FUNCTION_STATIC modelica_integer omc_Tpl_blockFile(threadData_t *threadData, modelica_complex _file, modelica_metatype _inBlockType, modelica_metatype _inTokens, modelica_integer _inActualPositionOnLine, modelica_boolean _inAtStartOfLine, modelica_integer _inAfterNewLineIndent, modelica_boolean *out_outAtStartOfLine, modelica_integer *out_outAfterNewLineIndent);
PROTECTED_FUNCTION_STATIC modelica_metatype boxptr_Tpl_blockFile(threadData_t *threadData, modelica_metatype _file, modelica_metatype _inBlockType, modelica_metatype _inTokens, modelica_metatype _inActualPositionOnLine, modelica_metatype _inAtStartOfLine, modelica_metatype _inAfterNewLineIndent, modelica_metatype *out_outAtStartOfLine, modelica_metatype *out_outAfterNewLineIndent);
static const MMC_DEFSTRUCTLIT(boxvar_lit_Tpl_blockFile,2,0) {(void*) boxptr_Tpl_blockFile,0}};
#define boxvar_Tpl_blockFile MMC_REFSTRUCTLIT(boxvar_lit_Tpl_blockFile)
PROTECTED_FUNCTION_STATIC modelica_integer omc_Tpl_tryWrapString(threadData_t *threadData, modelica_integer _inWrapWidth, modelica_metatype _inWrapSeparator, modelica_integer _inActualPositionOnLine, modelica_boolean _inAtStartOfLine, modelica_integer _inAfterNewLineIndent, modelica_boolean *out_outAtStartOfLine, modelica_integer *out_outAfterNewLineIndent);
PROTECTED_FUNCTION_STATIC modelica_metatype boxptr_Tpl_tryWrapString(threadData_t *threadData, modelica_metatype _inWrapWidth, modelica_metatype _inWrapSeparator, modelica_metatype _inActualPositionOnLine, modelica_metatype _inAtStartOfLine, modelica_metatype _inAfterNewLineIndent, modelica_metatype *out_outAtStartOfLine, modelica_metatype *out_outAfterNewLineIndent);
static const MMC_DEFSTRUCTLIT(boxvar_lit_Tpl_tryWrapString,2,0) {(void*) boxptr_Tpl_tryWrapString,0}};
#define boxvar_Tpl_tryWrapString MMC_REFSTRUCTLIT(boxvar_lit_Tpl_tryWrapString)
PROTECTED_FUNCTION_STATIC modelica_integer omc_Tpl_iterAlignWrapString(threadData_t *threadData, modelica_metatype _inTokens, modelica_integer _inActualIndex, modelica_integer _inAlignNum, modelica_metatype _inAlignSeparator, modelica_integer _inWrapWidth, modelica_metatype _inWrapSeparator, modelica_integer _inActualPositionOnLine, modelica_boolean _inAtStartOfLine, modelica_integer _inAfterNewLineIndent, modelica_boolean *out_outAtStartOfLine);
PROTECTED_FUNCTION_STATIC modelica_metatype boxptr_Tpl_iterAlignWrapString(threadData_t *threadData, modelica_metatype _inTokens, modelica_metatype _inActualIndex, modelica_metatype _inAlignNum, modelica_metatype _inAlignSeparator, modelica_metatype _inWrapWidth, modelica_metatype _inWrapSeparator, modelica_metatype _inActualPositionOnLine, modelica_metatype _inAtStartOfLine, modelica_metatype _inAfterNewLineIndent, modelica_metatype *out_outAtStartOfLine);
static const MMC_DEFSTRUCTLIT(boxvar_lit_Tpl_iterAlignWrapString,2,0) {(void*) boxptr_Tpl_iterAlignWrapString,0}};
#define boxvar_Tpl_iterAlignWrapString MMC_REFSTRUCTLIT(boxvar_lit_Tpl_iterAlignWrapString)
PROTECTED_FUNCTION_STATIC modelica_integer omc_Tpl_iterSeparatorAlignWrapString(threadData_t *threadData, modelica_metatype _inTokens, modelica_metatype _inSeparator, modelica_integer _inActualIndex, modelica_integer _inAlignNum, modelica_metatype _inAlignSeparator, modelica_integer _inWrapWidth, modelica_metatype _inWrapSeparator, modelica_integer _inActualPositionOnLine, modelica_boolean _inAtStartOfLine, modelica_integer _inAfterNewLineIndent, modelica_boolean *out_outAtStartOfLine);
PROTECTED_FUNCTION_STATIC modelica_metatype boxptr_Tpl_iterSeparatorAlignWrapString(threadData_t *threadData, modelica_metatype _inTokens, modelica_metatype _inSeparator, modelica_metatype _inActualIndex, modelica_metatype _inAlignNum, modelica_metatype _inAlignSeparator, modelica_metatype _inWrapWidth, modelica_metatype _inWrapSeparator, modelica_metatype _inActualPositionOnLine, modelica_metatype _inAtStartOfLine, modelica_metatype _inAfterNewLineIndent, modelica_metatype *out_outAtStartOfLine);
static const MMC_DEFSTRUCTLIT(boxvar_lit_Tpl_iterSeparatorAlignWrapString,2,0) {(void*) boxptr_Tpl_iterSeparatorAlignWrapString,0}};
#define boxvar_Tpl_iterSeparatorAlignWrapString MMC_REFSTRUCTLIT(boxvar_lit_Tpl_iterSeparatorAlignWrapString)
PROTECTED_FUNCTION_STATIC modelica_integer omc_Tpl_iterSeparatorString(threadData_t *threadData, modelica_metatype _inTokens, modelica_metatype _inSeparator, modelica_integer _inActualPositionOnLine, modelica_boolean _inAtStartOfLine, modelica_integer _inAfterNewLineIndent, modelica_boolean *out_outAtStartOfLine);
PROTECTED_FUNCTION_STATIC modelica_metatype boxptr_Tpl_iterSeparatorString(threadData_t *threadData, modelica_metatype _inTokens, modelica_metatype _inSeparator, modelica_metatype _inActualPositionOnLine, modelica_metatype _inAtStartOfLine, modelica_metatype _inAfterNewLineIndent, modelica_metatype *out_outAtStartOfLine);
static const MMC_DEFSTRUCTLIT(boxvar_lit_Tpl_iterSeparatorString,2,0) {(void*) boxptr_Tpl_iterSeparatorString,0}};
#define boxvar_Tpl_iterSeparatorString MMC_REFSTRUCTLIT(boxvar_lit_Tpl_iterSeparatorString)
PROTECTED_FUNCTION_STATIC modelica_integer omc_Tpl_blockString(threadData_t *threadData, modelica_metatype _inBlockType, modelica_metatype _inTokens, modelica_integer _inActualPositionOnLine, modelica_boolean _inAtStartOfLine, modelica_integer _inAfterNewLineIndent, modelica_boolean *out_outAtStartOfLine, modelica_integer *out_outAfterNewLineIndent);
PROTECTED_FUNCTION_STATIC modelica_metatype boxptr_Tpl_blockString(threadData_t *threadData, modelica_metatype _inBlockType, modelica_metatype _inTokens, modelica_metatype _inActualPositionOnLine, modelica_metatype _inAtStartOfLine, modelica_metatype _inAfterNewLineIndent, modelica_metatype *out_outAtStartOfLine, modelica_metatype *out_outAfterNewLineIndent);
static const MMC_DEFSTRUCTLIT(boxvar_lit_Tpl_blockString,2,0) {(void*) boxptr_Tpl_blockString,0}};
#define boxvar_Tpl_blockString MMC_REFSTRUCTLIT(boxvar_lit_Tpl_blockString)
PROTECTED_FUNCTION_STATIC modelica_integer omc_Tpl_stringListFile(threadData_t *threadData, modelica_complex _file, modelica_metatype _inStringList, modelica_integer __omcQ_24in_5Fnchars, modelica_boolean __omcQ_24in_5Fisstart, modelica_integer __omcQ_24in_5Faind, modelica_boolean *out_isstart, modelica_integer *out_aind);
PROTECTED_FUNCTION_STATIC modelica_metatype boxptr_Tpl_stringListFile(threadData_t *threadData, modelica_metatype _file, modelica_metatype _inStringList, modelica_metatype __omcQ_24in_5Fnchars, modelica_metatype __omcQ_24in_5Fisstart, modelica_metatype __omcQ_24in_5Faind, modelica_metatype *out_isstart, modelica_metatype *out_aind);
static const MMC_DEFSTRUCTLIT(boxvar_lit_Tpl_stringListFile,2,0) {(void*) boxptr_Tpl_stringListFile,0}};
#define boxvar_Tpl_stringListFile MMC_REFSTRUCTLIT(boxvar_lit_Tpl_stringListFile)
PROTECTED_FUNCTION_STATIC modelica_integer omc_Tpl_stringListString(threadData_t *threadData, modelica_metatype _inStringList, modelica_integer _inActualPositionOnLine, modelica_boolean _inAtStartOfLine, modelica_integer _inAfterNewLineIndent, modelica_boolean *out_outAtStartOfLine, modelica_integer *out_outAfterNewLineIndent);
PROTECTED_FUNCTION_STATIC modelica_metatype boxptr_Tpl_stringListString(threadData_t *threadData, modelica_metatype _inStringList, modelica_metatype _inActualPositionOnLine, modelica_metatype _inAtStartOfLine, modelica_metatype _inAfterNewLineIndent, modelica_metatype *out_outAtStartOfLine, modelica_metatype *out_outAfterNewLineIndent);
static const MMC_DEFSTRUCTLIT(boxvar_lit_Tpl_stringListString,2,0) {(void*) boxptr_Tpl_stringListString,0}};
#define boxvar_Tpl_stringListString MMC_REFSTRUCTLIT(boxvar_lit_Tpl_stringListString)
PROTECTED_FUNCTION_STATIC modelica_integer omc_Tpl_tokFile(threadData_t *threadData, modelica_complex _file, modelica_metatype _inStringToken, modelica_integer __omcQ_24in_5Fnchars, modelica_boolean __omcQ_24in_5Fisstart, modelica_integer __omcQ_24in_5Faind, modelica_boolean *out_isstart, modelica_integer *out_aind);
PROTECTED_FUNCTION_STATIC modelica_metatype boxptr_Tpl_tokFile(threadData_t *threadData, modelica_metatype _file, modelica_metatype _inStringToken, modelica_metatype __omcQ_24in_5Fnchars, modelica_metatype __omcQ_24in_5Fisstart, modelica_metatype __omcQ_24in_5Faind, modelica_metatype *out_isstart, modelica_metatype *out_aind);
static const MMC_DEFSTRUCTLIT(boxvar_lit_Tpl_tokFile,2,0) {(void*) boxptr_Tpl_tokFile,0}};
#define boxvar_Tpl_tokFile MMC_REFSTRUCTLIT(boxvar_lit_Tpl_tokFile)
PROTECTED_FUNCTION_STATIC void omc_Tpl_tokFileText(threadData_t *threadData, modelica_metatype _inText, modelica_metatype _inStringToken, modelica_boolean _doHandleTok);
PROTECTED_FUNCTION_STATIC void boxptr_Tpl_tokFileText(threadData_t *threadData, modelica_metatype _inText, modelica_metatype _inStringToken, modelica_metatype _doHandleTok);
static const MMC_DEFSTRUCTLIT(boxvar_lit_Tpl_tokFileText,2,0) {(void*) boxptr_Tpl_tokFileText,0}};
#define boxvar_Tpl_tokFileText MMC_REFSTRUCTLIT(boxvar_lit_Tpl_tokFileText)
PROTECTED_FUNCTION_STATIC modelica_integer omc_Tpl_tokString(threadData_t *threadData, modelica_metatype _inStringToken, modelica_integer _inActualPositionOnLine, modelica_boolean _inAtStartOfLine, modelica_integer _inAfterNewLineIndent, modelica_boolean *out_outAtStartOfLine, modelica_integer *out_outAfterNewLineIndent);
PROTECTED_FUNCTION_STATIC modelica_metatype boxptr_Tpl_tokString(threadData_t *threadData, modelica_metatype _inStringToken, modelica_metatype _inActualPositionOnLine, modelica_metatype _inAtStartOfLine, modelica_metatype _inAfterNewLineIndent, modelica_metatype *out_outAtStartOfLine, modelica_metatype *out_outAfterNewLineIndent);
static const MMC_DEFSTRUCTLIT(boxvar_lit_Tpl_tokString,2,0) {(void*) boxptr_Tpl_tokString,0}};
#define boxvar_Tpl_tokString MMC_REFSTRUCTLIT(boxvar_lit_Tpl_tokString)
PROTECTED_FUNCTION_STATIC modelica_integer omc_Tpl_tokensFile(threadData_t *threadData, modelica_complex _file, modelica_metatype _inTokens, modelica_integer __omcQ_24in_5FactualPositionOnLine, modelica_boolean __omcQ_24in_5FatStartOfLine, modelica_integer __omcQ_24in_5FafterNewLineIndent, modelica_boolean *out_atStartOfLine, modelica_integer *out_afterNewLineIndent);
PROTECTED_FUNCTION_STATIC modelica_metatype boxptr_Tpl_tokensFile(threadData_t *threadData, modelica_metatype _file, modelica_metatype _inTokens, modelica_metatype __omcQ_24in_5FactualPositionOnLine, modelica_metatype __omcQ_24in_5FatStartOfLine, modelica_metatype __omcQ_24in_5FafterNewLineIndent, modelica_metatype *out_atStartOfLine, modelica_metatype *out_afterNewLineIndent);
static const MMC_DEFSTRUCTLIT(boxvar_lit_Tpl_tokensFile,2,0) {(void*) boxptr_Tpl_tokensFile,0}};
#define boxvar_Tpl_tokensFile MMC_REFSTRUCTLIT(boxvar_lit_Tpl_tokensFile)
PROTECTED_FUNCTION_STATIC modelica_integer omc_Tpl_tokensString(threadData_t *threadData, modelica_metatype _inTokens, modelica_integer __omcQ_24in_5FactualPositionOnLine, modelica_boolean __omcQ_24in_5FatStartOfLine, modelica_integer __omcQ_24in_5FafterNewLineIndent, modelica_boolean *out_atStartOfLine, modelica_integer *out_afterNewLineIndent);
PROTECTED_FUNCTION_STATIC modelica_metatype boxptr_Tpl_tokensString(threadData_t *threadData, modelica_metatype _inTokens, modelica_metatype __omcQ_24in_5FactualPositionOnLine, modelica_metatype __omcQ_24in_5FatStartOfLine, modelica_metatype __omcQ_24in_5FafterNewLineIndent, modelica_metatype *out_atStartOfLine, modelica_metatype *out_afterNewLineIndent);
static const MMC_DEFSTRUCTLIT(boxvar_lit_Tpl_tokensString,2,0) {(void*) boxptr_Tpl_tokensString,0}};
#define boxvar_Tpl_tokensString MMC_REFSTRUCTLIT(boxvar_lit_Tpl_tokensString)
PROTECTED_FUNCTION_STATIC modelica_boolean omc_Tpl_isAtStartOfLineTok(threadData_t *threadData, modelica_metatype _inTok);
PROTECTED_FUNCTION_STATIC modelica_metatype boxptr_Tpl_isAtStartOfLineTok(threadData_t *threadData, modelica_metatype _inTok);
static const MMC_DEFSTRUCTLIT(boxvar_lit_Tpl_isAtStartOfLineTok,2,0) {(void*) boxptr_Tpl_isAtStartOfLineTok,0}};
#define boxvar_Tpl_isAtStartOfLineTok MMC_REFSTRUCTLIT(boxvar_lit_Tpl_isAtStartOfLineTok)
PROTECTED_FUNCTION_STATIC modelica_boolean omc_Tpl_isAtStartOfLine(threadData_t *threadData, modelica_metatype _text);
PROTECTED_FUNCTION_STATIC modelica_metatype boxptr_Tpl_isAtStartOfLine(threadData_t *threadData, modelica_metatype _text);
static const MMC_DEFSTRUCTLIT(boxvar_lit_Tpl_isAtStartOfLine,2,0) {(void*) boxptr_Tpl_isAtStartOfLine,0}};
#define boxvar_Tpl_isAtStartOfLine MMC_REFSTRUCTLIT(boxvar_lit_Tpl_isAtStartOfLine)
PROTECTED_FUNCTION_STATIC modelica_metatype omc_Tpl_takeLineOrString(threadData_t *threadData, modelica_metatype _inChars, modelica_metatype *out_outRestChars, modelica_boolean *out_outIsLine);
PROTECTED_FUNCTION_STATIC modelica_metatype boxptr_Tpl_takeLineOrString(threadData_t *threadData, modelica_metatype _inChars, modelica_metatype *out_outRestChars, modelica_metatype *out_outIsLine);
static const MMC_DEFSTRUCTLIT(boxvar_lit_Tpl_takeLineOrString,2,0) {(void*) boxptr_Tpl_takeLineOrString,0}};
#define boxvar_Tpl_takeLineOrString MMC_REFSTRUCTLIT(boxvar_lit_Tpl_takeLineOrString)
PROTECTED_FUNCTION_STATIC modelica_metatype omc_Tpl_writeLineOrStr(threadData_t *threadData, modelica_metatype _inText, modelica_string _inStr, modelica_boolean _inIsLine);
PROTECTED_FUNCTION_STATIC modelica_metatype boxptr_Tpl_writeLineOrStr(threadData_t *threadData, modelica_metatype _inText, modelica_metatype _inStr, modelica_metatype _inIsLine);
static const MMC_DEFSTRUCTLIT(boxvar_lit_Tpl_writeLineOrStr,2,0) {(void*) boxptr_Tpl_writeLineOrStr,0}};
#define boxvar_Tpl_writeLineOrStr MMC_REFSTRUCTLIT(boxvar_lit_Tpl_writeLineOrStr)
PROTECTED_FUNCTION_STATIC modelica_metatype omc_Tpl_writeChars(threadData_t *threadData, modelica_metatype _inText, modelica_metatype _inChars);
static const MMC_DEFSTRUCTLIT(boxvar_lit_Tpl_writeChars,2,0) {(void*) boxptr_Tpl_writeChars,0}};
#define boxvar_Tpl_writeChars MMC_REFSTRUCTLIT(boxvar_lit_Tpl_writeChars)
DLLExport
void omc_Tpl_fakeStackOverflow(threadData_t *threadData)
{
modelica_metatype tmpMeta1;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
tmpMeta1 = stringAppend(_OMC_LIT0,omc_StackOverflow_generateReadableMessage(threadData, ((modelica_integer) 1000), ((modelica_integer) 4), _OMC_LIT1));
omc_Error_addInternalError(threadData, tmpMeta1, _OMC_LIT3);
omc_StackOverflow_triggerStackOverflow(threadData);
_return: OMC_LABEL_UNUSED
return;
}
DLLExport
modelica_boolean omc_Tpl_debugSusan(threadData_t *threadData)
{
modelica_boolean _b;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
_b = omc_Flags_isSet(threadData, _OMC_LIT7);
_return: OMC_LABEL_UNUSED
return _b;
}
modelica_metatype boxptr_Tpl_debugSusan(threadData_t *threadData)
{
modelica_boolean _b;
modelica_metatype out_b;
_b = omc_Tpl_debugSusan(threadData);
out_b = mmc_mk_icon(_b);
return out_b;
}
PROTECTED_FUNCTION_STATIC void omc_Tpl_handleTok(threadData_t *threadData, modelica_metatype _txt)
{
modelica_metatype _septok = NULL;
modelica_metatype _aseptok = NULL;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
modelica_metatype tmp3_1;
tmp3_1 = _txt;
{
volatile mmc_switch_type tmp3;
int tmp4;
tmp3 = 0;
for (; tmp3 < 1; tmp3++) {
switch (MMC_SWITCH_CAST(tmp3)) {
case 0: {
if (mmc__uniontype__metarecord__typedef__equal(tmp3_1,1,5) == 0) goto tmp2_end;
{
modelica_metatype tmp7_1;
tmp7_1 = arrayGet((MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_txt), 6))), ((modelica_integer) 1));
{
volatile mmc_switch_type tmp7;
int tmp8;
tmp7 = 0;
for (; tmp7 < 2; tmp7++) {
switch (MMC_SWITCH_CAST(tmp7)) {
case 0: {
modelica_metatype tmpMeta9;
modelica_metatype tmpMeta10;
modelica_metatype tmpMeta11;
modelica_metatype tmpMeta12;
if (listEmpty(tmp7_1)) goto tmp6_end;
tmpMeta9 = MMC_CAR(tmp7_1);
tmpMeta10 = MMC_CDR(tmp7_1);
tmpMeta11 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta9), 2));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta11,5,2) == 0) goto tmp6_end;
tmpMeta12 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta9), 7));
_aseptok = tmpMeta12;
{
modelica_metatype tmp15_1;
tmp15_1 = arrayGet(_aseptok, ((modelica_integer) 1));
{
volatile mmc_switch_type tmp15;
int tmp16;
tmp15 = 0;
for (; tmp15 < 2; tmp15++) {
switch (MMC_SWITCH_CAST(tmp15)) {
case 0: {
modelica_metatype tmpMeta17;
if (optionNone(tmp15_1)) goto tmp14_end;
tmpMeta17 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp15_1), 1));
_septok = tmpMeta17;
arrayUpdate(_aseptok, ((modelica_integer) 1), mmc_mk_none());
omc_Tpl_tokFileText(threadData, _txt, _septok, 0);
goto tmp14_done;
}
case 1: {
goto tmp14_done;
}
}
goto tmp14_end;
tmp14_end: ;
}
goto goto_13;
goto_13:;
goto goto_5;
goto tmp14_done;
tmp14_done:;
}
}
;
goto tmp6_done;
}
case 1: {
goto tmp6_done;
}
}
goto tmp6_end;
tmp6_end: ;
}
goto goto_5;
goto_5:;
goto goto_1;
goto tmp6_done;
tmp6_done:;
}
}
;
goto tmp2_done;
}
}
goto tmp2_end;
tmp2_end: ;
}
goto goto_1;
goto_1:;
MMC_THROW_INTERNAL();
goto tmp2_done;
tmp2_done:;
}
}
;
_return: OMC_LABEL_UNUSED
return;
}
PROTECTED_FUNCTION_STATIC modelica_integer omc_Tpl_textFileTell(threadData_t *threadData, modelica_metatype _inText)
{
modelica_integer _tell;
modelica_complex _file;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
_file = omc_File_File_constructor(threadData, omc_Tpl_getTextOpaqueFile(threadData, _inText));
_tell = omc_File_tell(threadData, _file);
_return: OMC_LABEL_UNUSED
omc_File_File_destructor(threadData,_file);
return _tell;
}
PROTECTED_FUNCTION_STATIC modelica_metatype boxptr_Tpl_textFileTell(threadData_t *threadData, modelica_metatype _inText)
{
modelica_integer _tell;
modelica_metatype out_tell;
_tell = omc_Tpl_textFileTell(threadData, _inText);
out_tell = mmc_mk_icon(_tell);
return out_tell;
}
PROTECTED_FUNCTION_STATIC void omc_Tpl_newlineFile(threadData_t *threadData, modelica_metatype _inText)
{
modelica_complex _file;
modelica_integer _nchars;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
_file = omc_File_File_constructor(threadData, omc_Tpl_getTextOpaqueFile(threadData, _inText));
{
modelica_metatype tmp3_1;
tmp3_1 = _inText;
{
volatile mmc_switch_type tmp3;
int tmp4;
tmp3 = 0;
for (; tmp3 < 1; tmp3++) {
switch (MMC_SWITCH_CAST(tmp3)) {
case 0: {
if (mmc__uniontype__metarecord__typedef__equal(tmp3_1,1,5) == 0) goto tmp2_end;
omc_File_write(threadData, _file, _OMC_LIT1);
arrayUpdate((MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_inText), 3))), ((modelica_integer) 1), arrayGet((MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_inText), 4))), ((modelica_integer) 1)));
arrayUpdate((MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_inText), 5))), ((modelica_integer) 1), mmc_mk_boolean(1));
goto tmp2_done;
}
}
goto tmp2_end;
tmp2_end: ;
}
goto goto_1;
goto_1:;
MMC_THROW_INTERNAL();
goto tmp2_done;
tmp2_done:;
}
}
;
_return: OMC_LABEL_UNUSED
omc_File_File_destructor(threadData,_file);
return;
}
PROTECTED_FUNCTION_STATIC void omc_Tpl_stringFile(threadData_t *threadData, modelica_metatype _inText, modelica_string _str, modelica_boolean _line, modelica_boolean _recurseSeparator)
{
modelica_complex _file;
modelica_integer _nchars;
modelica_metatype _iopts = NULL;
modelica_metatype _septok = NULL;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
_file = omc_File_File_constructor(threadData, omc_Tpl_getTextOpaqueFile(threadData, _inText));
{
modelica_metatype tmp3_1;
tmp3_1 = _inText;
{
volatile mmc_switch_type tmp3;
int tmp4;
tmp3 = 0;
for (; tmp3 < 1; tmp3++) {
switch (MMC_SWITCH_CAST(tmp3)) {
case 0: {
if (mmc__uniontype__metarecord__typedef__equal(tmp3_1,1,5) == 0) goto tmp2_end;
omc_Tpl_handleTok(threadData, _inText);
_nchars = mmc_unbox_integer(arrayGet((MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_inText), 3))), ((modelica_integer) 1)));
if((!_line))
{
if(mmc_unbox_boolean(arrayGet((MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_inText), 5))), ((modelica_integer) 1))))
{
omc_File_writeSpace(threadData, _file, _nchars);
omc_File_write(threadData, _file, _str);
arrayUpdate((MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_inText), 3))), ((modelica_integer) 1), mmc_mk_integer(_nchars + stringLength(_str)));
arrayUpdate((MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_inText), 5))), ((modelica_integer) 1), mmc_mk_boolean(0));
}
else
{
omc_File_write(threadData, _file, _str);
arrayUpdate((MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_inText), 3))), ((modelica_integer) 1), mmc_mk_integer(_nchars + stringLength(_str)));
}
}
else
{
if(mmc_unbox_boolean(arrayGet((MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_inText), 5))), ((modelica_integer) 1))))
{
omc_File_writeSpace(threadData, _file, _nchars);
}
else
{
arrayUpdate((MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_inText), 5))), ((modelica_integer) 1), mmc_mk_boolean(1));
}
omc_File_write(threadData, _file, _str);
arrayUpdate((MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_inText), 3))), ((modelica_integer) 1), arrayGet((MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_inText), 4))), ((modelica_integer) 1)));
}
goto tmp2_done;
}
}
goto tmp2_end;
tmp2_end: ;
}
goto goto_1;
goto_1:;
MMC_THROW_INTERNAL();
goto tmp2_done;
tmp2_done:;
}
}
;
_return: OMC_LABEL_UNUSED
omc_File_File_destructor(threadData,_file);
return;
}
PROTECTED_FUNCTION_STATIC void boxptr_Tpl_stringFile(threadData_t *threadData, modelica_metatype _inText, modelica_metatype _str, modelica_metatype _line, modelica_metatype _recurseSeparator)
{
modelica_integer tmp1;
modelica_integer tmp2;
tmp1 = mmc_unbox_integer(_line);
tmp2 = mmc_unbox_integer(_recurseSeparator);
omc_Tpl_stringFile(threadData, _inText, _str, tmp1, tmp2);
return;
}
PROTECTED_FUNCTION_STATIC modelica_metatype omc_Tpl_getTextOpaqueFile(threadData_t *threadData, modelica_metatype _text)
{
modelica_metatype _opaqueFile = NULL;
modelica_metatype tmpMeta1;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
modelica_metatype tmp4_1;
tmp4_1 = _text;
{
volatile mmc_switch_type tmp4;
int tmp5;
tmp4 = 0;
for (; tmp4 < 2; tmp4++) {
switch (MMC_SWITCH_CAST(tmp4)) {
case 0: {
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,1,5) == 0) goto tmp3_end;
tmpMeta1 = (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_text), 2)));
goto tmp3_done;
}
case 1: {
omc_Error_addInternalError(threadData, _OMC_LIT8, _OMC_LIT9);
goto goto_2;
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
_opaqueFile = tmpMeta1;
_return: OMC_LABEL_UNUSED
return _opaqueFile;
}
DLLExport
modelica_string omc_Tpl_booleanString(threadData_t *threadData, modelica_boolean _b)
{
modelica_string _s = NULL;
modelica_string tmp1;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
tmp1 = modelica_boolean_to_modelica_string(_b, ((modelica_integer) 0), 1);
_s = tmp1;
_return: OMC_LABEL_UNUSED
return _s;
}
modelica_metatype boxptr_Tpl_booleanString(threadData_t *threadData, modelica_metatype _b)
{
modelica_integer tmp1;
modelica_string _s = NULL;
tmp1 = mmc_unbox_integer(_b);
_s = omc_Tpl_booleanString(threadData, tmp1);
return _s;
}
DLLExport
modelica_metatype omc_Tpl_closeFile(threadData_t *threadData, modelica_metatype __omcQ_24in_5Ftext)
{
modelica_metatype _text = NULL;
modelica_complex _file;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
_text = __omcQ_24in_5Ftext;
_file = omc_File_File_constructor(threadData, omc_Tpl_getTextOpaqueFile(threadData, _text));
omc_File_releaseReference(threadData, _file);
_text = _OMC_LIT10;
_return: OMC_LABEL_UNUSED
omc_File_File_destructor(threadData,_file);
return _text;
}
DLLExport
modelica_metatype omc_Tpl_redirectToFile(threadData_t *threadData, modelica_metatype __omcQ_24in_5Ftext, modelica_string _fileName)
{
modelica_metatype _text = NULL;
modelica_complex _file;
modelica_metatype tmpMeta1;
modelica_metatype tmpMeta2;
modelica_metatype tmpMeta3;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
_text = __omcQ_24in_5Ftext;
_file = omc_File_File_constructor(threadData, omc_File_noReference(threadData));
if(omc_Testsuite_isRunning(threadData))
{
tmpMeta1 = stringAppend(_fileName,_OMC_LIT1);
omc_System_appendFile(threadData, omc_Testsuite_getTempFilesFile(threadData), tmpMeta1);
}
omc_File_open(threadData, _file, _fileName, 2);
tmpMeta2 = MMC_REFSTRUCTLIT(mmc_nil);
tmpMeta3 = mmc_mk_box6(4, &Tpl_Text_FILE__TEXT__desc, omc_File_getReference(threadData, _file), arrayCreate(((modelica_integer) 1), mmc_mk_integer(((modelica_integer) 0))), arrayCreate(((modelica_integer) 1), mmc_mk_integer(((modelica_integer) 0))), arrayCreate(((modelica_integer) 1), mmc_mk_boolean(1)), arrayCreate(((modelica_integer) 1), tmpMeta2));
_text = omc_Tpl_writeText(threadData, tmpMeta3, _text);
_return: OMC_LABEL_UNUSED
omc_File_File_destructor(threadData,_file);
return _text;
}
DLLExport
void omc_Tpl_addTemplateError(threadData_t *threadData, modelica_string _msg)
{
modelica_metatype tmpMeta1;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
tmpMeta1 = mmc_mk_cons(_msg, MMC_REFSTRUCTLIT(mmc_nil));
omc_Error_addMessage(threadData, _OMC_LIT15, tmpMeta1);
_return: OMC_LABEL_UNUSED
return;
}
PROTECTED_FUNCTION_STATIC void omc_Tpl_addTemplateErrorFunc(threadData_t *threadData, modelica_metatype _func)
{
modelica_metatype tmpMeta1;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
tmpMeta1 = mmc_mk_cons(omc_System_dladdr(threadData, _func, NULL, NULL), MMC_REFSTRUCTLIT(mmc_nil));
omc_Error_addMessage(threadData, _OMC_LIT18, tmpMeta1);
_return: OMC_LABEL_UNUSED
return;
}
DLLExport
void omc_Tpl_addSourceTemplateError(threadData_t *threadData, modelica_string _inErrMsg, modelica_metatype _inInfo)
{
modelica_metatype tmpMeta1;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
tmpMeta1 = mmc_mk_cons(_inErrMsg, MMC_REFSTRUCTLIT(mmc_nil));
omc_Error_addSourceMessage(threadData, _OMC_LIT15, tmpMeta1, _inInfo);
_return: OMC_LABEL_UNUSED
return;
}
DLLExport
modelica_metatype omc_Tpl_sourceInfo(threadData_t *threadData, modelica_string _inFileName, modelica_integer _inLineNum, modelica_integer _inColumnNum)
{
modelica_metatype _outSourceInfo = NULL;
modelica_metatype tmpMeta1;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
tmpMeta1 = mmc_mk_box8(3, &SourceInfo_SOURCEINFO__desc, _inFileName, mmc_mk_boolean(0), mmc_mk_integer(_inLineNum), mmc_mk_integer(_inColumnNum), mmc_mk_integer(_inLineNum), mmc_mk_integer(_inColumnNum), _OMC_LIT19);
_outSourceInfo = tmpMeta1;
_return: OMC_LABEL_UNUSED
return _outSourceInfo;
}
modelica_metatype boxptr_Tpl_sourceInfo(threadData_t *threadData, modelica_metatype _inFileName, modelica_metatype _inLineNum, modelica_metatype _inColumnNum)
{
modelica_integer tmp1;
modelica_integer tmp2;
modelica_metatype _outSourceInfo = NULL;
tmp1 = mmc_unbox_integer(_inLineNum);
tmp2 = mmc_unbox_integer(_inColumnNum);
_outSourceInfo = omc_Tpl_sourceInfo(threadData, _inFileName, tmp1, tmp2);
return _outSourceInfo;
}
DLLExport
void omc_Tpl_textFileConvertLines(threadData_t *threadData, modelica_metatype _inText, modelica_string _inFileName)
{
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
volatile modelica_metatype tmp3_1;volatile modelica_string tmp3_2;
tmp3_1 = _inText;
tmp3_2 = _inFileName;
{
modelica_metatype _txt = NULL;
modelica_string _file = NULL;
modelica_real _rtTickTxt;
modelica_real _rtTickW;
volatile mmc_switch_type tmp3;
int tmp4;
tmp3 = 0;
MMC_TRY_INTERNAL(mmc_jumper)
tmp2_top:
threadData->mmc_jumper = &new_mmc_jumper;
for (; tmp3 < 2; tmp3++) {
switch (MMC_SWITCH_CAST(tmp3)) {
case 0: {
modelica_metatype tmpMeta5;
modelica_metatype tmpMeta6;
modelica_metatype tmpMeta7;
modelica_metatype tmpMeta8;
modelica_metatype tmpMeta9;
modelica_metatype tmpMeta10;
_txt = tmp3_1;
_file = tmp3_2;
_rtTickTxt = omc_System_realtimeTock(threadData, ((modelica_integer) 10));
omc_Print_clearBuf(threadData);
omc_Tpl_textStringBuf(threadData, _txt);
_rtTickW = omc_System_realtimeTock(threadData, ((modelica_integer) 10));
omc_System_writeFile(threadData, _file, _OMC_LIT20);
if((omc_Config_acceptMetaModelicaGrammar(threadData) || omc_Flags_isSet(threadData, _OMC_LIT24)))
{
omc_Print_writeBufConvertLines(threadData, omc_System_realpath(threadData, _file));
}
else
{
omc_Print_writeBuf(threadData, _file);
}
if(omc_Testsuite_isRunning(threadData))
{
tmpMeta5 = stringAppend(_file,_OMC_LIT1);
omc_System_appendFile(threadData, omc_Testsuite_getTempFilesFile(threadData), tmpMeta5);
}
omc_Print_clearBuf(threadData);
if(omc_Flags_isSet(threadData, _OMC_LIT31))
{
tmpMeta6 = stringAppend(_OMC_LIT25,_file);
tmpMeta7 = stringAppend(tmpMeta6,_OMC_LIT26);
tmpMeta8 = stringAppend(tmpMeta7,realString(_rtTickW - _rtTickTxt));
tmpMeta9 = stringAppend(tmpMeta8,_OMC_LIT27);
tmpMeta10 = stringAppend(tmpMeta9,realString(omc_System_realtimeTock(threadData, ((modelica_integer) 10)) - _rtTickW));
omc_Debug_traceln(threadData, tmpMeta10);
}
goto tmp2_done;
}
case 1: {
modelica_boolean tmp11;
tmp11 = omc_Flags_isSet(threadData, _OMC_LIT35);
if (1 != tmp11) goto goto_1;
omc_Debug_trace(threadData, _OMC_LIT36);
goto tmp2_done;
}
}
goto tmp2_end;
tmp2_end: ;
}
goto goto_1;
tmp2_done:
(void)tmp3;
MMC_RESTORE_INTERNAL(mmc_jumper);
goto tmp2_done2;
goto_1:;
MMC_CATCH_INTERNAL(mmc_jumper);
if (++tmp3 < 2) {
goto tmp2_top;
}
MMC_THROW_INTERNAL();
tmp2_done2:;
}
}
;
_return: OMC_LABEL_UNUSED
return;
}
DLLExport
void omc_Tpl_textFile(threadData_t *threadData, modelica_metatype _inText, modelica_string _inFileName)
{
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
volatile modelica_metatype tmp3_1;volatile modelica_string tmp3_2;
tmp3_1 = _inText;
tmp3_2 = _inFileName;
{
modelica_metatype _txt = NULL;
modelica_string _file = NULL;
modelica_real _rtTickTxt;
modelica_real _rtTickW;
volatile mmc_switch_type tmp3;
int tmp4;
tmp3 = 0;
MMC_TRY_INTERNAL(mmc_jumper)
tmp2_top:
threadData->mmc_jumper = &new_mmc_jumper;
for (; tmp3 < 2; tmp3++) {
switch (MMC_SWITCH_CAST(tmp3)) {
case 0: {
modelica_metatype tmpMeta5;
modelica_metatype tmpMeta6;
modelica_metatype tmpMeta7;
modelica_metatype tmpMeta8;
modelica_metatype tmpMeta9;
modelica_metatype tmpMeta10;
_txt = tmp3_1;
_file = tmp3_2;
_rtTickTxt = omc_System_realtimeTock(threadData, ((modelica_integer) 10));
omc_Print_clearBuf(threadData);
omc_Tpl_textStringBuf(threadData, _txt);
_rtTickW = omc_System_realtimeTock(threadData, ((modelica_integer) 10));
omc_Print_writeBuf(threadData, _file);
if(omc_Testsuite_isRunning(threadData))
{
tmpMeta5 = stringAppend(_file,_OMC_LIT1);
omc_System_appendFile(threadData, omc_Testsuite_getTempFilesFile(threadData), tmpMeta5);
}
omc_Print_clearBuf(threadData);
if(omc_Flags_isSet(threadData, _OMC_LIT31))
{
tmpMeta6 = stringAppend(_OMC_LIT25,_file);
tmpMeta7 = stringAppend(tmpMeta6,_OMC_LIT26);
tmpMeta8 = stringAppend(tmpMeta7,realString(_rtTickW - _rtTickTxt));
tmpMeta9 = stringAppend(tmpMeta8,_OMC_LIT27);
tmpMeta10 = stringAppend(tmpMeta9,realString(omc_System_realtimeTock(threadData, ((modelica_integer) 10)) - _rtTickW));
omc_Debug_trace(threadData, tmpMeta10);
}
goto tmp2_done;
}
case 1: {
if(omc_Flags_isSet(threadData, _OMC_LIT35))
{
omc_Debug_trace(threadData, _OMC_LIT36);
}
goto tmp2_done;
}
}
goto tmp2_end;
tmp2_end: ;
}
goto goto_1;
tmp2_done:
(void)tmp3;
MMC_RESTORE_INTERNAL(mmc_jumper);
goto tmp2_done2;
goto_1:;
MMC_CATCH_INTERNAL(mmc_jumper);
if (++tmp3 < 2) {
goto tmp2_top;
}
MMC_THROW_INTERNAL();
tmp2_done2:;
}
}
;
_return: OMC_LABEL_UNUSED
return;
}
DLLExport
void omc_Tpl_tplNoret(threadData_t *threadData, modelica_fnptr _inFun, modelica_metatype _inArg)
{
modelica_integer _nErr;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
_nErr = omc_Error_getNumErrorMessages(threadData);
omc_Tpl_tplCallWithFailError(threadData, ((modelica_fnptr) _inFun), _inArg, _OMC_LIT10);
omc_Tpl_failIfTrue(threadData, (omc_Error_getNumErrorMessages(threadData) > _nErr));
_return: OMC_LABEL_UNUSED
return;
}
DLLExport
void omc_Tpl_tplNoret2(threadData_t *threadData, modelica_fnptr _inFun, modelica_metatype _inArg, modelica_metatype _inArg2)
{
modelica_integer _nErr;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
_nErr = omc_Error_getNumErrorMessages(threadData);
omc_Tpl_tplCallWithFailError2(threadData, ((modelica_fnptr) _inFun), _inArg, _inArg2, _OMC_LIT10);
omc_Tpl_failIfTrue(threadData, (omc_Error_getNumErrorMessages(threadData) > _nErr));
_return: OMC_LABEL_UNUSED
return;
}
DLLExport
void omc_Tpl_tplNoret3(threadData_t *threadData, modelica_fnptr _inFun, modelica_metatype _inArg, modelica_metatype _inArg2, modelica_metatype _inArg3)
{
modelica_integer _nErr;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
_nErr = omc_Error_getNumErrorMessages(threadData);
omc_Tpl_tplCallWithFailError3(threadData, ((modelica_fnptr) _inFun), _inArg, _inArg2, _inArg3, _OMC_LIT10);
omc_Tpl_failIfTrue(threadData, (omc_Error_getNumErrorMessages(threadData) > _nErr));
_return: OMC_LABEL_UNUSED
return;
}
DLLExport
void omc_Tpl_tplPrint3(threadData_t *threadData, modelica_fnptr _inFun, modelica_metatype _inArgA, modelica_metatype _inArgB, modelica_metatype _inArgC)
{
modelica_metatype _txt = NULL;
modelica_integer _nErr;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
_nErr = omc_Error_getNumErrorMessages(threadData);
_txt = omc_Tpl_tplCallWithFailError3(threadData, ((modelica_fnptr) _inFun), _inArgA, _inArgB, _inArgC, _OMC_LIT10);
omc_Tpl_failIfTrue(threadData, (omc_Error_getNumErrorMessages(threadData) > _nErr));
omc_Tpl_textStringBuf(threadData, _txt);
_return: OMC_LABEL_UNUSED
return;
}
DLLExport
void omc_Tpl_tplPrint2(threadData_t *threadData, modelica_fnptr _inFun, modelica_metatype _inArgA, modelica_metatype _inArgB)
{
modelica_metatype _txt = NULL;
modelica_integer _nErr;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
_nErr = omc_Error_getNumErrorMessages(threadData);
_txt = omc_Tpl_tplCallWithFailError2(threadData, ((modelica_fnptr) _inFun), _inArgA, _inArgB, _OMC_LIT10);
omc_Tpl_failIfTrue(threadData, (omc_Error_getNumErrorMessages(threadData) > _nErr));
omc_Tpl_textStringBuf(threadData, _txt);
_return: OMC_LABEL_UNUSED
return;
}
DLLExport
void omc_Tpl_tplPrint(threadData_t *threadData, modelica_fnptr _inFun, modelica_metatype _inArg)
{
modelica_metatype _txt = NULL;
modelica_integer _nErr;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
_nErr = omc_Error_getNumErrorMessages(threadData);
_txt = omc_Tpl_tplCallWithFailError(threadData, ((modelica_fnptr) _inFun), _inArg, _OMC_LIT10);
omc_Tpl_failIfTrue(threadData, (omc_Error_getNumErrorMessages(threadData) > _nErr));
omc_Tpl_textStringBuf(threadData, _txt);
_return: OMC_LABEL_UNUSED
return;
}
DLLExport
modelica_string omc_Tpl_tplString3(threadData_t *threadData, modelica_fnptr _inFun, modelica_metatype _inArgA, modelica_metatype _inArgB, modelica_metatype _inArgC)
{
modelica_string _outString = NULL;
modelica_metatype _txt = NULL;
modelica_integer _nErr;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
_nErr = omc_Error_getNumErrorMessages(threadData);
_txt = omc_Tpl_tplCallWithFailError3(threadData, ((modelica_fnptr) _inFun), _inArgA, _inArgB, _inArgC, _OMC_LIT10);
omc_Tpl_failIfTrue(threadData, (omc_Error_getNumErrorMessages(threadData) > _nErr));
_outString = omc_Tpl_textString(threadData, _txt);
_return: OMC_LABEL_UNUSED
return _outString;
}
DLLExport
modelica_string omc_Tpl_tplString2(threadData_t *threadData, modelica_fnptr _inFun, modelica_metatype _inArgA, modelica_metatype _inArgB)
{
modelica_string _outString = NULL;
modelica_metatype _txt = NULL;
modelica_integer _nErr;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
_nErr = omc_Error_getNumErrorMessages(threadData);
_txt = omc_Tpl_tplCallWithFailError2(threadData, ((modelica_fnptr) _inFun), _inArgA, _inArgB, _OMC_LIT10);
omc_Tpl_failIfTrue(threadData, (omc_Error_getNumErrorMessages(threadData) > _nErr));
_outString = omc_Tpl_textString(threadData, _txt);
_return: OMC_LABEL_UNUSED
return _outString;
}
DLLExport
modelica_string omc_Tpl_tplString(threadData_t *threadData, modelica_fnptr _inFun, modelica_metatype _inArg)
{
modelica_string _outString = NULL;
modelica_metatype _txt = NULL;
modelica_integer _nErr;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
_nErr = omc_Error_getNumErrorMessages(threadData);
_txt = omc_Tpl_tplCallWithFailError(threadData, ((modelica_fnptr) _inFun), _inArg, _OMC_LIT10);
omc_Tpl_failIfTrue(threadData, (omc_Error_getNumErrorMessages(threadData) > _nErr));
_outString = omc_Tpl_textString(threadData, _txt);
_return: OMC_LABEL_UNUSED
return _outString;
}
static modelica_metatype closure0_inFun(threadData_t *thData, modelica_metatype closure, modelica_metatype in_txt)
{
modelica_metatype inArgA = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(closure),1));
modelica_metatype inArgB = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(closure),2));
modelica_metatype inArgC = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(closure),3));
modelica_fnptr _inFun = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(closure),4));
if (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_inFun),2))) {
return  ((modelica_metatype(*)(threadData_t*, modelica_metatype, modelica_metatype, modelica_metatype, modelica_metatype, modelica_metatype)) (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_inFun), 1)))) (thData, MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_inFun),2)), in_txt, inArgA, inArgB, inArgC);
} else {
return  ((modelica_metatype(*)(threadData_t*, modelica_metatype, modelica_metatype, modelica_metatype, modelica_metatype)) (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_inFun), 1)))) (thData, in_txt, inArgA, inArgB, inArgC);
}
}
DLLExport
modelica_metatype omc_Tpl_tplCallWithFailError3(threadData_t *threadData, modelica_fnptr _inFun, modelica_metatype _inArgA, modelica_metatype _inArgB, modelica_metatype _inArgC, modelica_metatype __omcQ_24in_5Ftxt)
{
modelica_metatype _txt = NULL;
modelica_metatype tmpMeta1;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
_txt = __omcQ_24in_5Ftxt;
tmpMeta1 = mmc_mk_box4(0, _inArgA, _inArgB, _inArgC, _inFun);
_txt = omc_Tpl_tplCallHandleErrors(threadData, (modelica_fnptr) mmc_mk_box2(0,closure0_inFun,tmpMeta1), _txt);
_return: OMC_LABEL_UNUSED
return _txt;
}
static modelica_metatype closure1_inFun(threadData_t *thData, modelica_metatype closure, modelica_metatype in_txt)
{
modelica_metatype inArgA = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(closure),1));
modelica_metatype inArgB = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(closure),2));
modelica_fnptr _inFun = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(closure),3));
if (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_inFun),2))) {
return  ((modelica_metatype(*)(threadData_t*, modelica_metatype, modelica_metatype, modelica_metatype, modelica_metatype)) (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_inFun), 1)))) (thData, MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_inFun),2)), in_txt, inArgA, inArgB);
} else {
return  ((modelica_metatype(*)(threadData_t*, modelica_metatype, modelica_metatype, modelica_metatype)) (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_inFun), 1)))) (thData, in_txt, inArgA, inArgB);
}
}
DLLExport
modelica_metatype omc_Tpl_tplCallWithFailError2(threadData_t *threadData, modelica_fnptr _inFun, modelica_metatype _inArgA, modelica_metatype _inArgB, modelica_metatype __omcQ_24in_5Ftxt)
{
modelica_metatype _txt = NULL;
modelica_metatype _argA = NULL;
modelica_metatype _argB = NULL;
modelica_metatype tmpMeta1;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
_txt = __omcQ_24in_5Ftxt;
tmpMeta1 = mmc_mk_box3(0, _inArgA, _inArgB, _inFun);
_txt = omc_Tpl_tplCallHandleErrors(threadData, (modelica_fnptr) mmc_mk_box2(0,closure1_inFun,tmpMeta1), _txt);
_return: OMC_LABEL_UNUSED
return _txt;
}
static modelica_metatype closure2_inFun(threadData_t *thData, modelica_metatype closure, modelica_metatype in_txt)
{
modelica_metatype inArgA = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(closure),1));
modelica_fnptr _inFun = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(closure),2));
if (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_inFun),2))) {
return  ((modelica_metatype(*)(threadData_t*, modelica_metatype, modelica_metatype, modelica_metatype)) (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_inFun), 1)))) (thData, MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_inFun),2)), in_txt, inArgA);
} else {
return  ((modelica_metatype(*)(threadData_t*, modelica_metatype, modelica_metatype)) (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_inFun), 1)))) (thData, in_txt, inArgA);
}
}
DLLExport
modelica_metatype omc_Tpl_tplCallWithFailError(threadData_t *threadData, modelica_fnptr _inFun, modelica_metatype _inArg, modelica_metatype __omcQ_24in_5Ftxt)
{
modelica_metatype _txt = NULL;
modelica_metatype _arg = NULL;
modelica_metatype tmpMeta1;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
_txt = __omcQ_24in_5Ftxt;
tmpMeta1 = mmc_mk_box2(0, _inArg, _inFun);
_txt = omc_Tpl_tplCallHandleErrors(threadData, (modelica_fnptr) mmc_mk_box2(0,closure2_inFun,tmpMeta1), _txt);
_return: OMC_LABEL_UNUSED
return _txt;
}
DLLExport
modelica_metatype omc_Tpl_tplCallWithFailErrorNoArg(threadData_t *threadData, modelica_fnptr _inFun, modelica_metatype __omcQ_24in_5Ftxt)
{
modelica_metatype _txt = NULL;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
_txt = __omcQ_24in_5Ftxt;
_txt = omc_Tpl_tplCallHandleErrors(threadData, ((modelica_fnptr) _inFun), _txt);
_return: OMC_LABEL_UNUSED
return _txt;
}
PROTECTED_FUNCTION_STATIC modelica_metatype omc_Tpl_tplCallHandleErrors(threadData_t *threadData, modelica_fnptr _inFun, modelica_metatype __omcQ_24in_5Ftxt)
{
modelica_metatype _txt = NULL;
modelica_integer _nErr;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
_txt = __omcQ_24in_5Ftxt;
_nErr = omc_Error_getNumErrorMessages(threadData);
{
{
modelica_metatype tmpMeta8;
MMC_TRY_STACK()
{
{
volatile mmc_switch_type tmp6;
int tmp7;
tmp6 = 0;
MMC_TRY_INTERNAL(mmc_jumper)
tmp5_top:
threadData->mmc_jumper = &new_mmc_jumper;
for (; tmp6 < 2; tmp6++) {
switch (MMC_SWITCH_CAST(tmp6)) {
case 0: {
_txt = (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_inFun), 2))) ? ((modelica_metatype(*)(threadData_t*, modelica_metatype, modelica_metatype)) (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_inFun), 1)))) (threadData, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_inFun), 2))), _txt) : ((modelica_metatype(*)(threadData_t*, modelica_metatype)) (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_inFun), 1)))) (threadData, _txt);
goto tmp5_done;
}
case 1: {
omc_Tpl_addTemplateErrorFunc(threadData, ((modelica_fnptr) _inFun));
goto goto_4;
goto tmp5_done;
}
}
goto tmp5_end;
tmp5_end: ;
}
goto goto_4;
tmp5_done:
(void)tmp6;
MMC_RESTORE_INTERNAL(mmc_jumper);
goto tmp5_done2;
goto_4:;
MMC_CATCH_INTERNAL(mmc_jumper);
if (++tmp6 < 2) {
goto tmp5_top;
}
MMC_THROW_INTERNAL();
tmp5_done2:;
}
}
;
MMC_ELSE_STACK()
if(omc_StackOverflow_hasStacktraceMessages(threadData))
{
tmpMeta8 = stringAppend(_OMC_LIT37,stringDelimitList(omc_StackOverflow_readableStacktraceMessages(threadData), _OMC_LIT1));
omc_Error_addInternalError(threadData, tmpMeta8, _OMC_LIT38);
}
omc_Tpl_addTemplateErrorFunc(threadData, ((modelica_fnptr) _inFun));
MMC_THROW_INTERNAL();
MMC_CATCH_STACK()
}
}
;
_return: OMC_LABEL_UNUSED
return _txt;
}
DLLExport
void omc_Tpl_failIfTrue(threadData_t *threadData, modelica_boolean _istrue)
{
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
if(_istrue)
{
MMC_THROW_INTERNAL();
}
_return: OMC_LABEL_UNUSED
return;
}
void boxptr_Tpl_failIfTrue(threadData_t *threadData, modelica_metatype _istrue)
{
modelica_integer tmp1;
tmp1 = mmc_unbox_integer(_istrue);
omc_Tpl_failIfTrue(threadData, tmp1);
return;
}
DLLExport
modelica_string omc_Tpl_strTokString(threadData_t *threadData, modelica_metatype _inStringToken)
{
modelica_string _outString = NULL;
modelica_metatype tmpMeta1;
modelica_metatype tmpMeta2;
modelica_metatype tmpMeta3;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
tmpMeta1 = mmc_mk_cons(_inStringToken, MMC_REFSTRUCTLIT(mmc_nil));
tmpMeta2 = MMC_REFSTRUCTLIT(mmc_nil);
tmpMeta3 = mmc_mk_box3(3, &Tpl_Text_MEM__TEXT__desc, tmpMeta1, tmpMeta2);
_outString = omc_Tpl_textString(threadData, tmpMeta3);
_return: OMC_LABEL_UNUSED
return _outString;
}
DLLExport
modelica_metatype omc_Tpl_stringText(threadData_t *threadData, modelica_string _inString)
{
modelica_metatype _outText = NULL;
modelica_metatype tmpMeta1;
modelica_metatype tmpMeta2;
modelica_metatype tmpMeta3;
modelica_metatype tmpMeta4;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
tmpMeta2 = mmc_mk_box2(4, &Tpl_StringToken_ST__STRING__desc, _inString);
tmpMeta1 = mmc_mk_cons(tmpMeta2, MMC_REFSTRUCTLIT(mmc_nil));
tmpMeta3 = MMC_REFSTRUCTLIT(mmc_nil);
tmpMeta4 = mmc_mk_box3(3, &Tpl_Text_MEM__TEXT__desc, tmpMeta1, tmpMeta3);
_outText = tmpMeta4;
_return: OMC_LABEL_UNUSED
return _outText;
}
DLLExport
modelica_metatype omc_Tpl_textStrTok(threadData_t *threadData, modelica_metatype _inText)
{
modelica_metatype _outStringToken = NULL;
modelica_metatype tmpMeta1;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
modelica_metatype tmp4_1;
tmp4_1 = _inText;
{
modelica_metatype _txttoks = NULL;
volatile mmc_switch_type tmp4;
int tmp5;
tmp4 = 0;
for (; tmp4 < 3; tmp4++) {
switch (MMC_SWITCH_CAST(tmp4)) {
case 0: {
modelica_metatype tmpMeta6;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,0,2) == 0) goto tmp3_end;
tmpMeta6 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
if (!listEmpty(tmpMeta6)) goto tmp3_end;
tmpMeta1 = _OMC_LIT39;
goto tmp3_done;
}
case 1: {
modelica_metatype tmpMeta7;
modelica_metatype tmpMeta8;
modelica_metatype tmpMeta9;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,0,2) == 0) goto tmp3_end;
tmpMeta7 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
tmpMeta8 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 3));
if (!listEmpty(tmpMeta8)) goto tmp3_end;
_txttoks = tmpMeta7;
tmpMeta9 = mmc_mk_box3(7, &Tpl_StringToken_ST__BLOCK__desc, _txttoks, _OMC_LIT40);
tmpMeta1 = tmpMeta9;
goto tmp3_done;
}
case 2: {
modelica_boolean tmp10;
tmp10 = omc_Flags_isSet(threadData, _OMC_LIT35);
if (1 != tmp10) goto goto_2;
omc_Debug_trace(threadData, _OMC_LIT41);
goto goto_2;
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
_outStringToken = tmpMeta1;
_return: OMC_LABEL_UNUSED
return _outStringToken;
}
DLLExport
modelica_metatype omc_Tpl_strTokText(threadData_t *threadData, modelica_metatype _inStringToken)
{
modelica_metatype _outText = NULL;
modelica_metatype tmpMeta1;
modelica_metatype tmpMeta2;
modelica_metatype tmpMeta3;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
tmpMeta1 = mmc_mk_cons(_inStringToken, MMC_REFSTRUCTLIT(mmc_nil));
tmpMeta2 = MMC_REFSTRUCTLIT(mmc_nil);
tmpMeta3 = mmc_mk_box3(3, &Tpl_Text_MEM__TEXT__desc, tmpMeta1, tmpMeta2);
_outText = tmpMeta3;
_return: OMC_LABEL_UNUSED
return _outText;
}
PROTECTED_FUNCTION_STATIC modelica_integer omc_Tpl_tryWrapFile(threadData_t *threadData, modelica_complex _file, modelica_integer _inWrapWidth, modelica_metatype _inWrapSeparator, modelica_integer _inActualPositionOnLine, modelica_boolean _inAtStartOfLine, modelica_integer _inAfterNewLineIndent, modelica_boolean *out_outAtStartOfLine, modelica_integer *out_outAfterNewLineIndent)
{
modelica_integer _outActualPositionOnLine;
modelica_boolean _outAtStartOfLine;
modelica_integer _outAfterNewLineIndent;
modelica_integer tmp1_c0 __attribute__((unused)) = 0;
modelica_boolean tmp1_c1 __attribute__((unused)) = 0;
modelica_integer tmp1_c2 __attribute__((unused)) = 0;
modelica_metatype tmpMeta[3] __attribute__((unused)) = {0};
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
modelica_integer tmp4_1;modelica_metatype tmp4_2;modelica_integer tmp4_3;modelica_boolean tmp4_4;modelica_integer tmp4_5;
tmp4_1 = _inWrapWidth;
tmp4_2 = _inWrapSeparator;
tmp4_3 = _inActualPositionOnLine;
tmp4_4 = _inAtStartOfLine;
tmp4_5 = _inAfterNewLineIndent;
{
modelica_integer _pos;
modelica_integer _aind;
modelica_integer _wwidth;
modelica_boolean _isstart;
modelica_metatype _wsep = NULL;
volatile mmc_switch_type tmp4;
int tmp5;
tmp4 = 0;
for (; tmp4 < 2; tmp4++) {
switch (MMC_SWITCH_CAST(tmp4)) {
case 0: {
_wwidth = tmp4_1;
_wsep = tmp4_2;
_pos = tmp4_3;
_isstart = tmp4_4;
_aind = tmp4_5;
if (!((_wwidth > ((modelica_integer) 0)) && (_pos >= _wwidth))) goto tmp3_end;
tmp1_c0 = omc_Tpl_tokFile(threadData, _file, _wsep, _pos, _isstart, _aind, &tmp1_c1, &tmp1_c2);
goto tmp3_done;
}
case 1: {
tmp1_c0 = _inActualPositionOnLine;
tmp1_c1 = _inAtStartOfLine;
tmp1_c2 = _inAfterNewLineIndent;
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
_outActualPositionOnLine = tmp1_c0;
_outAtStartOfLine = tmp1_c1;
_outAfterNewLineIndent = tmp1_c2;
_return: OMC_LABEL_UNUSED
if (out_outAtStartOfLine) { *out_outAtStartOfLine = _outAtStartOfLine; }
if (out_outAfterNewLineIndent) { *out_outAfterNewLineIndent = _outAfterNewLineIndent; }
return _outActualPositionOnLine;
}
PROTECTED_FUNCTION_STATIC modelica_metatype boxptr_Tpl_tryWrapFile(threadData_t *threadData, modelica_metatype _file, modelica_metatype _inWrapWidth, modelica_metatype _inWrapSeparator, modelica_metatype _inActualPositionOnLine, modelica_metatype _inAtStartOfLine, modelica_metatype _inAfterNewLineIndent, modelica_metatype *out_outAtStartOfLine, modelica_metatype *out_outAfterNewLineIndent)
{
modelica_integer tmp1;
modelica_integer tmp2;
modelica_integer tmp3;
modelica_integer tmp4;
modelica_boolean _outAtStartOfLine;
modelica_integer _outAfterNewLineIndent;
modelica_integer _outActualPositionOnLine;
modelica_metatype out_outActualPositionOnLine;
tmp1 = mmc_unbox_integer(_inWrapWidth);
tmp2 = mmc_unbox_integer(_inActualPositionOnLine);
tmp3 = mmc_unbox_integer(_inAtStartOfLine);
tmp4 = mmc_unbox_integer(_inAfterNewLineIndent);
_outActualPositionOnLine = omc_Tpl_tryWrapFile(threadData, _file, tmp1, _inWrapSeparator, tmp2, tmp3, tmp4, &_outAtStartOfLine, &_outAfterNewLineIndent);
out_outActualPositionOnLine = mmc_mk_icon(_outActualPositionOnLine);
if (out_outAtStartOfLine) { *out_outAtStartOfLine = mmc_mk_icon(_outAtStartOfLine); }
if (out_outAfterNewLineIndent) { *out_outAfterNewLineIndent = mmc_mk_icon(_outAfterNewLineIndent); }
return out_outActualPositionOnLine;
}
PROTECTED_FUNCTION_STATIC modelica_integer omc_Tpl_iterAlignWrapFile(threadData_t *threadData, modelica_complex _file, modelica_metatype _inTokens, modelica_integer _inActualIndex, modelica_integer _inAlignNum, modelica_metatype _inAlignSeparator, modelica_integer _inWrapWidth, modelica_metatype _inWrapSeparator, modelica_integer _inActualPositionOnLine, modelica_boolean _inAtStartOfLine, modelica_integer _inAfterNewLineIndent, modelica_boolean *out_outAtStartOfLine)
{
modelica_integer _outActualPositionOnLine;
modelica_boolean _outAtStartOfLine;
modelica_integer tmp1_c0 __attribute__((unused)) = 0;
modelica_boolean tmp1_c1 __attribute__((unused)) = 0;
modelica_metatype tmpMeta[2] __attribute__((unused)) = {0};
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
modelica_metatype tmp4_1;modelica_integer tmp4_2;modelica_integer tmp4_3;modelica_metatype tmp4_4;modelica_integer tmp4_5;modelica_metatype tmp4_6;modelica_integer tmp4_7;modelica_boolean tmp4_8;modelica_integer tmp4_9;
tmp4_1 = _inTokens;
tmp4_2 = _inActualIndex;
tmp4_3 = _inAlignNum;
tmp4_4 = _inAlignSeparator;
tmp4_5 = _inWrapWidth;
tmp4_6 = _inWrapSeparator;
tmp4_7 = _inActualPositionOnLine;
tmp4_8 = _inAtStartOfLine;
tmp4_9 = _inAfterNewLineIndent;
{
modelica_metatype _toks = NULL;
modelica_metatype _tok = NULL;
modelica_metatype _asep = NULL;
modelica_metatype _wsep = NULL;
modelica_integer _pos;
modelica_integer _aind;
modelica_integer _idx;
modelica_integer _anum;
modelica_integer _wwidth;
modelica_boolean _isstart;
volatile mmc_switch_type tmp4;
int tmp5;
tmp4 = 0;
for (; tmp4 < 5; tmp4++) {
switch (MMC_SWITCH_CAST(tmp4)) {
case 0: {
if (!listEmpty(tmp4_1)) goto tmp3_end;
_pos = tmp4_7;
_isstart = tmp4_8;
tmp1_c0 = _pos;
tmp1_c1 = _isstart;
goto tmp3_done;
}
case 1: {
modelica_metatype tmpMeta6;
modelica_metatype tmpMeta7;
if (listEmpty(tmp4_1)) goto tmp3_end;
tmpMeta6 = MMC_CAR(tmp4_1);
tmpMeta7 = MMC_CDR(tmp4_1);
_tok = tmpMeta6;
_toks = tmpMeta7;
_idx = tmp4_2;
_anum = tmp4_3;
_asep = tmp4_4;
_wwidth = tmp4_5;
_wsep = tmp4_6;
_pos = tmp4_7;
_isstart = tmp4_8;
_aind = tmp4_9;
if (!((_idx > ((modelica_integer) 0)) && (modelica_integer_mod(_idx, _anum) == ((modelica_integer) 0)))) goto tmp3_end;
_pos = omc_Tpl_tokFile(threadData, _file, _asep, _pos, _isstart, _aind ,&_isstart ,&_aind);
_pos = omc_Tpl_tryWrapFile(threadData, _file, _wwidth, _wsep, _pos, _isstart, _aind ,&_isstart ,&_aind);
_pos = omc_Tpl_tokFile(threadData, _file, _tok, _pos, _isstart, _aind ,&_isstart ,&_aind);
_inTokens = _toks;
_inActualIndex = ((modelica_integer) 1) + _idx;
_inAlignNum = _anum;
_inAlignSeparator = _asep;
_inWrapWidth = _wwidth;
_inWrapSeparator = _wsep;
_inActualPositionOnLine = _pos;
_inAtStartOfLine = _isstart;
_inAfterNewLineIndent = _aind;
goto _tailrecursive;
goto tmp3_done;
}
case 2: {
modelica_metatype tmpMeta8;
modelica_metatype tmpMeta9;
if (listEmpty(tmp4_1)) goto tmp3_end;
tmpMeta8 = MMC_CAR(tmp4_1);
tmpMeta9 = MMC_CDR(tmp4_1);
_tok = tmpMeta8;
_toks = tmpMeta9;
_idx = tmp4_2;
_anum = tmp4_3;
_asep = tmp4_4;
_wwidth = tmp4_5;
_wsep = tmp4_6;
_pos = tmp4_7;
_isstart = tmp4_8;
_aind = tmp4_9;
if (!((_wwidth > ((modelica_integer) 0)) && (_pos >= _wwidth))) goto tmp3_end;
_pos = omc_Tpl_tokFile(threadData, _file, _wsep, _pos, _isstart, _aind ,&_isstart ,&_aind);
_pos = omc_Tpl_tokFile(threadData, _file, _tok, _pos, _isstart, _aind ,&_isstart ,&_aind);
_inTokens = _toks;
_inActualIndex = ((modelica_integer) 1) + _idx;
_inAlignNum = _anum;
_inAlignSeparator = _asep;
_inWrapWidth = _wwidth;
_inWrapSeparator = _wsep;
_inActualPositionOnLine = _pos;
_inAtStartOfLine = _isstart;
_inAfterNewLineIndent = _aind;
goto _tailrecursive;
goto tmp3_done;
}
case 3: {
modelica_metatype tmpMeta10;
modelica_metatype tmpMeta11;
if (listEmpty(tmp4_1)) goto tmp3_end;
tmpMeta10 = MMC_CAR(tmp4_1);
tmpMeta11 = MMC_CDR(tmp4_1);
_tok = tmpMeta10;
_toks = tmpMeta11;
_idx = tmp4_2;
_anum = tmp4_3;
_asep = tmp4_4;
_wwidth = tmp4_5;
_wsep = tmp4_6;
_pos = tmp4_7;
_isstart = tmp4_8;
_aind = tmp4_9;
_pos = omc_Tpl_tokFile(threadData, _file, _tok, _pos, _isstart, _aind ,&_isstart ,&_aind);
_inTokens = _toks;
_inActualIndex = ((modelica_integer) 1) + _idx;
_inAlignNum = _anum;
_inAlignSeparator = _asep;
_inWrapWidth = _wwidth;
_inWrapSeparator = _wsep;
_inActualPositionOnLine = _pos;
_inAtStartOfLine = _isstart;
_inAfterNewLineIndent = _aind;
goto _tailrecursive;
goto tmp3_done;
}
case 4: {
modelica_boolean tmp12;
tmp12 = omc_Flags_isSet(threadData, _OMC_LIT35);
if (1 != tmp12) goto goto_2;
omc_Debug_trace(threadData, _OMC_LIT42);
goto goto_2;
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
_outActualPositionOnLine = tmp1_c0;
_outAtStartOfLine = tmp1_c1;
_return: OMC_LABEL_UNUSED
if (out_outAtStartOfLine) { *out_outAtStartOfLine = _outAtStartOfLine; }
return _outActualPositionOnLine;
}
PROTECTED_FUNCTION_STATIC modelica_metatype boxptr_Tpl_iterAlignWrapFile(threadData_t *threadData, modelica_metatype _file, modelica_metatype _inTokens, modelica_metatype _inActualIndex, modelica_metatype _inAlignNum, modelica_metatype _inAlignSeparator, modelica_metatype _inWrapWidth, modelica_metatype _inWrapSeparator, modelica_metatype _inActualPositionOnLine, modelica_metatype _inAtStartOfLine, modelica_metatype _inAfterNewLineIndent, modelica_metatype *out_outAtStartOfLine)
{
modelica_integer tmp1;
modelica_integer tmp2;
modelica_integer tmp3;
modelica_integer tmp4;
modelica_integer tmp5;
modelica_integer tmp6;
modelica_boolean _outAtStartOfLine;
modelica_integer _outActualPositionOnLine;
modelica_metatype out_outActualPositionOnLine;
tmp1 = mmc_unbox_integer(_inActualIndex);
tmp2 = mmc_unbox_integer(_inAlignNum);
tmp3 = mmc_unbox_integer(_inWrapWidth);
tmp4 = mmc_unbox_integer(_inActualPositionOnLine);
tmp5 = mmc_unbox_integer(_inAtStartOfLine);
tmp6 = mmc_unbox_integer(_inAfterNewLineIndent);
_outActualPositionOnLine = omc_Tpl_iterAlignWrapFile(threadData, _file, _inTokens, tmp1, tmp2, _inAlignSeparator, tmp3, _inWrapSeparator, tmp4, tmp5, tmp6, &_outAtStartOfLine);
out_outActualPositionOnLine = mmc_mk_icon(_outActualPositionOnLine);
if (out_outAtStartOfLine) { *out_outAtStartOfLine = mmc_mk_icon(_outAtStartOfLine); }
return out_outActualPositionOnLine;
}
PROTECTED_FUNCTION_STATIC modelica_integer omc_Tpl_iterSeparatorAlignWrapFile(threadData_t *threadData, modelica_complex _file, modelica_metatype _inTokens, modelica_metatype _inSeparator, modelica_integer _inActualIndex, modelica_integer _inAlignNum, modelica_metatype _inAlignSeparator, modelica_integer _inWrapWidth, modelica_metatype _inWrapSeparator, modelica_integer _inActualPositionOnLine, modelica_boolean _inAtStartOfLine, modelica_integer _inAfterNewLineIndent, modelica_boolean *out_outAtStartOfLine)
{
modelica_integer _outActualPositionOnLine;
modelica_boolean _outAtStartOfLine;
modelica_metatype _toks = NULL;
modelica_metatype _tok = NULL;
modelica_metatype _septok = NULL;
modelica_integer _idx;
modelica_integer _anum;
modelica_metatype _asep = NULL;
modelica_integer _wwidth;
modelica_metatype _wsep = NULL;
modelica_integer _pos;
modelica_boolean _isstart;
modelica_integer _aind;
modelica_metatype tmpMeta1;
modelica_metatype tmpMeta2;
modelica_metatype tmpMeta3;
modelica_metatype tmpMeta4;
modelica_metatype tmpMeta5;
modelica_metatype tmpMeta6;
modelica_integer tmp7;
modelica_metatype tmpMeta8;
modelica_integer tmp9;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
_toks = _inTokens;
_septok = _inSeparator;
_idx = _inActualIndex;
_anum = _inAlignNum;
_asep = _inAlignSeparator;
_wwidth = _inWrapWidth;
_wsep = _inWrapSeparator;
_pos = _inActualPositionOnLine;
_isstart = _inAtStartOfLine;
_aind = _inAfterNewLineIndent;
while(1)
{
if(!(!listEmpty(_toks))) break;
tmpMeta1 = _toks;
if (listEmpty(tmpMeta1)) MMC_THROW_INTERNAL();
tmpMeta2 = MMC_CAR(tmpMeta1);
tmpMeta3 = MMC_CDR(tmpMeta1);
_tok = tmpMeta2;
_toks = tmpMeta3;
if(((_idx > ((modelica_integer) 0)) && (modelica_integer_mod(_idx, _anum) == ((modelica_integer) 0))))
{
_pos = omc_Tpl_tokFile(threadData, _file, _asep, _pos, _isstart, _aind ,&_isstart ,&_aind);
}
else
{
_pos = omc_Tpl_tokFile(threadData, _file, _septok, _pos, _isstart, _aind ,&_isstart ,&_aind);
}
_pos = omc_Tpl_tryWrapFile(threadData, _file, _wwidth, _wsep, _pos, _isstart, _aind ,&_isstart ,&_aind);
_pos = omc_Tpl_tokFile(threadData, _file, _tok, _pos, _isstart, _aind ,&_isstart ,&_aind);
_idx = ((modelica_integer) 1) + _idx;
}
tmpMeta4 = mmc_mk_box2(0, mmc_mk_integer(_pos), mmc_mk_boolean(_isstart));
tmpMeta5 = tmpMeta4;
tmpMeta6 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta5), 1));
tmp7 = mmc_unbox_integer(tmpMeta6);
tmpMeta8 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta5), 2));
tmp9 = mmc_unbox_integer(tmpMeta8);
_outActualPositionOnLine = tmp7;
_outAtStartOfLine = tmp9;
_return: OMC_LABEL_UNUSED
if (out_outAtStartOfLine) { *out_outAtStartOfLine = _outAtStartOfLine; }
return _outActualPositionOnLine;
}
PROTECTED_FUNCTION_STATIC modelica_metatype boxptr_Tpl_iterSeparatorAlignWrapFile(threadData_t *threadData, modelica_metatype _file, modelica_metatype _inTokens, modelica_metatype _inSeparator, modelica_metatype _inActualIndex, modelica_metatype _inAlignNum, modelica_metatype _inAlignSeparator, modelica_metatype _inWrapWidth, modelica_metatype _inWrapSeparator, modelica_metatype _inActualPositionOnLine, modelica_metatype _inAtStartOfLine, modelica_metatype _inAfterNewLineIndent, modelica_metatype *out_outAtStartOfLine)
{
modelica_integer tmp1;
modelica_integer tmp2;
modelica_integer tmp3;
modelica_integer tmp4;
modelica_integer tmp5;
modelica_integer tmp6;
modelica_boolean _outAtStartOfLine;
modelica_integer _outActualPositionOnLine;
modelica_metatype out_outActualPositionOnLine;
tmp1 = mmc_unbox_integer(_inActualIndex);
tmp2 = mmc_unbox_integer(_inAlignNum);
tmp3 = mmc_unbox_integer(_inWrapWidth);
tmp4 = mmc_unbox_integer(_inActualPositionOnLine);
tmp5 = mmc_unbox_integer(_inAtStartOfLine);
tmp6 = mmc_unbox_integer(_inAfterNewLineIndent);
_outActualPositionOnLine = omc_Tpl_iterSeparatorAlignWrapFile(threadData, _file, _inTokens, _inSeparator, tmp1, tmp2, _inAlignSeparator, tmp3, _inWrapSeparator, tmp4, tmp5, tmp6, &_outAtStartOfLine);
out_outActualPositionOnLine = mmc_mk_icon(_outActualPositionOnLine);
if (out_outAtStartOfLine) { *out_outAtStartOfLine = mmc_mk_icon(_outAtStartOfLine); }
return out_outActualPositionOnLine;
}
PROTECTED_FUNCTION_STATIC modelica_integer omc_Tpl_iterSeparatorFile(threadData_t *threadData, modelica_complex _file, modelica_metatype _inTokens, modelica_metatype _inSeparator, modelica_integer _inActualPositionOnLine, modelica_boolean _inAtStartOfLine, modelica_integer _inAfterNewLineIndent, modelica_boolean *out_outAtStartOfLine)
{
modelica_integer _outActualPositionOnLine;
modelica_boolean _outAtStartOfLine;
modelica_integer tmp1_c0 __attribute__((unused)) = 0;
modelica_boolean tmp1_c1 __attribute__((unused)) = 0;
modelica_metatype tmpMeta[2] __attribute__((unused)) = {0};
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
modelica_metatype tmp4_1;modelica_metatype tmp4_2;modelica_integer tmp4_3;modelica_boolean tmp4_4;modelica_integer tmp4_5;
tmp4_1 = _inTokens;
tmp4_2 = _inSeparator;
tmp4_3 = _inActualPositionOnLine;
tmp4_4 = _inAtStartOfLine;
tmp4_5 = _inAfterNewLineIndent;
{
modelica_metatype _toks = NULL;
modelica_metatype _tok = NULL;
modelica_metatype _septok = NULL;
modelica_integer _pos;
modelica_integer _aind;
modelica_boolean _isstart;
volatile mmc_switch_type tmp4;
int tmp5;
tmp4 = 0;
for (; tmp4 < 2; tmp4++) {
switch (MMC_SWITCH_CAST(tmp4)) {
case 0: {
if (!listEmpty(tmp4_1)) goto tmp3_end;
_pos = tmp4_3;
_isstart = tmp4_4;
tmp1_c0 = _pos;
tmp1_c1 = _isstart;
goto tmp3_done;
}
case 1: {
modelica_metatype tmpMeta6;
modelica_metatype tmpMeta7;
if (listEmpty(tmp4_1)) goto tmp3_end;
tmpMeta6 = MMC_CAR(tmp4_1);
tmpMeta7 = MMC_CDR(tmp4_1);
_tok = tmpMeta6;
_toks = tmpMeta7;
_septok = tmp4_2;
_pos = tmp4_3;
_isstart = tmp4_4;
_aind = tmp4_5;
_pos = omc_Tpl_tokFile(threadData, _file, _septok, _pos, _isstart, _aind ,&_isstart ,&_aind);
_pos = omc_Tpl_tokFile(threadData, _file, _tok, _pos, _isstart, _aind ,&_isstart ,&_aind);
_inTokens = _toks;
_inSeparator = _septok;
_inActualPositionOnLine = _pos;
_inAtStartOfLine = _isstart;
_inAfterNewLineIndent = _aind;
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
_outActualPositionOnLine = tmp1_c0;
_outAtStartOfLine = tmp1_c1;
_return: OMC_LABEL_UNUSED
if (out_outAtStartOfLine) { *out_outAtStartOfLine = _outAtStartOfLine; }
return _outActualPositionOnLine;
}
PROTECTED_FUNCTION_STATIC modelica_metatype boxptr_Tpl_iterSeparatorFile(threadData_t *threadData, modelica_metatype _file, modelica_metatype _inTokens, modelica_metatype _inSeparator, modelica_metatype _inActualPositionOnLine, modelica_metatype _inAtStartOfLine, modelica_metatype _inAfterNewLineIndent, modelica_metatype *out_outAtStartOfLine)
{
modelica_integer tmp1;
modelica_integer tmp2;
modelica_integer tmp3;
modelica_boolean _outAtStartOfLine;
modelica_integer _outActualPositionOnLine;
modelica_metatype out_outActualPositionOnLine;
tmp1 = mmc_unbox_integer(_inActualPositionOnLine);
tmp2 = mmc_unbox_integer(_inAtStartOfLine);
tmp3 = mmc_unbox_integer(_inAfterNewLineIndent);
_outActualPositionOnLine = omc_Tpl_iterSeparatorFile(threadData, _file, _inTokens, _inSeparator, tmp1, tmp2, tmp3, &_outAtStartOfLine);
out_outActualPositionOnLine = mmc_mk_icon(_outActualPositionOnLine);
if (out_outAtStartOfLine) { *out_outAtStartOfLine = mmc_mk_icon(_outAtStartOfLine); }
return out_outActualPositionOnLine;
}
PROTECTED_FUNCTION_STATIC modelica_integer omc_Tpl_blockFile(threadData_t *threadData, modelica_complex _file, modelica_metatype _inBlockType, modelica_metatype _inTokens, modelica_integer _inActualPositionOnLine, modelica_boolean _inAtStartOfLine, modelica_integer _inAfterNewLineIndent, modelica_boolean *out_outAtStartOfLine, modelica_integer *out_outAfterNewLineIndent)
{
modelica_integer _outActualPositionOnLine;
modelica_boolean _outAtStartOfLine;
modelica_integer _outAfterNewLineIndent;
modelica_integer tmp1_c0 __attribute__((unused)) = 0;
modelica_boolean tmp1_c1 __attribute__((unused)) = 0;
modelica_integer tmp1_c2 __attribute__((unused)) = 0;
modelica_metatype tmpMeta[3] __attribute__((unused)) = {0};
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
modelica_metatype tmp4_1;modelica_metatype tmp4_2;modelica_integer tmp4_3;modelica_boolean tmp4_4;modelica_integer tmp4_5;
tmp4_1 = _inBlockType;
tmp4_2 = _inTokens;
tmp4_3 = _inActualPositionOnLine;
tmp4_4 = _inAtStartOfLine;
tmp4_5 = _inAfterNewLineIndent;
{
modelica_metatype _toks = NULL;
modelica_metatype _septok = NULL;
modelica_metatype _tok = NULL;
modelica_metatype _asep = NULL;
modelica_metatype _wsep = NULL;
modelica_integer _nchars;
modelica_integer _tsnchars;
modelica_integer _aind;
modelica_integer _w;
modelica_integer _aoffset;
modelica_integer _anum;
modelica_integer _wwidth;
modelica_integer _blen;
modelica_boolean _isstart;
volatile mmc_switch_type tmp4;
int tmp5;
tmp4 = 0;
for (; tmp4 < 15; tmp4++) {
switch (MMC_SWITCH_CAST(tmp4)) {
case 0: {
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,0,0) == 0) goto tmp3_end;
_toks = tmp4_2;
_nchars = tmp4_3;
_isstart = tmp4_4;
_aind = tmp4_5;
tmp1_c0 = omc_Tpl_tokensFile(threadData, _file, _toks, _nchars, _isstart, _aind, &tmp1_c1, &tmp1_c2);
goto tmp3_done;
}
case 1: {
modelica_metatype tmpMeta6;
modelica_integer tmp7;
if (1 != tmp4_4) goto tmp3_end;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,1,1) == 0) goto tmp3_end;
tmpMeta6 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
tmp7 = mmc_unbox_integer(tmpMeta6);
_w = tmp7;
_toks = tmp4_2;
_nchars = tmp4_3;
_aind = tmp4_5;
_tsnchars = omc_Tpl_tokensFile(threadData, _file, _toks, _w + _nchars, 1, _w + _aind ,&_isstart, NULL);
_nchars = (_isstart?_nchars:_tsnchars);
tmp1_c0 = _nchars;
tmp1_c1 = _isstart;
tmp1_c2 = _aind;
goto tmp3_done;
}
case 2: {
modelica_metatype tmpMeta8;
modelica_integer tmp9;
if (0 != tmp4_4) goto tmp3_end;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,1,1) == 0) goto tmp3_end;
tmpMeta8 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
tmp9 = mmc_unbox_integer(tmpMeta8);
_w = tmp9;
_toks = tmp4_2;
_nchars = tmp4_3;
_aind = tmp4_5;
omc_File_writeSpace(threadData, _file, _w);
_tsnchars = omc_Tpl_tokensFile(threadData, _file, _toks, _w + _nchars, 0, _w + _aind ,&_isstart, NULL);
_nchars = (_isstart?_aind:_tsnchars);
tmp1_c0 = _nchars;
tmp1_c1 = _isstart;
tmp1_c2 = _aind;
goto tmp3_done;
}
case 3: {
modelica_metatype tmpMeta10;
modelica_integer tmp11;
if (1 != tmp4_4) goto tmp3_end;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,2,1) == 0) goto tmp3_end;
tmpMeta10 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
tmp11 = mmc_unbox_integer(tmpMeta10);
_w = tmp11;
_toks = tmp4_2;
_nchars = tmp4_3;
_aind = tmp4_5;
_blen = omc_File_tell(threadData, _file);
_tsnchars = omc_Tpl_tokensFile(threadData, _file, _toks, ((modelica_integer) 0), 1, _w ,&_isstart, NULL);
_blen = omc_File_tell(threadData, _file) - _blen;
_nchars = ((_blen == ((modelica_integer) 0))?_nchars:(_isstart?_aind:_tsnchars));
tmp1_c0 = _nchars;
tmp1_c1 = _isstart;
tmp1_c2 = _aind;
goto tmp3_done;
}
case 4: {
modelica_metatype tmpMeta12;
modelica_integer tmp13;
if (0 != tmp4_4) goto tmp3_end;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,2,1) == 0) goto tmp3_end;
tmpMeta12 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
tmp13 = mmc_unbox_integer(tmpMeta12);
_w = tmp13;
_toks = tmp4_2;
_nchars = tmp4_3;
_aind = tmp4_5;
_tsnchars = omc_Tpl_tokensFile(threadData, _file, _toks, _nchars, 0, _w ,&_isstart, NULL);
_nchars = (_isstart?_aind:_tsnchars);
tmp1_c0 = _nchars;
tmp1_c1 = _isstart;
tmp1_c2 = _aind;
goto tmp3_done;
}
case 5: {
modelica_metatype tmpMeta14;
modelica_integer tmp15;
if (1 != tmp4_4) goto tmp3_end;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,3,1) == 0) goto tmp3_end;
tmpMeta14 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
tmp15 = mmc_unbox_integer(tmpMeta14);
_w = tmp15;
_toks = tmp4_2;
_nchars = tmp4_3;
_aind = tmp4_5;
_blen = omc_File_tell(threadData, _file);
_tsnchars = omc_Tpl_tokensFile(threadData, _file, _toks, _nchars, 1, _aind + _w ,&_isstart, NULL);
_blen = omc_File_tell(threadData, _file) - _blen;
_nchars = ((_blen == ((modelica_integer) 0))?_nchars:(_isstart?_aind:_tsnchars));
tmp1_c0 = _nchars;
tmp1_c1 = _isstart;
tmp1_c2 = _aind;
goto tmp3_done;
}
case 6: {
modelica_metatype tmpMeta16;
modelica_integer tmp17;
if (0 != tmp4_4) goto tmp3_end;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,3,1) == 0) goto tmp3_end;
tmpMeta16 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
tmp17 = mmc_unbox_integer(tmpMeta16);
_w = tmp17;
_toks = tmp4_2;
_nchars = tmp4_3;
_aind = tmp4_5;
_tsnchars = omc_Tpl_tokensFile(threadData, _file, _toks, _nchars, 0, _aind + _w ,&_isstart, NULL);
_nchars = (_isstart?_aind:_tsnchars);
tmp1_c0 = _nchars;
tmp1_c1 = _isstart;
tmp1_c2 = _aind;
goto tmp3_done;
}
case 7: {
modelica_metatype tmpMeta18;
modelica_integer tmp19;
if (1 != tmp4_4) goto tmp3_end;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,4,1) == 0) goto tmp3_end;
tmpMeta18 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
tmp19 = mmc_unbox_integer(tmpMeta18);
_w = tmp19;
_toks = tmp4_2;
_nchars = tmp4_3;
_aind = tmp4_5;
_blen = omc_File_tell(threadData, _file);
_tsnchars = omc_Tpl_tokensFile(threadData, _file, _toks, _nchars, 1, _nchars + _w ,&_isstart, NULL);
_blen = omc_File_tell(threadData, _file) - _blen;
_nchars = ((_blen == ((modelica_integer) 0))?_nchars:(_isstart?_aind:_tsnchars));
tmp1_c0 = _nchars;
tmp1_c1 = _isstart;
tmp1_c2 = _aind;
goto tmp3_done;
}
case 8: {
modelica_metatype tmpMeta20;
modelica_integer tmp21;
if (0 != tmp4_4) goto tmp3_end;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,4,1) == 0) goto tmp3_end;
tmpMeta20 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
tmp21 = mmc_unbox_integer(tmpMeta20);
_w = tmp21;
_toks = tmp4_2;
_nchars = tmp4_3;
_aind = tmp4_5;
_tsnchars = omc_Tpl_tokensFile(threadData, _file, _toks, _nchars, 0, _nchars + _w ,&_isstart, NULL);
_nchars = (_isstart?_aind:_tsnchars);
tmp1_c0 = _nchars;
tmp1_c1 = _isstart;
tmp1_c2 = _aind;
goto tmp3_done;
}
case 9: {
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,5,2) == 0) goto tmp3_end;
if (!listEmpty(tmp4_2)) goto tmp3_end;
_nchars = tmp4_3;
_isstart = tmp4_4;
_aind = tmp4_5;
tmp1_c0 = _nchars;
tmp1_c1 = _isstart;
tmp1_c2 = _aind;
goto tmp3_done;
}
case 10: {
modelica_metatype tmpMeta22;
modelica_metatype tmpMeta23;
modelica_metatype tmpMeta24;
modelica_integer tmp25;
modelica_metatype tmpMeta26;
modelica_integer tmp27;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,5,2) == 0) goto tmp3_end;
tmpMeta22 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
tmpMeta23 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta22), 4));
if (!optionNone(tmpMeta23)) goto tmp3_end;
tmpMeta24 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta22), 5));
tmp25 = mmc_unbox_integer(tmpMeta24);
if (0 != tmp25) goto tmp3_end;
tmpMeta26 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta22), 8));
tmp27 = mmc_unbox_integer(tmpMeta26);
if (0 != tmp27) goto tmp3_end;
_toks = tmp4_2;
_nchars = tmp4_3;
_isstart = tmp4_4;
_aind = tmp4_5;
tmp1_c0 = omc_Tpl_tokensFile(threadData, _file, _toks, _nchars, _isstart, _aind, &tmp1_c1, &tmp1_c2);
goto tmp3_done;
}
case 11: {
modelica_metatype tmpMeta28;
modelica_metatype tmpMeta29;
modelica_metatype tmpMeta30;
modelica_metatype tmpMeta31;
modelica_metatype tmpMeta32;
modelica_metatype tmpMeta33;
modelica_integer tmp34;
modelica_metatype tmpMeta35;
modelica_integer tmp36;
if (listEmpty(tmp4_2)) goto tmp3_end;
tmpMeta28 = MMC_CAR(tmp4_2);
tmpMeta29 = MMC_CDR(tmp4_2);
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,5,2) == 0) goto tmp3_end;
tmpMeta30 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
tmpMeta31 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta30), 4));
if (optionNone(tmpMeta31)) goto tmp3_end;
tmpMeta32 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta31), 1));
tmpMeta33 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta30), 5));
tmp34 = mmc_unbox_integer(tmpMeta33);
if (0 != tmp34) goto tmp3_end;
tmpMeta35 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta30), 8));
tmp36 = mmc_unbox_integer(tmpMeta35);
if (0 != tmp36) goto tmp3_end;
_tok = tmpMeta28;
_toks = tmpMeta29;
_septok = tmpMeta32;
_nchars = tmp4_3;
_isstart = tmp4_4;
_aind = tmp4_5;
_nchars = omc_Tpl_tokFile(threadData, _file, _tok, _nchars, _isstart, _aind ,&_isstart ,&_aind);
_nchars = omc_Tpl_iterSeparatorFile(threadData, _file, _toks, _septok, _nchars, _isstart, _aind ,&_isstart);
tmp1_c0 = _nchars;
tmp1_c1 = _isstart;
tmp1_c2 = _aind;
goto tmp3_done;
}
case 12: {
modelica_metatype tmpMeta37;
modelica_metatype tmpMeta38;
modelica_metatype tmpMeta39;
modelica_metatype tmpMeta40;
modelica_metatype tmpMeta41;
modelica_metatype tmpMeta42;
modelica_integer tmp43;
modelica_metatype tmpMeta44;
modelica_integer tmp45;
modelica_metatype tmpMeta46;
modelica_metatype tmpMeta47;
modelica_integer tmp48;
modelica_metatype tmpMeta49;
if (listEmpty(tmp4_2)) goto tmp3_end;
tmpMeta37 = MMC_CAR(tmp4_2);
tmpMeta38 = MMC_CDR(tmp4_2);
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,5,2) == 0) goto tmp3_end;
tmpMeta39 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
tmpMeta40 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta39), 4));
if (optionNone(tmpMeta40)) goto tmp3_end;
tmpMeta41 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta40), 1));
tmpMeta42 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta39), 5));
tmp43 = mmc_unbox_integer(tmpMeta42);
tmpMeta44 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta39), 6));
tmp45 = mmc_unbox_integer(tmpMeta44);
tmpMeta46 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta39), 7));
tmpMeta47 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta39), 8));
tmp48 = mmc_unbox_integer(tmpMeta47);
tmpMeta49 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta39), 9));
_tok = tmpMeta37;
_toks = tmpMeta38;
_septok = tmpMeta41;
_anum = tmp43;
_aoffset = tmp45;
_asep = tmpMeta46;
_wwidth = tmp48;
_wsep = tmpMeta49;
_nchars = tmp4_3;
_isstart = tmp4_4;
_aind = tmp4_5;
_nchars = omc_Tpl_tokFile(threadData, _file, _tok, _nchars, _isstart, _aind ,&_isstart ,&_aind);
_nchars = omc_Tpl_iterSeparatorAlignWrapFile(threadData, _file, _toks, _septok, ((modelica_integer) 1) + _aoffset, _anum, _asep, _wwidth, _wsep, _nchars, _isstart, _aind ,&_isstart);
tmp1_c0 = _nchars;
tmp1_c1 = _isstart;
tmp1_c2 = _aind;
goto tmp3_done;
}
case 13: {
modelica_metatype tmpMeta50;
modelica_metatype tmpMeta51;
modelica_metatype tmpMeta52;
modelica_integer tmp53;
modelica_metatype tmpMeta54;
modelica_integer tmp55;
modelica_metatype tmpMeta56;
modelica_metatype tmpMeta57;
modelica_integer tmp58;
modelica_metatype tmpMeta59;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,5,2) == 0) goto tmp3_end;
tmpMeta50 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
tmpMeta51 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta50), 4));
if (!optionNone(tmpMeta51)) goto tmp3_end;
tmpMeta52 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta50), 5));
tmp53 = mmc_unbox_integer(tmpMeta52);
tmpMeta54 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta50), 6));
tmp55 = mmc_unbox_integer(tmpMeta54);
tmpMeta56 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta50), 7));
tmpMeta57 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta50), 8));
tmp58 = mmc_unbox_integer(tmpMeta57);
tmpMeta59 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta50), 9));
_anum = tmp53;
_aoffset = tmp55;
_asep = tmpMeta56;
_wwidth = tmp58;
_wsep = tmpMeta59;
_toks = tmp4_2;
_nchars = tmp4_3;
_isstart = tmp4_4;
_aind = tmp4_5;
_nchars = omc_Tpl_iterAlignWrapFile(threadData, _file, _toks, _aoffset, _anum, _asep, _wwidth, _wsep, _nchars, _isstart, _aind ,&_isstart);
tmp1_c0 = _nchars;
tmp1_c1 = _isstart;
tmp1_c2 = _aind;
goto tmp3_done;
}
case 14: {
modelica_boolean tmp60;
tmp60 = omc_Flags_isSet(threadData, _OMC_LIT35);
if (1 != tmp60) goto goto_2;
omc_Debug_trace(threadData, _OMC_LIT43);
goto goto_2;
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
_outActualPositionOnLine = tmp1_c0;
_outAtStartOfLine = tmp1_c1;
_outAfterNewLineIndent = tmp1_c2;
_return: OMC_LABEL_UNUSED
if (out_outAtStartOfLine) { *out_outAtStartOfLine = _outAtStartOfLine; }
if (out_outAfterNewLineIndent) { *out_outAfterNewLineIndent = _outAfterNewLineIndent; }
return _outActualPositionOnLine;
}
PROTECTED_FUNCTION_STATIC modelica_metatype boxptr_Tpl_blockFile(threadData_t *threadData, modelica_metatype _file, modelica_metatype _inBlockType, modelica_metatype _inTokens, modelica_metatype _inActualPositionOnLine, modelica_metatype _inAtStartOfLine, modelica_metatype _inAfterNewLineIndent, modelica_metatype *out_outAtStartOfLine, modelica_metatype *out_outAfterNewLineIndent)
{
modelica_integer tmp1;
modelica_integer tmp2;
modelica_integer tmp3;
modelica_boolean _outAtStartOfLine;
modelica_integer _outAfterNewLineIndent;
modelica_integer _outActualPositionOnLine;
modelica_metatype out_outActualPositionOnLine;
tmp1 = mmc_unbox_integer(_inActualPositionOnLine);
tmp2 = mmc_unbox_integer(_inAtStartOfLine);
tmp3 = mmc_unbox_integer(_inAfterNewLineIndent);
_outActualPositionOnLine = omc_Tpl_blockFile(threadData, _file, _inBlockType, _inTokens, tmp1, tmp2, tmp3, &_outAtStartOfLine, &_outAfterNewLineIndent);
out_outActualPositionOnLine = mmc_mk_icon(_outActualPositionOnLine);
if (out_outAtStartOfLine) { *out_outAtStartOfLine = mmc_mk_icon(_outAtStartOfLine); }
if (out_outAfterNewLineIndent) { *out_outAfterNewLineIndent = mmc_mk_icon(_outAfterNewLineIndent); }
return out_outActualPositionOnLine;
}
PROTECTED_FUNCTION_STATIC modelica_integer omc_Tpl_tryWrapString(threadData_t *threadData, modelica_integer _inWrapWidth, modelica_metatype _inWrapSeparator, modelica_integer _inActualPositionOnLine, modelica_boolean _inAtStartOfLine, modelica_integer _inAfterNewLineIndent, modelica_boolean *out_outAtStartOfLine, modelica_integer *out_outAfterNewLineIndent)
{
modelica_integer _outActualPositionOnLine;
modelica_boolean _outAtStartOfLine;
modelica_integer _outAfterNewLineIndent;
modelica_integer tmp1_c0 __attribute__((unused)) = 0;
modelica_boolean tmp1_c1 __attribute__((unused)) = 0;
modelica_integer tmp1_c2 __attribute__((unused)) = 0;
modelica_metatype tmpMeta[3] __attribute__((unused)) = {0};
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
modelica_integer tmp4_1;modelica_metatype tmp4_2;modelica_integer tmp4_3;modelica_boolean tmp4_4;modelica_integer tmp4_5;
tmp4_1 = _inWrapWidth;
tmp4_2 = _inWrapSeparator;
tmp4_3 = _inActualPositionOnLine;
tmp4_4 = _inAtStartOfLine;
tmp4_5 = _inAfterNewLineIndent;
{
modelica_integer _pos;
modelica_integer _aind;
modelica_integer _wwidth;
modelica_boolean _isstart;
modelica_metatype _wsep = NULL;
volatile mmc_switch_type tmp4;
int tmp5;
tmp4 = 0;
for (; tmp4 < 2; tmp4++) {
switch (MMC_SWITCH_CAST(tmp4)) {
case 0: {
_wwidth = tmp4_1;
_wsep = tmp4_2;
_pos = tmp4_3;
_isstart = tmp4_4;
_aind = tmp4_5;
if (!((_wwidth > ((modelica_integer) 0)) && (_pos >= _wwidth))) goto tmp3_end;
tmp1_c0 = omc_Tpl_tokString(threadData, _wsep, _pos, _isstart, _aind, &tmp1_c1, &tmp1_c2);
goto tmp3_done;
}
case 1: {
tmp1_c0 = _inActualPositionOnLine;
tmp1_c1 = _inAtStartOfLine;
tmp1_c2 = _inAfterNewLineIndent;
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
_outActualPositionOnLine = tmp1_c0;
_outAtStartOfLine = tmp1_c1;
_outAfterNewLineIndent = tmp1_c2;
_return: OMC_LABEL_UNUSED
if (out_outAtStartOfLine) { *out_outAtStartOfLine = _outAtStartOfLine; }
if (out_outAfterNewLineIndent) { *out_outAfterNewLineIndent = _outAfterNewLineIndent; }
return _outActualPositionOnLine;
}
PROTECTED_FUNCTION_STATIC modelica_metatype boxptr_Tpl_tryWrapString(threadData_t *threadData, modelica_metatype _inWrapWidth, modelica_metatype _inWrapSeparator, modelica_metatype _inActualPositionOnLine, modelica_metatype _inAtStartOfLine, modelica_metatype _inAfterNewLineIndent, modelica_metatype *out_outAtStartOfLine, modelica_metatype *out_outAfterNewLineIndent)
{
modelica_integer tmp1;
modelica_integer tmp2;
modelica_integer tmp3;
modelica_integer tmp4;
modelica_boolean _outAtStartOfLine;
modelica_integer _outAfterNewLineIndent;
modelica_integer _outActualPositionOnLine;
modelica_metatype out_outActualPositionOnLine;
tmp1 = mmc_unbox_integer(_inWrapWidth);
tmp2 = mmc_unbox_integer(_inActualPositionOnLine);
tmp3 = mmc_unbox_integer(_inAtStartOfLine);
tmp4 = mmc_unbox_integer(_inAfterNewLineIndent);
_outActualPositionOnLine = omc_Tpl_tryWrapString(threadData, tmp1, _inWrapSeparator, tmp2, tmp3, tmp4, &_outAtStartOfLine, &_outAfterNewLineIndent);
out_outActualPositionOnLine = mmc_mk_icon(_outActualPositionOnLine);
if (out_outAtStartOfLine) { *out_outAtStartOfLine = mmc_mk_icon(_outAtStartOfLine); }
if (out_outAfterNewLineIndent) { *out_outAfterNewLineIndent = mmc_mk_icon(_outAfterNewLineIndent); }
return out_outActualPositionOnLine;
}
PROTECTED_FUNCTION_STATIC modelica_integer omc_Tpl_iterAlignWrapString(threadData_t *threadData, modelica_metatype _inTokens, modelica_integer _inActualIndex, modelica_integer _inAlignNum, modelica_metatype _inAlignSeparator, modelica_integer _inWrapWidth, modelica_metatype _inWrapSeparator, modelica_integer _inActualPositionOnLine, modelica_boolean _inAtStartOfLine, modelica_integer _inAfterNewLineIndent, modelica_boolean *out_outAtStartOfLine)
{
modelica_integer _outActualPositionOnLine;
modelica_boolean _outAtStartOfLine;
modelica_integer tmp1_c0 __attribute__((unused)) = 0;
modelica_boolean tmp1_c1 __attribute__((unused)) = 0;
modelica_metatype tmpMeta[2] __attribute__((unused)) = {0};
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
modelica_metatype tmp4_1;modelica_integer tmp4_2;modelica_integer tmp4_3;modelica_metatype tmp4_4;modelica_integer tmp4_5;modelica_metatype tmp4_6;modelica_integer tmp4_7;modelica_boolean tmp4_8;modelica_integer tmp4_9;
tmp4_1 = _inTokens;
tmp4_2 = _inActualIndex;
tmp4_3 = _inAlignNum;
tmp4_4 = _inAlignSeparator;
tmp4_5 = _inWrapWidth;
tmp4_6 = _inWrapSeparator;
tmp4_7 = _inActualPositionOnLine;
tmp4_8 = _inAtStartOfLine;
tmp4_9 = _inAfterNewLineIndent;
{
modelica_metatype _toks = NULL;
modelica_metatype _tok = NULL;
modelica_metatype _asep = NULL;
modelica_metatype _wsep = NULL;
modelica_integer _pos;
modelica_integer _aind;
modelica_integer _idx;
modelica_integer _anum;
modelica_integer _wwidth;
modelica_boolean _isstart;
volatile mmc_switch_type tmp4;
int tmp5;
tmp4 = 0;
for (; tmp4 < 5; tmp4++) {
switch (MMC_SWITCH_CAST(tmp4)) {
case 0: {
if (!listEmpty(tmp4_1)) goto tmp3_end;
_pos = tmp4_7;
_isstart = tmp4_8;
tmp1_c0 = _pos;
tmp1_c1 = _isstart;
goto tmp3_done;
}
case 1: {
modelica_metatype tmpMeta6;
modelica_metatype tmpMeta7;
if (listEmpty(tmp4_1)) goto tmp3_end;
tmpMeta6 = MMC_CAR(tmp4_1);
tmpMeta7 = MMC_CDR(tmp4_1);
_tok = tmpMeta6;
_toks = tmpMeta7;
_idx = tmp4_2;
_anum = tmp4_3;
_asep = tmp4_4;
_wwidth = tmp4_5;
_wsep = tmp4_6;
_pos = tmp4_7;
_isstart = tmp4_8;
_aind = tmp4_9;
if (!((_idx > ((modelica_integer) 0)) && (modelica_integer_mod(_idx, _anum) == ((modelica_integer) 0)))) goto tmp3_end;
_pos = omc_Tpl_tokString(threadData, _asep, _pos, _isstart, _aind ,&_isstart ,&_aind);
_pos = omc_Tpl_tryWrapString(threadData, _wwidth, _wsep, _pos, _isstart, _aind ,&_isstart ,&_aind);
_pos = omc_Tpl_tokString(threadData, _tok, _pos, _isstart, _aind ,&_isstart ,&_aind);
_inTokens = _toks;
_inActualIndex = ((modelica_integer) 1) + _idx;
_inAlignNum = _anum;
_inAlignSeparator = _asep;
_inWrapWidth = _wwidth;
_inWrapSeparator = _wsep;
_inActualPositionOnLine = _pos;
_inAtStartOfLine = _isstart;
_inAfterNewLineIndent = _aind;
goto _tailrecursive;
goto tmp3_done;
}
case 2: {
modelica_metatype tmpMeta8;
modelica_metatype tmpMeta9;
if (listEmpty(tmp4_1)) goto tmp3_end;
tmpMeta8 = MMC_CAR(tmp4_1);
tmpMeta9 = MMC_CDR(tmp4_1);
_tok = tmpMeta8;
_toks = tmpMeta9;
_idx = tmp4_2;
_anum = tmp4_3;
_asep = tmp4_4;
_wwidth = tmp4_5;
_wsep = tmp4_6;
_pos = tmp4_7;
_isstart = tmp4_8;
_aind = tmp4_9;
if (!((_wwidth > ((modelica_integer) 0)) && (_pos >= _wwidth))) goto tmp3_end;
_pos = omc_Tpl_tokString(threadData, _wsep, _pos, _isstart, _aind ,&_isstart ,&_aind);
_pos = omc_Tpl_tokString(threadData, _tok, _pos, _isstart, _aind ,&_isstart ,&_aind);
_inTokens = _toks;
_inActualIndex = ((modelica_integer) 1) + _idx;
_inAlignNum = _anum;
_inAlignSeparator = _asep;
_inWrapWidth = _wwidth;
_inWrapSeparator = _wsep;
_inActualPositionOnLine = _pos;
_inAtStartOfLine = _isstart;
_inAfterNewLineIndent = _aind;
goto _tailrecursive;
goto tmp3_done;
}
case 3: {
modelica_metatype tmpMeta10;
modelica_metatype tmpMeta11;
if (listEmpty(tmp4_1)) goto tmp3_end;
tmpMeta10 = MMC_CAR(tmp4_1);
tmpMeta11 = MMC_CDR(tmp4_1);
_tok = tmpMeta10;
_toks = tmpMeta11;
_idx = tmp4_2;
_anum = tmp4_3;
_asep = tmp4_4;
_wwidth = tmp4_5;
_wsep = tmp4_6;
_pos = tmp4_7;
_isstart = tmp4_8;
_aind = tmp4_9;
_pos = omc_Tpl_tokString(threadData, _tok, _pos, _isstart, _aind ,&_isstart ,&_aind);
_inTokens = _toks;
_inActualIndex = ((modelica_integer) 1) + _idx;
_inAlignNum = _anum;
_inAlignSeparator = _asep;
_inWrapWidth = _wwidth;
_inWrapSeparator = _wsep;
_inActualPositionOnLine = _pos;
_inAtStartOfLine = _isstart;
_inAfterNewLineIndent = _aind;
goto _tailrecursive;
goto tmp3_done;
}
case 4: {
modelica_boolean tmp12;
tmp12 = omc_Flags_isSet(threadData, _OMC_LIT35);
if (1 != tmp12) goto goto_2;
omc_Debug_trace(threadData, _OMC_LIT42);
goto goto_2;
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
_outActualPositionOnLine = tmp1_c0;
_outAtStartOfLine = tmp1_c1;
_return: OMC_LABEL_UNUSED
if (out_outAtStartOfLine) { *out_outAtStartOfLine = _outAtStartOfLine; }
return _outActualPositionOnLine;
}
PROTECTED_FUNCTION_STATIC modelica_metatype boxptr_Tpl_iterAlignWrapString(threadData_t *threadData, modelica_metatype _inTokens, modelica_metatype _inActualIndex, modelica_metatype _inAlignNum, modelica_metatype _inAlignSeparator, modelica_metatype _inWrapWidth, modelica_metatype _inWrapSeparator, modelica_metatype _inActualPositionOnLine, modelica_metatype _inAtStartOfLine, modelica_metatype _inAfterNewLineIndent, modelica_metatype *out_outAtStartOfLine)
{
modelica_integer tmp1;
modelica_integer tmp2;
modelica_integer tmp3;
modelica_integer tmp4;
modelica_integer tmp5;
modelica_integer tmp6;
modelica_boolean _outAtStartOfLine;
modelica_integer _outActualPositionOnLine;
modelica_metatype out_outActualPositionOnLine;
tmp1 = mmc_unbox_integer(_inActualIndex);
tmp2 = mmc_unbox_integer(_inAlignNum);
tmp3 = mmc_unbox_integer(_inWrapWidth);
tmp4 = mmc_unbox_integer(_inActualPositionOnLine);
tmp5 = mmc_unbox_integer(_inAtStartOfLine);
tmp6 = mmc_unbox_integer(_inAfterNewLineIndent);
_outActualPositionOnLine = omc_Tpl_iterAlignWrapString(threadData, _inTokens, tmp1, tmp2, _inAlignSeparator, tmp3, _inWrapSeparator, tmp4, tmp5, tmp6, &_outAtStartOfLine);
out_outActualPositionOnLine = mmc_mk_icon(_outActualPositionOnLine);
if (out_outAtStartOfLine) { *out_outAtStartOfLine = mmc_mk_icon(_outAtStartOfLine); }
return out_outActualPositionOnLine;
}
PROTECTED_FUNCTION_STATIC modelica_integer omc_Tpl_iterSeparatorAlignWrapString(threadData_t *threadData, modelica_metatype _inTokens, modelica_metatype _inSeparator, modelica_integer _inActualIndex, modelica_integer _inAlignNum, modelica_metatype _inAlignSeparator, modelica_integer _inWrapWidth, modelica_metatype _inWrapSeparator, modelica_integer _inActualPositionOnLine, modelica_boolean _inAtStartOfLine, modelica_integer _inAfterNewLineIndent, modelica_boolean *out_outAtStartOfLine)
{
modelica_integer _outActualPositionOnLine;
modelica_boolean _outAtStartOfLine;
modelica_metatype _toks = NULL;
modelica_metatype _tok = NULL;
modelica_metatype _septok = NULL;
modelica_integer _idx;
modelica_integer _anum;
modelica_metatype _asep = NULL;
modelica_integer _wwidth;
modelica_metatype _wsep = NULL;
modelica_integer _pos;
modelica_boolean _isstart;
modelica_integer _aind;
modelica_metatype tmpMeta1;
modelica_metatype tmpMeta2;
modelica_metatype tmpMeta3;
modelica_metatype tmpMeta4;
modelica_metatype tmpMeta5;
modelica_metatype tmpMeta6;
modelica_integer tmp7;
modelica_metatype tmpMeta8;
modelica_integer tmp9;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
_toks = _inTokens;
_septok = _inSeparator;
_idx = _inActualIndex;
_anum = _inAlignNum;
_asep = _inAlignSeparator;
_wwidth = _inWrapWidth;
_wsep = _inWrapSeparator;
_pos = _inActualPositionOnLine;
_isstart = _inAtStartOfLine;
_aind = _inAfterNewLineIndent;
while(1)
{
if(!(!listEmpty(_toks))) break;
tmpMeta1 = _toks;
if (listEmpty(tmpMeta1)) MMC_THROW_INTERNAL();
tmpMeta2 = MMC_CAR(tmpMeta1);
tmpMeta3 = MMC_CDR(tmpMeta1);
_tok = tmpMeta2;
_toks = tmpMeta3;
if(((_idx > ((modelica_integer) 0)) && (modelica_integer_mod(_idx, _anum) == ((modelica_integer) 0))))
{
_pos = omc_Tpl_tokString(threadData, _asep, _pos, _isstart, _aind ,&_isstart ,&_aind);
}
else
{
_pos = omc_Tpl_tokString(threadData, _septok, _pos, _isstart, _aind ,&_isstart ,&_aind);
}
_pos = omc_Tpl_tryWrapString(threadData, _wwidth, _wsep, _pos, _isstart, _aind ,&_isstart ,&_aind);
_pos = omc_Tpl_tokString(threadData, _tok, _pos, _isstart, _aind ,&_isstart ,&_aind);
_idx = ((modelica_integer) 1) + _idx;
}
tmpMeta4 = mmc_mk_box2(0, mmc_mk_integer(_pos), mmc_mk_boolean(_isstart));
tmpMeta5 = tmpMeta4;
tmpMeta6 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta5), 1));
tmp7 = mmc_unbox_integer(tmpMeta6);
tmpMeta8 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta5), 2));
tmp9 = mmc_unbox_integer(tmpMeta8);
_outActualPositionOnLine = tmp7;
_outAtStartOfLine = tmp9;
_return: OMC_LABEL_UNUSED
if (out_outAtStartOfLine) { *out_outAtStartOfLine = _outAtStartOfLine; }
return _outActualPositionOnLine;
}
PROTECTED_FUNCTION_STATIC modelica_metatype boxptr_Tpl_iterSeparatorAlignWrapString(threadData_t *threadData, modelica_metatype _inTokens, modelica_metatype _inSeparator, modelica_metatype _inActualIndex, modelica_metatype _inAlignNum, modelica_metatype _inAlignSeparator, modelica_metatype _inWrapWidth, modelica_metatype _inWrapSeparator, modelica_metatype _inActualPositionOnLine, modelica_metatype _inAtStartOfLine, modelica_metatype _inAfterNewLineIndent, modelica_metatype *out_outAtStartOfLine)
{
modelica_integer tmp1;
modelica_integer tmp2;
modelica_integer tmp3;
modelica_integer tmp4;
modelica_integer tmp5;
modelica_integer tmp6;
modelica_boolean _outAtStartOfLine;
modelica_integer _outActualPositionOnLine;
modelica_metatype out_outActualPositionOnLine;
tmp1 = mmc_unbox_integer(_inActualIndex);
tmp2 = mmc_unbox_integer(_inAlignNum);
tmp3 = mmc_unbox_integer(_inWrapWidth);
tmp4 = mmc_unbox_integer(_inActualPositionOnLine);
tmp5 = mmc_unbox_integer(_inAtStartOfLine);
tmp6 = mmc_unbox_integer(_inAfterNewLineIndent);
_outActualPositionOnLine = omc_Tpl_iterSeparatorAlignWrapString(threadData, _inTokens, _inSeparator, tmp1, tmp2, _inAlignSeparator, tmp3, _inWrapSeparator, tmp4, tmp5, tmp6, &_outAtStartOfLine);
out_outActualPositionOnLine = mmc_mk_icon(_outActualPositionOnLine);
if (out_outAtStartOfLine) { *out_outAtStartOfLine = mmc_mk_icon(_outAtStartOfLine); }
return out_outActualPositionOnLine;
}
PROTECTED_FUNCTION_STATIC modelica_integer omc_Tpl_iterSeparatorString(threadData_t *threadData, modelica_metatype _inTokens, modelica_metatype _inSeparator, modelica_integer _inActualPositionOnLine, modelica_boolean _inAtStartOfLine, modelica_integer _inAfterNewLineIndent, modelica_boolean *out_outAtStartOfLine)
{
modelica_integer _outActualPositionOnLine;
modelica_boolean _outAtStartOfLine;
modelica_integer tmp1_c0 __attribute__((unused)) = 0;
modelica_boolean tmp1_c1 __attribute__((unused)) = 0;
modelica_metatype tmpMeta[2] __attribute__((unused)) = {0};
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
modelica_metatype tmp4_1;modelica_metatype tmp4_2;modelica_integer tmp4_3;modelica_boolean tmp4_4;modelica_integer tmp4_5;
tmp4_1 = _inTokens;
tmp4_2 = _inSeparator;
tmp4_3 = _inActualPositionOnLine;
tmp4_4 = _inAtStartOfLine;
tmp4_5 = _inAfterNewLineIndent;
{
modelica_metatype _toks = NULL;
modelica_metatype _tok = NULL;
modelica_metatype _septok = NULL;
modelica_integer _pos;
modelica_integer _aind;
modelica_boolean _isstart;
volatile mmc_switch_type tmp4;
int tmp5;
tmp4 = 0;
for (; tmp4 < 2; tmp4++) {
switch (MMC_SWITCH_CAST(tmp4)) {
case 0: {
if (!listEmpty(tmp4_1)) goto tmp3_end;
_pos = tmp4_3;
_isstart = tmp4_4;
tmp1_c0 = _pos;
tmp1_c1 = _isstart;
goto tmp3_done;
}
case 1: {
modelica_metatype tmpMeta6;
modelica_metatype tmpMeta7;
if (listEmpty(tmp4_1)) goto tmp3_end;
tmpMeta6 = MMC_CAR(tmp4_1);
tmpMeta7 = MMC_CDR(tmp4_1);
_tok = tmpMeta6;
_toks = tmpMeta7;
_septok = tmp4_2;
_pos = tmp4_3;
_isstart = tmp4_4;
_aind = tmp4_5;
_pos = omc_Tpl_tokString(threadData, _septok, _pos, _isstart, _aind ,&_isstart ,&_aind);
_pos = omc_Tpl_tokString(threadData, _tok, _pos, _isstart, _aind ,&_isstart ,&_aind);
_inTokens = _toks;
_inSeparator = _septok;
_inActualPositionOnLine = _pos;
_inAtStartOfLine = _isstart;
_inAfterNewLineIndent = _aind;
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
_outActualPositionOnLine = tmp1_c0;
_outAtStartOfLine = tmp1_c1;
_return: OMC_LABEL_UNUSED
if (out_outAtStartOfLine) { *out_outAtStartOfLine = _outAtStartOfLine; }
return _outActualPositionOnLine;
}
PROTECTED_FUNCTION_STATIC modelica_metatype boxptr_Tpl_iterSeparatorString(threadData_t *threadData, modelica_metatype _inTokens, modelica_metatype _inSeparator, modelica_metatype _inActualPositionOnLine, modelica_metatype _inAtStartOfLine, modelica_metatype _inAfterNewLineIndent, modelica_metatype *out_outAtStartOfLine)
{
modelica_integer tmp1;
modelica_integer tmp2;
modelica_integer tmp3;
modelica_boolean _outAtStartOfLine;
modelica_integer _outActualPositionOnLine;
modelica_metatype out_outActualPositionOnLine;
tmp1 = mmc_unbox_integer(_inActualPositionOnLine);
tmp2 = mmc_unbox_integer(_inAtStartOfLine);
tmp3 = mmc_unbox_integer(_inAfterNewLineIndent);
_outActualPositionOnLine = omc_Tpl_iterSeparatorString(threadData, _inTokens, _inSeparator, tmp1, tmp2, tmp3, &_outAtStartOfLine);
out_outActualPositionOnLine = mmc_mk_icon(_outActualPositionOnLine);
if (out_outAtStartOfLine) { *out_outAtStartOfLine = mmc_mk_icon(_outAtStartOfLine); }
return out_outActualPositionOnLine;
}
PROTECTED_FUNCTION_STATIC modelica_integer omc_Tpl_blockString(threadData_t *threadData, modelica_metatype _inBlockType, modelica_metatype _inTokens, modelica_integer _inActualPositionOnLine, modelica_boolean _inAtStartOfLine, modelica_integer _inAfterNewLineIndent, modelica_boolean *out_outAtStartOfLine, modelica_integer *out_outAfterNewLineIndent)
{
modelica_integer _outActualPositionOnLine;
modelica_boolean _outAtStartOfLine;
modelica_integer _outAfterNewLineIndent;
modelica_integer tmp1_c0 __attribute__((unused)) = 0;
modelica_boolean tmp1_c1 __attribute__((unused)) = 0;
modelica_integer tmp1_c2 __attribute__((unused)) = 0;
modelica_metatype tmpMeta[3] __attribute__((unused)) = {0};
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
modelica_metatype tmp4_1;modelica_metatype tmp4_2;modelica_integer tmp4_3;modelica_boolean tmp4_4;modelica_integer tmp4_5;
tmp4_1 = _inBlockType;
tmp4_2 = _inTokens;
tmp4_3 = _inActualPositionOnLine;
tmp4_4 = _inAtStartOfLine;
tmp4_5 = _inAfterNewLineIndent;
{
modelica_metatype _toks = NULL;
modelica_metatype _septok = NULL;
modelica_metatype _tok = NULL;
modelica_metatype _asep = NULL;
modelica_metatype _wsep = NULL;
modelica_integer _nchars;
modelica_integer _tsnchars;
modelica_integer _aind;
modelica_integer _w;
modelica_integer _aoffset;
modelica_integer _anum;
modelica_integer _wwidth;
modelica_integer _blen;
modelica_boolean _isstart;
volatile mmc_switch_type tmp4;
int tmp5;
tmp4 = 0;
for (; tmp4 < 15; tmp4++) {
switch (MMC_SWITCH_CAST(tmp4)) {
case 0: {
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,0,0) == 0) goto tmp3_end;
_toks = tmp4_2;
_nchars = tmp4_3;
_isstart = tmp4_4;
_aind = tmp4_5;
tmp1_c0 = omc_Tpl_tokensString(threadData, _toks, _nchars, _isstart, _aind, &tmp1_c1, &tmp1_c2);
goto tmp3_done;
}
case 1: {
modelica_metatype tmpMeta6;
modelica_integer tmp7;
if (1 != tmp4_4) goto tmp3_end;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,1,1) == 0) goto tmp3_end;
tmpMeta6 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
tmp7 = mmc_unbox_integer(tmpMeta6);
_w = tmp7;
_toks = tmp4_2;
_nchars = tmp4_3;
_aind = tmp4_5;
_tsnchars = omc_Tpl_tokensString(threadData, _toks, _w + _nchars, 1, _w + _aind ,&_isstart, NULL);
_nchars = (_isstart?_nchars:_tsnchars);
tmp1_c0 = _nchars;
tmp1_c1 = _isstart;
tmp1_c2 = _aind;
goto tmp3_done;
}
case 2: {
modelica_metatype tmpMeta8;
modelica_integer tmp9;
if (0 != tmp4_4) goto tmp3_end;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,1,1) == 0) goto tmp3_end;
tmpMeta8 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
tmp9 = mmc_unbox_integer(tmpMeta8);
_w = tmp9;
_toks = tmp4_2;
_nchars = tmp4_3;
_aind = tmp4_5;
omc_Print_printBufSpace(threadData, _w);
_tsnchars = omc_Tpl_tokensString(threadData, _toks, _w + _nchars, 0, _w + _aind ,&_isstart, NULL);
_nchars = (_isstart?_aind:_tsnchars);
tmp1_c0 = _nchars;
tmp1_c1 = _isstart;
tmp1_c2 = _aind;
goto tmp3_done;
}
case 3: {
modelica_metatype tmpMeta10;
modelica_integer tmp11;
if (1 != tmp4_4) goto tmp3_end;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,2,1) == 0) goto tmp3_end;
tmpMeta10 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
tmp11 = mmc_unbox_integer(tmpMeta10);
_w = tmp11;
_toks = tmp4_2;
_nchars = tmp4_3;
_aind = tmp4_5;
_blen = omc_Print_getBufLength(threadData);
_tsnchars = omc_Tpl_tokensString(threadData, _toks, ((modelica_integer) 0), 1, _w ,&_isstart, NULL);
_blen = omc_Print_getBufLength(threadData) - _blen;
_nchars = ((_blen == ((modelica_integer) 0))?_nchars:(_isstart?_aind:_tsnchars));
tmp1_c0 = _nchars;
tmp1_c1 = _isstart;
tmp1_c2 = _aind;
goto tmp3_done;
}
case 4: {
modelica_metatype tmpMeta12;
modelica_integer tmp13;
if (0 != tmp4_4) goto tmp3_end;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,2,1) == 0) goto tmp3_end;
tmpMeta12 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
tmp13 = mmc_unbox_integer(tmpMeta12);
_w = tmp13;
_toks = tmp4_2;
_nchars = tmp4_3;
_aind = tmp4_5;
_tsnchars = omc_Tpl_tokensString(threadData, _toks, _nchars, 0, _w ,&_isstart, NULL);
_nchars = (_isstart?_aind:_tsnchars);
tmp1_c0 = _nchars;
tmp1_c1 = _isstart;
tmp1_c2 = _aind;
goto tmp3_done;
}
case 5: {
modelica_metatype tmpMeta14;
modelica_integer tmp15;
if (1 != tmp4_4) goto tmp3_end;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,3,1) == 0) goto tmp3_end;
tmpMeta14 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
tmp15 = mmc_unbox_integer(tmpMeta14);
_w = tmp15;
_toks = tmp4_2;
_nchars = tmp4_3;
_aind = tmp4_5;
_blen = omc_Print_getBufLength(threadData);
_tsnchars = omc_Tpl_tokensString(threadData, _toks, _nchars, 1, _aind + _w ,&_isstart, NULL);
_blen = omc_Print_getBufLength(threadData) - _blen;
_nchars = ((_blen == ((modelica_integer) 0))?_nchars:(_isstart?_aind:_tsnchars));
tmp1_c0 = _nchars;
tmp1_c1 = _isstart;
tmp1_c2 = _aind;
goto tmp3_done;
}
case 6: {
modelica_metatype tmpMeta16;
modelica_integer tmp17;
if (0 != tmp4_4) goto tmp3_end;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,3,1) == 0) goto tmp3_end;
tmpMeta16 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
tmp17 = mmc_unbox_integer(tmpMeta16);
_w = tmp17;
_toks = tmp4_2;
_nchars = tmp4_3;
_aind = tmp4_5;
_tsnchars = omc_Tpl_tokensString(threadData, _toks, _nchars, 0, _aind + _w ,&_isstart, NULL);
_nchars = (_isstart?_aind:_tsnchars);
tmp1_c0 = _nchars;
tmp1_c1 = _isstart;
tmp1_c2 = _aind;
goto tmp3_done;
}
case 7: {
modelica_metatype tmpMeta18;
modelica_integer tmp19;
if (1 != tmp4_4) goto tmp3_end;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,4,1) == 0) goto tmp3_end;
tmpMeta18 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
tmp19 = mmc_unbox_integer(tmpMeta18);
_w = tmp19;
_toks = tmp4_2;
_nchars = tmp4_3;
_aind = tmp4_5;
_blen = omc_Print_getBufLength(threadData);
_tsnchars = omc_Tpl_tokensString(threadData, _toks, _nchars, 1, _nchars + _w ,&_isstart, NULL);
_blen = omc_Print_getBufLength(threadData) - _blen;
_nchars = ((_blen == ((modelica_integer) 0))?_nchars:(_isstart?_aind:_tsnchars));
tmp1_c0 = _nchars;
tmp1_c1 = _isstart;
tmp1_c2 = _aind;
goto tmp3_done;
}
case 8: {
modelica_metatype tmpMeta20;
modelica_integer tmp21;
if (0 != tmp4_4) goto tmp3_end;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,4,1) == 0) goto tmp3_end;
tmpMeta20 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
tmp21 = mmc_unbox_integer(tmpMeta20);
_w = tmp21;
_toks = tmp4_2;
_nchars = tmp4_3;
_aind = tmp4_5;
_tsnchars = omc_Tpl_tokensString(threadData, _toks, _nchars, 0, _nchars + _w ,&_isstart, NULL);
_nchars = (_isstart?_aind:_tsnchars);
tmp1_c0 = _nchars;
tmp1_c1 = _isstart;
tmp1_c2 = _aind;
goto tmp3_done;
}
case 9: {
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,5,2) == 0) goto tmp3_end;
if (!listEmpty(tmp4_2)) goto tmp3_end;
_nchars = tmp4_3;
_isstart = tmp4_4;
_aind = tmp4_5;
tmp1_c0 = _nchars;
tmp1_c1 = _isstart;
tmp1_c2 = _aind;
goto tmp3_done;
}
case 10: {
modelica_metatype tmpMeta22;
modelica_metatype tmpMeta23;
modelica_metatype tmpMeta24;
modelica_integer tmp25;
modelica_metatype tmpMeta26;
modelica_integer tmp27;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,5,2) == 0) goto tmp3_end;
tmpMeta22 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
tmpMeta23 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta22), 4));
if (!optionNone(tmpMeta23)) goto tmp3_end;
tmpMeta24 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta22), 5));
tmp25 = mmc_unbox_integer(tmpMeta24);
if (0 != tmp25) goto tmp3_end;
tmpMeta26 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta22), 8));
tmp27 = mmc_unbox_integer(tmpMeta26);
if (0 != tmp27) goto tmp3_end;
_toks = tmp4_2;
_nchars = tmp4_3;
_isstart = tmp4_4;
_aind = tmp4_5;
tmp1_c0 = omc_Tpl_tokensString(threadData, _toks, _nchars, _isstart, _aind, &tmp1_c1, &tmp1_c2);
goto tmp3_done;
}
case 11: {
modelica_metatype tmpMeta28;
modelica_metatype tmpMeta29;
modelica_metatype tmpMeta30;
modelica_metatype tmpMeta31;
modelica_metatype tmpMeta32;
modelica_metatype tmpMeta33;
modelica_integer tmp34;
modelica_metatype tmpMeta35;
modelica_integer tmp36;
if (listEmpty(tmp4_2)) goto tmp3_end;
tmpMeta28 = MMC_CAR(tmp4_2);
tmpMeta29 = MMC_CDR(tmp4_2);
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,5,2) == 0) goto tmp3_end;
tmpMeta30 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
tmpMeta31 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta30), 4));
if (optionNone(tmpMeta31)) goto tmp3_end;
tmpMeta32 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta31), 1));
tmpMeta33 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta30), 5));
tmp34 = mmc_unbox_integer(tmpMeta33);
if (0 != tmp34) goto tmp3_end;
tmpMeta35 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta30), 8));
tmp36 = mmc_unbox_integer(tmpMeta35);
if (0 != tmp36) goto tmp3_end;
_tok = tmpMeta28;
_toks = tmpMeta29;
_septok = tmpMeta32;
_nchars = tmp4_3;
_isstart = tmp4_4;
_aind = tmp4_5;
_nchars = omc_Tpl_tokString(threadData, _tok, _nchars, _isstart, _aind ,&_isstart ,&_aind);
_nchars = omc_Tpl_iterSeparatorString(threadData, _toks, _septok, _nchars, _isstart, _aind ,&_isstart);
tmp1_c0 = _nchars;
tmp1_c1 = _isstart;
tmp1_c2 = _aind;
goto tmp3_done;
}
case 12: {
modelica_metatype tmpMeta37;
modelica_metatype tmpMeta38;
modelica_metatype tmpMeta39;
modelica_metatype tmpMeta40;
modelica_metatype tmpMeta41;
modelica_metatype tmpMeta42;
modelica_integer tmp43;
modelica_metatype tmpMeta44;
modelica_integer tmp45;
modelica_metatype tmpMeta46;
modelica_metatype tmpMeta47;
modelica_integer tmp48;
modelica_metatype tmpMeta49;
if (listEmpty(tmp4_2)) goto tmp3_end;
tmpMeta37 = MMC_CAR(tmp4_2);
tmpMeta38 = MMC_CDR(tmp4_2);
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,5,2) == 0) goto tmp3_end;
tmpMeta39 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
tmpMeta40 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta39), 4));
if (optionNone(tmpMeta40)) goto tmp3_end;
tmpMeta41 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta40), 1));
tmpMeta42 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta39), 5));
tmp43 = mmc_unbox_integer(tmpMeta42);
tmpMeta44 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta39), 6));
tmp45 = mmc_unbox_integer(tmpMeta44);
tmpMeta46 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta39), 7));
tmpMeta47 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta39), 8));
tmp48 = mmc_unbox_integer(tmpMeta47);
tmpMeta49 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta39), 9));
_tok = tmpMeta37;
_toks = tmpMeta38;
_septok = tmpMeta41;
_anum = tmp43;
_aoffset = tmp45;
_asep = tmpMeta46;
_wwidth = tmp48;
_wsep = tmpMeta49;
_nchars = tmp4_3;
_isstart = tmp4_4;
_aind = tmp4_5;
_nchars = omc_Tpl_tokString(threadData, _tok, _nchars, _isstart, _aind ,&_isstart ,&_aind);
_nchars = omc_Tpl_iterSeparatorAlignWrapString(threadData, _toks, _septok, ((modelica_integer) 1) + _aoffset, _anum, _asep, _wwidth, _wsep, _nchars, _isstart, _aind ,&_isstart);
tmp1_c0 = _nchars;
tmp1_c1 = _isstart;
tmp1_c2 = _aind;
goto tmp3_done;
}
case 13: {
modelica_metatype tmpMeta50;
modelica_metatype tmpMeta51;
modelica_metatype tmpMeta52;
modelica_integer tmp53;
modelica_metatype tmpMeta54;
modelica_integer tmp55;
modelica_metatype tmpMeta56;
modelica_metatype tmpMeta57;
modelica_integer tmp58;
modelica_metatype tmpMeta59;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,5,2) == 0) goto tmp3_end;
tmpMeta50 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
tmpMeta51 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta50), 4));
if (!optionNone(tmpMeta51)) goto tmp3_end;
tmpMeta52 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta50), 5));
tmp53 = mmc_unbox_integer(tmpMeta52);
tmpMeta54 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta50), 6));
tmp55 = mmc_unbox_integer(tmpMeta54);
tmpMeta56 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta50), 7));
tmpMeta57 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta50), 8));
tmp58 = mmc_unbox_integer(tmpMeta57);
tmpMeta59 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta50), 9));
_anum = tmp53;
_aoffset = tmp55;
_asep = tmpMeta56;
_wwidth = tmp58;
_wsep = tmpMeta59;
_toks = tmp4_2;
_nchars = tmp4_3;
_isstart = tmp4_4;
_aind = tmp4_5;
_nchars = omc_Tpl_iterAlignWrapString(threadData, _toks, _aoffset, _anum, _asep, _wwidth, _wsep, _nchars, _isstart, _aind ,&_isstart);
tmp1_c0 = _nchars;
tmp1_c1 = _isstart;
tmp1_c2 = _aind;
goto tmp3_done;
}
case 14: {
modelica_boolean tmp60;
tmp60 = omc_Flags_isSet(threadData, _OMC_LIT35);
if (1 != tmp60) goto goto_2;
omc_Debug_trace(threadData, _OMC_LIT43);
goto goto_2;
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
_outActualPositionOnLine = tmp1_c0;
_outAtStartOfLine = tmp1_c1;
_outAfterNewLineIndent = tmp1_c2;
_return: OMC_LABEL_UNUSED
if (out_outAtStartOfLine) { *out_outAtStartOfLine = _outAtStartOfLine; }
if (out_outAfterNewLineIndent) { *out_outAfterNewLineIndent = _outAfterNewLineIndent; }
return _outActualPositionOnLine;
}
PROTECTED_FUNCTION_STATIC modelica_metatype boxptr_Tpl_blockString(threadData_t *threadData, modelica_metatype _inBlockType, modelica_metatype _inTokens, modelica_metatype _inActualPositionOnLine, modelica_metatype _inAtStartOfLine, modelica_metatype _inAfterNewLineIndent, modelica_metatype *out_outAtStartOfLine, modelica_metatype *out_outAfterNewLineIndent)
{
modelica_integer tmp1;
modelica_integer tmp2;
modelica_integer tmp3;
modelica_boolean _outAtStartOfLine;
modelica_integer _outAfterNewLineIndent;
modelica_integer _outActualPositionOnLine;
modelica_metatype out_outActualPositionOnLine;
tmp1 = mmc_unbox_integer(_inActualPositionOnLine);
tmp2 = mmc_unbox_integer(_inAtStartOfLine);
tmp3 = mmc_unbox_integer(_inAfterNewLineIndent);
_outActualPositionOnLine = omc_Tpl_blockString(threadData, _inBlockType, _inTokens, tmp1, tmp2, tmp3, &_outAtStartOfLine, &_outAfterNewLineIndent);
out_outActualPositionOnLine = mmc_mk_icon(_outActualPositionOnLine);
if (out_outAtStartOfLine) { *out_outAtStartOfLine = mmc_mk_icon(_outAtStartOfLine); }
if (out_outAfterNewLineIndent) { *out_outAfterNewLineIndent = mmc_mk_icon(_outAfterNewLineIndent); }
return out_outActualPositionOnLine;
}
PROTECTED_FUNCTION_STATIC modelica_integer omc_Tpl_stringListFile(threadData_t *threadData, modelica_complex _file, modelica_metatype _inStringList, modelica_integer __omcQ_24in_5Fnchars, modelica_boolean __omcQ_24in_5Fisstart, modelica_integer __omcQ_24in_5Faind, modelica_boolean *out_isstart, modelica_integer *out_aind)
{
modelica_integer _nchars;
modelica_boolean _isstart;
modelica_integer _aind;
modelica_integer tmp1_c0 __attribute__((unused)) = 0;
modelica_boolean tmp1_c1 __attribute__((unused)) = 0;
modelica_integer tmp1_c2 __attribute__((unused)) = 0;
modelica_metatype tmpMeta[3] __attribute__((unused)) = {0};
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
_nchars = __omcQ_24in_5Fnchars;
_isstart = __omcQ_24in_5Fisstart;
_aind = __omcQ_24in_5Faind;
{
modelica_metatype tmp4_1;modelica_integer tmp4_2;modelica_boolean tmp4_3;modelica_integer tmp4_4;
tmp4_1 = _inStringList;
tmp4_2 = _nchars;
tmp4_3 = _isstart;
tmp4_4 = _aind;
{
modelica_string _str = NULL;
modelica_metatype _strLst = NULL;
modelica_boolean _hasNL;
volatile mmc_switch_type tmp4;
int tmp5;
tmp4 = 0;
for (; tmp4 < 5; tmp4++) {
switch (MMC_SWITCH_CAST(tmp4)) {
case 0: {
if (!listEmpty(tmp4_1)) goto tmp3_end;
_isstart = tmp4_3;
_aind = tmp4_4;
tmp1_c0 = _aind;
tmp1_c1 = _isstart;
tmp1_c2 = _aind;
goto tmp3_done;
}
case 1: {
modelica_metatype tmpMeta6;
modelica_metatype tmpMeta7;
if (listEmpty(tmp4_1)) goto tmp3_end;
tmpMeta6 = MMC_CAR(tmp4_1);
tmpMeta7 = MMC_CDR(tmp4_1);
if (0 != MMC_STRLEN(tmpMeta6) || strcmp(MMC_STRINGDATA(_OMC_LIT20), MMC_STRINGDATA(tmpMeta6)) != 0) goto tmp3_end;
_strLst = tmpMeta7;
_nchars = tmp4_2;
_isstart = tmp4_3;
_aind = tmp4_4;
_inStringList = _strLst;
__omcQ_24in_5Fnchars = _nchars;
__omcQ_24in_5Fisstart = _isstart;
__omcQ_24in_5Faind = _aind;
goto _tailrecursive;
goto tmp3_done;
}
case 2: {
modelica_metatype tmpMeta8;
modelica_metatype tmpMeta9;
if (1 != tmp4_3) goto tmp3_end;
if (listEmpty(tmp4_1)) goto tmp3_end;
tmpMeta8 = MMC_CAR(tmp4_1);
tmpMeta9 = MMC_CDR(tmp4_1);
_str = tmpMeta8;
_strLst = tmpMeta9;
_nchars = tmp4_2;
_aind = tmp4_4;
omc_File_writeSpace(threadData, _file, _nchars);
omc_File_write(threadData, _file, _str);
_hasNL = omc_StringUtil_endsWithNewline(threadData, _str);
_nchars = (_hasNL?_aind:_nchars + stringLength(_str));
_inStringList = _strLst;
__omcQ_24in_5Fnchars = _nchars;
__omcQ_24in_5Fisstart = _hasNL;
__omcQ_24in_5Faind = _aind;
goto _tailrecursive;
goto tmp3_done;
}
case 3: {
modelica_metatype tmpMeta10;
modelica_metatype tmpMeta11;
if (0 != tmp4_3) goto tmp3_end;
if (listEmpty(tmp4_1)) goto tmp3_end;
tmpMeta10 = MMC_CAR(tmp4_1);
tmpMeta11 = MMC_CDR(tmp4_1);
_str = tmpMeta10;
_strLst = tmpMeta11;
_nchars = tmp4_2;
_aind = tmp4_4;
omc_File_write(threadData, _file, _str);
_hasNL = omc_StringUtil_endsWithNewline(threadData, _str);
_nchars = (_hasNL?_aind:_nchars + stringLength(_str));
_inStringList = _strLst;
__omcQ_24in_5Fnchars = _nchars;
__omcQ_24in_5Fisstart = _hasNL;
__omcQ_24in_5Faind = _aind;
goto _tailrecursive;
goto tmp3_done;
}
case 4: {
modelica_boolean tmp12;
tmp12 = omc_Flags_isSet(threadData, _OMC_LIT35);
if (1 != tmp12) goto goto_2;
omc_Debug_trace(threadData, _OMC_LIT44);
goto goto_2;
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
_nchars = tmp1_c0;
_isstart = tmp1_c1;
_aind = tmp1_c2;
_return: OMC_LABEL_UNUSED
if (out_isstart) { *out_isstart = _isstart; }
if (out_aind) { *out_aind = _aind; }
return _nchars;
}
PROTECTED_FUNCTION_STATIC modelica_metatype boxptr_Tpl_stringListFile(threadData_t *threadData, modelica_metatype _file, modelica_metatype _inStringList, modelica_metatype __omcQ_24in_5Fnchars, modelica_metatype __omcQ_24in_5Fisstart, modelica_metatype __omcQ_24in_5Faind, modelica_metatype *out_isstart, modelica_metatype *out_aind)
{
modelica_integer tmp1;
modelica_integer tmp2;
modelica_integer tmp3;
modelica_boolean _isstart;
modelica_integer _aind;
modelica_integer _nchars;
modelica_metatype out_nchars;
tmp1 = mmc_unbox_integer(__omcQ_24in_5Fnchars);
tmp2 = mmc_unbox_integer(__omcQ_24in_5Fisstart);
tmp3 = mmc_unbox_integer(__omcQ_24in_5Faind);
_nchars = omc_Tpl_stringListFile(threadData, _file, _inStringList, tmp1, tmp2, tmp3, &_isstart, &_aind);
out_nchars = mmc_mk_icon(_nchars);
if (out_isstart) { *out_isstart = mmc_mk_icon(_isstart); }
if (out_aind) { *out_aind = mmc_mk_icon(_aind); }
return out_nchars;
}
PROTECTED_FUNCTION_STATIC modelica_integer omc_Tpl_stringListString(threadData_t *threadData, modelica_metatype _inStringList, modelica_integer _inActualPositionOnLine, modelica_boolean _inAtStartOfLine, modelica_integer _inAfterNewLineIndent, modelica_boolean *out_outAtStartOfLine, modelica_integer *out_outAfterNewLineIndent)
{
modelica_integer _outActualPositionOnLine;
modelica_boolean _outAtStartOfLine;
modelica_integer _outAfterNewLineIndent;
modelica_integer tmp1_c0 __attribute__((unused)) = 0;
modelica_boolean tmp1_c1 __attribute__((unused)) = 0;
modelica_integer tmp1_c2 __attribute__((unused)) = 0;
modelica_metatype tmpMeta[3] __attribute__((unused)) = {0};
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
modelica_metatype tmp4_1;modelica_integer tmp4_2;modelica_boolean tmp4_3;modelica_integer tmp4_4;
tmp4_1 = _inStringList;
tmp4_2 = _inActualPositionOnLine;
tmp4_3 = _inAtStartOfLine;
tmp4_4 = _inAfterNewLineIndent;
{
modelica_string _str = NULL;
modelica_metatype _strLst = NULL;
modelica_integer _nchars;
modelica_integer _aind;
modelica_integer _blen;
modelica_boolean _isstart;
modelica_boolean _hasNL;
volatile mmc_switch_type tmp4;
int tmp5;
tmp4 = 0;
for (; tmp4 < 5; tmp4++) {
switch (MMC_SWITCH_CAST(tmp4)) {
case 0: {
if (!listEmpty(tmp4_1)) goto tmp3_end;
_isstart = tmp4_3;
_aind = tmp4_4;
tmp1_c0 = _aind;
tmp1_c1 = _isstart;
tmp1_c2 = _aind;
goto tmp3_done;
}
case 1: {
modelica_metatype tmpMeta6;
modelica_metatype tmpMeta7;
if (listEmpty(tmp4_1)) goto tmp3_end;
tmpMeta6 = MMC_CAR(tmp4_1);
tmpMeta7 = MMC_CDR(tmp4_1);
if (0 != MMC_STRLEN(tmpMeta6) || strcmp(MMC_STRINGDATA(_OMC_LIT20), MMC_STRINGDATA(tmpMeta6)) != 0) goto tmp3_end;
_strLst = tmpMeta7;
_nchars = tmp4_2;
_isstart = tmp4_3;
_aind = tmp4_4;
_inStringList = _strLst;
_inActualPositionOnLine = _nchars;
_inAtStartOfLine = _isstart;
_inAfterNewLineIndent = _aind;
goto _tailrecursive;
goto tmp3_done;
}
case 2: {
modelica_metatype tmpMeta8;
modelica_metatype tmpMeta9;
if (1 != tmp4_3) goto tmp3_end;
if (listEmpty(tmp4_1)) goto tmp3_end;
tmpMeta8 = MMC_CAR(tmp4_1);
tmpMeta9 = MMC_CDR(tmp4_1);
_str = tmpMeta8;
_strLst = tmpMeta9;
_nchars = tmp4_2;
_aind = tmp4_4;
_blen = omc_Print_getBufLength(threadData);
omc_Print_printBufSpace(threadData, _nchars);
omc_Print_printBuf(threadData, _str);
_blen = omc_Print_getBufLength(threadData) - _blen;
_hasNL = omc_Print_hasBufNewLineAtEnd(threadData);
_nchars = (_hasNL?_aind:_blen);
_inStringList = _strLst;
_inActualPositionOnLine = _nchars;
_inAtStartOfLine = _hasNL;
_inAfterNewLineIndent = _aind;
goto _tailrecursive;
goto tmp3_done;
}
case 3: {
modelica_metatype tmpMeta10;
modelica_metatype tmpMeta11;
if (0 != tmp4_3) goto tmp3_end;
if (listEmpty(tmp4_1)) goto tmp3_end;
tmpMeta10 = MMC_CAR(tmp4_1);
tmpMeta11 = MMC_CDR(tmp4_1);
_str = tmpMeta10;
_strLst = tmpMeta11;
_nchars = tmp4_2;
_aind = tmp4_4;
_blen = omc_Print_getBufLength(threadData);
omc_Print_printBuf(threadData, _str);
_blen = omc_Print_getBufLength(threadData) - _blen;
_hasNL = omc_Print_hasBufNewLineAtEnd(threadData);
_nchars = (_hasNL?_aind:_nchars + _blen);
_inStringList = _strLst;
_inActualPositionOnLine = _nchars;
_inAtStartOfLine = _hasNL;
_inAfterNewLineIndent = _aind;
goto _tailrecursive;
goto tmp3_done;
}
case 4: {
modelica_boolean tmp12;
tmp12 = omc_Flags_isSet(threadData, _OMC_LIT35);
if (1 != tmp12) goto goto_2;
omc_Debug_trace(threadData, _OMC_LIT45);
goto goto_2;
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
_outActualPositionOnLine = tmp1_c0;
_outAtStartOfLine = tmp1_c1;
_outAfterNewLineIndent = tmp1_c2;
_return: OMC_LABEL_UNUSED
if (out_outAtStartOfLine) { *out_outAtStartOfLine = _outAtStartOfLine; }
if (out_outAfterNewLineIndent) { *out_outAfterNewLineIndent = _outAfterNewLineIndent; }
return _outActualPositionOnLine;
}
PROTECTED_FUNCTION_STATIC modelica_metatype boxptr_Tpl_stringListString(threadData_t *threadData, modelica_metatype _inStringList, modelica_metatype _inActualPositionOnLine, modelica_metatype _inAtStartOfLine, modelica_metatype _inAfterNewLineIndent, modelica_metatype *out_outAtStartOfLine, modelica_metatype *out_outAfterNewLineIndent)
{
modelica_integer tmp1;
modelica_integer tmp2;
modelica_integer tmp3;
modelica_boolean _outAtStartOfLine;
modelica_integer _outAfterNewLineIndent;
modelica_integer _outActualPositionOnLine;
modelica_metatype out_outActualPositionOnLine;
tmp1 = mmc_unbox_integer(_inActualPositionOnLine);
tmp2 = mmc_unbox_integer(_inAtStartOfLine);
tmp3 = mmc_unbox_integer(_inAfterNewLineIndent);
_outActualPositionOnLine = omc_Tpl_stringListString(threadData, _inStringList, tmp1, tmp2, tmp3, &_outAtStartOfLine, &_outAfterNewLineIndent);
out_outActualPositionOnLine = mmc_mk_icon(_outActualPositionOnLine);
if (out_outAtStartOfLine) { *out_outAtStartOfLine = mmc_mk_icon(_outAtStartOfLine); }
if (out_outAfterNewLineIndent) { *out_outAfterNewLineIndent = mmc_mk_icon(_outAfterNewLineIndent); }
return out_outActualPositionOnLine;
}
PROTECTED_FUNCTION_STATIC modelica_integer omc_Tpl_tokFile(threadData_t *threadData, modelica_complex _file, modelica_metatype _inStringToken, modelica_integer __omcQ_24in_5Fnchars, modelica_boolean __omcQ_24in_5Fisstart, modelica_integer __omcQ_24in_5Faind, modelica_boolean *out_isstart, modelica_integer *out_aind)
{
modelica_integer _nchars;
modelica_boolean _isstart;
modelica_integer _aind;
modelica_integer tmp1_c0 __attribute__((unused)) = 0;
modelica_boolean tmp1_c1 __attribute__((unused)) = 0;
modelica_integer tmp1_c2 __attribute__((unused)) = 0;
modelica_metatype tmpMeta[3] __attribute__((unused)) = {0};
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
_nchars = __omcQ_24in_5Fnchars;
_isstart = __omcQ_24in_5Fisstart;
_aind = __omcQ_24in_5Faind;
{
modelica_metatype tmp4_1;modelica_integer tmp4_2;modelica_boolean tmp4_3;modelica_integer tmp4_4;
tmp4_1 = _inStringToken;
tmp4_2 = _nchars;
tmp4_3 = _isstart;
tmp4_4 = _aind;
{
modelica_metatype _toks = NULL;
modelica_metatype _bt = NULL;
modelica_string _str = NULL;
modelica_metatype _strLst = NULL;
volatile mmc_switch_type tmp4;
int tmp5;
tmp4 = 0;
for (; tmp4 < 7; tmp4++) {
switch (MMC_SWITCH_CAST(tmp4)) {
case 0: {
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,0,0) == 0) goto tmp3_end;
_aind = tmp4_4;
omc_File_write(threadData, _file, _OMC_LIT1);
tmp1_c0 = _aind;
tmp1_c1 = 1;
tmp1_c2 = _aind;
goto tmp3_done;
}
case 1: {
modelica_metatype tmpMeta6;
if (1 != tmp4_3) goto tmp3_end;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,1,1) == 0) goto tmp3_end;
tmpMeta6 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
_str = tmpMeta6;
_nchars = tmp4_2;
_aind = tmp4_4;
omc_File_writeSpace(threadData, _file, _nchars);
omc_File_write(threadData, _file, _str);
tmp1_c0 = _nchars + stringLength(_str);
tmp1_c1 = 0;
tmp1_c2 = _aind;
goto tmp3_done;
}
case 2: {
modelica_metatype tmpMeta7;
if (0 != tmp4_3) goto tmp3_end;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,1,1) == 0) goto tmp3_end;
tmpMeta7 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
_str = tmpMeta7;
_nchars = tmp4_2;
_aind = tmp4_4;
omc_File_write(threadData, _file, _str);
tmp1_c0 = _nchars + stringLength(_str);
tmp1_c1 = 0;
tmp1_c2 = _aind;
goto tmp3_done;
}
case 3: {
modelica_metatype tmpMeta8;
if (1 != tmp4_3) goto tmp3_end;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,2,1) == 0) goto tmp3_end;
tmpMeta8 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
_str = tmpMeta8;
_nchars = tmp4_2;
_aind = tmp4_4;
omc_File_writeSpace(threadData, _file, _nchars);
omc_File_write(threadData, _file, _str);
tmp1_c0 = _aind;
tmp1_c1 = 1;
tmp1_c2 = _aind;
goto tmp3_done;
}
case 4: {
modelica_metatype tmpMeta9;
if (0 != tmp4_3) goto tmp3_end;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,2,1) == 0) goto tmp3_end;
tmpMeta9 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
_str = tmpMeta9;
_aind = tmp4_4;
omc_File_write(threadData, _file, _str);
tmp1_c0 = _aind;
tmp1_c1 = 1;
tmp1_c2 = _aind;
goto tmp3_done;
}
case 5: {
modelica_metatype tmpMeta10;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,3,2) == 0) goto tmp3_end;
tmpMeta10 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
_strLst = tmpMeta10;
_nchars = tmp4_2;
_isstart = tmp4_3;
_aind = tmp4_4;
tmp1_c0 = omc_Tpl_stringListFile(threadData, _file, _strLst, _nchars, _isstart, _aind, &tmp1_c1, &tmp1_c2);
goto tmp3_done;
}
case 6: {
modelica_metatype tmpMeta11;
modelica_metatype tmpMeta12;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,4,2) == 0) goto tmp3_end;
tmpMeta11 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
tmpMeta12 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 3));
_toks = tmpMeta11;
_bt = tmpMeta12;
_nchars = tmp4_2;
_isstart = tmp4_3;
_aind = tmp4_4;
tmp1_c0 = omc_Tpl_blockFile(threadData, _file, _bt, listReverse(_toks), _nchars, _isstart, _aind, &tmp1_c1, &tmp1_c2);
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
_nchars = tmp1_c0;
_isstart = tmp1_c1;
_aind = tmp1_c2;
_return: OMC_LABEL_UNUSED
if (out_isstart) { *out_isstart = _isstart; }
if (out_aind) { *out_aind = _aind; }
return _nchars;
}
PROTECTED_FUNCTION_STATIC modelica_metatype boxptr_Tpl_tokFile(threadData_t *threadData, modelica_metatype _file, modelica_metatype _inStringToken, modelica_metatype __omcQ_24in_5Fnchars, modelica_metatype __omcQ_24in_5Fisstart, modelica_metatype __omcQ_24in_5Faind, modelica_metatype *out_isstart, modelica_metatype *out_aind)
{
modelica_integer tmp1;
modelica_integer tmp2;
modelica_integer tmp3;
modelica_boolean _isstart;
modelica_integer _aind;
modelica_integer _nchars;
modelica_metatype out_nchars;
tmp1 = mmc_unbox_integer(__omcQ_24in_5Fnchars);
tmp2 = mmc_unbox_integer(__omcQ_24in_5Fisstart);
tmp3 = mmc_unbox_integer(__omcQ_24in_5Faind);
_nchars = omc_Tpl_tokFile(threadData, _file, _inStringToken, tmp1, tmp2, tmp3, &_isstart, &_aind);
out_nchars = mmc_mk_icon(_nchars);
if (out_isstart) { *out_isstart = mmc_mk_icon(_isstart); }
if (out_aind) { *out_aind = mmc_mk_icon(_aind); }
return out_nchars;
}
PROTECTED_FUNCTION_STATIC void omc_Tpl_tokFileText(threadData_t *threadData, modelica_metatype _inText, modelica_metatype _inStringToken, modelica_boolean _doHandleTok)
{
modelica_complex _file;
modelica_integer _nchars;
modelica_integer _aind;
modelica_boolean _isstart;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
_file = omc_File_File_constructor(threadData, omc_Tpl_getTextOpaqueFile(threadData, _inText));
if(_doHandleTok)
{
omc_Tpl_handleTok(threadData, _inText);
}
{
modelica_metatype tmp3_1;
tmp3_1 = _inText;
{
volatile mmc_switch_type tmp3;
int tmp4;
tmp3 = 0;
for (; tmp3 < 1; tmp3++) {
switch (MMC_SWITCH_CAST(tmp3)) {
case 0: {
if (mmc__uniontype__metarecord__typedef__equal(tmp3_1,1,5) == 0) goto tmp2_end;
_nchars = mmc_unbox_integer(arrayGet((MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_inText), 3))), ((modelica_integer) 1)));
_aind = mmc_unbox_integer(arrayGet((MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_inText), 4))), ((modelica_integer) 1)));
_isstart = mmc_unbox_boolean(arrayGet((MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_inText), 5))), ((modelica_integer) 1)));
_nchars = omc_Tpl_tokFile(threadData, _file, _inStringToken, _nchars, _isstart, _aind ,&_isstart ,&_aind);
arrayUpdate((MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_inText), 3))), ((modelica_integer) 1), mmc_mk_integer(_nchars));
arrayUpdate((MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_inText), 4))), ((modelica_integer) 1), mmc_mk_integer(_aind));
arrayUpdate((MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_inText), 5))), ((modelica_integer) 1), mmc_mk_boolean(_isstart));
goto tmp2_done;
}
}
goto tmp2_end;
tmp2_end: ;
}
goto goto_1;
goto_1:;
MMC_THROW_INTERNAL();
goto tmp2_done;
tmp2_done:;
}
}
;
_return: OMC_LABEL_UNUSED
omc_File_File_destructor(threadData,_file);
return;
}
PROTECTED_FUNCTION_STATIC void boxptr_Tpl_tokFileText(threadData_t *threadData, modelica_metatype _inText, modelica_metatype _inStringToken, modelica_metatype _doHandleTok)
{
modelica_integer tmp1;
tmp1 = mmc_unbox_integer(_doHandleTok);
omc_Tpl_tokFileText(threadData, _inText, _inStringToken, tmp1);
return;
}
PROTECTED_FUNCTION_STATIC modelica_integer omc_Tpl_tokString(threadData_t *threadData, modelica_metatype _inStringToken, modelica_integer _inActualPositionOnLine, modelica_boolean _inAtStartOfLine, modelica_integer _inAfterNewLineIndent, modelica_boolean *out_outAtStartOfLine, modelica_integer *out_outAfterNewLineIndent)
{
modelica_integer _outActualPositionOnLine;
modelica_boolean _outAtStartOfLine;
modelica_integer _outAfterNewLineIndent;
modelica_integer tmp1_c0 __attribute__((unused)) = 0;
modelica_boolean tmp1_c1 __attribute__((unused)) = 0;
modelica_integer tmp1_c2 __attribute__((unused)) = 0;
modelica_metatype tmpMeta[3] __attribute__((unused)) = {0};
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
modelica_metatype tmp4_1;modelica_integer tmp4_2;modelica_boolean tmp4_3;modelica_integer tmp4_4;
tmp4_1 = _inStringToken;
tmp4_2 = _inActualPositionOnLine;
tmp4_3 = _inAtStartOfLine;
tmp4_4 = _inAfterNewLineIndent;
{
modelica_metatype _toks = NULL;
modelica_metatype _bt = NULL;
modelica_string _str = NULL;
modelica_metatype _strLst = NULL;
modelica_integer _nchars;
modelica_integer _aind;
modelica_integer _blen;
modelica_boolean _isstart;
volatile mmc_switch_type tmp4;
int tmp5;
tmp4 = 0;
for (; tmp4 < 8; tmp4++) {
switch (MMC_SWITCH_CAST(tmp4)) {
case 0: {
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,0,0) == 0) goto tmp3_end;
_aind = tmp4_4;
omc_Print_printBufNewLine(threadData);
tmp1_c0 = _aind;
tmp1_c1 = 1;
tmp1_c2 = _aind;
goto tmp3_done;
}
case 1: {
modelica_metatype tmpMeta6;
if (1 != tmp4_3) goto tmp3_end;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,1,1) == 0) goto tmp3_end;
tmpMeta6 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
_str = tmpMeta6;
_nchars = tmp4_2;
_aind = tmp4_4;
_blen = omc_Print_getBufLength(threadData);
omc_Print_printBufSpace(threadData, _nchars);
omc_Print_printBuf(threadData, _str);
_blen = omc_Print_getBufLength(threadData) - _blen;
tmp1_c0 = _blen;
tmp1_c1 = 0;
tmp1_c2 = _aind;
goto tmp3_done;
}
case 2: {
modelica_metatype tmpMeta7;
if (0 != tmp4_3) goto tmp3_end;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,1,1) == 0) goto tmp3_end;
tmpMeta7 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
_str = tmpMeta7;
_nchars = tmp4_2;
_aind = tmp4_4;
_blen = omc_Print_getBufLength(threadData);
omc_Print_printBuf(threadData, _str);
_blen = omc_Print_getBufLength(threadData) - _blen;
tmp1_c0 = _nchars + _blen;
tmp1_c1 = 0;
tmp1_c2 = _aind;
goto tmp3_done;
}
case 3: {
modelica_metatype tmpMeta8;
if (1 != tmp4_3) goto tmp3_end;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,2,1) == 0) goto tmp3_end;
tmpMeta8 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
_str = tmpMeta8;
_nchars = tmp4_2;
_aind = tmp4_4;
omc_Print_printBufSpace(threadData, _nchars);
omc_Print_printBuf(threadData, _str);
tmp1_c0 = _aind;
tmp1_c1 = 1;
tmp1_c2 = _aind;
goto tmp3_done;
}
case 4: {
modelica_metatype tmpMeta9;
if (0 != tmp4_3) goto tmp3_end;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,2,1) == 0) goto tmp3_end;
tmpMeta9 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
_str = tmpMeta9;
_aind = tmp4_4;
omc_Print_printBuf(threadData, _str);
tmp1_c0 = _aind;
tmp1_c1 = 1;
tmp1_c2 = _aind;
goto tmp3_done;
}
case 5: {
modelica_metatype tmpMeta10;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,3,2) == 0) goto tmp3_end;
tmpMeta10 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
_strLst = tmpMeta10;
_nchars = tmp4_2;
_isstart = tmp4_3;
_aind = tmp4_4;
tmp1_c0 = omc_Tpl_stringListString(threadData, _strLst, _nchars, _isstart, _aind, &tmp1_c1, &tmp1_c2);
goto tmp3_done;
}
case 6: {
modelica_metatype tmpMeta11;
modelica_metatype tmpMeta12;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,4,2) == 0) goto tmp3_end;
tmpMeta11 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
tmpMeta12 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 3));
_toks = tmpMeta11;
_bt = tmpMeta12;
_nchars = tmp4_2;
_isstart = tmp4_3;
_aind = tmp4_4;
tmp1_c0 = omc_Tpl_blockString(threadData, _bt, listReverse(_toks), _nchars, _isstart, _aind, &tmp1_c1, &tmp1_c2);
goto tmp3_done;
}
case 7: {
modelica_boolean tmp13;
tmp13 = omc_Flags_isSet(threadData, _OMC_LIT35);
if (1 != tmp13) goto goto_2;
omc_Debug_trace(threadData, _OMC_LIT43);
goto goto_2;
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
_outActualPositionOnLine = tmp1_c0;
_outAtStartOfLine = tmp1_c1;
_outAfterNewLineIndent = tmp1_c2;
_return: OMC_LABEL_UNUSED
if (out_outAtStartOfLine) { *out_outAtStartOfLine = _outAtStartOfLine; }
if (out_outAfterNewLineIndent) { *out_outAfterNewLineIndent = _outAfterNewLineIndent; }
return _outActualPositionOnLine;
}
PROTECTED_FUNCTION_STATIC modelica_metatype boxptr_Tpl_tokString(threadData_t *threadData, modelica_metatype _inStringToken, modelica_metatype _inActualPositionOnLine, modelica_metatype _inAtStartOfLine, modelica_metatype _inAfterNewLineIndent, modelica_metatype *out_outAtStartOfLine, modelica_metatype *out_outAfterNewLineIndent)
{
modelica_integer tmp1;
modelica_integer tmp2;
modelica_integer tmp3;
modelica_boolean _outAtStartOfLine;
modelica_integer _outAfterNewLineIndent;
modelica_integer _outActualPositionOnLine;
modelica_metatype out_outActualPositionOnLine;
tmp1 = mmc_unbox_integer(_inActualPositionOnLine);
tmp2 = mmc_unbox_integer(_inAtStartOfLine);
tmp3 = mmc_unbox_integer(_inAfterNewLineIndent);
_outActualPositionOnLine = omc_Tpl_tokString(threadData, _inStringToken, tmp1, tmp2, tmp3, &_outAtStartOfLine, &_outAfterNewLineIndent);
out_outActualPositionOnLine = mmc_mk_icon(_outActualPositionOnLine);
if (out_outAtStartOfLine) { *out_outAtStartOfLine = mmc_mk_icon(_outAtStartOfLine); }
if (out_outAfterNewLineIndent) { *out_outAfterNewLineIndent = mmc_mk_icon(_outAfterNewLineIndent); }
return out_outActualPositionOnLine;
}
PROTECTED_FUNCTION_STATIC modelica_integer omc_Tpl_tokensFile(threadData_t *threadData, modelica_complex _file, modelica_metatype _inTokens, modelica_integer __omcQ_24in_5FactualPositionOnLine, modelica_boolean __omcQ_24in_5FatStartOfLine, modelica_integer __omcQ_24in_5FafterNewLineIndent, modelica_boolean *out_atStartOfLine, modelica_integer *out_afterNewLineIndent)
{
modelica_integer _actualPositionOnLine;
modelica_boolean _atStartOfLine;
modelica_integer _afterNewLineIndent;
modelica_metatype tmpMeta1;
modelica_metatype tmpMeta2;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
_actualPositionOnLine = __omcQ_24in_5FactualPositionOnLine;
_atStartOfLine = __omcQ_24in_5FatStartOfLine;
_afterNewLineIndent = __omcQ_24in_5FafterNewLineIndent;
{
modelica_metatype _tok;
for (tmpMeta1 = _inTokens; !listEmpty(tmpMeta1); tmpMeta1=MMC_CDR(tmpMeta1))
{
_tok = MMC_CAR(tmpMeta1);
_actualPositionOnLine = omc_Tpl_tokFile(threadData, _file, _tok, _actualPositionOnLine, _atStartOfLine, _afterNewLineIndent ,&_atStartOfLine ,&_afterNewLineIndent);
}
}
_return: OMC_LABEL_UNUSED
if (out_atStartOfLine) { *out_atStartOfLine = _atStartOfLine; }
if (out_afterNewLineIndent) { *out_afterNewLineIndent = _afterNewLineIndent; }
return _actualPositionOnLine;
}
PROTECTED_FUNCTION_STATIC modelica_metatype boxptr_Tpl_tokensFile(threadData_t *threadData, modelica_metatype _file, modelica_metatype _inTokens, modelica_metatype __omcQ_24in_5FactualPositionOnLine, modelica_metatype __omcQ_24in_5FatStartOfLine, modelica_metatype __omcQ_24in_5FafterNewLineIndent, modelica_metatype *out_atStartOfLine, modelica_metatype *out_afterNewLineIndent)
{
modelica_integer tmp1;
modelica_integer tmp2;
modelica_integer tmp3;
modelica_boolean _atStartOfLine;
modelica_integer _afterNewLineIndent;
modelica_integer _actualPositionOnLine;
modelica_metatype out_actualPositionOnLine;
tmp1 = mmc_unbox_integer(__omcQ_24in_5FactualPositionOnLine);
tmp2 = mmc_unbox_integer(__omcQ_24in_5FatStartOfLine);
tmp3 = mmc_unbox_integer(__omcQ_24in_5FafterNewLineIndent);
_actualPositionOnLine = omc_Tpl_tokensFile(threadData, _file, _inTokens, tmp1, tmp2, tmp3, &_atStartOfLine, &_afterNewLineIndent);
out_actualPositionOnLine = mmc_mk_icon(_actualPositionOnLine);
if (out_atStartOfLine) { *out_atStartOfLine = mmc_mk_icon(_atStartOfLine); }
if (out_afterNewLineIndent) { *out_afterNewLineIndent = mmc_mk_icon(_afterNewLineIndent); }
return out_actualPositionOnLine;
}
PROTECTED_FUNCTION_STATIC modelica_integer omc_Tpl_tokensString(threadData_t *threadData, modelica_metatype _inTokens, modelica_integer __omcQ_24in_5FactualPositionOnLine, modelica_boolean __omcQ_24in_5FatStartOfLine, modelica_integer __omcQ_24in_5FafterNewLineIndent, modelica_boolean *out_atStartOfLine, modelica_integer *out_afterNewLineIndent)
{
modelica_integer _actualPositionOnLine;
modelica_boolean _atStartOfLine;
modelica_integer _afterNewLineIndent;
modelica_metatype tmpMeta1;
modelica_metatype tmpMeta2;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
_actualPositionOnLine = __omcQ_24in_5FactualPositionOnLine;
_atStartOfLine = __omcQ_24in_5FatStartOfLine;
_afterNewLineIndent = __omcQ_24in_5FafterNewLineIndent;
{
modelica_metatype _tok;
for (tmpMeta1 = _inTokens; !listEmpty(tmpMeta1); tmpMeta1=MMC_CDR(tmpMeta1))
{
_tok = MMC_CAR(tmpMeta1);
_actualPositionOnLine = omc_Tpl_tokString(threadData, _tok, _actualPositionOnLine, _atStartOfLine, _afterNewLineIndent ,&_atStartOfLine ,&_afterNewLineIndent);
}
}
_return: OMC_LABEL_UNUSED
if (out_atStartOfLine) { *out_atStartOfLine = _atStartOfLine; }
if (out_afterNewLineIndent) { *out_afterNewLineIndent = _afterNewLineIndent; }
return _actualPositionOnLine;
}
PROTECTED_FUNCTION_STATIC modelica_metatype boxptr_Tpl_tokensString(threadData_t *threadData, modelica_metatype _inTokens, modelica_metatype __omcQ_24in_5FactualPositionOnLine, modelica_metatype __omcQ_24in_5FatStartOfLine, modelica_metatype __omcQ_24in_5FafterNewLineIndent, modelica_metatype *out_atStartOfLine, modelica_metatype *out_afterNewLineIndent)
{
modelica_integer tmp1;
modelica_integer tmp2;
modelica_integer tmp3;
modelica_boolean _atStartOfLine;
modelica_integer _afterNewLineIndent;
modelica_integer _actualPositionOnLine;
modelica_metatype out_actualPositionOnLine;
tmp1 = mmc_unbox_integer(__omcQ_24in_5FactualPositionOnLine);
tmp2 = mmc_unbox_integer(__omcQ_24in_5FatStartOfLine);
tmp3 = mmc_unbox_integer(__omcQ_24in_5FafterNewLineIndent);
_actualPositionOnLine = omc_Tpl_tokensString(threadData, _inTokens, tmp1, tmp2, tmp3, &_atStartOfLine, &_afterNewLineIndent);
out_actualPositionOnLine = mmc_mk_icon(_actualPositionOnLine);
if (out_atStartOfLine) { *out_atStartOfLine = mmc_mk_icon(_atStartOfLine); }
if (out_afterNewLineIndent) { *out_afterNewLineIndent = mmc_mk_icon(_afterNewLineIndent); }
return out_actualPositionOnLine;
}
DLLExport
void omc_Tpl_textStringBuf(threadData_t *threadData, modelica_metatype _inText)
{
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
modelica_metatype tmp3_1;
tmp3_1 = _inText;
{
modelica_metatype _toks = NULL;
volatile mmc_switch_type tmp3;
int tmp4;
tmp3 = 0;
for (; tmp3 < 3; tmp3++) {
switch (MMC_SWITCH_CAST(tmp3)) {
case 0: {
modelica_metatype tmpMeta5;
modelica_metatype tmpMeta6;
if (mmc__uniontype__metarecord__typedef__equal(tmp3_1,0,2) == 0) goto tmp2_end;
tmpMeta5 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 2));
tmpMeta6 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 3));
if (!listEmpty(tmpMeta6)) goto tmp2_end;
_toks = tmpMeta5;
omc_Tpl_tokensString(threadData, listReverse(_toks), ((modelica_integer) 0), 1, ((modelica_integer) 0), NULL, NULL);
goto tmp2_done;
}
case 1: {
modelica_metatype tmpMeta7;
modelica_metatype tmpMeta8;
modelica_metatype tmpMeta9;
modelica_boolean tmp10;
if (mmc__uniontype__metarecord__typedef__equal(tmp3_1,0,2) == 0) goto tmp2_end;
tmpMeta7 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 3));
if (listEmpty(tmpMeta7)) goto tmp2_end;
tmpMeta8 = MMC_CAR(tmpMeta7);
tmpMeta9 = MMC_CDR(tmpMeta7);
tmp10 = omc_Flags_isSet(threadData, _OMC_LIT35);
if (1 != tmp10) goto goto_1;
omc_Debug_trace(threadData, _OMC_LIT46);
goto goto_1;
goto tmp2_done;
}
case 2: {
modelica_boolean tmp11;
tmp11 = omc_Flags_isSet(threadData, _OMC_LIT35);
if (1 != tmp11) goto goto_1;
omc_Debug_trace(threadData, _OMC_LIT47);
goto goto_1;
goto tmp2_done;
}
}
goto tmp2_end;
tmp2_end: ;
}
goto goto_1;
goto_1:;
MMC_THROW_INTERNAL();
goto tmp2_done;
tmp2_done:;
}
}
;
_return: OMC_LABEL_UNUSED
return;
}
DLLExport
modelica_string omc_Tpl_textString(threadData_t *threadData, modelica_metatype _inText)
{
modelica_string _outString = NULL;
modelica_string tmp1 = 0;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
modelica_metatype tmp4_1;
tmp4_1 = _inText;
{
modelica_metatype _txt = NULL;
modelica_string _str = NULL;
modelica_integer _handle;
volatile mmc_switch_type tmp4;
int tmp5;
tmp4 = 0;
for (; tmp4 < 2; tmp4++) {
switch (MMC_SWITCH_CAST(tmp4)) {
case 0: {
_txt = tmp4_1;
_handle = omc_Print_saveAndClearBuf(threadData);
omc_Tpl_textStringBuf(threadData, _txt);
_str = omc_Print_getString(threadData);
omc_Print_restoreBuf(threadData, _handle);
tmp1 = _str;
goto tmp3_done;
}
case 1: {
modelica_boolean tmp6;
tmp6 = omc_Flags_isSet(threadData, _OMC_LIT35);
if (1 != tmp6) goto goto_2;
omc_Debug_trace(threadData, _OMC_LIT47);
goto goto_2;
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
_outString = tmp1;
_return: OMC_LABEL_UNUSED
return _outString;
}
DLLExport
modelica_integer omc_Tpl_getIteri__i0(threadData_t *threadData, modelica_metatype _inText)
{
modelica_integer _outI0;
modelica_integer tmp1 = 0;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
modelica_metatype tmp4_1;
tmp4_1 = _inText;
{
modelica_metatype _i0 = NULL;
volatile mmc_switch_type tmp4;
int tmp5;
tmp4 = 0;
for (; tmp4 < 3; tmp4++) {
switch (MMC_SWITCH_CAST(tmp4)) {
case 0: {
modelica_metatype tmpMeta6;
modelica_metatype tmpMeta7;
modelica_metatype tmpMeta8;
modelica_metatype tmpMeta9;
modelica_metatype tmpMeta10;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,0,2) == 0) goto tmp3_end;
tmpMeta6 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 3));
if (listEmpty(tmpMeta6)) goto tmp3_end;
tmpMeta7 = MMC_CAR(tmpMeta6);
tmpMeta8 = MMC_CDR(tmpMeta6);
tmpMeta9 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta7), 2));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta9,5,2) == 0) goto tmp3_end;
tmpMeta10 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta9), 3));
_i0 = tmpMeta10;
tmp1 = mmc_unbox_integer(arrayGet(_i0, ((modelica_integer) 1)));
goto tmp3_done;
}
case 1: {
modelica_integer tmp11 = 0;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,1,5) == 0) goto tmp3_end;
{
modelica_metatype tmp14_1;
tmp14_1 = listGet(arrayGet((MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_inText), 6))), ((modelica_integer) 1)), ((modelica_integer) 1));
{
volatile mmc_switch_type tmp14;
int tmp15;
tmp14 = 0;
for (; tmp14 < 1; tmp14++) {
switch (MMC_SWITCH_CAST(tmp14)) {
case 0: {
modelica_metatype tmpMeta16;
modelica_metatype tmpMeta17;
tmpMeta16 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp14_1), 2));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta16,5,2) == 0) goto tmp13_end;
tmpMeta17 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta16), 3));
_i0 = tmpMeta17;
tmp11 = mmc_unbox_integer(arrayGet(_i0, ((modelica_integer) 1)));
goto tmp13_done;
}
}
goto tmp13_end;
tmp13_end: ;
}
goto goto_12;
goto_12:;
goto goto_2;
goto tmp13_done;
tmp13_done:;
}
}tmp1 = tmp11;
goto tmp3_done;
}
case 2: {
modelica_boolean tmp18;
tmp18 = omc_Flags_isSet(threadData, _OMC_LIT35);
if (1 != tmp18) goto goto_2;
omc_Debug_trace(threadData, _OMC_LIT48);
goto goto_2;
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
_outI0 = tmp1;
_return: OMC_LABEL_UNUSED
return _outI0;
}
modelica_metatype boxptr_Tpl_getIteri__i0(threadData_t *threadData, modelica_metatype _inText)
{
modelica_integer _outI0;
modelica_metatype out_outI0;
_outI0 = omc_Tpl_getIteri__i0(threadData, _inText);
out_outI0 = mmc_mk_icon(_outI0);
return out_outI0;
}
DLLExport
modelica_metatype omc_Tpl_nextIter(threadData_t *threadData, modelica_metatype __omcQ_24in_5Ftxt)
{
modelica_metatype _txt = NULL;
modelica_metatype tmpMeta1;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
_txt = __omcQ_24in_5Ftxt;
{
modelica_metatype tmp4_1;
tmp4_1 = _txt;
{
modelica_metatype _toks = NULL;
modelica_metatype _itertoks = NULL;
modelica_metatype _tok = NULL;
modelica_metatype _emptok = NULL;
modelica_metatype _blstack = NULL;
modelica_metatype _iopts = NULL;
modelica_metatype _i0 = NULL;
modelica_metatype _tell = NULL;
modelica_metatype _bt = NULL;
modelica_integer _tellpos;
modelica_integer _curIndex;
modelica_metatype _txt2 = NULL;
modelica_boolean _haveToken;
modelica_metatype _septok = NULL;
volatile mmc_switch_type tmp4;
int tmp5;
tmp4 = 0;
for (; tmp4 < 6; tmp4++) {
switch (MMC_SWITCH_CAST(tmp4)) {
case 0: {
modelica_metatype tmpMeta6;
modelica_metatype tmpMeta7;
modelica_metatype tmpMeta8;
modelica_metatype tmpMeta9;
modelica_metatype tmpMeta10;
modelica_metatype tmpMeta11;
modelica_metatype tmpMeta12;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,0,2) == 0) goto tmp3_end;
tmpMeta6 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
if (!listEmpty(tmpMeta6)) goto tmp3_end;
tmpMeta7 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 3));
if (listEmpty(tmpMeta7)) goto tmp3_end;
tmpMeta8 = MMC_CAR(tmpMeta7);
tmpMeta9 = MMC_CDR(tmpMeta7);
tmpMeta10 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta8), 2));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta10,5,2) == 0) goto tmp3_end;
tmpMeta11 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta10), 2));
tmpMeta12 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta11), 3));
if (!optionNone(tmpMeta12)) goto tmp3_end;
_txt = tmp4_1;
tmpMeta1 = _txt;
goto tmp3_done;
}
case 1: {
modelica_metatype tmpMeta13;
modelica_metatype tmpMeta14;
modelica_metatype tmpMeta15;
modelica_metatype tmpMeta16;
modelica_metatype tmpMeta17;
modelica_metatype tmpMeta18;
modelica_metatype tmpMeta19;
modelica_metatype tmpMeta20;
modelica_metatype tmpMeta21;
modelica_metatype tmpMeta22;
modelica_metatype tmpMeta23;
modelica_metatype tmpMeta24;
modelica_metatype tmpMeta25;
modelica_metatype tmpMeta26;
modelica_metatype tmpMeta27;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,0,2) == 0) goto tmp3_end;
tmpMeta13 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
if (!listEmpty(tmpMeta13)) goto tmp3_end;
tmpMeta14 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 3));
if (listEmpty(tmpMeta14)) goto tmp3_end;
tmpMeta15 = MMC_CAR(tmpMeta14);
tmpMeta16 = MMC_CDR(tmpMeta14);
tmpMeta17 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta15), 1));
tmpMeta18 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta15), 2));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta18,5,2) == 0) goto tmp3_end;
tmpMeta19 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta18), 2));
tmpMeta20 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta19), 3));
if (optionNone(tmpMeta20)) goto tmp3_end;
tmpMeta21 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta20), 1));
tmpMeta22 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta18), 3));
_itertoks = tmpMeta17;
_bt = tmpMeta18;
_emptok = tmpMeta21;
_i0 = tmpMeta22;
_blstack = tmpMeta16;
arrayUpdate(_i0, ((modelica_integer) 1), mmc_mk_integer(((modelica_integer) 1) + mmc_unbox_integer(arrayGet(_i0, ((modelica_integer) 1)))));
tmpMeta23 = MMC_REFSTRUCTLIT(mmc_nil);
tmpMeta25 = mmc_mk_cons(_emptok, _itertoks);
tmpMeta26 = mmc_mk_box2(0, tmpMeta25, _bt);
tmpMeta24 = mmc_mk_cons(tmpMeta26, _blstack);
tmpMeta27 = mmc_mk_box3(3, &Tpl_Text_MEM__TEXT__desc, tmpMeta23, tmpMeta24);
tmpMeta1 = tmpMeta27;
goto tmp3_done;
}
case 2: {
modelica_metatype tmpMeta28;
modelica_metatype tmpMeta29;
modelica_metatype tmpMeta30;
modelica_metatype tmpMeta31;
modelica_metatype tmpMeta32;
modelica_metatype tmpMeta33;
modelica_metatype tmpMeta34;
modelica_metatype tmpMeta35;
modelica_metatype tmpMeta36;
modelica_metatype tmpMeta37;
modelica_metatype tmpMeta38;
modelica_metatype tmpMeta39;
modelica_metatype tmpMeta40;
modelica_metatype tmpMeta41;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,0,2) == 0) goto tmp3_end;
tmpMeta28 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
if (listEmpty(tmpMeta28)) goto tmp3_end;
tmpMeta29 = MMC_CAR(tmpMeta28);
tmpMeta30 = MMC_CDR(tmpMeta28);
if (!listEmpty(tmpMeta30)) goto tmp3_end;
tmpMeta31 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 3));
if (listEmpty(tmpMeta31)) goto tmp3_end;
tmpMeta32 = MMC_CAR(tmpMeta31);
tmpMeta33 = MMC_CDR(tmpMeta31);
tmpMeta34 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta32), 1));
tmpMeta35 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta32), 2));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta35,5,2) == 0) goto tmp3_end;
tmpMeta36 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta35), 3));
_tok = tmpMeta29;
_itertoks = tmpMeta34;
_bt = tmpMeta35;
_i0 = tmpMeta36;
_blstack = tmpMeta33;
arrayUpdate(_i0, ((modelica_integer) 1), mmc_mk_integer(((modelica_integer) 1) + mmc_unbox_integer(arrayGet(_i0, ((modelica_integer) 1)))));
tmpMeta37 = MMC_REFSTRUCTLIT(mmc_nil);
tmpMeta39 = mmc_mk_cons(_tok, _itertoks);
tmpMeta40 = mmc_mk_box2(0, tmpMeta39, _bt);
tmpMeta38 = mmc_mk_cons(tmpMeta40, _blstack);
tmpMeta41 = mmc_mk_box3(3, &Tpl_Text_MEM__TEXT__desc, tmpMeta37, tmpMeta38);
tmpMeta1 = tmpMeta41;
goto tmp3_done;
}
case 3: {
modelica_metatype tmpMeta42;
modelica_metatype tmpMeta43;
modelica_metatype tmpMeta44;
modelica_metatype tmpMeta45;
modelica_metatype tmpMeta46;
modelica_metatype tmpMeta47;
modelica_metatype tmpMeta48;
modelica_metatype tmpMeta49;
modelica_metatype tmpMeta50;
modelica_metatype tmpMeta51;
modelica_metatype tmpMeta52;
modelica_metatype tmpMeta53;
modelica_metatype tmpMeta54;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,0,2) == 0) goto tmp3_end;
tmpMeta42 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
tmpMeta43 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 3));
if (listEmpty(tmpMeta43)) goto tmp3_end;
tmpMeta44 = MMC_CAR(tmpMeta43);
tmpMeta45 = MMC_CDR(tmpMeta43);
tmpMeta46 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta44), 1));
tmpMeta47 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta44), 2));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta47,5,2) == 0) goto tmp3_end;
tmpMeta48 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta47), 3));
_toks = tmpMeta42;
_itertoks = tmpMeta46;
_bt = tmpMeta47;
_i0 = tmpMeta48;
_blstack = tmpMeta45;
arrayUpdate(_i0, ((modelica_integer) 1), mmc_mk_integer(((modelica_integer) 1) + mmc_unbox_integer(arrayGet(_i0, ((modelica_integer) 1)))));
tmpMeta49 = MMC_REFSTRUCTLIT(mmc_nil);
tmpMeta52 = mmc_mk_box3(7, &Tpl_StringToken_ST__BLOCK__desc, _toks, _OMC_LIT40);
tmpMeta51 = mmc_mk_cons(tmpMeta52, _itertoks);
tmpMeta53 = mmc_mk_box2(0, tmpMeta51, _bt);
tmpMeta50 = mmc_mk_cons(tmpMeta53, _blstack);
tmpMeta54 = mmc_mk_box3(3, &Tpl_Text_MEM__TEXT__desc, tmpMeta49, tmpMeta50);
tmpMeta1 = tmpMeta54;
goto tmp3_done;
}
case 4: {
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,1,5) == 0) goto tmp3_end;
{
modelica_metatype tmp57_1;
tmp57_1 = listGet(arrayGet((MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_txt), 6))), ((modelica_integer) 1)), ((modelica_integer) 1));
{
volatile mmc_switch_type tmp57;
int tmp58;
tmp57 = 0;
for (; tmp57 < 1; tmp57++) {
switch (MMC_SWITCH_CAST(tmp57)) {
case 0: {
modelica_metatype tmpMeta59;
modelica_metatype tmpMeta60;
modelica_metatype tmpMeta61;
modelica_metatype tmpMeta62;
modelica_metatype tmpMeta63;
modelica_metatype tmpMeta64;
tmpMeta59 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp57_1), 2));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta59,5,2) == 0) goto tmp56_end;
tmpMeta60 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta59), 2));
tmpMeta61 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta59), 3));
tmpMeta62 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp57_1), 6));
tmpMeta63 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp57_1), 7));
_iopts = tmpMeta60;
_i0 = tmpMeta61;
_tell = tmpMeta62;
_septok = tmpMeta63;
_tellpos = omc_Tpl_textFileTell(threadData, _txt);
if((mmc_unbox_integer(arrayGet(_tell, ((modelica_integer) 1))) != _tellpos))
{
arrayUpdate(_tell, ((modelica_integer) 1), mmc_mk_integer(_tellpos));
_txt2 = _txt;
_haveToken = 1;
}
else
{
{
modelica_metatype tmp67_1;
tmp67_1 = (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_iopts), 3)));
{
volatile mmc_switch_type tmp67;
int tmp68;
tmp67 = 0;
for (; tmp67 < 2; tmp67++) {
switch (MMC_SWITCH_CAST(tmp67)) {
case 0: {
if (!optionNone(tmp67_1)) goto tmp66_end;
_haveToken = 0;
tmpMeta64 = _txt;
goto tmp66_done;
}
case 1: {
modelica_metatype tmpMeta69;
if (optionNone(tmp67_1)) goto tmp66_end;
tmpMeta69 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp67_1), 1));
_emptok = tmpMeta69;
arrayUpdate(_i0, ((modelica_integer) 1), mmc_mk_integer(((modelica_integer) 1) + mmc_unbox_integer(arrayGet(_i0, ((modelica_integer) 1)))));
_haveToken = 1;
tmpMeta64 = omc_Tpl_writeTok(threadData, _txt, _emptok);
goto tmp66_done;
}
}
goto tmp66_end;
tmp66_end: ;
}
goto goto_65;
goto_65:;
goto goto_55;
goto tmp66_done;
tmp66_done:;
}
}
_txt2 = tmpMeta64;
}
if(_haveToken)
{
_curIndex = mmc_unbox_integer(arrayGet(_i0, ((modelica_integer) 1)));
arrayUpdate(_septok, ((modelica_integer) 1), (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_iopts), 4))));
arrayUpdate(_i0, ((modelica_integer) 1), mmc_mk_integer(((modelica_integer) 1) + _curIndex));
}
goto tmp56_done;
}
}
goto tmp56_end;
tmp56_end: ;
}
goto goto_55;
goto_55:;
goto goto_2;
goto tmp56_done;
tmp56_done:;
}
}
;
tmpMeta1 = _txt2;
goto tmp3_done;
}
case 5: {
omc_Error_addInternalError(threadData, _OMC_LIT49, _OMC_LIT50);
goto goto_2;
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
_txt = tmpMeta1;
_return: OMC_LABEL_UNUSED
return _txt;
}
DLLExport
modelica_metatype omc_Tpl_popIter(threadData_t *threadData, modelica_metatype __omcQ_24in_5Ftxt)
{
modelica_metatype _txt = NULL;
modelica_metatype tmpMeta1;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
_txt = __omcQ_24in_5Ftxt;
{
modelica_metatype tmp4_1;
tmp4_1 = _txt;
{
modelica_metatype _stacktoks = NULL;
modelica_metatype _itertoks = NULL;
modelica_metatype _blstack = NULL;
modelica_metatype _blType = NULL;
volatile mmc_switch_type tmp4;
int tmp5;
tmp4 = 0;
for (; tmp4 < 4; tmp4++) {
switch (MMC_SWITCH_CAST(tmp4)) {
case 0: {
modelica_metatype tmpMeta6;
modelica_metatype tmpMeta7;
modelica_metatype tmpMeta8;
modelica_metatype tmpMeta9;
modelica_metatype tmpMeta10;
modelica_metatype tmpMeta11;
modelica_metatype tmpMeta12;
modelica_metatype tmpMeta13;
modelica_metatype tmpMeta14;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,0,2) == 0) goto tmp3_end;
tmpMeta6 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
if (!listEmpty(tmpMeta6)) goto tmp3_end;
tmpMeta7 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 3));
if (listEmpty(tmpMeta7)) goto tmp3_end;
tmpMeta8 = MMC_CAR(tmpMeta7);
tmpMeta9 = MMC_CDR(tmpMeta7);
tmpMeta10 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta8), 1));
if (!listEmpty(tmpMeta10)) goto tmp3_end;
if (listEmpty(tmpMeta9)) goto tmp3_end;
tmpMeta11 = MMC_CAR(tmpMeta9);
tmpMeta12 = MMC_CDR(tmpMeta9);
tmpMeta13 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta11), 1));
_stacktoks = tmpMeta13;
_blstack = tmpMeta12;
tmpMeta14 = mmc_mk_box3(3, &Tpl_Text_MEM__TEXT__desc, _stacktoks, _blstack);
tmpMeta1 = tmpMeta14;
goto tmp3_done;
}
case 1: {
modelica_metatype tmpMeta15;
modelica_metatype tmpMeta16;
modelica_metatype tmpMeta17;
modelica_metatype tmpMeta18;
modelica_metatype tmpMeta19;
modelica_metatype tmpMeta20;
modelica_metatype tmpMeta21;
modelica_metatype tmpMeta22;
modelica_metatype tmpMeta23;
modelica_metatype tmpMeta24;
modelica_metatype tmpMeta25;
modelica_metatype tmpMeta26;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,0,2) == 0) goto tmp3_end;
tmpMeta15 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
if (!listEmpty(tmpMeta15)) goto tmp3_end;
tmpMeta16 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 3));
if (listEmpty(tmpMeta16)) goto tmp3_end;
tmpMeta17 = MMC_CAR(tmpMeta16);
tmpMeta18 = MMC_CDR(tmpMeta16);
tmpMeta19 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta17), 1));
tmpMeta20 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta17), 2));
if (listEmpty(tmpMeta18)) goto tmp3_end;
tmpMeta21 = MMC_CAR(tmpMeta18);
tmpMeta22 = MMC_CDR(tmpMeta18);
tmpMeta23 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta21), 1));
_itertoks = tmpMeta19;
_blType = tmpMeta20;
_stacktoks = tmpMeta23;
_blstack = tmpMeta22;
tmpMeta25 = mmc_mk_box3(7, &Tpl_StringToken_ST__BLOCK__desc, _itertoks, _blType);
tmpMeta24 = mmc_mk_cons(tmpMeta25, _stacktoks);
tmpMeta26 = mmc_mk_box3(3, &Tpl_Text_MEM__TEXT__desc, tmpMeta24, _blstack);
tmpMeta1 = tmpMeta26;
goto tmp3_done;
}
case 2: {
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,1,5) == 0) goto tmp3_end;
arrayUpdate((MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_txt), 6))), ((modelica_integer) 1), listRest(arrayGet((MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_txt), 6))), ((modelica_integer) 1))));
tmpMeta1 = _txt;
goto tmp3_done;
}
case 3: {
modelica_boolean tmp27;
tmp27 = omc_Flags_isSet(threadData, _OMC_LIT35);
if (1 != tmp27) goto goto_2;
omc_Debug_trace(threadData, _OMC_LIT51);
goto goto_2;
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
_txt = tmpMeta1;
_return: OMC_LABEL_UNUSED
return _txt;
}
DLLExport
modelica_metatype omc_Tpl_pushIter(threadData_t *threadData, modelica_metatype __omcQ_24in_5Ftxt, modelica_metatype _inIterOptions)
{
modelica_metatype _txt = NULL;
modelica_metatype tmpMeta1;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
_txt = __omcQ_24in_5Ftxt;
{
modelica_metatype tmp4_1;modelica_metatype tmp4_2;
tmp4_1 = _txt;
tmp4_2 = _inIterOptions;
{
modelica_metatype _toks = NULL;
modelica_metatype _blstack = NULL;
modelica_metatype _iopts = NULL;
modelica_integer _i0;
volatile mmc_switch_type tmp4;
int tmp5;
tmp4 = 0;
for (; tmp4 < 3; tmp4++) {
switch (MMC_SWITCH_CAST(tmp4)) {
case 0: {
modelica_metatype tmpMeta6;
modelica_metatype tmpMeta7;
modelica_metatype tmpMeta8;
modelica_integer tmp9;
modelica_metatype tmpMeta10;
modelica_metatype tmpMeta11;
modelica_metatype tmpMeta12;
modelica_metatype tmpMeta13;
modelica_metatype tmpMeta14;
modelica_metatype tmpMeta15;
modelica_metatype tmpMeta16;
modelica_metatype tmpMeta17;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,0,2) == 0) goto tmp3_end;
tmpMeta6 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
tmpMeta7 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 3));
tmpMeta8 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_2), 2));
tmp9 = mmc_unbox_integer(tmpMeta8);
_toks = tmpMeta6;
_blstack = tmpMeta7;
_iopts = tmp4_2;
_i0 = tmp9;
tmpMeta10 = MMC_REFSTRUCTLIT(mmc_nil);
tmpMeta12 = MMC_REFSTRUCTLIT(mmc_nil);
tmpMeta13 = mmc_mk_box3(8, &Tpl_BlockType_BT__ITER__desc, _iopts, arrayCreate(((modelica_integer) 1), mmc_mk_integer(_i0)));
tmpMeta14 = mmc_mk_box2(0, tmpMeta12, tmpMeta13);
tmpMeta16 = mmc_mk_box2(0, _toks, _OMC_LIT40);
tmpMeta15 = mmc_mk_cons(tmpMeta16, _blstack);
tmpMeta11 = mmc_mk_cons(tmpMeta14, tmpMeta15);
tmpMeta17 = mmc_mk_box3(3, &Tpl_Text_MEM__TEXT__desc, tmpMeta10, tmpMeta11);
tmpMeta1 = tmpMeta17;
goto tmp3_done;
}
case 1: {
modelica_metatype tmpMeta18;
modelica_integer tmp19;
modelica_metatype tmpMeta28;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,1,5) == 0) goto tmp3_end;
tmpMeta18 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_2), 2));
tmp19 = mmc_unbox_integer(tmpMeta18);
_iopts = tmp4_2;
_i0 = tmp19;
{
modelica_metatype tmp22_1;
tmp22_1 = _iopts;
{
volatile mmc_switch_type tmp22;
int tmp23;
tmp22 = 0;
for (; tmp22 < 2; tmp22++) {
switch (MMC_SWITCH_CAST(tmp22)) {
case 0: {
modelica_metatype tmpMeta24;
modelica_integer tmp25;
modelica_metatype tmpMeta26;
modelica_integer tmp27;
tmpMeta24 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp22_1), 5));
tmp25 = mmc_unbox_integer(tmpMeta24);
if (0 != tmp25) goto tmp21_end;
tmpMeta26 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp22_1), 8));
tmp27 = mmc_unbox_integer(tmpMeta26);
if (0 != tmp27) goto tmp21_end;
goto tmp21_done;
}
case 1: {
omc_Error_addInternalError(threadData, _OMC_LIT52, _OMC_LIT53);
goto goto_20;
goto tmp21_done;
}
}
goto tmp21_end;
tmp21_end: ;
}
goto goto_20;
goto_20:;
goto goto_2;
goto tmp21_done;
tmp21_done:;
}
}
;
tmpMeta28 = mmc_mk_box3(8, &Tpl_BlockType_BT__ITER__desc, _inIterOptions, arrayCreate(((modelica_integer) 1), mmc_mk_integer(_i0)));
omc_Tpl_pushBlock(threadData, _txt, tmpMeta28);
tmpMeta1 = _txt;
goto tmp3_done;
}
case 2: {
modelica_boolean tmp29;
tmp29 = omc_Flags_isSet(threadData, _OMC_LIT35);
if (1 != tmp29) goto goto_2;
omc_Debug_trace(threadData, _OMC_LIT54);
goto goto_2;
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
_txt = tmpMeta1;
_return: OMC_LABEL_UNUSED
return _txt;
}
DLLExport
modelica_metatype omc_Tpl_popBlock(threadData_t *threadData, modelica_metatype __omcQ_24in_5Ftxt)
{
modelica_metatype _txt = NULL;
modelica_metatype tmpMeta1;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
_txt = __omcQ_24in_5Ftxt;
{
modelica_metatype tmp4_1;
tmp4_1 = _txt;
{
modelica_metatype _toks = NULL;
modelica_metatype _stacktoks = NULL;
modelica_metatype _blstack = NULL;
modelica_metatype _blType = NULL;
modelica_metatype _rest = NULL;
modelica_metatype _blk = NULL;
modelica_boolean _oldisstart;
volatile mmc_switch_type tmp4;
int tmp5;
tmp4 = 0;
for (; tmp4 < 4; tmp4++) {
switch (MMC_SWITCH_CAST(tmp4)) {
case 0: {
modelica_metatype tmpMeta6;
modelica_metatype tmpMeta7;
modelica_metatype tmpMeta8;
modelica_metatype tmpMeta9;
modelica_metatype tmpMeta10;
modelica_metatype tmpMeta11;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,0,2) == 0) goto tmp3_end;
tmpMeta6 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
if (!listEmpty(tmpMeta6)) goto tmp3_end;
tmpMeta7 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 3));
if (listEmpty(tmpMeta7)) goto tmp3_end;
tmpMeta8 = MMC_CAR(tmpMeta7);
tmpMeta9 = MMC_CDR(tmpMeta7);
tmpMeta10 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta8), 1));
_stacktoks = tmpMeta10;
_blstack = tmpMeta9;
tmpMeta11 = mmc_mk_box3(3, &Tpl_Text_MEM__TEXT__desc, _stacktoks, _blstack);
tmpMeta1 = tmpMeta11;
goto tmp3_done;
}
case 1: {
modelica_metatype tmpMeta12;
modelica_metatype tmpMeta13;
modelica_metatype tmpMeta14;
modelica_metatype tmpMeta15;
modelica_metatype tmpMeta16;
modelica_metatype tmpMeta17;
modelica_metatype tmpMeta18;
modelica_metatype tmpMeta19;
modelica_metatype tmpMeta20;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,0,2) == 0) goto tmp3_end;
tmpMeta12 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
tmpMeta13 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 3));
if (listEmpty(tmpMeta13)) goto tmp3_end;
tmpMeta14 = MMC_CAR(tmpMeta13);
tmpMeta15 = MMC_CDR(tmpMeta13);
tmpMeta16 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta14), 1));
tmpMeta17 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta14), 2));
_toks = tmpMeta12;
_stacktoks = tmpMeta16;
_blType = tmpMeta17;
_blstack = tmpMeta15;
tmpMeta19 = mmc_mk_box3(7, &Tpl_StringToken_ST__BLOCK__desc, _toks, _blType);
tmpMeta18 = mmc_mk_cons(tmpMeta19, _stacktoks);
tmpMeta20 = mmc_mk_box3(3, &Tpl_Text_MEM__TEXT__desc, tmpMeta18, _blstack);
tmpMeta1 = tmpMeta20;
goto tmp3_done;
}
case 2: {
modelica_metatype tmpMeta21;
modelica_metatype tmpMeta22;
modelica_metatype tmpMeta23;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,1,5) == 0) goto tmp3_end;
tmpMeta21 = arrayGet((MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_txt), 6))), ((modelica_integer) 1));
if (listEmpty(tmpMeta21)) goto goto_2;
tmpMeta22 = MMC_CAR(tmpMeta21);
tmpMeta23 = MMC_CDR(tmpMeta21);
_blk = tmpMeta22;
_rest = tmpMeta23;
arrayUpdate((MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_txt), 6))), ((modelica_integer) 1), _rest);
{
modelica_metatype tmp26_1;
tmp26_1 = (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_blk), 2)));
{
volatile mmc_switch_type tmp26;
int tmp27;
tmp26 = 0;
for (; tmp26 < 3; tmp26++) {
switch (MMC_SWITCH_CAST(tmp26)) {
case 0: {
if (mmc__uniontype__metarecord__typedef__equal(tmp26_1,1,1) == 0) goto tmp25_end;
if(mmc_unbox_boolean(arrayGet((MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_txt), 5))), ((modelica_integer) 1))))
{
arrayUpdate((MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_txt), 3))), ((modelica_integer) 1), (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_blk), 3))));
}
arrayUpdate((MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_txt), 4))), ((modelica_integer) 1), (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_blk), 4))));
goto tmp25_done;
}
case 1: {
modelica_boolean tmp28 = 0;
{
modelica_metatype tmp31_1;
tmp31_1 = (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_blk), 2)));
{
int tmp31;
{
switch (MMC_SWITCH_CAST(valueConstructor(tmp31_1))) {
case 5: {
tmp28 = 1;
goto tmp30_done;
}
case 6: {
tmp28 = 1;
goto tmp30_done;
}
case 7: {
tmp28 = 1;
goto tmp30_done;
}
}
goto tmp30_end;
tmp30_end: ;
}
goto goto_29;
goto_29:;
goto goto_24;
goto tmp30_done;
tmp30_done:;
}
}
if (!tmp28) goto tmp25_end;
_oldisstart = mmc_unbox_boolean(arrayGet((MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_txt), 5))), ((modelica_integer) 1)));
if(_oldisstart)
{
if((omc_Tpl_textFileTell(threadData, _txt) == mmc_unbox_integer(arrayGet((MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_blk), 6))), ((modelica_integer) 1)))))
{
arrayUpdate((MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_txt), 3))), ((modelica_integer) 1), (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_blk), 3))));
}
else
{
if(mmc_unbox_boolean(arrayGet((MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_txt), 5))), ((modelica_integer) 1))))
{
arrayUpdate((MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_txt), 3))), ((modelica_integer) 1), (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_blk), 4))));
}
}
}
else
{
if(mmc_unbox_boolean(arrayGet((MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_txt), 5))), ((modelica_integer) 1))))
{
arrayUpdate((MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_txt), 3))), ((modelica_integer) 1), (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_blk), 4))));
}
}
arrayUpdate((MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_txt), 4))), ((modelica_integer) 1), (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_blk), 4))));
goto tmp25_done;
}
case 2: {
goto tmp25_done;
}
}
goto tmp25_end;
tmp25_end: ;
}
goto goto_24;
goto_24:;
goto goto_2;
goto tmp25_done;
tmp25_done:;
}
}
;
tmpMeta1 = _txt;
goto tmp3_done;
}
case 3: {
modelica_boolean tmp32;
tmp32 = omc_Flags_isSet(threadData, _OMC_LIT35);
if (1 != tmp32) goto goto_2;
omc_Debug_trace(threadData, _OMC_LIT55);
goto goto_2;
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
_txt = tmpMeta1;
_return: OMC_LABEL_UNUSED
return _txt;
}
DLLExport
modelica_metatype omc_Tpl_pushBlock(threadData_t *threadData, modelica_metatype __omcQ_24in_5Ftxt, modelica_metatype _inBlockType)
{
modelica_metatype _txt = NULL;
modelica_metatype tmpMeta1;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
_txt = __omcQ_24in_5Ftxt;
{
modelica_metatype tmp4_1;
tmp4_1 = _txt;
{
modelica_metatype _toks = NULL;
modelica_metatype _blstack = NULL;
modelica_integer _nchars;
modelica_integer _aind;
modelica_integer _w;
modelica_boolean _isstart;
int tmp4;
{
switch (MMC_SWITCH_CAST(valueConstructor(tmp4_1))) {
case 3: {
modelica_metatype tmpMeta5;
modelica_metatype tmpMeta6;
modelica_metatype tmpMeta7;
modelica_metatype tmpMeta8;
modelica_metatype tmpMeta9;
modelica_metatype tmpMeta10;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,0,2) == 0) goto tmp3_end;
tmpMeta5 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
tmpMeta6 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 3));
_toks = tmpMeta5;
_blstack = tmpMeta6;
tmpMeta7 = MMC_REFSTRUCTLIT(mmc_nil);
tmpMeta9 = mmc_mk_box2(0, _toks, _inBlockType);
tmpMeta8 = mmc_mk_cons(tmpMeta9, _blstack);
tmpMeta10 = mmc_mk_box3(3, &Tpl_Text_MEM__TEXT__desc, tmpMeta7, tmpMeta8);
tmpMeta1 = tmpMeta10;
goto tmp3_done;
}
case 4: {
modelica_metatype tmpMeta11;
modelica_metatype tmpMeta12;
_nchars = mmc_unbox_integer(arrayGet((MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_txt), 3))), ((modelica_integer) 1)));
_aind = mmc_unbox_integer(arrayGet((MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_txt), 4))), ((modelica_integer) 1)));
_isstart = mmc_unbox_boolean(arrayGet((MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_txt), 5))), ((modelica_integer) 1)));
tmpMeta12 = mmc_mk_box7(3, &Tpl_BlockTypeFileText_BT__FILE__TEXT__desc, _inBlockType, mmc_mk_integer(_nchars), mmc_mk_integer(_aind), mmc_mk_boolean(_isstart), arrayCreate(((modelica_integer) 1), mmc_mk_integer(omc_Tpl_textFileTell(threadData, _txt))), arrayCreate(((modelica_integer) 1), mmc_mk_none()));
tmpMeta11 = mmc_mk_cons(tmpMeta12, arrayGet((MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_txt), 6))), ((modelica_integer) 1)));
arrayUpdate((MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_txt), 6))), ((modelica_integer) 1), tmpMeta11);
{
modelica_metatype tmp15_1;
tmp15_1 = _inBlockType;
{
int tmp15;
{
switch (MMC_SWITCH_CAST(valueConstructor(tmp15_1))) {
case 4: {
modelica_metatype tmpMeta16;
modelica_integer tmp17;
if (mmc__uniontype__metarecord__typedef__equal(tmp15_1,1,1) == 0) goto tmp14_end;
tmpMeta16 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp15_1), 2));
tmp17 = mmc_unbox_integer(tmpMeta16);
_w = tmp17;
arrayUpdate((MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_txt), 3))), ((modelica_integer) 1), mmc_mk_integer(_nchars + _w));
arrayUpdate((MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_txt), 4))), ((modelica_integer) 1), mmc_mk_integer(_aind + _w));
goto tmp14_done;
}
case 5: {
modelica_metatype tmpMeta18;
modelica_integer tmp19;
if (mmc__uniontype__metarecord__typedef__equal(tmp15_1,2,1) == 0) goto tmp14_end;
tmpMeta18 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp15_1), 2));
tmp19 = mmc_unbox_integer(tmpMeta18);
_w = tmp19;
if(_isstart)
{
arrayUpdate((MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_txt), 3))), ((modelica_integer) 1), mmc_mk_integer(((modelica_integer) 0)));
}
arrayUpdate((MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_txt), 4))), ((modelica_integer) 1), mmc_mk_integer(_w));
goto tmp14_done;
}
case 6: {
modelica_metatype tmpMeta20;
modelica_integer tmp21;
if (mmc__uniontype__metarecord__typedef__equal(tmp15_1,3,1) == 0) goto tmp14_end;
tmpMeta20 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp15_1), 2));
tmp21 = mmc_unbox_integer(tmpMeta20);
_w = tmp21;
arrayUpdate((MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_txt), 4))), ((modelica_integer) 1), mmc_mk_integer(_aind + _w));
goto tmp14_done;
}
case 7: {
modelica_metatype tmpMeta22;
modelica_integer tmp23;
if (mmc__uniontype__metarecord__typedef__equal(tmp15_1,4,1) == 0) goto tmp14_end;
tmpMeta22 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp15_1), 2));
tmp23 = mmc_unbox_integer(tmpMeta22);
_w = tmp23;
arrayUpdate((MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_txt), 4))), ((modelica_integer) 1), mmc_mk_integer(_nchars + _w));
goto tmp14_done;
}
default:
tmp14_default: OMC_LABEL_UNUSED; {
goto tmp14_done;
}
}
goto tmp14_end;
tmp14_end: ;
}
goto goto_13;
goto_13:;
goto goto_2;
goto tmp14_done;
tmp14_done:;
}
}
;
tmpMeta1 = _txt;
goto tmp3_done;
}
default:
tmp3_default: OMC_LABEL_UNUSED; {
modelica_boolean tmp24;
tmp24 = omc_Flags_isSet(threadData, _OMC_LIT35);
if (1 != tmp24) goto goto_2;
omc_Debug_trace(threadData, _OMC_LIT56);
goto goto_2;
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
_txt = tmpMeta1;
_return: OMC_LABEL_UNUSED
return _txt;
}
DLLExport
modelica_metatype omc_Tpl_newLine(threadData_t *threadData, modelica_metatype _inText)
{
modelica_metatype _outText = NULL;
modelica_metatype tmpMeta1;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
modelica_metatype tmp4_1;
tmp4_1 = _inText;
{
modelica_metatype _toks = NULL;
modelica_metatype _blstack = NULL;
volatile mmc_switch_type tmp4;
int tmp5;
tmp4 = 0;
for (; tmp4 < 2; tmp4++) {
switch (MMC_SWITCH_CAST(tmp4)) {
case 0: {
modelica_metatype tmpMeta6;
modelica_metatype tmpMeta7;
modelica_metatype tmpMeta8;
modelica_metatype tmpMeta9;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,0,2) == 0) goto tmp3_end;
tmpMeta6 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
tmpMeta7 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 3));
_toks = tmpMeta6;
_blstack = tmpMeta7;
tmpMeta8 = mmc_mk_cons(_OMC_LIT57, _toks);
tmpMeta9 = mmc_mk_box3(3, &Tpl_Text_MEM__TEXT__desc, tmpMeta8, _blstack);
tmpMeta1 = tmpMeta9;
goto tmp3_done;
}
case 1: {
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,1,5) == 0) goto tmp3_end;
omc_Tpl_newlineFile(threadData, _inText);
tmpMeta1 = _inText;
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
_outText = tmpMeta1;
_return: OMC_LABEL_UNUSED
return _outText;
}
PROTECTED_FUNCTION_STATIC modelica_boolean omc_Tpl_isAtStartOfLineTok(threadData_t *threadData, modelica_metatype _inTok)
{
modelica_boolean _b;
modelica_boolean tmp1 = 0;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
modelica_metatype tmp4_1;
tmp4_1 = _inTok;
{
modelica_metatype _tok = NULL;
volatile mmc_switch_type tmp4;
int tmp5;
tmp4 = 0;
for (; tmp4 < 5; tmp4++) {
switch (MMC_SWITCH_CAST(tmp4)) {
case 0: {
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,0,0) == 0) goto tmp3_end;
tmp1 = 1;
goto tmp3_done;
}
case 1: {
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,2,1) == 0) goto tmp3_end;
tmp1 = 1;
goto tmp3_done;
}
case 2: {
modelica_metatype tmpMeta6;
modelica_integer tmp7;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,3,2) == 0) goto tmp3_end;
tmpMeta6 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 3));
tmp7 = mmc_unbox_integer(tmpMeta6);
if (1 != tmp7) goto tmp3_end;
tmp1 = 1;
goto tmp3_done;
}
case 3: {
modelica_metatype tmpMeta8;
modelica_metatype tmpMeta9;
modelica_metatype tmpMeta10;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,4,2) == 0) goto tmp3_end;
tmpMeta8 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
if (listEmpty(tmpMeta8)) goto tmp3_end;
tmpMeta9 = MMC_CAR(tmpMeta8);
tmpMeta10 = MMC_CDR(tmpMeta8);
_tok = tmpMeta9;
_inTok = _tok;
goto _tailrecursive;
goto tmp3_done;
}
case 4: {
tmp1 = 0;
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
_b = tmp1;
_return: OMC_LABEL_UNUSED
return _b;
}
PROTECTED_FUNCTION_STATIC modelica_metatype boxptr_Tpl_isAtStartOfLineTok(threadData_t *threadData, modelica_metatype _inTok)
{
modelica_boolean _b;
modelica_metatype out_b;
_b = omc_Tpl_isAtStartOfLineTok(threadData, _inTok);
out_b = mmc_mk_icon(_b);
return out_b;
}
PROTECTED_FUNCTION_STATIC modelica_boolean omc_Tpl_isAtStartOfLine(threadData_t *threadData, modelica_metatype _text)
{
modelica_boolean _b;
modelica_boolean tmp1 = 0;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
modelica_metatype tmp4_1;
tmp4_1 = _text;
{
modelica_metatype _tok = NULL;
volatile mmc_switch_type tmp4;
int tmp5;
tmp4 = 0;
for (; tmp4 < 2; tmp4++) {
switch (MMC_SWITCH_CAST(tmp4)) {
case 0: {
modelica_metatype tmpMeta6;
modelica_metatype tmpMeta7;
modelica_metatype tmpMeta8;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,0,2) == 0) goto tmp3_end;
tmpMeta6 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
if (listEmpty(tmpMeta6)) goto tmp3_end;
tmpMeta7 = MMC_CAR(tmpMeta6);
tmpMeta8 = MMC_CDR(tmpMeta6);
_tok = tmpMeta7;
tmp1 = omc_Tpl_isAtStartOfLineTok(threadData, _tok);
goto tmp3_done;
}
case 1: {
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,1,5) == 0) goto tmp3_end;
tmp1 = mmc_unbox_boolean(arrayGet((MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_text), 5))), ((modelica_integer) 1)));
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
_b = tmp1;
_return: OMC_LABEL_UNUSED
return _b;
}
PROTECTED_FUNCTION_STATIC modelica_metatype boxptr_Tpl_isAtStartOfLine(threadData_t *threadData, modelica_metatype _text)
{
modelica_boolean _b;
modelica_metatype out_b;
_b = omc_Tpl_isAtStartOfLine(threadData, _text);
out_b = mmc_mk_icon(_b);
return out_b;
}
DLLExport
modelica_metatype omc_Tpl_softNewLine(threadData_t *threadData, modelica_metatype _inText)
{
modelica_metatype _outText = NULL;
modelica_metatype tmpMeta1;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
modelica_metatype tmp4_1;
tmp4_1 = _inText;
{
modelica_metatype _txt = NULL;
modelica_metatype _toks = NULL;
volatile mmc_switch_type tmp4;
int tmp5;
tmp4 = 0;
for (; tmp4 < 4; tmp4++) {
switch (MMC_SWITCH_CAST(tmp4)) {
case 0: {
modelica_metatype tmpMeta6;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,0,2) == 0) goto tmp3_end;
tmpMeta6 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
if (!listEmpty(tmpMeta6)) goto tmp3_end;
_txt = tmp4_1;
tmpMeta1 = _txt;
goto tmp3_done;
}
case 1: {
modelica_metatype tmpMeta7;
modelica_metatype tmpMeta8;
modelica_metatype tmpMeta9;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,0,2) == 0) goto tmp3_end;
tmpMeta7 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
_txt = tmp4_1;
_toks = tmpMeta7;
if((!omc_Tpl_isAtStartOfLine(threadData, _txt)))
{
tmpMeta9 = mmc_mk_cons(_OMC_LIT57, _toks);
tmpMeta8 = MMC_TAGPTR(mmc_alloc_words(4));
memcpy(MMC_UNTAGPTR(tmpMeta8), MMC_UNTAGPTR(_txt), 4*sizeof(modelica_metatype));
((modelica_metatype*)MMC_UNTAGPTR(tmpMeta8))[2] = tmpMeta9;
_txt = tmpMeta8;
}
tmpMeta1 = _txt;
goto tmp3_done;
}
case 2: {
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,1,5) == 0) goto tmp3_end;
if((!omc_Tpl_isAtStartOfLine(threadData, _inText)))
{
omc_Tpl_newlineFile(threadData, _inText);
}
tmpMeta1 = _inText;
goto tmp3_done;
}
case 3: {
modelica_boolean tmp10;
tmp10 = omc_Flags_isSet(threadData, _OMC_LIT35);
if (1 != tmp10) goto goto_2;
omc_Debug_trace(threadData, _OMC_LIT58);
goto goto_2;
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
_outText = tmpMeta1;
_return: OMC_LABEL_UNUSED
return _outText;
}
PROTECTED_FUNCTION_STATIC modelica_metatype omc_Tpl_takeLineOrString(threadData_t *threadData, modelica_metatype _inChars, modelica_metatype *out_outRestChars, modelica_boolean *out_outIsLine)
{
modelica_metatype _outTillNewLineChars = NULL;
modelica_metatype _outRestChars = NULL;
modelica_boolean _outIsLine;
modelica_boolean tmp1_c2 __attribute__((unused)) = 0;
modelica_metatype tmpMeta[3] __attribute__((unused)) = {0};
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
modelica_metatype tmp4_1;
tmp4_1 = _inChars;
{
modelica_string _char = NULL;
modelica_metatype _tnlchars = NULL;
modelica_metatype _restchars = NULL;
modelica_metatype _chars = NULL;
modelica_boolean _isline;
volatile mmc_switch_type tmp4;
int tmp5;
tmp4 = 0;
for (; tmp4 < 3; tmp4++) {
switch (MMC_SWITCH_CAST(tmp4)) {
case 0: {
modelica_metatype tmpMeta6;
modelica_metatype tmpMeta7;
if (!listEmpty(tmp4_1)) goto tmp3_end;
tmpMeta6 = MMC_REFSTRUCTLIT(mmc_nil);
tmpMeta7 = MMC_REFSTRUCTLIT(mmc_nil);
tmpMeta[0+0] = tmpMeta6;
tmpMeta[0+1] = tmpMeta7;
tmp1_c2 = 0;
goto tmp3_done;
}
case 1: {
modelica_metatype tmpMeta8;
modelica_metatype tmpMeta9;
if (listEmpty(tmp4_1)) goto tmp3_end;
tmpMeta8 = MMC_CAR(tmp4_1);
tmpMeta9 = MMC_CDR(tmp4_1);
if (1 != MMC_STRLEN(tmpMeta8) || strcmp(MMC_STRINGDATA(_OMC_LIT1), MMC_STRINGDATA(tmpMeta8)) != 0) goto tmp3_end;
_chars = tmpMeta9;
tmpMeta[0+0] = _OMC_LIT59;
tmpMeta[0+1] = _chars;
tmp1_c2 = 1;
goto tmp3_done;
}
case 2: {
modelica_metatype tmpMeta10;
modelica_metatype tmpMeta11;
modelica_metatype tmpMeta12;
if (listEmpty(tmp4_1)) goto tmp3_end;
tmpMeta10 = MMC_CAR(tmp4_1);
tmpMeta11 = MMC_CDR(tmp4_1);
_char = tmpMeta10;
_chars = tmpMeta11;
_tnlchars = omc_Tpl_takeLineOrString(threadData, _chars ,&_restchars ,&_isline);
tmpMeta12 = mmc_mk_cons(_char, _tnlchars);
tmpMeta[0+0] = tmpMeta12;
tmpMeta[0+1] = _restchars;
tmp1_c2 = _isline;
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
_outTillNewLineChars = tmpMeta[0+0];
_outRestChars = tmpMeta[0+1];
_outIsLine = tmp1_c2;
_return: OMC_LABEL_UNUSED
if (out_outRestChars) { *out_outRestChars = _outRestChars; }
if (out_outIsLine) { *out_outIsLine = _outIsLine; }
return _outTillNewLineChars;
}
PROTECTED_FUNCTION_STATIC modelica_metatype boxptr_Tpl_takeLineOrString(threadData_t *threadData, modelica_metatype _inChars, modelica_metatype *out_outRestChars, modelica_metatype *out_outIsLine)
{
modelica_boolean _outIsLine;
modelica_metatype _outTillNewLineChars = NULL;
_outTillNewLineChars = omc_Tpl_takeLineOrString(threadData, _inChars, out_outRestChars, &_outIsLine);
if (out_outIsLine) { *out_outIsLine = mmc_mk_icon(_outIsLine); }
return _outTillNewLineChars;
}
PROTECTED_FUNCTION_STATIC modelica_metatype omc_Tpl_writeLineOrStr(threadData_t *threadData, modelica_metatype _inText, modelica_string _inStr, modelica_boolean _inIsLine)
{
modelica_metatype _outText = NULL;
modelica_metatype tmpMeta1;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
modelica_metatype tmp4_1;modelica_string tmp4_2;modelica_boolean tmp4_3;
tmp4_1 = _inText;
tmp4_2 = _inStr;
tmp4_3 = _inIsLine;
{
modelica_metatype _toks = NULL;
modelica_metatype _blstack = NULL;
modelica_string _str = NULL;
modelica_metatype _txt = NULL;
volatile mmc_switch_type tmp4;
int tmp5;
tmp4 = 0;
for (; tmp4 < 4; tmp4++) {
switch (MMC_SWITCH_CAST(tmp4)) {
case 0: {
if (0 != MMC_STRLEN(tmp4_2) || strcmp(MMC_STRINGDATA(_OMC_LIT20), MMC_STRINGDATA(tmp4_2)) != 0) goto tmp3_end;
_txt = tmp4_1;
tmpMeta1 = _txt;
goto tmp3_done;
}
case 1: {
modelica_metatype tmpMeta6;
modelica_metatype tmpMeta7;
modelica_metatype tmpMeta8;
modelica_metatype tmpMeta9;
modelica_metatype tmpMeta10;
if (0 != tmp4_3) goto tmp3_end;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,0,2) == 0) goto tmp3_end;
tmpMeta6 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
tmpMeta7 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 3));
_toks = tmpMeta6;
_blstack = tmpMeta7;
_str = tmp4_2;
tmpMeta9 = mmc_mk_box2(4, &Tpl_StringToken_ST__STRING__desc, _str);
tmpMeta8 = mmc_mk_cons(tmpMeta9, _toks);
tmpMeta10 = mmc_mk_box3(3, &Tpl_Text_MEM__TEXT__desc, tmpMeta8, _blstack);
tmpMeta1 = tmpMeta10;
goto tmp3_done;
}
case 2: {
modelica_metatype tmpMeta11;
modelica_metatype tmpMeta12;
modelica_metatype tmpMeta13;
modelica_metatype tmpMeta14;
modelica_metatype tmpMeta15;
if (1 != tmp4_3) goto tmp3_end;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,0,2) == 0) goto tmp3_end;
tmpMeta11 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
tmpMeta12 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 3));
_toks = tmpMeta11;
_blstack = tmpMeta12;
_str = tmp4_2;
tmpMeta14 = mmc_mk_box2(5, &Tpl_StringToken_ST__LINE__desc, _str);
tmpMeta13 = mmc_mk_cons(tmpMeta14, _toks);
tmpMeta15 = mmc_mk_box3(3, &Tpl_Text_MEM__TEXT__desc, tmpMeta13, _blstack);
tmpMeta1 = tmpMeta15;
goto tmp3_done;
}
case 3: {
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,1,5) == 0) goto tmp3_end;
_str = tmp4_2;
omc_Tpl_stringFile(threadData, _inText, _str, _inIsLine, 1);
tmpMeta1 = _inText;
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
_outText = tmpMeta1;
_return: OMC_LABEL_UNUSED
return _outText;
}
PROTECTED_FUNCTION_STATIC modelica_metatype boxptr_Tpl_writeLineOrStr(threadData_t *threadData, modelica_metatype _inText, modelica_metatype _inStr, modelica_metatype _inIsLine)
{
modelica_integer tmp1;
modelica_metatype _outText = NULL;
tmp1 = mmc_unbox_integer(_inIsLine);
_outText = omc_Tpl_writeLineOrStr(threadData, _inText, _inStr, tmp1);
return _outText;
}
PROTECTED_FUNCTION_STATIC modelica_metatype omc_Tpl_writeChars(threadData_t *threadData, modelica_metatype _inText, modelica_metatype _inChars)
{
modelica_metatype _outText = NULL;
modelica_metatype tmpMeta1;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
modelica_metatype tmp4_1;modelica_metatype tmp4_2;
tmp4_1 = _inText;
tmp4_2 = _inChars;
{
modelica_metatype _txt = NULL;
modelica_string _c = NULL;
modelica_metatype _chars = NULL;
modelica_metatype _lschars = NULL;
modelica_boolean _isline;
volatile mmc_switch_type tmp4;
int tmp5;
tmp4 = 0;
for (; tmp4 < 4; tmp4++) {
switch (MMC_SWITCH_CAST(tmp4)) {
case 0: {
if (!listEmpty(tmp4_2)) goto tmp3_end;
_txt = tmp4_1;
tmpMeta1 = _txt;
goto tmp3_done;
}
case 1: {
modelica_metatype tmpMeta6;
modelica_metatype tmpMeta7;
if (listEmpty(tmp4_2)) goto tmp3_end;
tmpMeta6 = MMC_CAR(tmp4_2);
tmpMeta7 = MMC_CDR(tmp4_2);
if (1 != MMC_STRLEN(tmpMeta6) || strcmp(MMC_STRINGDATA(_OMC_LIT1), MMC_STRINGDATA(tmpMeta6)) != 0) goto tmp3_end;
_chars = tmpMeta7;
_txt = tmp4_1;
_txt = omc_Tpl_newLine(threadData, _txt);
_inText = _txt;
_inChars = _chars;
goto _tailrecursive;
goto tmp3_done;
}
case 2: {
modelica_metatype tmpMeta8;
modelica_metatype tmpMeta9;
modelica_metatype tmpMeta10;
if (listEmpty(tmp4_2)) goto tmp3_end;
tmpMeta8 = MMC_CAR(tmp4_2);
tmpMeta9 = MMC_CDR(tmp4_2);
_c = tmpMeta8;
_chars = tmpMeta9;
_txt = tmp4_1;
_lschars = omc_Tpl_takeLineOrString(threadData, _chars ,&_chars ,&_isline);
tmpMeta10 = mmc_mk_cons(_c, _lschars);
_txt = omc_Tpl_writeLineOrStr(threadData, _txt, stringAppendList(tmpMeta10), _isline);
_inText = _txt;
_inChars = _chars;
goto _tailrecursive;
goto tmp3_done;
}
case 3: {
modelica_boolean tmp11;
tmp11 = omc_Flags_isSet(threadData, _OMC_LIT35);
if (1 != tmp11) goto goto_2;
omc_Debug_trace(threadData, _OMC_LIT60);
goto goto_2;
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
_outText = tmpMeta1;
_return: OMC_LABEL_UNUSED
return _outText;
}
DLLExport
modelica_metatype omc_Tpl_writeText(threadData_t *threadData, modelica_metatype _inText, modelica_metatype _inTextToWrite)
{
modelica_metatype _outText = NULL;
modelica_metatype tmpMeta1;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
modelica_metatype tmp4_1;modelica_metatype tmp4_2;
tmp4_1 = _inText;
tmp4_2 = _inTextToWrite;
{
modelica_metatype _toks = NULL;
modelica_metatype _txttoks = NULL;
modelica_metatype _blstack = NULL;
modelica_metatype _txt = NULL;
volatile mmc_switch_type tmp4;
int tmp5;
tmp4 = 0;
for (; tmp4 < 4; tmp4++) {
switch (MMC_SWITCH_CAST(tmp4)) {
case 0: {
modelica_metatype tmpMeta6;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_2,0,2) == 0) goto tmp3_end;
tmpMeta6 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_2), 2));
if (!listEmpty(tmpMeta6)) goto tmp3_end;
_txt = tmp4_1;
tmpMeta1 = _txt;
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
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,0,2) == 0) goto tmp3_end;
tmpMeta7 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
tmpMeta8 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 3));
if (mmc__uniontype__metarecord__typedef__equal(tmp4_2,0,2) == 0) goto tmp3_end;
tmpMeta9 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_2), 2));
tmpMeta10 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_2), 3));
if (!listEmpty(tmpMeta10)) goto tmp3_end;
_toks = tmpMeta7;
_blstack = tmpMeta8;
_txttoks = tmpMeta9;
tmpMeta12 = mmc_mk_box3(7, &Tpl_StringToken_ST__BLOCK__desc, _txttoks, _OMC_LIT40);
tmpMeta11 = mmc_mk_cons(tmpMeta12, _toks);
tmpMeta13 = mmc_mk_box3(3, &Tpl_Text_MEM__TEXT__desc, tmpMeta11, _blstack);
tmpMeta1 = tmpMeta13;
goto tmp3_done;
}
case 2: {
modelica_metatype tmpMeta14;
modelica_metatype tmpMeta15;
modelica_metatype tmpMeta16;
modelica_metatype tmpMeta17;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,1,5) == 0) goto tmp3_end;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_2,0,2) == 0) goto tmp3_end;
tmpMeta14 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_2), 2));
tmpMeta15 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_2), 3));
if (!listEmpty(tmpMeta15)) goto tmp3_end;
_txttoks = tmpMeta14;
{
modelica_metatype _tok;
for (tmpMeta16 = listReverse(_txttoks); !listEmpty(tmpMeta16); tmpMeta16=MMC_CDR(tmpMeta16))
{
_tok = MMC_CAR(tmpMeta16);
omc_Tpl_writeTok(threadData, _inText, _tok);
}
}
tmpMeta1 = _inText;
goto tmp3_done;
}
case 3: {
modelica_boolean tmp18;
tmp18 = omc_Flags_isSet(threadData, _OMC_LIT35);
if (1 != tmp18) goto goto_2;
omc_Debug_trace(threadData, _OMC_LIT61);
goto goto_2;
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
_outText = tmpMeta1;
_return: OMC_LABEL_UNUSED
return _outText;
}
DLLExport
modelica_metatype omc_Tpl_writeTok(threadData_t *threadData, modelica_metatype _inText, modelica_metatype _inToken)
{
modelica_metatype _outText = NULL;
modelica_metatype tmpMeta1;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
modelica_metatype tmp4_1;modelica_metatype tmp4_2;
tmp4_1 = _inText;
tmp4_2 = _inToken;
{
modelica_metatype _txt = NULL;
modelica_metatype _toks = NULL;
modelica_metatype _blstack = NULL;
modelica_metatype _tok = NULL;
volatile mmc_switch_type tmp4;
int tmp5;
tmp4 = 0;
for (; tmp4 < 4; tmp4++) {
switch (MMC_SWITCH_CAST(tmp4)) {
case 0: {
modelica_metatype tmpMeta6;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_2,4,2) == 0) goto tmp3_end;
tmpMeta6 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_2), 2));
if (!listEmpty(tmpMeta6)) goto tmp3_end;
_txt = tmp4_1;
tmpMeta1 = _txt;
goto tmp3_done;
}
case 1: {
modelica_metatype tmpMeta7;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_2,1,1) == 0) goto tmp3_end;
tmpMeta7 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_2), 2));
if (0 != MMC_STRLEN(tmpMeta7) || strcmp(MMC_STRINGDATA(_OMC_LIT20), MMC_STRINGDATA(tmpMeta7)) != 0) goto tmp3_end;
_txt = tmp4_1;
tmpMeta1 = _txt;
goto tmp3_done;
}
case 2: {
modelica_metatype tmpMeta8;
modelica_metatype tmpMeta9;
modelica_metatype tmpMeta10;
modelica_metatype tmpMeta11;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,0,2) == 0) goto tmp3_end;
tmpMeta8 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
tmpMeta9 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 3));
_toks = tmpMeta8;
_blstack = tmpMeta9;
_tok = tmp4_2;
tmpMeta10 = mmc_mk_cons(_tok, _toks);
tmpMeta11 = mmc_mk_box3(3, &Tpl_Text_MEM__TEXT__desc, tmpMeta10, _blstack);
tmpMeta1 = tmpMeta11;
goto tmp3_done;
}
case 3: {
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,1,5) == 0) goto tmp3_end;
_tok = tmp4_2;
omc_Tpl_tokFileText(threadData, _inText, _tok, 1);
tmpMeta1 = _inText;
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
_outText = tmpMeta1;
_return: OMC_LABEL_UNUSED
return _outText;
}
DLLExport
modelica_metatype omc_Tpl_writeStr(threadData_t *threadData, modelica_metatype _inText, modelica_string _inStr)
{
modelica_metatype _outText = NULL;
modelica_metatype tmpMeta1;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
modelica_metatype tmp4_1;modelica_string tmp4_2;
tmp4_1 = _inText;
tmp4_2 = _inStr;
{
modelica_metatype _toks = NULL;
modelica_metatype _blstack = NULL;
modelica_string _str = NULL;
modelica_metatype _txt = NULL;
volatile mmc_switch_type tmp4;
int tmp5;
tmp4 = 0;
for (; tmp4 < 4; tmp4++) {
switch (MMC_SWITCH_CAST(tmp4)) {
case 0: {
if (0 != MMC_STRLEN(tmp4_2) || strcmp(MMC_STRINGDATA(_OMC_LIT20), MMC_STRINGDATA(tmp4_2)) != 0) goto tmp3_end;
_txt = tmp4_1;
tmpMeta1 = _txt;
goto tmp3_done;
}
case 1: {
modelica_metatype tmpMeta6;
modelica_metatype tmpMeta7;
modelica_metatype tmpMeta8;
modelica_metatype tmpMeta9;
modelica_metatype tmpMeta10;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,0,2) == 0) goto tmp3_end;
tmpMeta6 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
tmpMeta7 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 3));
_toks = tmpMeta6;
_blstack = tmpMeta7;
_str = tmp4_2;
if (!(((modelica_integer) -1) == omc_System_stringFind(threadData, _str, _OMC_LIT1))) goto tmp3_end;
tmpMeta9 = mmc_mk_box2(4, &Tpl_StringToken_ST__STRING__desc, _str);
tmpMeta8 = mmc_mk_cons(tmpMeta9, _toks);
tmpMeta10 = mmc_mk_box3(3, &Tpl_Text_MEM__TEXT__desc, tmpMeta8, _blstack);
tmpMeta1 = tmpMeta10;
goto tmp3_done;
}
case 2: {
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,1,5) == 0) goto tmp3_end;
_str = tmp4_2;
if (!(((modelica_integer) -1) == omc_System_stringFind(threadData, _str, _OMC_LIT1))) goto tmp3_end;
omc_Tpl_stringFile(threadData, _inText, _str, 0, 1);
tmpMeta1 = _inText;
goto tmp3_done;
}
case 3: {
tmpMeta1 = omc_Tpl_writeChars(threadData, _inText, omc_System_strtokIncludingDelimiters(threadData, _inStr, _OMC_LIT1));
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
_outText = tmpMeta1;
_return: OMC_LABEL_UNUSED
return _outText;
}
