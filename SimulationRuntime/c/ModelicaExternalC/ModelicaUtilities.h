#ifndef MODELICA_UTILITIES_H
#define MODELICA_UTILITIES_H

#include <stddef.h>
/*
 * Utility functions for external functions.
 * The functionality is defined in the Modelica 2.x and 3.x specifications.
 */

extern void ModelicaMessage(const char* string);
extern void ModelicaFormatMessage(const char* string,...);
extern void ModelicaError(const char* string);
extern void ModelicaFormatError(const char* string, ...);
extern char* ModelicaAllocateString(size_t len);
extern char* ModelicaAllocateStringWithErrorReturn(size_t len);

#endif /* MODELICA_UTILITIES_H */
