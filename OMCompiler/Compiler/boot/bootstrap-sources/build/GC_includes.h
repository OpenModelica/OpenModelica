#ifdef __cplusplus
extern "C" {
#endif
void omc_GC_free_ext(void *data)
{
GC_free(MMC_UNTAGPTR(data));
}
#define GC_expand_hp_dbl(sz) GC_expand_hp(sz)
#define GC_set_free_space_divisor_int(divisor) GC_set_free_space_divisor(divisor)
#define GC_set_max_heap_size_dbl(sz) omc_GC_set_max_heap_size((size_t)sz)
static inline modelica_metatype GC_get_prof_stats_modelica()
{
#if ((GC_VERSION_MAJOR == 7) && (GC_VERSION_MINOR >= 5)) || (GC_VERSION_MAJOR >= 8)
struct GC_prof_stats_s info;
GC_get_prof_stats(&info,sizeof(struct GC_prof_stats_s));
return mmc_mk_box10(
0,
mmc_mk_icon(info.heapsize_full),
mmc_mk_icon(info.free_bytes_full),
mmc_mk_icon(info.unmapped_bytes),
mmc_mk_icon(info.bytes_allocd_since_gc),
mmc_mk_icon(info.allocd_bytes_before_gc),
mmc_mk_icon(info.non_gc_bytes),
mmc_mk_icon(info.gc_no),
mmc_mk_icon(info.markers_m1),
mmc_mk_icon(info.bytes_reclaimed_since_gc),
mmc_mk_icon(info.reclaimed_bytes_before_gc));
#else
return mmc_mk_box10(
0,
mmc_mk_icon(0),
mmc_mk_icon(0),
mmc_mk_icon(0),
mmc_mk_icon(0),
mmc_mk_icon(0),
mmc_mk_icon(0),
mmc_mk_icon(0),
mmc_mk_icon(0),
mmc_mk_icon(0),
mmc_mk_icon(0));
#endif
}
#include "GC.h"
#ifdef __cplusplus
}
#endif
