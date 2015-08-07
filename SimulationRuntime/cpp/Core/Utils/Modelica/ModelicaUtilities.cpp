/** @addtogroup coreUtils
 *
 *  @{
 */
#include <Core/ModelicaDefine.h>
#include <Core/Modelica.h>
#include <Core/Utils/Modelica/ModelicaUtilities.h>
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
  throw  ModelicaSimulationError(UTILITY,"ModelicaMessage not implemented yet");
}

void ModelicaVFormatMessage(const char*string, va_list args)
{
  vfprintf(stdout, string, args);
  fflush(stdout);
}

void ModelicaFormatMessage(const char* string,...)
{
  va_list args;
  va_start(args, string);
  ModelicaVFormatMessage(string, args);
  va_end(args);
}

void ModelicaError(const char* string)
{
  throw  ModelicaSimulationError(UTILITY,string);
}

void ModelicaVFormatError(const char*string, va_list args)
{
 throw  ModelicaSimulationError(UTILITY,"ModelicaVFormatError not implemented yet");
}

void ModelicaFormatError(const char* text, ...)
{
  std::stringstream ss;
  va_list args;
  va_start(args, text);
  ss <<  text;
  va_end(args);
  ModelicaError(ss.str().c_str());
}

static std::map<const char*, char*> _allocatedStrings;

char* ModelicaAllocateString(size_t len)
{
  char *res = new char[len];
  if (!res)
    ModelicaFormatError("%s:%d: ModelicaAllocateString failed", __FILE__, __LINE__);
  _allocatedStrings[res] = res;
  return res;
}

char* ModelicaAllocateStringWithErrorReturn(size_t len)
{
  char *res = new char[len];
  if (res)
    _allocatedStrings[res] = res;
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
