#ifndef PWE_ACCUMULATOR_C
#define PWE_ACCUMULATOR_C
#include <stdlib.h>

void* pwe_accumulator_new(void) { return calloc(1, sizeof(double)); }
void pwe_accumulator_free(void* acc) { free(acc); }
double pwe_accumulate(void* acc, double x) { return *(double*)acc += x; }
#endif
