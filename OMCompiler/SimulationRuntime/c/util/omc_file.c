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

#ifdef __cplusplus
extern "C" {
#endif

#include "omc_file.h"
#include "omc_error.h"

#if defined(__MINGW32__) || defined(_MSC_VER)
wchar_t* longabspath(wchar_t* unicodePath);
#endif

#define BUFSIZE 4096

/**
 * @brief Open a file in given mode.
 *
 * Using (long) unicode absolute path and `_wfopen` on Windows.
 * Using `fopen` on Unix.
 *
 * @param filename  File name.
 * @param mode      Kind of access to file.
 * @return FILE*    Pointer to opened file.
 */
FILE* omc_fopen(const char *filename, const char *mode)
{
#if defined(__MINGW32__) || defined(_MSC_VER)
  MULTIBYTE_TO_WIDECHAR_LENGTH(filename, unicodeFilenameLength);
  MULTIBYTE_TO_WIDECHAR_VAR(filename, unicodeFilename, unicodeFilenameLength);

  wchar_t* unicodeLongFileName = longabspath(unicodeFilename);

  MULTIBYTE_TO_WIDECHAR_LENGTH(mode, unicodeModeLength);
  MULTIBYTE_TO_WIDECHAR_VAR(mode, unicodeMode, unicodeModeLength);

  FILE *f = _wfopen(unicodeLongFileName, unicodeMode);

  free(unicodeLongFileName);
  MULTIBYTE_OR_WIDECHAR_VAR_FREE(unicodeFilename);
  MULTIBYTE_OR_WIDECHAR_VAR_FREE(unicodeMode);
#else /* unix */
  FILE *f = fopen(filename, mode);
#endif
  return f;
}

/// The last argument allow_early_eof specifies wheather the call is okay or not with reaching
/// EOF before reading the specified amount. Set it to 1 if you do not exactly know how much to read
/// and would not mind if the file ends before 'count' elements are read from it.
/// If you are not sure what to do start by passing 0.

/**
 * @brief Read data from stream.
 *
 * @param buffer            Pointer to block of memory with a minimum size of `size`.
 * @param size              Size in bytes of each element to read.
 * @param count             Number of elements to read, each with size `size` bytes.
 * @param stream            Pointer to FILE object with input stream.
 * @param allow_early_eof   Specifies wheather the call is okay or not with reaching
 *                          EOF before reading the specified amount. Set it to 1 if you do not exactly know how much to read
 *                          and would not mind if the file ends before 'count' elements are read from it.
 *                          If you are not sure what to do start by passing 0.
 * @return size_t           Total number of elements read.
 */
size_t omc_fread(void *buffer, size_t size, size_t count, FILE *stream, int allow_early_eof) {
  size_t read_len = fread(buffer, size, count, stream);
  if(read_len != count)  {
    if (feof(stream) && !allow_early_eof) {
      fprintf(stderr, "Error reading stream: unexpected end of file.\n");
      fprintf(stderr, "Expected to read %ld. Read only %ld\n", count, read_len);
    }
    else if (ferror(stream)) {
      fprintf(stderr, "Error: omc_fread() failed to read file.\n");
    }
  }

  return read_len;
}



#if defined(__MINGW32__) || defined(_MSC_VER)
/**
 * @brief File attributes
 *
 * Using (long) unicode absolute path and `_wstat` on Windows.
 * Using `stat` on Unix.
 *
 * @param filename  File name.
 * @param statbuf   Pointer to stat structure.
 * @return int      0 on success, -1 on error.
 */
int omc_stat(const char *filename, struct _stat *statbuf)
{
  MULTIBYTE_TO_WIDECHAR_LENGTH(filename, unicodeFilenameLength);
  MULTIBYTE_TO_WIDECHAR_VAR(filename, unicodeFilename, unicodeFilenameLength);
  wchar_t* unicodeLongFileName = longabspath(unicodeFilename);

  int res;
  res = _wstat(unicodeLongFileName, statbuf);

  free(unicodeLongFileName);
  MULTIBYTE_OR_WIDECHAR_VAR_FREE(unicodeFilename);

  return res;
}
#else /* unix */
int omc_stat(const char *filename, struct stat *statbuf)
{
  int res;
  res = stat(filename, statbuf);
  return res;
}
#endif

/**
 * @brief Unlink file.
 *
 * Using (long) unicode absolute path and `_wunlink` on Windows.
 * Using `unlink` on Unix.
 *
 * @param filename  File name
 * @return int      0 on success, -1 on error.
 */
int omc_unlink(const char *filename)
{
  int result = 0;
#if defined(__MINGW32__) || defined(_MSC_VER)
  MULTIBYTE_TO_WIDECHAR_LENGTH(filename, unicodeFilenameLength);
  MULTIBYTE_TO_WIDECHAR_VAR(filename, unicodeFilename, unicodeFilenameLength);
  wchar_t* unicodeLongFileName = longabspath(unicodeFilename);
  result = _wunlink(unicodeFilename);
  free(unicodeLongFileName);
  MULTIBYTE_OR_WIDECHAR_VAR_FREE(unicodeFilename);
#else /* unix */
  result = unlink(filename);
#endif
  /* uncomment for debugging
  if (result == -1)
  {
    const char* s = "Could not delete file: ";
    char *msg = (char*)malloc(strlen(s) + strlen(filename) + 1);
    sprintf(msg, "%s%s", s, filename);
    perror(msg);
  }
  */
  return result;
}

#if defined(__MINGW32__) || defined(_MSC_VER)
/**
 * @brief Return long absolute path from given path.
 *
 * Windows only.
 * Adding "\\?\" prefix if absolute path exceeds length of MAX_PATH and issue a warning.
 *
 * @param unicodePath  Path
 * @return wchar_t*    (Long) absolute path
 */
wchar_t* longabspath(wchar_t* unicodePath) {

  DWORD retval;
  wchar_t unicodeAbsPath[BUFSIZE];
  wchar_t unicodeLongAbsPath[BUFSIZE];
  wchar_t* path;

  retval = GetFullPathNameW(unicodePath, BUFSIZE, unicodeAbsPath, NULL);
  if (retval == 0)
  {
    printf("GetFullPathName failed for %ls with error code %d\n", unicodePath, GetLastError());
    return NULL;
  }
  if (wcslen(unicodeAbsPath) >= MAX_PATH) {
    printf("Warning: Maximum path length limitation reached while opening\n"
           "\t%ls\n"
           "Consider changing the working directory, "
           "using shorter names or to enable longer paths in Windows.\n"
           "See https://docs.microsoft.com/en-us/windows/win32/fileio/maximum-file-path-limitation for more information.\n", unicodeAbsPath);

    const wchar_t longPathPrefix[] = L"\\\\\?\\";
    size_t longPathPrefix_size =  wcslen(longPathPrefix);
    wcsncpy(unicodeLongAbsPath, longPathPrefix, longPathPrefix_size);
    wcsncpy(unicodeLongAbsPath+longPathPrefix_size, unicodeAbsPath, BUFSIZE - longPathPrefix_size -1);
    path = _wcsdup(unicodeLongAbsPath);
  }
  else {
    path = _wcsdup(unicodeAbsPath);
  }

  return path;
}
#endif

#ifdef __cplusplus
}
#endif
