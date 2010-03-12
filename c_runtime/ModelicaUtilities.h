#ifndef MODELICA_UTILITIES_H
#define MODELICA_UTILITIES_H

#include <stddef.h>
/*
 * Utility functions for external functions.
 * The functionality is defined in the Modelica 2.x and 3.x specifications.
 */

void ModelicaMessage(const char* string);
void ModelicaFormatMessage(const char* string,...);
void ModelicaError(const char* string);
void ModelicaFormatError(const char* string, ...);
char* ModelicaAllocateString(size_t len);
char* ModelicaAllocateStringWithErrorReturn(size_t len);

#endif /* MODELICA_UTILITIES_H */
