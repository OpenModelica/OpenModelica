#include <ModelicaUtilities.h>

/* 1/x, defined on (0, 10]; a trial outside that is an error, not a value. */
double ExternalNlsRecovery_f(double x)
{
  if (x <= 0.0 || x > 10.0) {
    ModelicaError("ExternalNlsRecovery_f: x is out of range");
  }
  return 1.0 / x;
}
