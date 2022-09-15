#ifdef OMC_BASE_FILE
#define OMC_FILE OMC_BASE_FILE
#else
#define OMC_FILE "StackOverflow.c"
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
modelica_metatype tmpMeta1;
modelica_string _prev = NULL;
modelica_integer _n;
modelica_integer _prevN;
modelica_metatype tmpMeta2;
modelica_metatype tmpMeta3;
modelica_string tmp4;
modelica_metatype tmpMeta5;
modelica_string tmp6;
modelica_metatype tmpMeta7;
modelica_boolean tmp8;
modelica_string tmp9;
modelica_metatype tmpMeta10;
modelica_metatype tmpMeta11;
modelica_metatype tmpMeta12;
modelica_metatype tmpMeta13;
modelica_metatype tmpMeta14;
modelica_metatype tmpMeta18;
modelica_string tmp19;
modelica_metatype tmpMeta20;
modelica_string tmp21;
modelica_metatype tmpMeta22;
modelica_boolean tmp23;
modelica_string tmp24;
modelica_metatype tmpMeta25;
modelica_metatype tmpMeta26;
modelica_metatype tmpMeta27;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
tmpMeta1 = MMC_REFSTRUCTLIT(mmc_nil);
_symbols = tmpMeta1;
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
modelica_metatype* tmp15;
modelica_metatype tmpMeta16;
modelica_string __omcQ_24tmpVar0;
modelica_integer tmp17;
modelica_metatype _s_loopVar = 0;
modelica_metatype _s;
_s_loopVar = omc_StackOverflow_getStacktraceMessages(threadData);
tmpMeta16 = MMC_REFSTRUCTLIT(mmc_nil);
__omcQ_24tmpVar1 = tmpMeta16;
tmp15 = &__omcQ_24tmpVar1;
while(1) {
tmp17 = 1;
if (!listEmpty(_s_loopVar)) {
_s = MMC_CAR(_s_loopVar);
_s_loopVar = MMC_CDR(_s_loopVar);
tmp17--;
}
if (tmp17 == 0) {
__omcQ_24tmpVar0 = omc_StackOverflow_stripAddresses(threadData, _s);
*tmp15 = mmc_mk_cons(__omcQ_24tmpVar0,0);
tmp15 = &MMC_CDR(*tmp15);
} else if (tmp17 == 1) {
break;
} else {
MMC_THROW_INTERNAL();
}
}
*tmp15 = mmc_mk_nil();
tmpMeta14 = __omcQ_24tmpVar1;
}
{
modelica_metatype _symbol;
for (tmpMeta2 = tmpMeta14; !listEmpty(tmpMeta2); tmpMeta2=MMC_CDR(tmpMeta2))
{
_symbol = MMC_CAR(tmpMeta2);
if((stringEqual(_prev, _OMC_LIT0)))
{
}
else
{
if((!stringEqual(_symbol, _prev)))
{
tmp4 = modelica_integer_to_modelica_string(_prevN, ((modelica_integer) 0), 1);
tmpMeta5 = stringAppend(_OMC_LIT3,tmp4);
tmp8 = (modelica_boolean)(_n != _prevN);
if(tmp8)
{
tmp6 = modelica_integer_to_modelica_string(_n, ((modelica_integer) 0), 1);
tmpMeta7 = stringAppend(_OMC_LIT4,tmp6);
tmp9 = tmpMeta7;
}
else
{
tmp9 = _OMC_LIT0;
}
tmpMeta10 = stringAppend(tmpMeta5,tmp9);
tmpMeta11 = stringAppend(tmpMeta10,_OMC_LIT5);
tmpMeta12 = stringAppend(tmpMeta11,_prev);
tmpMeta3 = mmc_mk_cons(tmpMeta12, _symbols);
_symbols = tmpMeta3;
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
tmp19 = modelica_integer_to_modelica_string(_prevN, ((modelica_integer) 0), 1);
tmpMeta20 = stringAppend(_OMC_LIT3,tmp19);
tmp23 = (modelica_boolean)(_n != _prevN);
if(tmp23)
{
tmp21 = modelica_integer_to_modelica_string(_n, ((modelica_integer) 0), 1);
tmpMeta22 = stringAppend(_OMC_LIT4,tmp21);
tmp24 = tmpMeta22;
}
else
{
tmp24 = _OMC_LIT0;
}
tmpMeta25 = stringAppend(tmpMeta20,tmp24);
tmpMeta26 = stringAppend(tmpMeta25,_OMC_LIT5);
tmpMeta27 = stringAppend(tmpMeta26,_prev);
tmpMeta18 = mmc_mk_cons(tmpMeta27, _symbols);
_symbols = tmpMeta18;
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
modelica_metatype tmpMeta1;
modelica_metatype tmpMeta2;
modelica_metatype tmpMeta3;
modelica_metatype tmpMeta4;
modelica_metatype tmpMeta5;
modelica_metatype tmpMeta6;
modelica_metatype tmpMeta7;
modelica_metatype tmpMeta8;
modelica_metatype tmpMeta9;
modelica_metatype tmpMeta10;
modelica_metatype tmpMeta11;
modelica_metatype tmpMeta12;
modelica_metatype tmpMeta13;
modelica_metatype tmpMeta14;
modelica_metatype tmpMeta15;
modelica_metatype tmpMeta16;
modelica_metatype tmpMeta17;
modelica_metatype tmpMeta18;
modelica_metatype tmpMeta19;
modelica_metatype tmpMeta20;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
_n = omc_System_regex(threadData, _inSymbol, _OMC_LIT7, ((modelica_integer) 3), 1, 0 ,&_strs);
if((_n == ((modelica_integer) 3)))
{
tmpMeta1 = _strs;
if (listEmpty(tmpMeta1)) MMC_THROW_INTERNAL();
tmpMeta2 = MMC_CAR(tmpMeta1);
tmpMeta3 = MMC_CDR(tmpMeta1);
if (listEmpty(tmpMeta3)) MMC_THROW_INTERNAL();
tmpMeta4 = MMC_CAR(tmpMeta3);
tmpMeta5 = MMC_CDR(tmpMeta3);
if (listEmpty(tmpMeta5)) MMC_THROW_INTERNAL();
tmpMeta6 = MMC_CAR(tmpMeta5);
tmpMeta7 = MMC_CDR(tmpMeta5);
if (!listEmpty(tmpMeta7)) MMC_THROW_INTERNAL();
_so = tmpMeta4;
_fun = tmpMeta6;
tmpMeta8 = stringAppend(_so,_OMC_LIT9);
tmpMeta9 = stringAppend(tmpMeta8,omc_StackOverflow_unmangle(threadData, _fun));
tmpMeta10 = stringAppend(tmpMeta9,_OMC_LIT10);
_outSymbol = tmpMeta10;
}
else
{
_n = omc_System_regex(threadData, _inSymbol, _OMC_LIT8, ((modelica_integer) 3), 1, 0 ,&_strs);
if((_n == ((modelica_integer) 3)))
{
tmpMeta11 = _strs;
if (listEmpty(tmpMeta11)) MMC_THROW_INTERNAL();
tmpMeta12 = MMC_CAR(tmpMeta11);
tmpMeta13 = MMC_CDR(tmpMeta11);
if (listEmpty(tmpMeta13)) MMC_THROW_INTERNAL();
tmpMeta14 = MMC_CAR(tmpMeta13);
tmpMeta15 = MMC_CDR(tmpMeta13);
if (listEmpty(tmpMeta15)) MMC_THROW_INTERNAL();
tmpMeta16 = MMC_CAR(tmpMeta15);
tmpMeta17 = MMC_CDR(tmpMeta15);
if (!listEmpty(tmpMeta17)) MMC_THROW_INTERNAL();
_so = tmpMeta14;
_fun = tmpMeta16;
tmpMeta18 = stringAppend(_so,_OMC_LIT9);
tmpMeta19 = stringAppend(tmpMeta18,omc_StackOverflow_unmangle(threadData, _fun));
tmpMeta20 = stringAppend(tmpMeta19,_OMC_LIT10);
_outSymbol = tmpMeta20;
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
