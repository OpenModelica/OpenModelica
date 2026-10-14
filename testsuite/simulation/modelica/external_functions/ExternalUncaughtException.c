#include <stdlib.h>

/* Ends as a C++ exception nothing catches does: thrown with the C++ tag. */
int uncaught_throw(int x)
{
  if (x > 1) {
    __builtin_wasm_throw(0, malloc(16));
  }
  return x;
}
