#ifndef MODELICA_UTILITIES_H
#define MODELICA_UTILITIES_H

#include <stddef.h>
#include <stdarg.h>
/*
 * Utility functions for external functions.
 * The functionality is defined in the Modelica 2.x and 3.x specifications.
 */

extern void ModelicaMessage(const char* string);
extern void ModelicaFormatMessage(const char* string, ...);
extern void ModelicaError(const char* string);
extern void ModelicaFormatError(const char* string, ...);
extern char* ModelicaAllocateString(size_t len);
extern char* ModelicaAllocateStringWithErrorReturn(size_t len);
extern void ModelicaVFormatMessage(const char*string, va_list);
extern void ModelicaVFormatError(const char*string, va_list);

#endif /* MODELICA_UTILITIES_H */
