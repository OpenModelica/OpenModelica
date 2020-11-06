#ifdef OMC_BASE_FILE
#define OMC_FILE OMC_BASE_FILE
#else
#define OMC_FILE "/home/mahge/dev/OpenModelica/OMCompiler/Compiler/boot/build/tmp/GC.c"
#endif
#include "omc_simulation_settings.h"
#include "GC.h"
#define _OMC_LIT0_data "GC Profiling Stats: "
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT0,20,_OMC_LIT0_data);
#define _OMC_LIT0 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT0)
#define _OMC_LIT1_data "\n  "
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT1,3,_OMC_LIT1_data);
#define _OMC_LIT1 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT1)
#define _OMC_LIT2_data "heapsize_full: "
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT2,15,_OMC_LIT2_data);
#define _OMC_LIT2 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT2)
#define _OMC_LIT3_data "free_bytes_full: "
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT3,17,_OMC_LIT3_data);
#define _OMC_LIT3 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT3)
#define _OMC_LIT4_data "unmapped_bytes: "
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT4,16,_OMC_LIT4_data);
#define _OMC_LIT4 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT4)
#define _OMC_LIT5_data "bytes_allocd_since_gc: "
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT5,23,_OMC_LIT5_data);
#define _OMC_LIT5 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT5)
#define _OMC_LIT6_data "allocd_bytes_before_gc: "
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT6,24,_OMC_LIT6_data);
#define _OMC_LIT6 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT6)
#define _OMC_LIT7_data "total_allocd_bytes: "
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT7,20,_OMC_LIT7_data);
#define _OMC_LIT7 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT7)
#define _OMC_LIT8_data "non_gc_bytes: "
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT8,14,_OMC_LIT8_data);
#define _OMC_LIT8 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT8)
#define _OMC_LIT9_data "gc_no: "
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT9,7,_OMC_LIT9_data);
#define _OMC_LIT9 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT9)
#define _OMC_LIT10_data "markers_m1: "
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT10,12,_OMC_LIT10_data);
#define _OMC_LIT10 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT10)
#define _OMC_LIT11_data "bytes_reclaimed_since_gc: "
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT11,26,_OMC_LIT11_data);
#define _OMC_LIT11 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT11)
#define _OMC_LIT12_data "reclaimed_bytes_before_gc: "
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT12,27,_OMC_LIT12_data);
#define _OMC_LIT12 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT12)
#include "util/modelica.h"
#include "GC_includes.h"
#if !defined(PROTECTED_FUNCTION_STATIC)
#define PROTECTED_FUNCTION_STATIC
#endif
PROTECTED_FUNCTION_STATIC modelica_metatype omc_GC_getProfStats_GC__get__prof__stats__modelica(threadData_t *threadData);
static const MMC_DEFSTRUCTLIT(boxvar_lit_GC_getProfStats_GC__get__prof__stats__modelica,2,0) {(void*) boxptr_GC_getProfStats_GC__get__prof__stats__modelica,0}};
#define boxvar_GC_getProfStats_GC__get__prof__stats__modelica MMC_REFSTRUCTLIT(boxvar_lit_GC_getProfStats_GC__get__prof__stats__modelica)
PROTECTED_FUNCTION_STATIC modelica_metatype omc_GC_getProfStats_GC__get__prof__stats__modelica(threadData_t *threadData)
{
modelica_metatype _stats_ext;
modelica_metatype _stats = NULL;
_stats_ext = GC_get_prof_stats_modelica();
_stats = (modelica_metatype)_stats_ext;
return _stats;
}
DLLExport
modelica_metatype omc_GC_getProfStats(threadData_t *threadData)
{
modelica_metatype _stats = NULL;
modelica_integer _heapsize_full;
modelica_integer _free_bytes_full;
modelica_integer _unmapped_bytes;
modelica_integer _bytes_allocd_since_gc;
modelica_integer _allocd_bytes_before_gc;
modelica_integer _non_gc_bytes;
modelica_integer _gc_no;
modelica_integer _markers_m1;
modelica_integer _bytes_reclaimed_since_gc;
modelica_integer _reclaimed_bytes_before_gc;
modelica_integer tmp1;
modelica_integer tmp2;
modelica_integer tmp3;
modelica_integer tmp4;
modelica_integer tmp5;
modelica_integer tmp6;
modelica_integer tmp7;
modelica_integer tmp8;
modelica_integer tmp9;
modelica_integer tmp10;
modelica_metatype tmpMeta[11] __attribute__((unused)) = {0};
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
tmpMeta[0] = omc_GC_getProfStats_GC__get__prof__stats__modelica(threadData);
tmpMeta[1] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[0]), 1));
tmp1 = mmc_unbox_integer(tmpMeta[1]);
tmpMeta[2] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[0]), 2));
tmp2 = mmc_unbox_integer(tmpMeta[2]);
tmpMeta[3] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[0]), 3));
tmp3 = mmc_unbox_integer(tmpMeta[3]);
tmpMeta[4] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[0]), 4));
tmp4 = mmc_unbox_integer(tmpMeta[4]);
tmpMeta[5] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[0]), 5));
tmp5 = mmc_unbox_integer(tmpMeta[5]);
tmpMeta[6] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[0]), 6));
tmp6 = mmc_unbox_integer(tmpMeta[6]);
tmpMeta[7] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[0]), 7));
tmp7 = mmc_unbox_integer(tmpMeta[7]);
tmpMeta[8] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[0]), 8));
tmp8 = mmc_unbox_integer(tmpMeta[8]);
tmpMeta[9] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[0]), 9));
tmp9 = mmc_unbox_integer(tmpMeta[9]);
tmpMeta[10] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[0]), 10));
tmp10 = mmc_unbox_integer(tmpMeta[10]);
_heapsize_full = tmp1;
_free_bytes_full = tmp2;
_unmapped_bytes = tmp3;
_bytes_allocd_since_gc = tmp4;
_allocd_bytes_before_gc = tmp5;
_non_gc_bytes = tmp6;
_gc_no = tmp7;
_markers_m1 = tmp8;
_bytes_reclaimed_since_gc = tmp9;
_reclaimed_bytes_before_gc = tmp10;
tmpMeta[0] = mmc_mk_box11(3, &GC_ProfStats_PROFSTATS__desc, mmc_mk_integer(_heapsize_full), mmc_mk_integer(_free_bytes_full), mmc_mk_integer(_unmapped_bytes), mmc_mk_integer(_bytes_allocd_since_gc), mmc_mk_integer(_allocd_bytes_before_gc), mmc_mk_integer(_non_gc_bytes), mmc_mk_integer(_gc_no), mmc_mk_integer(_markers_m1), mmc_mk_integer(_bytes_reclaimed_since_gc), mmc_mk_integer(_reclaimed_bytes_before_gc));
_stats = tmpMeta[0];
_return: OMC_LABEL_UNUSED
return _stats;
}
DLLExport
modelica_string omc_GC_profStatsStr(threadData_t *threadData, modelica_metatype _stats, modelica_string _head, modelica_string _delimiter)
{
modelica_string _str = NULL;
modelica_string tmp1 = 0;
modelica_metatype tmpMeta[33] __attribute__((unused)) = {0};
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
modelica_metatype tmp4_1;
tmp4_1 = _stats;
{
volatile mmc_switch_type tmp4;
int tmp5;
tmp4 = 0;
for (; tmp4 < 1; tmp4++) {
switch (MMC_SWITCH_CAST(tmp4)) {
case 0: {
tmpMeta[0] = stringAppend(_head,_delimiter);
tmpMeta[1] = stringAppend(tmpMeta[0],_OMC_LIT2);
tmpMeta[2] = stringAppend(tmpMeta[1],intString(mmc_unbox_integer((MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_stats), 2))))));
tmpMeta[3] = stringAppend(tmpMeta[2],_delimiter);
tmpMeta[4] = stringAppend(tmpMeta[3],_OMC_LIT3);
tmpMeta[5] = stringAppend(tmpMeta[4],intString(mmc_unbox_integer((MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_stats), 3))))));
tmpMeta[6] = stringAppend(tmpMeta[5],_delimiter);
tmpMeta[7] = stringAppend(tmpMeta[6],_OMC_LIT4);
tmpMeta[8] = stringAppend(tmpMeta[7],intString(mmc_unbox_integer((MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_stats), 4))))));
tmpMeta[9] = stringAppend(tmpMeta[8],_delimiter);
tmpMeta[10] = stringAppend(tmpMeta[9],_OMC_LIT5);
tmpMeta[11] = stringAppend(tmpMeta[10],intString(mmc_unbox_integer((MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_stats), 5))))));
tmpMeta[12] = stringAppend(tmpMeta[11],_delimiter);
tmpMeta[13] = stringAppend(tmpMeta[12],_OMC_LIT6);
tmpMeta[14] = stringAppend(tmpMeta[13],intString(mmc_unbox_integer((MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_stats), 6))))));
tmpMeta[15] = stringAppend(tmpMeta[14],_delimiter);
tmpMeta[16] = stringAppend(tmpMeta[15],_OMC_LIT7);
tmpMeta[17] = stringAppend(tmpMeta[16],intString(mmc_unbox_integer((MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_stats), 5)))) + mmc_unbox_integer((MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_stats), 6))))));
tmpMeta[18] = stringAppend(tmpMeta[17],_delimiter);
tmpMeta[19] = stringAppend(tmpMeta[18],_OMC_LIT8);
tmpMeta[20] = stringAppend(tmpMeta[19],intString(mmc_unbox_integer((MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_stats), 7))))));
tmpMeta[21] = stringAppend(tmpMeta[20],_delimiter);
tmpMeta[22] = stringAppend(tmpMeta[21],_OMC_LIT9);
tmpMeta[23] = stringAppend(tmpMeta[22],intString(mmc_unbox_integer((MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_stats), 8))))));
tmpMeta[24] = stringAppend(tmpMeta[23],_delimiter);
tmpMeta[25] = stringAppend(tmpMeta[24],_OMC_LIT10);
tmpMeta[26] = stringAppend(tmpMeta[25],intString(mmc_unbox_integer((MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_stats), 9))))));
tmpMeta[27] = stringAppend(tmpMeta[26],_delimiter);
tmpMeta[28] = stringAppend(tmpMeta[27],_OMC_LIT11);
tmpMeta[29] = stringAppend(tmpMeta[28],intString(mmc_unbox_integer((MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_stats), 10))))));
tmpMeta[30] = stringAppend(tmpMeta[29],_delimiter);
tmpMeta[31] = stringAppend(tmpMeta[30],_OMC_LIT12);
tmpMeta[32] = stringAppend(tmpMeta[31],intString(mmc_unbox_integer((MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_stats), 11))))));
tmp1 = tmpMeta[32];
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
_str = tmp1;
_return: OMC_LABEL_UNUSED
return _str;
}
void omc_GC_setMaxHeapSize(threadData_t *threadData, modelica_real _sz)
{
double _sz_ext;
_sz_ext = (double)_sz;
GC_set_max_heap_size_dbl(_sz_ext);
return;
}
void boxptr_GC_setMaxHeapSize(threadData_t *threadData, modelica_metatype _sz)
{
modelica_real tmp1;
tmp1 = mmc_unbox_real(_sz);
omc_GC_setMaxHeapSize(threadData, tmp1);
return;
}
void omc_GC_setForceUnmapOnGcollect(threadData_t *threadData, modelica_boolean _forceUnmap)
{
int _forceUnmap_ext;
_forceUnmap_ext = (int)_forceUnmap;
GC_set_force_unmap_on_gcollect(_forceUnmap_ext);
return;
}
void boxptr_GC_setForceUnmapOnGcollect(threadData_t *threadData, modelica_metatype _forceUnmap)
{
modelica_integer tmp1;
tmp1 = mmc_unbox_integer(_forceUnmap);
omc_GC_setForceUnmapOnGcollect(threadData, tmp1);
return;
}
modelica_boolean omc_GC_getForceUnmapOnGcollect(threadData_t *threadData)
{
int _res_ext;
modelica_boolean _res;
_res_ext = GC_get_force_unmap_on_gcollect();
_res = (modelica_boolean)_res_ext;
return _res;
}
modelica_metatype boxptr_GC_getForceUnmapOnGcollect(threadData_t *threadData)
{
modelica_boolean _res;
modelica_metatype out_res;
_res = omc_GC_getForceUnmapOnGcollect(threadData);
out_res = mmc_mk_icon(_res);
return out_res;
}
void omc_GC_setFreeSpaceDivisor(threadData_t *threadData, modelica_integer _divisor)
{
int _divisor_ext;
_divisor_ext = (int)_divisor;
GC_set_free_space_divisor(_divisor_ext);
return;
}
void boxptr_GC_setFreeSpaceDivisor(threadData_t *threadData, modelica_metatype _divisor)
{
modelica_integer tmp1;
tmp1 = mmc_unbox_integer(_divisor);
omc_GC_setFreeSpaceDivisor(threadData, tmp1);
return;
}
modelica_boolean omc_GC_expandHeap(threadData_t *threadData, modelica_real _sz)
{
double _sz_ext;
int _success_ext;
modelica_boolean _success;
_sz_ext = (double)_sz;
_success_ext = GC_expand_hp_dbl(_sz_ext);
_success = (modelica_boolean)_success_ext;
return _success;
}
modelica_metatype boxptr_GC_expandHeap(threadData_t *threadData, modelica_metatype _sz)
{
modelica_real tmp1;
modelica_boolean _success;
modelica_metatype out_success;
tmp1 = mmc_unbox_real(_sz);
_success = omc_GC_expandHeap(threadData, tmp1);
out_success = mmc_mk_icon(_success);
return out_success;
}
void omc_GC_free(threadData_t *threadData, modelica_metatype _data)
{
modelica_metatype _data_ext;
_data_ext = (modelica_metatype)_data;
omc_GC_free_ext(_data_ext);
return;
}
void omc_GC_disable(threadData_t *threadData)
{
GC_disable();
return;
}
void omc_GC_enable(threadData_t *threadData)
{
GC_enable();
return;
}
void omc_GC_gcollectAndUnmap(threadData_t *threadData)
{
GC_gcollect_and_unmap();
return;
}
void omc_GC_gcollect(threadData_t *threadData)
{
GC_gcollect();
return;
}
