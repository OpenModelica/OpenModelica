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
#include "errorext.h"
#include "omcruntime_rust.h"

static void report(const char *message)
{
  c_add_message(NULL, -1, ErrorType_runtime, ErrorLevel_error, "%s", &message, 1);
}

int om_curl_multi_download(void *urlPathList, int maxParallel)
{
  size_t n = listLength(urlPathList), nUrls = 0, i = 0, j = 0;
  void *l, *u;
  const char **urls, **files;
  size_t *counts;
  int result;
  for (l = urlPathList; !listEmpty(l); l = MMC_CDR(l)) {
    nUrls += listLength(MMC_CAR(MMC_CAR(l)));
  }
  urls = (const char **) malloc((nUrls + 1) * sizeof(char *));
  files = (const char **) malloc((n + 1) * sizeof(char *));
  counts = (size_t *) malloc((n + 1) * sizeof(size_t));
  for (l = urlPathList; !listEmpty(l); l = MMC_CDR(l), i++) {
    counts[i] = 0;
    for (u = MMC_CAR(MMC_CAR(l)); !listEmpty(u); u = MMC_CDR(u)) {
      urls[j++] = MMC_STRINGDATA(MMC_CAR(u));
      counts[i]++;
    }
    files[i] = MMC_STRINGDATA(MMC_CDR(MMC_CAR(l)));
  }
  result = omcrs_download(urls, counts, files, n, maxParallel > 0 ? maxParallel : 1, report);
  free(urls);
  free(files);
  free(counts);
  return result;
}
