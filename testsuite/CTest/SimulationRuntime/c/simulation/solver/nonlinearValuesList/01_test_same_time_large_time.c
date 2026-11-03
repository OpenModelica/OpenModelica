#include <math.h>
#include <stdio.h>
#include "simulation/solver/nonlinearValuesList.h"
#include "util/list.h"

static void add(LIST* list, double time, double value)
{
  VALUE* elem = createValueElement(1, time, &value);
  addListElement(list, elem);
  freeValue(elem);
}

/**
 * @brief Test that two solutions a few ulps apart count as the same time (#17738).
 *
 * At t = 4097 one ulp is 9.1e-13, so solutions 3 ulps apart are more than 1e-12
 * apart. They must still be one entry, or the next start value is extrapolated
 * with a factor of about 1e11.
 *
 * @return int  Return 0 on test success, 1 otherwise.
 */
int main(void)
{
  int failed = 0;
  double guess, old;
  double t1 = 4097.0;
  double t2 = nextafter(nextafter(nextafter(t1, INFINITY), INFINITY), INFINITY);
  VALUES_LIST* lists = allocValueList(1, 1);
  LIST* list = lists[0].valueList;

  add(list, 4096.75, 1.0e6);
  add(list, t1, 1.0e6 + 1);
  add(list, t2, 1.0e6 + 2);
  if (listLen(list) != 2) {
    printf("Expected 2 entries at large time, got %d\n", listLen(list));
    failed = 1;
  }
  getValues(list, 4097.25, &guess, &old);
  if (fabs(guess - (1.0e6 + 4)) > 1e-3) {
    printf("Expected guess 1000004 at large time, got %.17g\n", guess);
    failed = 1;
  }

  /* Below |t| = 1 the absolute MINIMAL_STEP_SIZE still decides. */
  cleanValueList(list, NULL);
  add(list, 0.25, 1.0);
  add(list, 0.5, 2.0);
  add(list, 0.5 + 2e-12, 3.0);
  if (listLen(list) != 3) {
    printf("Expected 3 entries at small time, got %d\n", listLen(list));
    failed = 1;
  }

  freeValueList(lists, 1);
  return failed;
}
