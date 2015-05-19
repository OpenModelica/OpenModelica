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

char* ModelicaAllocateString(size_t len)
{
   return new char[len];
}

char* ModelicaAllocateStringWithErrorReturn(size_t len)
{
 char *res = new char[len];
  if(!res)
    ModelicaFormatError("%s:%d: ModelicaAllocateString failed", __FILE__, __LINE__);
  return res;
}
#ifdef __cplusplus
}
#endif
