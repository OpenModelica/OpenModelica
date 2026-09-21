#include <stdio.h>
#include <string.h>
#include <stdlib.h>

#include "../../../Compiler/runtime/ASSCEXT.h"

// TODO: another example

/**
 * @brief Test function `test_assc`.
 *
 * @return int  Return 0 on test success, 1 otherwise.
 */
int main(void)
{
  int nv_ = 4;
  int ne_ = 4;

  int start[] = {
    1, 0, 0, 1,
    1, 1, 0, 0,
    0, 1, 1, 0,
    0, 0, 1, 1
  };

  ASSC_setMatrixDebug(start, nv_, ne_);
  ASSC_printMatrix();
  bareiss();


  int reference[] = {
    1, 0, 0, 1,
    0, 1, 0, -1,
    0, 0, 1, 1,
    0, 0, 0, 0
  };

  int mapping_ref[] = {0,1,2,3};

  LIST** result = ASSC_fromDense(reference, nv_, ne_);

  if (isEqualAsscMatrixDebug(result, mapping_ref, ne_))
  {
    printf("All tests passed!\n");
    ASSC_printMatrix();
    return 0;
  }
  else
  {
    printf("Some tests failed!\n");
    ASSC_printMatrix();
    return 1;
  }
}
