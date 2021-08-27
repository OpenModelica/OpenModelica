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

FILE* omc_fopen(const char *filename, const char *mode)
{
#if defined(__MINGW32__) || defined(_MSC_VER)
  MULTIBYTE_TO_WIDECHAR_LENGTH(filename, unicodeFilenameLength);
  MULTIBYTE_TO_WIDECHAR_VAR(filename, unicodeFilename, unicodeFilenameLength);

  MULTIBYTE_TO_WIDECHAR_LENGTH(mode, unicodeModeLength);
  MULTIBYTE_TO_WIDECHAR_VAR(mode, unicodeMode, unicodeModeLength);

  FILE *f = _wfopen(unicodeFilename, unicodeMode);

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
size_t omc_fread(void *buffer, size_t size, size_t count, FILE *stream, int allow_early_eof) {
  size_t read_len = fread(buffer, size, count, stream);
  if(read_len != count)  {
    if (feof(stream) && !allow_early_eof) {
      printf("Error reading stream: unexpected end of file\n");
      printf("Expected to read %ld. Read only %ld\n", count, read_len);
      throwStreamPrint(NULL, "Error: omc_fread() failed to read file\n");
    }
    else if (ferror(stream)) {
      perror("Error reading file.");
      throwStreamPrint(NULL, "Error: omc_fread() failed to read file\n");
    }
  }

  return read_len;
}



#if defined(__MINGW32__) || defined(_MSC_VER)
int omc_stat(const char *filename, struct _stat *statbuf)
{
  MULTIBYTE_TO_WIDECHAR_LENGTH(filename, unicodeFilenameLength);
  MULTIBYTE_TO_WIDECHAR_VAR(filename, unicodeFilename, unicodeFilenameLength);

  int res;
  res = _wstat(unicodeFilename, statbuf);

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

int omc_unlink(const char *filename)
{
  int result = 0;
#if defined(__MINGW32__) || defined(_MSC_VER)
  MULTIBYTE_TO_WIDECHAR_LENGTH(filename, unicodeFilenameLength);
  MULTIBYTE_TO_WIDECHAR_VAR(filename, unicodeFilename, unicodeFilenameLength);
  result = _wunlink(unicodeFilename);
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

#ifdef __cplusplus
}
#endif
