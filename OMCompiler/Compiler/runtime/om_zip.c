/*
 * This file is part of OpenModelica.
 *
 * Copyright (c) 1998-2026, Open Source Modelica Consortium (OSMC),
 * c/o Linköpings universitet, Department of Computer and Information Science,
 * SE-58183 Linköping, Sweden.
 *
 * All rights reserved.
 *
 * THIS PROGRAM IS PROVIDED UNDER THE TERMS OF AGPL VERSION 3 LICENSE OR
 * THIS OSMC PUBLIC LICENSE (OSMC-PL) VERSION 1.8.
 * ANY USE, REPRODUCTION OR DISTRIBUTION OF THIS PROGRAM CONSTITUTES
 * RECIPIENT'S ACCEPTANCE OF THE OSMC PUBLIC LICENSE OR THE GNU AGPL
 * VERSION 3, ACCORDING TO RECIPIENTS CHOICE.
 *
 * The OpenModelica software and the OSMC (Open Source Modelica Consortium)
 * Public License (OSMC-PL) are obtained from OSMC, either from the above
 * address, from the URLs:
 * http://www.openmodelica.org or
 * https://github.com/OpenModelica/ or
 * http://www.ida.liu.se/projects/OpenModelica,
 * and in the OpenModelica distribution.
 *
 * GNU AGPL version 3 is obtained from:
 * https://www.gnu.org/licenses/licenses.html#GPL
 *
 * This program is distributed WITHOUT ANY WARRANTY; without
 * even the implied warranty of MERCHANTABILITY or FITNESS
 * FOR A PARTICULAR PURPOSE, EXCEPT AS EXPRESSLY SET FORTH
 * IN THE BY RECIPIENT SELECTED SUBSIDIARY LICENSE CONDITIONS OF OSMC-PL.
 *
 * See the full OSMC Public License conditions for more details.
 *
 */

#include <stdlib.h>
#include "meta/meta_modelica.h"
#include "omcruntime_rust.h"
#include "util/omc_str_utils.h"
#include "errorext.h"

static int report(char *error)
{
  if (error == NULL) {
    return 1;
  }
  c_add_message(NULL, -1, ErrorType_runtime, ErrorLevel_error, "%s", (const char **) &error, 1);
  omcrs_free_string(error);
  return 0;
}

int om_unzip(const char *zipFileName, const char *pathToExtract, const char *destPath)
{
  return report(omcrs_unzip_path(zipFileName, pathToExtract, destPath));
}

int om_unzip_all(const char *zipFileName, const char *destPath)
{
  return report(omcrs_unzip_all(zipFileName, destPath));
}

int om_zip(const char *zipFileName, const char *path, const char *entryName)
{
  return report(omcrs_zip_paths(zipFileName, &path, &entryName, 1, NULL, 0));
}

int om_zip_paths(const char *zipFileName, const char *directory, modelica_metatype names)
{
  size_t n = listLength(names), i;
  const char **paths = (const char **) malloc(n * sizeof(char *));
  const char **entryNames = (const char **) malloc(n * sizeof(char *));
  int ok;
  for (i = 0; i < n; i++, names = MMC_CDR(names)) {
    entryNames[i] = MMC_STRINGDATA(MMC_CAR(names));
    GC_asprintf(&paths[i], "%s/%s", directory, entryNames[i]);
  }
  ok = report(omcrs_zip_paths(zipFileName, paths, entryNames, n, NULL, 0));
  free(paths);
  free(entryNames);
  return ok;
}
