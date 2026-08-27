#include <meta/meta_modelica.h>
#ifdef __cplusplus
extern "C" {
#endif
#ifdef ADD_METARECORD_DEFINITIONS
#ifndef GC_ProfStats_PROFSTATS__desc_added
#define GC_ProfStats_PROFSTATS__desc_added
ADD_METARECORD_DEFINITIONS const char* GC_ProfStats_PROFSTATS__desc__fields[10] = {"heapsize_full","free_bytes_full","unmapped_bytes","bytes_allocd_since_gc","allocd_bytes_before_gc","non_gc_bytes","gc_no","markers_m1","bytes_reclaimed_since_gc","reclaimed_bytes_before_gc"};
ADD_METARECORD_DEFINITIONS struct record_description GC_ProfStats_PROFSTATS__desc = {
"GC_ProfStats_PROFSTATS",
"GC.ProfStats.PROFSTATS",
GC_ProfStats_PROFSTATS__desc__fields
};
#endif
#else
extern struct record_description GC_ProfStats_PROFSTATS__desc;
#endif
#ifdef ADD_METARECORD_DEFINITIONS
#ifndef GC_ProfStats_PROFSTATS__desc_added
#define GC_ProfStats_PROFSTATS__desc_added
ADD_METARECORD_DEFINITIONS const char* GC_ProfStats_PROFSTATS__desc__fields[10] = {"heapsize_full","free_bytes_full","unmapped_bytes","bytes_allocd_since_gc","allocd_bytes_before_gc","non_gc_bytes","gc_no","markers_m1","bytes_reclaimed_since_gc","reclaimed_bytes_before_gc"};
ADD_METARECORD_DEFINITIONS struct record_description GC_ProfStats_PROFSTATS__desc = {
"GC_ProfStats_PROFSTATS",
"GC.ProfStats.PROFSTATS",
GC_ProfStats_PROFSTATS__desc__fields
};
#endif
#else
extern struct record_description GC_ProfStats_PROFSTATS__desc;
#endif
#ifdef __cplusplus
}
#endif
