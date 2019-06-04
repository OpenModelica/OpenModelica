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
#if defined(__MINGW32__) || defined(_MSC_VER)
  MULTIBYTE_TO_WIDECHAR_LENGTH(filename, unicodeFilenameLength);
  MULTIBYTE_TO_WIDECHAR_VAR(filename, unicodeFilename, unicodeFilenameLength);
  int result = _wunlink(unicodeFilename);
  MULTIBYTE_OR_WIDECHAR_VAR_FREE(unicodeFilename);
  return result;
#else /* unix */
  return unlink(filename);
#endif
}

#ifdef __cplusplus
}
#endif
