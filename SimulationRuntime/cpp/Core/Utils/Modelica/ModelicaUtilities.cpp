



#include "Utils\Modelica\ModelicaUtilities.h"
#include <stdexcept>     
#include <exception>
#include <string>

#ifdef __cplusplus
extern "C" {
#endif

void ModelicaMessage(const char* string) 
{
  throw std::invalid_argument("ModelicaMessage not implemented yet");
}

void ModelicaVFormatMessage(const char*string, va_list args) 
{
  throw std::invalid_argument("ModelicaVFormatMessage not implemented yet");
}

void ModelicaFormatMessage(const char* string,...)
{
 throw std::invalid_argument("ModelicaFormatMessage not implemented yet");
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

