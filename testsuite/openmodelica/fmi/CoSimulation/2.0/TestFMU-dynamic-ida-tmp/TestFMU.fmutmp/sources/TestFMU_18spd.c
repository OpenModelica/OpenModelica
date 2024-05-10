/* spatialDistribution */
#include "TestFMU_model.h"
#if defined(__cplusplus)
extern "C" {
#endif

int TestFMU_function_storeSpatialDistribution(DATA *data, threadData_t *threadData)
{
  int equationIndexes[2] = {1,-1};
  
  TRACE_POP
  return 0;
}

int TestFMU_function_initSpatialDistribution(DATA *data, threadData_t *threadData)
{

  
  TRACE_POP
  return 0;
}

#if defined(__cplusplus)
}
#endif

