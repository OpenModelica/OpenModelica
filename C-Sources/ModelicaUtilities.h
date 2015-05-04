#ifndef MODELICA_UTILITIES_H
#define MODELICA_UTILITIES_H

#include <stddef.h>
#include <stdarg.h>
#if defined(__cplusplus)
extern "C" {
#endif

/* Utility functions which can be called by external Modelica functions.

   These functions are defined in section 12.8.6 of the
   Modelica Specification 3.0 and section 12.9.6 of the
   Modelica Specification 3.1 and 3.2.

   A generic C-implementation of these functions cannot be given,
   because it is tool dependent how strings are output in a
   window of the respective simulation tool. Therefore, only
   this header file is shipped with the Modelica Standard Library.
*/

/*
 * Some of the functions never return to the caller. In order to compile
 * external Modelica C-code in most compilers, noreturn attributes need to
 * be present to avoid warnings or errors.
 *
 * The following macros handle noreturn attributes according to the latest
 * C11/C++11 standard with fallback to GNU or MSVC extensions if using an
 * older compiler.
 */
#if __STDC_VERSION__ >= 201112L
#define MODELICA_NORETURN _Noreturn
#define MODELICA_NORETURNATTR
#elif __cplusplus >= 201103L
#define MODELICA_NORETURN [[noreturn]]
#define MODELICA_NORETURNATTR
#elif defined(__GNUC__)
#define MODELICA_NORETURN
#define MODELICA_NORETURNATTR __attribute__((noreturn))
#elif defined(_MSC_VER) || defined(__BORLANDC__)
#define MODELICA_NORETURN __declspec(noreturn)
#define MODELICA_NORETURNATTR
#else
#define MODELICA_NORETURN
#define MODELICA_NORETURNATTR
#endif

void ModelicaMessage(const char *string);
/*
Output the message string (no format control).
*/


void ModelicaFormatMessage(const char *string, ...);
/*
Output the message under the same format control as the C-function printf.
*/


void ModelicaVFormatMessage(const char *string, va_list args);
/*
Output the message under the same format control as the C-function vprintf.
*/


MODELICA_NORETURN void ModelicaError(const char *string) MODELICA_NORETURNATTR;
/*
Output the error message string (no format control). This function
never returns to the calling function, but handles the error
similarly to an assert in the Modelica code.
*/


MODELICA_NORETURN void ModelicaFormatError(const char *string, ...) MODELICA_NORETURNATTR;
/*
Output the error message under the same format control as the C-function
printf. This function never returns to the calling function,
but handles the error similarly to an assert in the Modelica code.
*/


MODELICA_NORETURN void ModelicaVFormatError(const char *string, va_list args) MODELICA_NORETURNATTR;
/*
Output the error message under the same format control as the C-function
vprintf. This function never returns to the calling function,
but handles the error similarly to an assert in the Modelica code.
*/


char* ModelicaAllocateString(size_t len);
/*
Allocate memory for a Modelica string which is used as return
argument of an external Modelica function. Note, that the storage
for string arrays (= pointer to string array) is still provided by the
calling program, as for any other array. If an error occurs, this
function does not return, but calls "ModelicaError".
*/


char* ModelicaAllocateStringWithErrorReturn(size_t len);
/*
Same as ModelicaAllocateString, except that in case of error, the
function returns 0. This allows the external function to close files
and free other open resources in case of error. After cleaning up
resources use ModelicaError or ModelicaFormatError to signal
the error.
*/

#if defined(__cplusplus)
}
#endif

#endif
