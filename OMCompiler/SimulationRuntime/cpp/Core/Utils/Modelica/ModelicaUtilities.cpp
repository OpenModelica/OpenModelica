/** @addtogroup coreUtils
 *
 *  @{
 */
#include <Core/ModelicaDefine.h>
#include <Core/Modelica.h>
#include <ModelicaUtilities.h>
#include <stdexcept>
#include <exception>
#include <string>
#include <stdio.h>
#include <stdarg.h>
#include <sstream>
#ifdef __cplusplus
extern "C" {
#endif

void ModelicaMessage(const char* string)
{
  fprintf(stdout, string);
  fflush(stdout);
}

void ModelicaVFormatMessage(const char* string, va_list args)
{
  vfprintf(stdout, string, args);
  fflush(stdout);
}

void ModelicaFormatMessage(const char* string, ...)
{
  va_list args;
  va_start(args, string);
  ModelicaVFormatMessage(string, args);
  va_end(args);
}

void ModelicaError(const char* string)
{
  throw  ModelicaSimulationError(UTILITY, string);
}

void ModelicaVFormatError(const char* string, va_list args)
{
  char buffer[256];
  vsnprintf(buffer, 256, string, args);
  ModelicaError(buffer);
}

void ModelicaFormatError(const char* string, ...)
{
  va_list args;
  va_start(args, string);
  ModelicaVFormatError(string, args);
  va_end(args);
}

static std::map<const char*, char*> _allocatedStrings;

char* ModelicaAllocateString(size_t len)
{
  char *res = new char[len + 1];
  if (!res)
    ModelicaFormatError("%s:%d: ModelicaAllocateString failed", __FILE__, __LINE__);
  _allocatedStrings[res] = res;
  res[len] = '\0';
  return res;
}

char* ModelicaAllocateStringWithErrorReturn(size_t len)
{
  char *res = new char[len + 1];
  if (res) {
    _allocatedStrings[res] = res;
    res[len] = '\0';
  }
  return res;
}

void _ModelicaFreeStringIfAllocated(const char *str)
{
  std::map<const char*, char*>::iterator it;
  it = _allocatedStrings.find(str);
  if (it != _allocatedStrings.end()) {
    delete [] _allocatedStrings[str];
    _allocatedStrings.erase(it);
  }
}

#ifdef __cplusplus
}
#endif
/** @} */ // end of coreUtils
