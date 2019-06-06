/*
 * This file is part of OpenModelica.
 *
 * Copyright (c) 1998-CurrentYear, Open Source Modelica Consortium (OSMC),
 * c/o Linköpings universitet, Department of Computer and Information Science,
 * SE-58183 Linköping, Sweden.
 *
 * All rights reserved.
 *
 * THIS PROGRAM IS PROVIDED UNDER THE TERMS OF GPL VERSION 3 LICENSE OR
 * THIS OSMC PUBLIC LICENSE (OSMC-PL) VERSION 1.2.
 * ANY USE, REPRODUCTION OR DISTRIBUTION OF THIS PROGRAM CONSTITUTES
 * RECIPIENT'S ACCEPTANCE OF THE OSMC PUBLIC LICENSE OR THE GPL VERSION 3,
 * ACCORDING TO RECIPIENTS CHOICE.
 *
 * The OpenModelica software and the Open Source Modelica
 * Consortium (OSMC) Public License (OSMC-PL) are obtained
 * from OSMC, either from the above address,
 * from the URLs: http://www.ida.liu.se/projects/OpenModelica or
 * http://www.openmodelica.org, and in the OpenModelica distribution.
 * GNU version 3 is obtained from: http://www.gnu.org/copyleft/gpl.html.
 *
 * This program is distributed WITHOUT ANY WARRANTY; without
 * even the implied warranty of  MERCHANTABILITY or FITNESS
 * FOR A PARTICULAR PURPOSE, EXCEPT AS EXPRESSLY SET FORTH
 * IN THE BY RECIPIENT SELECTED SUBSIDIARY LICENSE CONDITIONS OF OSMC-PL.
 *
 * See the full OSMC Public License conditions for more details.
 *
 */

#ifndef __OPENMODELICA_FILE_H
#define __OPENMODELICA_FILE_H

#ifdef __cplusplus
extern "C" {
#endif

#include <stdio.h>
#include <sys/stat.h>
#include <sys/types.h>

#if defined(__MINGW32__) || defined(_MSC_VER)
#include <windows.h>
#else
#include <unistd.h>
#endif

#if defined(__MINGW32__) || defined(_MSC_VER)
#ifndef MULTIBYTE_TO_WIDECHAR_LENGTH
#define MULTIBYTE_TO_WIDECHAR_LENGTH(string, unicodeLength) int unicodeLength = MultiByteToWideChar(CP_UTF8, 0, string, -1, NULL, 0)
#endif

#ifndef WIDECHAR_TO_MULTIBYTE_LENGTH
#define WIDECHAR_TO_MULTIBYTE_LENGTH(unicode, stringLength) int stringLength = WideCharToMultiByte(CP_UTF8, 0, unicode, -1, NULL, 0, NULL, NULL)
#endif

#if defined(_MSC_VER)

#ifndef MULTIBYTE_TO_WIDECHAR_VAR
#define MULTIBYTE_TO_WIDECHAR_VAR(string, unicodeString, unicodeLength) wchar_t *unicodeString = (wchar_t*)malloc(unicodeLength*sizeof(wchar_t)); MultiByteToWideChar(CP_UTF8, 0, string, -1, unicodeString, unicodeLength)
#endif

#ifndef WIDECHAR_TO_MULTIBYTE_VAR
#define WIDECHAR_TO_MULTIBYTE_VAR(unicode, string, stringLength) char *string = (char*)malloc(stringLength*sizeof(char)); WideCharToMultiByte(CP_UTF8, 0, unicode, -1, string, stringLength, NULL, NULL)
#endif

#ifndef MULTIBYTE_OR_WIDECHAR_VAR_FREE
#define MULTIBYTE_OR_WIDECHAR_VAR_FREE(unicodeString) if (unicodeString) { free(unicodeString); }
#endif

#else /* mingw */

#ifndef MULTIBYTE_TO_WIDECHAR_VAR
#define MULTIBYTE_TO_WIDECHAR_VAR(string, unicodeString, unicodeLength) wchar_t unicodeString[unicodeLength]; MultiByteToWideChar(CP_UTF8, 0, string, -1, unicodeString, unicodeLength)
#endif

#ifndef WIDECHAR_TO_MULTIBYTE_VAR
#define WIDECHAR_TO_MULTIBYTE_VAR(unicode, string, stringLength) char string[stringLength]; WideCharToMultiByte(CP_UTF8, 0, unicode, -1, string, stringLength, NULL, NULL)
#endif

#ifndef MULTIBYTE_OR_WIDECHAR_VAR_FREE
#define MULTIBYTE_OR_WIDECHAR_VAR_FREE(unicodeString)
#endif

#endif /* msvc */

#endif /* mingw and msvc */

FILE* omc_fopen(const char *filename, const char *mode);
#if defined(__MINGW32__) || defined(_MSC_VER)
int omc_stat(const char *filename, struct _stat *statbuf);
#else
int omc_stat(const char *filename, struct stat *statbuf);
#endif
int omc_unlink(const char *filename);

#ifdef __cplusplus
}
#endif

#endif
