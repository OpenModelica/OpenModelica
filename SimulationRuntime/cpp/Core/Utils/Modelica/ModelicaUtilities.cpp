#include <Core/Utils/Modelica/ModelicaUtilities.h>
#include <stdexcept>
#include <exception>
#include <string>
#include <stdio.h>
#include <stdarg.h>
#ifdef __cplusplus
extern "C" {
#endif

void ModelicaMessage(const char* string)
{
  throw std::invalid_argument("ModelicaMessage not implemented yet");
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
  throw std::runtime_error(string);
}

void ModelicaVFormatError(const char*string, va_list args)
{
 throw std::invalid_argument("ModelicaVFormatError not implemented yet");
}

void ModelicaFormatError(const char* string, ...)
{
  throw std::invalid_argument("ModelicaFormatError not implemented yet");
}

char* ModelicaAllocateString(size_t len)
{
 throw std::invalid_argument("ModelicaAllocateString not implemented yet");
}

char* ModelicaAllocateStringWithErrorReturn(size_t len)
{
 throw std::invalid_argument("ModelicaAllocateStringWithErrorReturn ot implemented yet");
}
#ifdef __cplusplus
}
#endif
