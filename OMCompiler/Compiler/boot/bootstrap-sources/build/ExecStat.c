#include "omc_simulation_settings.h"
#include "ExecStat.h"
#define _OMC_LIT0_data "%.4g"
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT0,4,_OMC_LIT0_data);
#define _OMC_LIT0 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT0)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT1,1,5) {&ErrorTypes_MessageType_TRANSLATION__desc,}};
#define _OMC_LIT1 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT1)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT2,1,6) {&ErrorTypes_Severity_NOTIFICATION__desc,}};
#define _OMC_LIT2 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT2)
#define _OMC_LIT3_data "Performance of %s: time %s/%s, allocations: %s / %s, free: %s / %s"
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT3,66,_OMC_LIT3_data);
#define _OMC_LIT3 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT3)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT4,5,3) {&ErrorTypes_Message_MESSAGE__desc,MMC_IMMEDIATE(MMC_TAGFIXNUM(572)),_OMC_LIT1,_OMC_LIT2,_OMC_LIT3}};
#define _OMC_LIT4 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT4)
#define _OMC_LIT5_data " GC"
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT5,3,_OMC_LIT5_data);
#define _OMC_LIT5 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT5)
#define _OMC_LIT6_data ""
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT6,0,_OMC_LIT6_data);
#define _OMC_LIT6 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT6)
#define _OMC_LIT7_data " / "
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT7,3,_OMC_LIT7_data);
#define _OMC_LIT7 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT7)
#define _OMC_LIT8_data "Performance of %s: time %s/%s, GC stats:%s"
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT8,42,_OMC_LIT8_data);
#define _OMC_LIT8 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT8)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT9,5,3) {&ErrorTypes_Message_MESSAGE__desc,MMC_IMMEDIATE(MMC_TAGFIXNUM(573)),_OMC_LIT1,_OMC_LIT2,_OMC_LIT8}};
#define _OMC_LIT9 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT9)
#define _OMC_LIT10_data "gcProfiling"
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT10,11,_OMC_LIT10_data);
#define _OMC_LIT10 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT10)
#define _OMC_LIT11_data "Prints garbage collection stats to standard output."
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT11,51,_OMC_LIT11_data);
#define _OMC_LIT11 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT11)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT12,5,3) {&Flags_DebugFlag_DEBUG__FLAG__desc,MMC_IMMEDIATE(MMC_TAGFIXNUM(13)),_OMC_LIT10,MMC_IMMEDIATE(MMC_TAGFIXNUM(0 /* false */)),_OMC_LIT11}};
#define _OMC_LIT12 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT12)
#define _OMC_LIT13_data "execstatGCcollect"
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT13,17,_OMC_LIT13_data);
#define _OMC_LIT13 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT13)
#define _OMC_LIT14_data "When running execstat, also perform an extra full garbage collection."
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT14,69,_OMC_LIT14_data);
#define _OMC_LIT14 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT14)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT15,5,3) {&Flags_DebugFlag_DEBUG__FLAG__desc,MMC_IMMEDIATE(MMC_TAGFIXNUM(165)),_OMC_LIT13,MMC_IMMEDIATE(MMC_TAGFIXNUM(0 /* false */)),_OMC_LIT14}};
#define _OMC_LIT15 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT15)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT16,2,1) {MMC_IMMEDIATE(MMC_TAGFIXNUM(2)),MMC_REFSTRUCTLIT(mmc_nil)}};
#define _OMC_LIT16 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT16)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT17,2,1) {MMC_IMMEDIATE(MMC_TAGFIXNUM(1)),_OMC_LIT16}};
#define _OMC_LIT17 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT17)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT18,2,1) {MMC_IMMEDIATE(MMC_TAGFIXNUM(1)),MMC_REFSTRUCTLIT(mmc_nil)}};
#define _OMC_LIT18 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT18)
#define _OMC_LIT19_data "execstat"
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT19,8,_OMC_LIT19_data);
#define _OMC_LIT19 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT19)
#define _OMC_LIT20_data "Prints out execution statistics for the compiler."
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT20,49,_OMC_LIT20_data);
#define _OMC_LIT20 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT20)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT21,5,3) {&Flags_DebugFlag_DEBUG__FLAG__desc,MMC_IMMEDIATE(MMC_TAGFIXNUM(31)),_OMC_LIT19,MMC_IMMEDIATE(MMC_TAGFIXNUM(0 /* false */)),_OMC_LIT20}};
#define _OMC_LIT21 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT21)
#include "util/modelica.h"
#include "ExecStat_includes.h"
#if !defined(PROTECTED_FUNCTION_STATIC)
#define PROTECTED_FUNCTION_STATIC
#endif
PROTECTED_FUNCTION_STATIC modelica_string omc_ExecStat_execStat_bytesToReadableUnit(threadData_t *threadData, modelica_real _bytes);
PROTECTED_FUNCTION_STATIC modelica_metatype boxptr_ExecStat_execStat_bytesToReadableUnit(threadData_t *threadData, modelica_metatype _bytes);
static const MMC_DEFSTRUCTLIT(boxvar_lit_ExecStat_execStat_bytesToReadableUnit,2,0) {(void*) boxptr_ExecStat_execStat_bytesToReadableUnit,0}};
#define boxvar_ExecStat_execStat_bytesToReadableUnit MMC_REFSTRUCTLIT(boxvar_lit_ExecStat_execStat_bytesToReadableUnit)
PROTECTED_FUNCTION_STATIC modelica_string omc_ExecStat_execStat_snprintff(threadData_t *threadData, modelica_real _val);
PROTECTED_FUNCTION_STATIC modelica_metatype boxptr_ExecStat_execStat_snprintff(threadData_t *threadData, modelica_metatype _val);
static const MMC_DEFSTRUCTLIT(boxvar_lit_ExecStat_execStat_snprintff,2,0) {(void*) boxptr_ExecStat_execStat_snprintff,0}};
#define boxvar_ExecStat_execStat_snprintff MMC_REFSTRUCTLIT(boxvar_lit_ExecStat_execStat_snprintff)
PROTECTED_FUNCTION_STATIC modelica_string omc_ExecStat_execStat_bytesToReadableUnit(threadData_t *threadData, modelica_real _bytes)
{
modelica_string _str = NULL;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
_str = omc_StringUtil_bytesToReadableUnit(threadData, _bytes, ((modelica_integer) 4), 500.0);
_return: OMC_LABEL_UNUSED
return _str;
}
PROTECTED_FUNCTION_STATIC modelica_metatype boxptr_ExecStat_execStat_bytesToReadableUnit(threadData_t *threadData, modelica_metatype _bytes)
{
modelica_real tmp1;
modelica_string _str = NULL;
tmp1 = mmc_unbox_real(_bytes);
_str = omc_ExecStat_execStat_bytesToReadableUnit(threadData, tmp1);
return _str;
}
PROTECTED_FUNCTION_STATIC modelica_string omc_ExecStat_execStat_snprintff(threadData_t *threadData, modelica_real _val)
{
modelica_string _str = NULL;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
_str = omc_System_snprintff(threadData, _OMC_LIT0, ((modelica_integer) 20), _val);
_return: OMC_LABEL_UNUSED
return _str;
}
PROTECTED_FUNCTION_STATIC modelica_metatype boxptr_ExecStat_execStat_snprintff(threadData_t *threadData, modelica_metatype _val)
{
modelica_real tmp1;
modelica_string _str = NULL;
tmp1 = mmc_unbox_real(_val);
_str = omc_ExecStat_execStat_snprintff(threadData, tmp1);
return _str;
}
DLLDirection
void omc_ExecStat_execStat(threadData_t *threadData, modelica_string _name)
{
modelica_real _t;
modelica_real _total;
modelica_string _timeStr = NULL;
modelica_string _totalTimeStr = NULL;
modelica_string _gcStr = NULL;
modelica_integer _memory;
modelica_integer _oldMemory;
modelica_integer _heapsize_full;
modelica_integer _free_bytes_full;
modelica_integer _since;
modelica_integer _before;
modelica_metatype _stats = NULL;
modelica_metatype _oldStats = NULL;
modelica_metatype tmpMeta1;
modelica_metatype tmpMeta2;
modelica_metatype tmpMeta3;
modelica_integer tmp4;
modelica_metatype tmpMeta5;
modelica_integer tmp6;
modelica_metatype tmpMeta7;
modelica_integer tmp8;
modelica_metatype tmpMeta9;
modelica_integer tmp10;
modelica_metatype tmpMeta11;
modelica_metatype tmpMeta12;
modelica_integer tmp13;
modelica_metatype tmpMeta14;
modelica_integer tmp15;
modelica_metatype tmpMeta16;
modelica_metatype tmpMeta17;
modelica_metatype tmpMeta18;
modelica_metatype tmpMeta19;
modelica_metatype tmpMeta20;
#if defined(OMC_MINIMAL_RUNTIME) || defined(OMC_FMI_RUNTIME)
MemPoolState omc_pool_state = omc_util_get_pool_state();
#endif
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
if(omc_Flags_isSet(threadData, _OMC_LIT21))
{
{
modelica_metatype _i;
for (tmpMeta1 = (omc_Flags_isSet(threadData, _OMC_LIT15)?_OMC_LIT17:_OMC_LIT18); !listEmpty(tmpMeta1); tmpMeta1=MMC_CDR(tmpMeta1))
{
_i = MMC_CAR(tmpMeta1);
if((mmc_unbox_integer(_i) == ((modelica_integer) 2)))
{
omc_GCExt_gcollect(threadData);
}
_t = omc_System_realtimeAccumulate(threadData, ((modelica_integer) 11));
_total = omc_System_realtimeAccumulated(threadData, ((modelica_integer) 11));
tmpMeta2 = omc_GCExt_getProfStats(threadData);
tmpMeta3 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta2), 2));
tmp4 = mmc_unbox_integer(tmpMeta3);
tmpMeta5 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta2), 3));
tmp6 = mmc_unbox_integer(tmpMeta5);
tmpMeta7 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta2), 5));
tmp8 = mmc_unbox_integer(tmpMeta7);
tmpMeta9 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta2), 6));
tmp10 = mmc_unbox_integer(tmpMeta9);
_stats = tmpMeta2;
_heapsize_full = tmp4;
_free_bytes_full = tmp6;
_since = tmp8;
_before = tmp10;
_memory = _since + _before;
_oldStats = getGlobalRoot(((modelica_integer) 21));
tmpMeta11 = _oldStats;
tmpMeta12 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta11), 5));
tmp13 = mmc_unbox_integer(tmpMeta12);
tmpMeta14 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta11), 6));
tmp15 = mmc_unbox_integer(tmpMeta14);
_since = tmp13;
_before = tmp15;
_oldMemory = _since + _before;
_timeStr = omc_ExecStat_execStat_snprintff(threadData, _t);
_totalTimeStr = omc_ExecStat_execStat_snprintff(threadData, _total);
if(omc_Flags_isSet(threadData, _OMC_LIT12))
{
_gcStr = omc_GCExt_profStatsStr(threadData, _stats, _OMC_LIT6, _OMC_LIT7);
tmpMeta17 = stringAppend(_name,((mmc_unbox_integer(_i) == ((modelica_integer) 2))?_OMC_LIT5:_OMC_LIT6));
tmpMeta16 = mmc_mk_cons(tmpMeta17, mmc_mk_cons(_timeStr, mmc_mk_cons(_totalTimeStr, mmc_mk_cons(_gcStr, MMC_REFSTRUCTLIT(mmc_nil)))));
omc_Error_addMessage(threadData, _OMC_LIT9, tmpMeta16);
}
else
{
tmpMeta19 = stringAppend(_name,((mmc_unbox_integer(_i) == ((modelica_integer) 2))?_OMC_LIT5:_OMC_LIT6));
tmpMeta18 = mmc_mk_cons(tmpMeta19, mmc_mk_cons(_timeStr, mmc_mk_cons(_totalTimeStr, mmc_mk_cons(omc_ExecStat_execStat_bytesToReadableUnit(threadData, ((modelica_real)_memory - _oldMemory)), mmc_mk_cons(omc_ExecStat_execStat_bytesToReadableUnit(threadData, ((modelica_real)_memory)), mmc_mk_cons(omc_ExecStat_execStat_bytesToReadableUnit(threadData, ((modelica_real)_free_bytes_full)), mmc_mk_cons(omc_ExecStat_execStat_bytesToReadableUnit(threadData, ((modelica_real)_heapsize_full)), MMC_REFSTRUCTLIT(mmc_nil))))))));
omc_Error_addMessage(threadData, _OMC_LIT4, tmpMeta18);
}
setGlobalRoot(((modelica_integer) 21), _stats);
omc_System_realtimeTick(threadData, ((modelica_integer) 11));
}
}
}
_return: OMC_LABEL_UNUSED
#if defined(OMC_MINIMAL_RUNTIME) || defined(OMC_FMI_RUNTIME)
omc_util_restore_pool_state(omc_pool_state);
#endif
return;
}
DLLDirection
void omc_ExecStat_execStatReset(threadData_t *threadData)
{
#if defined(OMC_MINIMAL_RUNTIME) || defined(OMC_FMI_RUNTIME)
MemPoolState omc_pool_state = omc_util_get_pool_state();
#endif
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
setGlobalRoot(((modelica_integer) 21), omc_GCExt_getProfStats(threadData));
omc_System_realtimeClear(threadData, ((modelica_integer) 11));
omc_System_realtimeTick(threadData, ((modelica_integer) 11));
_return: OMC_LABEL_UNUSED
#if defined(OMC_MINIMAL_RUNTIME) || defined(OMC_FMI_RUNTIME)
omc_util_restore_pool_state(omc_pool_state);
#endif
return;
}
