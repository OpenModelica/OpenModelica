#ifdef __cplusplus
extern "C" {
#endif

/* Do not change this include; the name is defined in the specification */
#include <ModelicaUtilities.h>

const char* myExtFunction(const char* str, double t) {
  ModelicaMessage(str);
  ModelicaFormatMessage(" was normal - this is formatted %s\n",str);
  char* buf = ModelicaAllocateString(3);
  buf[0] = 'O';
  buf[1] = 'K';
  buf[2] = '\n';
  return buf;
}
const char* myExtFunctionError(const char* str, double t) {
  ModelicaFormatError("this is formatted error %s\n",str);
  char* buf = ModelicaAllocateString(3);
  buf[0] = 'O';
  buf[1] = 'K';
  buf[2] = '\n';
  return buf;
}

#ifdef __cplusplus
}
#endif
