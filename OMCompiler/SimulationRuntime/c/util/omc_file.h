/*
 * This file belongs to the OpenModelica Run-Time System
 *
 * Copyright (c) 1998-2026, Open Source Modelica Consortium (OSMC), c/o Linköpings
 * universitet, Department of Computer and Information Science, SE-58183 Linköping, Sweden. All rights
 * reserved.
 *
 * THIS PROGRAM IS PROVIDED UNDER THE TERMS OF THE BSD NEW LICENSE OR THE
 * AGPL VERSION 3 LICENSE OR THE OSMC PUBLIC LICENSE (OSMC-PL) VERSION 1.8. ANY
 * USE, REPRODUCTION OR DISTRIBUTION OF THIS PROGRAM CONSTITUTES RECIPIENT'S
 * ACCEPTANCE OF THE BSD NEW LICENSE OR THE OSMC PUBLIC LICENSE OR THE AGPL
 * VERSION 3, ACCORDING TO RECIPIENTS CHOICE.
 *
 * The OpenModelica software and the OSMC (Open Source Modelica Consortium) Public License
 * (OSMC-PL) are obtained from OSMC, either from the above address, from the URLs:
 * http://www.openmodelica.org or https://github.com/OpenModelica/ or
 * http://www.ida.liu.se/projects/OpenModelica, and in the OpenModelica distribution. GNU
 * AGPL version 3 is obtained from: https://www.gnu.org/licenses/licenses.html#GPL. The BSD NEW
 * License is obtained from: http://www.opensource.org/licenses/BSD-3-Clause.
 *
 * This program is distributed WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE, EXCEPT AS EXPRESSLY
 * SET FORTH IN THE BY RECIPIENT SELECTED SUBSIDIARY LICENSE CONDITIONS OF
 * OSMC-PL.
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
int omc_fclose(FILE * stream);
size_t omc_fread(void *buffer, size_t size, size_t count, FILE *stream, int allow_early_eof);
size_t omc_fwrite(void * buffer, size_t size, size_t count, FILE * stream);

#if defined(__MINGW32__) || defined(_MSC_VER)
typedef struct _stat omc_stat_t;
#define omc_fseek _fseeki64
#else
typedef struct stat omc_stat_t;
#define omc_fseek fseek
#endif // defined(__MINGW32__) || defined(_MSC_VER)

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
#endif // defined(__MINGW32__) || defined(_MSC_VER)

#ifdef __cplusplus
}
#endif

#endif
