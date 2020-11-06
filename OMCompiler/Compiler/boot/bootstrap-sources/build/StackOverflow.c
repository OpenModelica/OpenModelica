#ifdef OMC_BASE_FILE
#define OMC_FILE OMC_BASE_FILE
#else
#define OMC_FILE "/home/mahge/dev/OpenModelica/OMCompiler/Compiler/boot/build/tmp/StackOverflow.c"
#endif
#include "omc_simulation_settings.h"
#include "StackOverflow.h"
#define _OMC_LIT0_data ""
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT0,0,_OMC_LIT0_data);
#define _OMC_LIT0 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT0)
#define _OMC_LIT1_data "[bt] [Symbols are not generated when running the test suite]"
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT1,60,_OMC_LIT1_data);
#define _OMC_LIT1 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT1)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT2,2,1) {_OMC_LIT1,MMC_REFSTRUCTLIT(mmc_nil)}};
#define _OMC_LIT2 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT2)
#define _OMC_LIT3_data "[bt] #"
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT3,6,_OMC_LIT3_data);
#define _OMC_LIT3 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT3)
#define _OMC_LIT4_data "..."
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT4,3,_OMC_LIT4_data);
#define _OMC_LIT4 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT4)
#define _OMC_LIT5_data " "
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT5,1,_OMC_LIT5_data);
#define _OMC_LIT5 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT5)
#define _OMC_LIT6_data "\n"
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT6,1,_OMC_LIT6_data);
#define _OMC_LIT6 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT6)
#define _OMC_LIT7_data "^([^(]*)[(]([^+]*[^+]*)[+][^)]*[)] *[[]0x[0-9a-fA-F]*[]]$"
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT7,57,_OMC_LIT7_data);
#define _OMC_LIT7 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT7)
#define _OMC_LIT8_data "^[0-9 ]*([A-Za-z0-9.]*) *0x[0-9a-fA-F]* ([A-Za-z0-9_]*) *[+] *[0-9]*$"
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT8,69,_OMC_LIT8_data);
#define _OMC_LIT8 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT8)
#define _OMC_LIT9_data "("
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT9,1,_OMC_LIT9_data);
#define _OMC_LIT9 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT9)
#define _OMC_LIT10_data ")"
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT10,1,_OMC_LIT10_data);
#define _OMC_LIT10 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT10)
#define _OMC_LIT11_data "__"
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT11,2,_OMC_LIT11_data);
#define _OMC_LIT11 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT11)
#define _OMC_LIT12_data "#"
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT12,1,_OMC_LIT12_data);
#define _OMC_LIT12 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT12)
#define _OMC_LIT13_data "_"
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT13,1,_OMC_LIT13_data);
#define _OMC_LIT13 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT13)
#define _OMC_LIT14_data "."
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT14,1,_OMC_LIT14_data);
#define _OMC_LIT14 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT14)
#define _OMC_LIT15_data "omc_"
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT15,4,_OMC_LIT15_data);
#define _OMC_LIT15 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT15)
#include "util/modelica.h"
#include "StackOverflow_includes.h"
#if !defined(PROTECTED_FUNCTION_STATIC)
#define PROTECTED_FUNCTION_STATIC
#endif
PROTECTED_FUNCTION_STATIC modelica_string omc_StackOverflow_stripAddresses(threadData_t *threadData, modelica_string _inSymbol);
static const MMC_DEFSTRUCTLIT(boxvar_lit_StackOverflow_stripAddresses,2,0) {(void*) boxptr_StackOverflow_stripAddresses,0}};
#define boxvar_StackOverflow_stripAddresses MMC_REFSTRUCTLIT(boxvar_lit_StackOverflow_stripAddresses)
PROTECTED_FUNCTION_STATIC modelica_string omc_StackOverflow_unmangle(threadData_t *threadData, modelica_string _inSymbol);
static const MMC_DEFSTRUCTLIT(boxvar_lit_StackOverflow_unmangle,2,0) {(void*) boxptr_StackOverflow_unmangle,0}};
#define boxvar_StackOverflow_unmangle MMC_REFSTRUCTLIT(boxvar_lit_StackOverflow_unmangle)
void omc_StackOverflow_clearStacktraceMessages(threadData_t *threadData)
{
mmc_clearStacktraceMessages(threadData);
return;
}
modelica_boolean omc_StackOverflow_hasStacktraceMessages(threadData_t *threadData)
{
int _b_ext;
modelica_boolean _b;
_b_ext = mmc_hasStacktraceMessages(threadData);
_b = (modelica_boolean)_b_ext;
return _b;
}
modelica_metatype boxptr_StackOverflow_hasStacktraceMessages(threadData_t *threadData)
{
modelica_boolean _b;
modelica_metatype out_b;
_b = omc_StackOverflow_hasStacktraceMessages(threadData);
out_b = mmc_mk_icon(_b);
return out_b;
}
void omc_StackOverflow_setStacktraceMessages(threadData_t *threadData, modelica_integer _numSkip, modelica_integer _numFrames)
{
int _numSkip_ext;
int _numFrames_ext;
_numSkip_ext = (int)_numSkip;
_numFrames_ext = (int)_numFrames;
mmc_setStacktraceMessages_threadData(threadData, _numSkip_ext, _numFrames_ext);
return;
}
void boxptr_StackOverflow_setStacktraceMessages(threadData_t *threadData, modelica_metatype _numSkip, modelica_metatype _numFrames)
{
modelica_integer tmp1;
modelica_integer tmp2;
tmp1 = mmc_unbox_integer(_numSkip);
tmp2 = mmc_unbox_integer(_numFrames);
omc_StackOverflow_setStacktraceMessages(threadData, tmp1, tmp2);
return;
}
modelica_metatype omc_StackOverflow_getStacktraceMessages(threadData_t *threadData)
{
modelica_metatype _symbols_ext;
modelica_metatype _symbols = NULL;
_symbols_ext = mmc_getStacktraceMessages_threadData(threadData);
_symbols = (modelica_metatype)_symbols_ext;
return _symbols;
}
DLLExport
modelica_metatype omc_StackOverflow_readableStacktraceMessages(threadData_t *threadData)
{
modelica_metatype _symbols = NULL;
modelica_string _prev = NULL;
modelica_integer _n;
modelica_integer _prevN;
modelica_string tmp1;
modelica_string tmp2;
modelica_boolean tmp3;
modelica_string tmp4;
modelica_string tmp7;
modelica_string tmp8;
modelica_boolean tmp9;
modelica_string tmp10;
modelica_metatype tmpMeta[8] __attribute__((unused)) = {0};
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
tmpMeta[0] = MMC_REFSTRUCTLIT(mmc_nil);
_symbols = tmpMeta[0];
_prev = _OMC_LIT0;
_n = ((modelica_integer) 1);
_prevN = ((modelica_integer) 1);
if(omc_Testsuite_isRunning(threadData))
{
_symbols = _OMC_LIT2;
goto _return;
}
{
modelica_metatype __omcQ_24tmpVar1;
modelica_metatype* tmp5;
modelica_string __omcQ_24tmpVar0;
int tmp6;
modelica_metatype _s_loopVar = 0;
modelica_metatype _s;
_s_loopVar = omc_StackOverflow_getStacktraceMessages(threadData);
tmpMeta[4] = MMC_REFSTRUCTLIT(mmc_nil);
__omcQ_24tmpVar1 = tmpMeta[4];
tmp5 = &__omcQ_24tmpVar1;
while(1) {
tmp6 = 1;
if (!listEmpty(_s_loopVar)) {
_s = MMC_CAR(_s_loopVar);
_s_loopVar = MMC_CDR(_s_loopVar);
tmp6--;
}
if (tmp6 == 0) {
__omcQ_24tmpVar0 = omc_StackOverflow_stripAddresses(threadData, _s);
*tmp5 = mmc_mk_cons(__omcQ_24tmpVar0,0);
tmp5 = &MMC_CDR(*tmp5);
} else if (tmp6 == 1) {
break;
} else {
MMC_THROW_INTERNAL();
}
}
*tmp5 = mmc_mk_nil();
tmpMeta[3] = __omcQ_24tmpVar1;
}
{
modelica_metatype _symbol;
for (tmpMeta[1] = tmpMeta[3]; !listEmpty(tmpMeta[1]); tmpMeta[1]=MMC_CDR(tmpMeta[1]))
{
_symbol = MMC_CAR(tmpMeta[1]);
if((stringEqual(_prev, _OMC_LIT0)))
{
}
else
{
if((!stringEqual(_symbol, _prev)))
{
tmp1 = modelica_integer_to_modelica_string(_prevN, ((modelica_integer) 0), 1);
tmpMeta[3] = stringAppend(_OMC_LIT3,tmp1);
tmp3 = (modelica_boolean)(_n != _prevN);
if(tmp3)
{
tmp2 = modelica_integer_to_modelica_string(_n, ((modelica_integer) 0), 1);
tmpMeta[4] = stringAppend(_OMC_LIT4,tmp2);
tmp4 = tmpMeta[4];
}
else
{
tmp4 = _OMC_LIT0;
}
tmpMeta[5] = stringAppend(tmpMeta[3],tmp4);
tmpMeta[6] = stringAppend(tmpMeta[5],_OMC_LIT5);
tmpMeta[7] = stringAppend(tmpMeta[6],_prev);
tmpMeta[2] = mmc_mk_cons(tmpMeta[7], _symbols);
_symbols = tmpMeta[2];
_n = ((modelica_integer) 1) + _n;
_prevN = _n;
}
else
{
_n = ((modelica_integer) 1) + _n;
}
}
_prev = _symbol;
}
}
tmp7 = modelica_integer_to_modelica_string(_prevN, ((modelica_integer) 0), 1);
tmpMeta[2] = stringAppend(_OMC_LIT3,tmp7);
tmp9 = (modelica_boolean)(_n != _prevN);
if(tmp9)
{
tmp8 = modelica_integer_to_modelica_string(_n, ((modelica_integer) 0), 1);
tmpMeta[3] = stringAppend(_OMC_LIT4,tmp8);
tmp10 = tmpMeta[3];
}
else
{
tmp10 = _OMC_LIT0;
}
tmpMeta[4] = stringAppend(tmpMeta[2],tmp10);
tmpMeta[5] = stringAppend(tmpMeta[4],_OMC_LIT5);
tmpMeta[6] = stringAppend(tmpMeta[5],_prev);
tmpMeta[1] = mmc_mk_cons(tmpMeta[6], _symbols);
_symbols = tmpMeta[1];
_symbols = listReverse(_symbols);
_return: OMC_LABEL_UNUSED
return _symbols;
}
DLLExport
modelica_string omc_StackOverflow_getReadableMessage(threadData_t *threadData, modelica_string _delimiter)
{
modelica_string _str = NULL;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
_str = stringDelimitList(omc_StackOverflow_readableStacktraceMessages(threadData), _delimiter);
_return: OMC_LABEL_UNUSED
return _str;
}
DLLExport
modelica_string omc_StackOverflow_generateReadableMessage(threadData_t *threadData, modelica_integer _numFrames, modelica_integer _numSkip, modelica_string _delimiter)
{
modelica_string _str = NULL;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
omc_StackOverflow_setStacktraceMessages(threadData, _numSkip, _numFrames);
_str = omc_StackOverflow_getReadableMessage(threadData, _delimiter);
_return: OMC_LABEL_UNUSED
return _str;
}
modelica_metatype boxptr_StackOverflow_generateReadableMessage(threadData_t *threadData, modelica_metatype _numFrames, modelica_metatype _numSkip, modelica_metatype _delimiter)
{
modelica_integer tmp1;
modelica_integer tmp2;
modelica_string _str = NULL;
tmp1 = mmc_unbox_integer(_numFrames);
tmp2 = mmc_unbox_integer(_numSkip);
_str = omc_StackOverflow_generateReadableMessage(threadData, tmp1, tmp2, _delimiter);
return _str;
}
void omc_StackOverflow_triggerStackOverflow(threadData_t *threadData)
{
mmc_do_stackoverflow(threadData);
return;
}
PROTECTED_FUNCTION_STATIC modelica_string omc_StackOverflow_stripAddresses(threadData_t *threadData, modelica_string _inSymbol)
{
modelica_string _outSymbol = NULL;
modelica_integer _n;
modelica_metatype _strs = NULL;
modelica_string _so = NULL;
modelica_string _fun = NULL;
modelica_metatype tmpMeta[7] __attribute__((unused)) = {0};
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
_n = omc_System_regex(threadData, _inSymbol, _OMC_LIT7, ((modelica_integer) 3), 1, 0 ,&_strs);
if((_n == ((modelica_integer) 3)))
{
tmpMeta[0] = _strs;
if (listEmpty(tmpMeta[0])) MMC_THROW_INTERNAL();
tmpMeta[1] = MMC_CAR(tmpMeta[0]);
tmpMeta[2] = MMC_CDR(tmpMeta[0]);
if (listEmpty(tmpMeta[2])) MMC_THROW_INTERNAL();
tmpMeta[3] = MMC_CAR(tmpMeta[2]);
tmpMeta[4] = MMC_CDR(tmpMeta[2]);
if (listEmpty(tmpMeta[4])) MMC_THROW_INTERNAL();
tmpMeta[5] = MMC_CAR(tmpMeta[4]);
tmpMeta[6] = MMC_CDR(tmpMeta[4]);
if (!listEmpty(tmpMeta[6])) MMC_THROW_INTERNAL();
_so = tmpMeta[3];
_fun = tmpMeta[5];
tmpMeta[0] = stringAppend(_so,_OMC_LIT9);
tmpMeta[1] = stringAppend(tmpMeta[0],omc_StackOverflow_unmangle(threadData, _fun));
tmpMeta[2] = stringAppend(tmpMeta[1],_OMC_LIT10);
_outSymbol = tmpMeta[2];
}
else
{
_n = omc_System_regex(threadData, _inSymbol, _OMC_LIT8, ((modelica_integer) 3), 1, 0 ,&_strs);
if((_n == ((modelica_integer) 3)))
{
tmpMeta[0] = _strs;
if (listEmpty(tmpMeta[0])) MMC_THROW_INTERNAL();
tmpMeta[1] = MMC_CAR(tmpMeta[0]);
tmpMeta[2] = MMC_CDR(tmpMeta[0]);
if (listEmpty(tmpMeta[2])) MMC_THROW_INTERNAL();
tmpMeta[3] = MMC_CAR(tmpMeta[2]);
tmpMeta[4] = MMC_CDR(tmpMeta[2]);
if (listEmpty(tmpMeta[4])) MMC_THROW_INTERNAL();
tmpMeta[5] = MMC_CAR(tmpMeta[4]);
tmpMeta[6] = MMC_CDR(tmpMeta[4]);
if (!listEmpty(tmpMeta[6])) MMC_THROW_INTERNAL();
_so = tmpMeta[3];
_fun = tmpMeta[5];
tmpMeta[0] = stringAppend(_so,_OMC_LIT9);
tmpMeta[1] = stringAppend(tmpMeta[0],omc_StackOverflow_unmangle(threadData, _fun));
tmpMeta[2] = stringAppend(tmpMeta[1],_OMC_LIT10);
_outSymbol = tmpMeta[2];
}
else
{
_outSymbol = _inSymbol;
}
}
_return: OMC_LABEL_UNUSED
return _outSymbol;
}
PROTECTED_FUNCTION_STATIC modelica_string omc_StackOverflow_unmangle(threadData_t *threadData, modelica_string _inSymbol)
{
modelica_string _outSymbol = NULL;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
_outSymbol = _inSymbol;
if((stringLength(_inSymbol) > ((modelica_integer) 4)))
{
if((stringEqual(substring(_inSymbol, ((modelica_integer) 1), ((modelica_integer) 4)), _OMC_LIT15)))
{
_outSymbol = substring(_outSymbol, ((modelica_integer) 5), stringLength(_outSymbol));
_outSymbol = omc_System_stringReplace(threadData, _outSymbol, _OMC_LIT11, _OMC_LIT12);
_outSymbol = omc_System_stringReplace(threadData, _outSymbol, _OMC_LIT13, _OMC_LIT14);
_outSymbol = omc_System_stringReplace(threadData, _outSymbol, _OMC_LIT12, _OMC_LIT13);
}
}
_return: OMC_LABEL_UNUSED
return _outSymbol;
}
