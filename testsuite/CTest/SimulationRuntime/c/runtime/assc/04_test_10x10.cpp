#include <stdio.h>
#include <string.h>
#include <stdlib.h>
#include <chrono>

#include "../../../Compiler/runtime/ASSCEXT.h"

/**
 * @brief Test function `test_assc`.
 *
 * @return int  Return 0 on test success, 1 otherwise.
 */
int main(void)
{
  //tic
  auto start_time = std::chrono::high_resolution_clock::now();

  int nv_ = 10;
  int ne_ = 10;
  int runs = 10000;

  int start[] = {
    3,0,0,0,0,0,0,0,7,0,
    0,5,0,0,0,0,0,9,0,0,
    0,0,4,0,0,0,6,0,0,0,
    0,0,0,8,0,1,0,0,0,0,
    2,0,0,0,5,0,0,0,0,0,
    0,0,3,0,0,0,0,0,0,2,
    0,7,0,0,0,9,0,0,0,0,
    0,0,0,0,4,0,0,1,0,0,
    0,0,0,5,0,0,0,0,0,8,
    0,0,0,0,0,0,3,0,6,0
  };


  for (int i=0; i<runs; i++){
    ASSC_setMatrixDebug(start, nv_, ne_);
    //ASSC_printMatrix();
    bareiss();
  }

  int reference[] = {
    3,0,0,0,0,0,0,0,7,0,
    0,5,0,0,0,0,0,9,0,0,
    0,0,4,0,0,0,6,0,0,0,
    0,0,0,8,0,1,0,0,0,0,
    0,0,0,0,15,0,0,0,-14,0,
    0,0,0,0,0,45,0,-63,0,0,
    0,0,0,0,0,0,-18,0,0,8,
    0,0,0,0,0,0,0,15,56,0,
    0,0,0,0,0,0,0,0,49,120,
    0,0,0,0,0,0,0,0,0,1
  };

  int mapping_ref[] = {0,1,2,3,4,6,5,7,8,9};

  LIST** result = ASSC_fromDense(reference, nv_, ne_);

  if (isEqualAsscMatrixDebug(result, mapping_ref, ne_))
  {
    printf("All tests passed!\n");
    ASSC_printMatrix();
    //toc
    auto end_time = std::chrono::high_resolution_clock::now();

    std::chrono::duration<double, std::milli> elapsed = end_time - start_time;
    std::cout << "avg time: " << elapsed.count()/runs << " ms";
    return 0;
  }
  else
  {
    printf("Some tests failed!\n");
    ASSC_printMatrix();
    //toc
    auto end_time = std::chrono::high_resolution_clock::now();

    std::chrono::duration<double, std::milli> elapsed = end_time - start_time;
    std::cout << "avg time: " << elapsed.count()/runs << " ms";
    return 1;
  }
}
