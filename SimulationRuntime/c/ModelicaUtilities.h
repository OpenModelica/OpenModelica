#ifndef MODELICA_UTILITIES_H
#define MODELICA_UTILITIES_H

#include <stddef.h>
#include <stdarg.h>
#include "util/omc_msvc.h" /* for __attribute__() */
/*
 * Utility functions for external functions.
 * The functionality is defined in the Modelica 2.x and 3.x specifications.
 *
 * The noreturn attribute has been added for clarity
 */

extern void ModelicaMessage(const char* string);
extern void ModelicaFormatMessage(const char* string, ...);
extern void ModelicaError(const char* string) __attribute__ ((noreturn));
extern void ModelicaFormatError(const char* string, ...) __attribute__ ((noreturn));
extern char* ModelicaAllocateString(size_t len);
extern char* ModelicaAllocateStringWithErrorReturn(size_t len);
extern void ModelicaVFormatMessage(const char*string, va_list);
extern void ModelicaVFormatError(const char*string, va_list) __attribute__ ((noreturn));

#endif /* MODELICA_UTILITIES_H */
