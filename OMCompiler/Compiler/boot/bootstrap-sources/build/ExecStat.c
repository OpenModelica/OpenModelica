#ifdef OMC_BASE_FILE
#define OMC_FILE OMC_BASE_FILE
#else
#define OMC_FILE "/home/mahge/dev/OpenModelica/OMCompiler/Compiler/boot/build/tmp/ExecStat.c"
#endif
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
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT4,2,3) {&Gettext_TranslatableContent_gettext__desc,_OMC_LIT3}};
#define _OMC_LIT4 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT4)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT5,5,3) {&ErrorTypes_Message_MESSAGE__desc,MMC_IMMEDIATE(MMC_TAGFIXNUM(572)),_OMC_LIT1,_OMC_LIT2,_OMC_LIT4}};
#define _OMC_LIT5 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT5)
#define _OMC_LIT6_data " GC"
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT6,3,_OMC_LIT6_data);
#define _OMC_LIT6 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT6)
#define _OMC_LIT7_data ""
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT7,0,_OMC_LIT7_data);
#define _OMC_LIT7 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT7)
#define _OMC_LIT8_data " / "
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT8,3,_OMC_LIT8_data);
#define _OMC_LIT8 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT8)
#define _OMC_LIT9_data "Performance of %s: time %s/%s, GC stats:%s"
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT9,42,_OMC_LIT9_data);
#define _OMC_LIT9 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT9)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT10,2,3) {&Gettext_TranslatableContent_gettext__desc,_OMC_LIT9}};
#define _OMC_LIT10 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT10)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT11,5,3) {&ErrorTypes_Message_MESSAGE__desc,MMC_IMMEDIATE(MMC_TAGFIXNUM(573)),_OMC_LIT1,_OMC_LIT2,_OMC_LIT10}};
#define _OMC_LIT11 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT11)
#define _OMC_LIT12_data "gcProfiling"
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT12,11,_OMC_LIT12_data);
#define _OMC_LIT12 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT12)
#define _OMC_LIT13_data "Prints garbage collection stats to standard output."
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT13,51,_OMC_LIT13_data);
#define _OMC_LIT13 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT13)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT14,2,3) {&Gettext_TranslatableContent_gettext__desc,_OMC_LIT13}};
#define _OMC_LIT14 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT14)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT15,5,3) {&Flags_DebugFlag_DEBUG__FLAG__desc,MMC_IMMEDIATE(MMC_TAGFIXNUM(13)),_OMC_LIT12,MMC_IMMEDIATE(MMC_TAGFIXNUM(0)),_OMC_LIT14}};
#define _OMC_LIT15 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT15)
#define _OMC_LIT16_data "execstatGCcollect"
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT16,17,_OMC_LIT16_data);
#define _OMC_LIT16 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT16)
#define _OMC_LIT17_data "When running execstat, also perform an extra full garbage collection."
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT17,69,_OMC_LIT17_data);
#define _OMC_LIT17 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT17)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT18,2,3) {&Gettext_TranslatableContent_gettext__desc,_OMC_LIT17}};
#define _OMC_LIT18 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT18)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT19,5,3) {&Flags_DebugFlag_DEBUG__FLAG__desc,MMC_IMMEDIATE(MMC_TAGFIXNUM(176)),_OMC_LIT16,MMC_IMMEDIATE(MMC_TAGFIXNUM(0)),_OMC_LIT18}};
#define _OMC_LIT19 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT19)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT20,2,1) {MMC_IMMEDIATE(MMC_TAGFIXNUM(2)),MMC_REFSTRUCTLIT(mmc_nil)}};
#define _OMC_LIT20 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT20)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT21,2,1) {MMC_IMMEDIATE(MMC_TAGFIXNUM(1)),_OMC_LIT20}};
#define _OMC_LIT21 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT21)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT22,2,1) {MMC_IMMEDIATE(MMC_TAGFIXNUM(1)),MMC_REFSTRUCTLIT(mmc_nil)}};
#define _OMC_LIT22 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT22)
#define _OMC_LIT23_data "execstat"
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT23,8,_OMC_LIT23_data);
#define _OMC_LIT23 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT23)
#define _OMC_LIT24_data "Prints out execution statistics for the compiler."
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT24,49,_OMC_LIT24_data);
#define _OMC_LIT24 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT24)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT25,2,3) {&Gettext_TranslatableContent_gettext__desc,_OMC_LIT24}};
#define _OMC_LIT25 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT25)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT26,5,3) {&Flags_DebugFlag_DEBUG__FLAG__desc,MMC_IMMEDIATE(MMC_TAGFIXNUM(31)),_OMC_LIT23,MMC_IMMEDIATE(MMC_TAGFIXNUM(0)),_OMC_LIT25}};
#define _OMC_LIT26 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT26)
#include "util/modelica.h"
#include "ExecStat_includes.h"
DLLExport
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
modelica_integer tmp1;
modelica_integer tmp2;
modelica_integer tmp3;
modelica_integer tmp4;
modelica_integer tmp5;
modelica_integer tmp6;
modelica_metatype tmpMeta[6] __attribute__((unused)) = {0};
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
if(omc_Flags_isSet(threadData, _OMC_LIT26))
{
{
modelica_metatype _i;
for (tmpMeta[0] = (omc_Flags_isSet(threadData, _OMC_LIT19)?_OMC_LIT21:_OMC_LIT22); !listEmpty(tmpMeta[0]); tmpMeta[0]=MMC_CDR(tmpMeta[0]))
{
_i = MMC_CAR(tmpMeta[0]);
if((mmc_unbox_integer(_i) == ((modelica_integer) 2)))
{
omc_GC_gcollect(threadData);
}
tmpMeta[1] = omc_GC_getProfStats(threadData);
tmpMeta[2] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[1]), 2));
tmp1 = mmc_unbox_integer(tmpMeta[2]);
tmpMeta[3] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[1]), 3));
tmp2 = mmc_unbox_integer(tmpMeta[3]);
tmpMeta[4] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[1]), 5));
tmp3 = mmc_unbox_integer(tmpMeta[4]);
tmpMeta[5] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[1]), 6));
tmp4 = mmc_unbox_integer(tmpMeta[5]);
_stats = tmpMeta[1];
_heapsize_full = tmp1;
_free_bytes_full = tmp2;
_since = tmp3;
_before = tmp4;
_memory = _since + _before;
_oldStats = getGlobalRoot(((modelica_integer) 21));
tmpMeta[1] = _oldStats;
tmpMeta[2] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[1]), 5));
tmp5 = mmc_unbox_integer(tmpMeta[2]);
tmpMeta[3] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[1]), 6));
tmp6 = mmc_unbox_integer(tmpMeta[3]);
_since = tmp5;
_before = tmp6;
_oldMemory = _since + _before;
_t = omc_System_realtimeTock(threadData, ((modelica_integer) 11));
_total = omc_System_realtimeTock(threadData, ((modelica_integer) 12));
_timeStr = omc_System_snprintff(threadData, _OMC_LIT0, ((modelica_integer) 20), _t);
_totalTimeStr = omc_System_snprintff(threadData, _OMC_LIT0, ((modelica_integer) 20), _total);
if(omc_Flags_isSet(threadData, _OMC_LIT15))
{
_gcStr = omc_GC_profStatsStr(threadData, _stats, _OMC_LIT7, _OMC_LIT8);
tmpMeta[2] = stringAppend(_name,((mmc_unbox_integer(_i) == ((modelica_integer) 2))?_OMC_LIT6:_OMC_LIT7));
tmpMeta[1] = mmc_mk_cons(tmpMeta[2], mmc_mk_cons(_timeStr, mmc_mk_cons(_totalTimeStr, mmc_mk_cons(_gcStr, MMC_REFSTRUCTLIT(mmc_nil)))));
omc_Error_addMessage(threadData, _OMC_LIT11, tmpMeta[1]);
}
else
{
tmpMeta[2] = stringAppend(_name,((mmc_unbox_integer(_i) == ((modelica_integer) 2))?_OMC_LIT6:_OMC_LIT7));
tmpMeta[1] = mmc_mk_cons(tmpMeta[2], mmc_mk_cons(_timeStr, mmc_mk_cons(_totalTimeStr, mmc_mk_cons(omc_StringUtil_bytesToReadableUnit(threadData, ((modelica_real)_memory - _oldMemory), ((modelica_integer) 4), 500.0), mmc_mk_cons(omc_StringUtil_bytesToReadableUnit(threadData, ((modelica_real)_memory), ((modelica_integer) 4), 500.0), mmc_mk_cons(omc_StringUtil_bytesToReadableUnit(threadData, ((modelica_real)_free_bytes_full), ((modelica_integer) 4), 500.0), mmc_mk_cons(omc_StringUtil_bytesToReadableUnit(threadData, ((modelica_real)_heapsize_full), ((modelica_integer) 4), 500.0), MMC_REFSTRUCTLIT(mmc_nil))))))));
omc_Error_addMessage(threadData, _OMC_LIT5, tmpMeta[1]);
}
omc_System_realtimeTick(threadData, ((modelica_integer) 11));
setGlobalRoot(((modelica_integer) 21), _stats);
}
}
}
_return: OMC_LABEL_UNUSED
return;
}
DLLExport
void omc_ExecStat_execStatReset(threadData_t *threadData)
{
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
omc_System_realtimeTick(threadData, ((modelica_integer) 11));
omc_System_realtimeTick(threadData, ((modelica_integer) 12));
setGlobalRoot(((modelica_integer) 21), omc_GC_getProfStats(threadData));
_return: OMC_LABEL_UNUSED
return;
}
