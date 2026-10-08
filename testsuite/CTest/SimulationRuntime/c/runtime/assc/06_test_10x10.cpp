#include <stdio.h>
#include <string.h>
#include <stdlib.h>
#include <chrono>

#include "../../../Compiler/runtime/ASSCEXT.h"

// TODO: another example

/**
 * @brief Test function `test_assc`.
 *
 * @return int  Return 0 on test success, 1 otherwise.
 */
int main(void)
{
  int nv_ = 10;
  int ne_ = 10;

int start[] = {
  0,4,0,0,7,0,0,0,2,0,
  9,0,5,0,0,0,8,0,0,6,
  0,0,0,3,0,4,0,10,0,0,
  1,0,7,0,0,0,0,0,9,0,
  0,6,0,0,2,0,10,0,0,5,
  8,0,0,0,0,9,0,0,3,0,
  0,0,4,0,6,0,0,1,0,0,
  3,0,0,8,0,0,0,0,7,0,
  0,10,0,0,0,2,0,5,0,0,
  7,0,0,6,0,0,0,0,0,4
};




  ASSC_setMatrixDebug(start, nv_, ne_);
  ASSC_printMatrix();
  bareiss();


  int reference[] = {
    9, 0, 5, 0, 0, 0, 8, 0, 0, 6,
    0, 4, 0, 0, 7, 0, 0, 0, 2, 0,
    0, 0, 58, 0, 0, 0, -8, 0, 81, -6,
    0, 0, 0, 3, 0, 4, 0, 10, 0, 0,
    0, 0, 0, 0, -34, 0, 40, 0, -12, 20,
    0, 0, 0, 0, 0, 261, -224, 0, 267, -168,
    0, 0, 0, 0, 0, 0, 3752, 493, -3798, 1944,
    0, 0, 0, 0, 0, 0, 0, 90751, -29091, 10110,
    0, 0, 0, 0, 0, 0, 0, 0, 447959353, -13597650,
    0, 0, 0, 0, 0, 0, 0, 0, 0, 1
  };

  int mapping_ref[] = {1,0,3,2,4,5,6,7,8,9};

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
