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
  //tic
  auto start_time = std::chrono::high_resolution_clock::now();
  int nv_ = 7;
  int ne_ = 7;
  int runs = 10000;

int start[] = {
  2, 0, 3, 0, 0, 0, 0,
  0, 1, 0, 2, 0, 0, 0,
  0, 0, 4, 0, 0, 0, 1,
  0, 0, 0, 3, 0, 5, 0,
  1, 0, 0, 0, 2, 0, 0,
  0, 2, 0, 0, 0, 3, 0,
  0, 0, 0, 0, 4, 0, 2
};




  for (int i=0; i<runs; i++){
    ASSC_setMatrixDebug(start, nv_, ne_);
    //ASSC_printMatrix();
    bareiss();
  }


  int reference[] = {
    2, 0, 3, 0, 0, 0, 0,
    0, 1, 0, 2, 0, 0, 0,
    0, 0, 4, 0, 0, 0, 1,
    0, 0, 0, 3, 0, 5, 0,
    0, 0, 0, 0, 16, 0, 3,
    0, 0, 0, 0, 0, 29, 0,
    0, 0, 0, 0, 0, 0, 20
  };

  int mapping_ref[] = {0,1,2,3,4,5,6};

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
