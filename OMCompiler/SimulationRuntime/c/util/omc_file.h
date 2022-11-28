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
#include <winsock2.h>
#else
#include <unistd.h>
#endif

#if defined(__MINGW32__) || defined(_MSC_VER)
/**
 * @brief Convert a multibyte (normal) string to a wide character string.
 * NOTE: The caller is responsible for deallocating the memory of the returned wchar string.
 *
 * @param in_mb_str  multibyte (normal) string to be converted.
 * @return wchar_t*  A wide character representation of the multibyte string. The caller is responsible for deallocating the memory.
 */
wchar_t* omc_multibyte_to_wchar_str(const char* in_mb_str);

/**
 * @brief Convert a wide character string to multibyte (normal) string.
 * NOTE: The caller is responsible for deallocating the memory of the returned multibyte string.
 *
 * @param in_wc_str  wide character string to be converted.
 * @return char*  A multibyte string representation of the wide character. The caller is responsible for deallocating the memory.
 */
char* omc_wchar_to_multibyte_str(const wchar_t* in_wc_str);

#endif // defined(__MINGW32__) || defined(_MSC_VER)


FILE* omc_fopen(const char *filename, const char *mode);

size_t omc_fread(void *buffer, size_t size, size_t count, FILE *stream, int allow_early_eof);

#if defined(__MINGW32__) || defined(_MSC_VER)
typedef struct _stat omc_stat_t;
#else
typedef struct stat omc_stat_t;
#endif
int omc_stat(const char *filename, omc_stat_t *statbuf);
int omc_lstat(const char *filename, omc_stat_t *statbuf);

/**
 * @brief checks if a file/folder exists on the system.
 * NOTE: Will return success even for directories, i.e., will not confirm that it is indeed a file.
 *
 * @param filename  the filename to check for existence.
 * @return int  returns 1 if the file/folder exists, 0 otherwise.
 */
int omc_file_exists(const char* filename);

int omc_unlink(const char *filename);
int omc_rename(const char *source, const char *dest);

#if defined(__MINGW32__) || defined(_MSC_VER)
wchar_t* longabspath(wchar_t* unicodePath);
#endif

#ifdef __cplusplus
}
#endif

#endif
