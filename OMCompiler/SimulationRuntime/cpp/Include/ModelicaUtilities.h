/** @addtogroup coreUtils
 *
 *  @{
 */
/** \file ModelicaUtilities.h
 *  \brief Utility functions which can be called by external Modelica functions.
 **/

#ifndef MODELICA_UTILITIES_H
#define MODELICA_UTILITIES_H

#include <stddef.h>
#include <stdarg.h>

#ifdef __cplusplus
extern "C" {
#endif

/**
 * \brief Output the message string (no format control).
 *
 * @param string The message.
 */
BOOST_EXTENSION_EXPORT_DECL void ModelicaMessage(const char* string);

/**
 * \brief Output the message under the same format control as the C-function
 * printf.
 *
 * @param string The formatted message.
 */
BOOST_EXTENSION_EXPORT_DECL void ModelicaFormatMessage(const char* string,...);

/**
 * \brief Output the message under the same format control as the C-function
 * vprintf.
 *
 * @param string The formatted message.
 * @param arg_ptr Pointer to list of arguments.
 */
BOOST_EXTENSION_EXPORT_DECL void ModelicaVFormatMessage(const char* string, va_list arg_ptr);

/**
 * \brief Output the error message string (no format control). This function
 * never returns to the calling function, but handles the error similarly to an
 * assert in the Modelica code.
 *
 * @param string The error message.
 */
BOOST_EXTENSION_EXPORT_DECL void ModelicaError(const char* string);

/**
 * \brief Output the error message under the same format control as the
 * C-function printf. This function never returns to the calling function, but
 * handles the error similarly to an assert in the Modelica code.
 *
 * @param string The formatted error message.
 */
BOOST_EXTENSION_EXPORT_DECL void ModelicaFormatError(const char* string,...);

/**
 * \brief Output the error message under the same format control as the
 * C-function vprintf. This function never returns to the calling function, but
 * handles the error similarly to an assert in the Modelica code.
 *
 * @param string The formatted error message.
 * @param arg_ptr Pointer to list of arguments.
 */
BOOST_EXTENSION_EXPORT_DECL void ModelicaVFormatError(const char* string, va_list arg_ptr);

/**
 * \brief Allocate memory for a Modelica string which is used as return argument
 * of an external Modelica function. Note, that the storage for string arrays
 * (= pointer to string array) is still provided by the calling program, as for
 * any other array. If an error occurs, this function does not return, but calls
 * "ModelicaError".
 *
 * @param len Length of string to allocate.
 */
BOOST_EXTENSION_EXPORT_DECL  char* ModelicaAllocateString(size_t len);

/**
 * \brief Same as ModelicaAllocateString, except that in case of error, the
 * function returns 0. This allows the external function to close files and free
 * other open resources in case of error. After cleaning up resources use
 * ModelicaError or ModelicaFormatError to signal the error.
 *
 * @param len Length of string to allocate.
 */
BOOST_EXTENSION_EXPORT_DECL char* ModelicaAllocateStringWithErrorReturn(size_t len);

/**
 * \brief Free memory allocated by ModelicaAllocateString or
 * ModelicaAllocateStringWithErrorReturn.
 * This function is intended for internal use by the Cpp runtime.
 *
 * @param str C string
 */
BOOST_EXTENSION_EXPORT_DECL void _ModelicaFreeStringIfAllocated(const char *str);

#ifdef __cplusplus
}
#endif
#endif
/** @} */ // end of coreUtils
