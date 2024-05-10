/* Asserts */
#include "TestFMU_model.h"
#if defined(__cplusplus)
extern "C" {
#endif

/* function to check assert after a step is done */
OMC_DISABLE_OPT
int TestFMU_checkForAsserts(DATA *data, threadData_t *threadData)
{
  TRACE_PUSH

  
  TRACE_POP
  return 0;
}

#if defined(__cplusplus)
}
#endif

