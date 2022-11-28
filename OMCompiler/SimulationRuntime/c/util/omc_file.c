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

#define BUFSIZE 4096

#if defined(__MINGW32__) || defined(_MSC_VER)
wchar_t* longabspath(wchar_t* unicodePath);
#endif

#if defined(__MINGW32__) || defined(_MSC_VER)
/**
 * @brief Convert a multibyte (normal) string to a wide character string.
 * NOTE: The caller is responsible for deallocating the memory of the returned wchar string.
 *
 * @param in_mb_str  multibyte (normal) string to be converted.
 * @return wchar_t*  A wide character representation of the multibyte string. The caller is responsible for deallocating the memory.
 */
wchar_t* omc_multibyte_to_wchar_str(const char* in_mb_str) {
  int length = MultiByteToWideChar(CP_UTF8, 0, in_mb_str, -1, NULL, 0);

  wchar_t* out_wc_str = (wchar_t*) malloc(length * sizeof(wchar_t));
  MultiByteToWideChar(CP_UTF8, 0, in_mb_str, -1, out_wc_str, length);

  return out_wc_str;
}

/**
 * @brief Convert a wide character string to multibyte (normal) string.
 * NOTE: The caller is responsible for deallocating the memory of the returned multibyte string.
 *
 * @param in_wc_str  wide character string to be converted.
 * @return char*  A multibyte string representation of the wide character. The caller is responsible for deallocating the memory.
 */
char* omc_wchar_to_multibyte_str(const wchar_t* in_wc_str) {

  int length = WideCharToMultiByte(CP_UTF8, 0, in_wc_str, -1, NULL, 0, NULL, NULL);

  char* out_mb_str = (char*) malloc(length * sizeof(char));
  WideCharToMultiByte(CP_UTF8, 0, in_wc_str, -1, out_mb_str, length, NULL, NULL);

  return out_mb_str;
}

#endif // defined(__MINGW32__) || defined(_MSC_VER)


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

  wchar_t* unicodeFilename = omc_multibyte_to_wchar_str(filename);
  wchar_t* unicodeMode = omc_multibyte_to_wchar_str(mode);

  wchar_t* unicodeLongFileName = longabspath(unicodeFilename);
  FILE *f = _wfopen(unicodeLongFileName, unicodeMode);

  free(unicodeLongFileName);
  free(unicodeFilename);
  free(unicodeMode);
#else /* unix */
  FILE *f = fopen(filename, mode);
#endif
  return f;
}

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
int omc_stat(const char *filename, omc_stat_t* statbuf)
{
  wchar_t* unicodeFilename = omc_multibyte_to_wchar_str(filename);
  wchar_t* unicodeLongFileName = longabspath(unicodeFilename);

  int res;
  res = _wstat(unicodeLongFileName, statbuf);

  free(unicodeLongFileName);
  free(unicodeFilename);

  return res;
}
#else /* unix */
int omc_stat(const char *filename, omc_stat_t* statbuf)
{
  int res;
  res = stat(filename, statbuf);
  return res;
}
#endif


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
int omc_lstat(const char *filename, omc_stat_t* statbuf)
{
  return omc_stat(filename, statbuf);
}
#else /* unix */
int omc_lstat(const char *filename, omc_stat_t* statbuf)
{
  int res;
  res = lstat(filename, statbuf);
  return res;
}
#endif

/**
 * @brief checks if a file/folder exists on the system.
 * NOTE: Will return success even for directories, i.e., will not confirm that it is indeed a file.
 *
 * @param filename  the filename to check for existence.
 * @return int  returns 1 if the file/folder exists, 0 otherwise.
 */
int omc_file_exists(const char* filename) {
  omc_stat_t statbuf;
  return omc_stat(filename, &statbuf) == 0;
}


/**
 * @brief Unlink file.
 *
 * Using (long) unicode absolute path and `_wunlink` on Windows.
 * Using `unlink` on Unix.
 *
 * @param filename  File name
 * @return int      0 on success, -1 on error.
 */
int omc_unlink(const char *filename) {
  int result = 0;
#if defined(__MINGW32__) || defined(_MSC_VER)
  wchar_t* unicodeFilename = omc_multibyte_to_wchar_str(filename);
  wchar_t* unicodeLongFileName = longabspath(unicodeFilename);
  result = _wunlink(unicodeFilename);
  free(unicodeLongFileName);
  free(unicodeFilename);
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

// zero on success, anything else on failure!
int omc_rename(const char *source, const char *dest) {
#if defined(__MINGW32__) || defined(_MSC_VER)
  // If the function succeeds, the return value is nonzero.
  // If the function fails, the return value is zero (0). To get extended error information, call GetLastError.
  return !MoveFileEx(source, dest, MOVEFILE_REPLACE_EXISTING);
#endif
  // On success, zero is returned.  On error, -1 is returned, and
  // errno is set to indicate the error.
  return rename(source,dest);
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
