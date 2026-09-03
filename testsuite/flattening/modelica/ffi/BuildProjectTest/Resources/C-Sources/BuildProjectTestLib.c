#include "BuildProjectTestLib.h"
#include <ModelicaUtilities.h>

double buildProjectTest_scale(double x)
{
  if (x < 0.0) {
    ModelicaError("buildProjectTest_scale: x must not be negative");
  }
  return 21.0 * x;
}
