/* Synchronous systems */
#include "Example_model.h"
#if defined(__cplusplus)
extern "C" {
#endif

/* Initializes the clocks of model. */
void Example_function_initSynchronous(DATA *data, threadData_t *threadData)
{
  assertStreamPrint(threadData, data->modelData->nBaseClocks==0, "Number of base clocks doesn't match number of clocks that are initialized! Code generation error!");
  data->simulationInfo->baseClocks = calloc(0, sizeof(BASECLOCK_DATA));
  
}

/* Update base-clock. */
void Example_function_updateSynchronous(DATA *data, threadData_t *threadData, long base_idx)
{
  modelica_boolean ret;
  switch (base_idx) {
    default:
      throwStreamPrint(NULL, "Internal Error: unknown base partition %ld", base_idx);
      break;
  }
}



/* Clocked systems equations */
int Example_function_equationsSynchronous(DATA *data, threadData_t *threadData, long base_idx, long sub_idx)
{
  int ret;

  switch (base_idx) {
    default:
      throwStreamPrint(NULL, "Internal Error: unknown base-clock partition %ld", base_idx);
      ret = 1;
      break;
  }

  return ret;
}

/* %v% = pre(%v%)*/
void Example_function_savePreSynchronous(DATA *data, threadData_t *threadData)
{
}

#if defined(__cplusplus)
}
#endif

