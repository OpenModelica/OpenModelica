/* What the package manager builds from getExternalFunctions: the Include
   sources sharing counter.h in one unit, with the call wrappers omc binds. */
#include <stddef.h>
#include "counter_increment.c"
#include "counter_count.c"
#include "twice.c"
#include "accumulator.c"
int omc_ext_call_pwe_increment(void) { return pwe_increment(); }
int omc_ext_call_pwe_count(void) { return pwe_count(); }
double omc_ext_call_pwe_twice(double a0) { return pwe_twice(a0); }
void* omc_ext_call_pwe_accumulator_new(void) { return pwe_accumulator_new(); }
void omc_ext_call_pwe_accumulator_free(void* a0) { pwe_accumulator_free(a0); }
double omc_ext_call_pwe_accumulate(void* a0, double a1) { return pwe_accumulate(a0, a1); }
