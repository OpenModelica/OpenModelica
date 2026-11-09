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

#define ADD_METARECORD_DEFINITIONS static
#include "../OpenModelicaBootstrappingHeader.h"

#include "errorext.h"
#include "systemimpl.h"
#include "omc_result.h"

/* The result files are read and compared by libomc_result. */

static void add_message(void *data, int severity, const char *format, const char *const *tokens, size_t n)
{
  const char *reversed[16];
  size_t i;
  ErrorLevel level = severity == 0 ? ErrorLevel_error : severity == 1 ? ErrorLevel_warning : ErrorLevel_notification;
  if (n > 16) {
    n = 16;
  }
  /* c_add_message fills in the last token first */
  for (i = 0; i < n; i++) {
    reversed[i] = tokens[n-1-i];
  }
  c_add_message(NULL, -1, ErrorType_scripting, level, gettext(format), reversed, (int) n);
}

static const omc_result_messages messages = {add_message, NULL};

static const char** to_strings(void *lst, size_t *n)
{
  const char **res;
  void *it;
  size_t i = 0;
  *n = listLength(lst);
  res = (const char**) omc_alloc_interface.malloc(sizeof(char*) * (*n + 1));
  for (it = lst; !listEmpty(it); it = MMC_CDR(it)) {
    res[i++] = MMC_STRINGDATA(MMC_CAR(it));
  }
  return res;
}

static void* to_list(char **strings, size_t n)
{
  void *res = mmc_mk_nil();
  size_t i;
  for (i = n; i > 0; i--) {
    res = mmc_mk_cons(mmc_mk_scon(strings[i-1]), res);
  }
  omc_result_free_strings(strings, n);
  return res;
}

double SimulationResults_val(const char *filename, const char *varname, double timeStamp)
{
  return omc_result_script_val(&messages, filename, varname, timeStamp);
}

void* SimulationResults_readVariables(const char *filename, int readParameters, int omcStyle)
{
  size_t n = 0;
  char **vars = omc_result_script_variables(&messages, filename, readParameters, omcStyle, &n);
  return vars ? to_list(vars, n) : mmc_mk_nil();
}

/* Reversed rows of reversed columns, as SimulationResults.readDataset expects. */
void* SimulationResults_readDataset(const char *filename, void *vars, int datasize)
{
  size_t n, nrows = 0, i, j;
  const char **names = to_strings(vars, &n);
  double *vals = omc_result_script_dataset(&messages, filename, names, n, datasize, &nrows);
  void *res = mmc_mk_nil();
  if (vals == NULL) {
    MMC_THROW();
  }
  for (i = 0; i < n; i++) {
    void *col = mmc_mk_nil();
    for (j = 0; j < nrows; j++) {
      col = mmc_mk_cons(mmc_mk_rcon(vals[i*nrows+j]), col);
    }
    res = mmc_mk_cons(col, res);
  }
  omc_result_free_doubles(vals);
  return res;
}

int SimulationResults_readSimulationResultSize(const char *filename)
{
  return omc_result_script_size(&messages, filename);
}

void SimulationResults_close()
{
  omc_result_script_close();
}

void* SimulationResults_cmpSimulationResults(int runningTestsuite, const char *filename, const char *reffilename, const char *logfilename, double refTol, double absTol, void *vars)
{
  size_t n, nres = 0;
  const char **names = to_strings(vars, &n);
  char **res = omc_result_script_compare(&messages, runningTestsuite, filename, reffilename, logfilename, refTol, absTol, names, n, &nres);
  if (res == NULL) {
    MMC_THROW();
  }
  return to_list(res, nres);
}

double SimulationResults_deltaSimulationResults(const char *filename, const char *reffilename, const char *methodname, void *vars)
{
  size_t n;
  const char **names = to_strings(vars, &n);
  return omc_result_script_delta(&messages, filename, reffilename, methodname, names, n);
}

void* SimulationResults_diffSimulationResults(int runningTestsuite, const char *filename, const char *reffilename, const char *prefix, double refTol, double reltolDiffMaxMin, double rangeDelta, void *vars, int keepEqualResults, int *success)
{
  size_t n, nres = 0;
  const char **names = to_strings(vars, &n);
  char **res;
  *success = 0;
  res = omc_result_script_diff(&messages, runningTestsuite, filename, reffilename, prefix, refTol, reltolDiffMaxMin, rangeDelta, names, n, keepEqualResults, success, &nres);
  return res ? to_list(res, nres) : mmc_mk_nil();
}

const char* SimulationResults_diffSimulationResultsHtml(int runningTestsuite, const char *var, const char *filename, const char *reffilename, double refTol, double reltolDiffMaxMin, double rangeDelta)
{
  char *html = omc_result_script_diff_html(&messages, runningTestsuite, var, filename, reffilename, refTol, reltolDiffMaxMin, rangeDelta);
  const char *res;
  if (html == NULL) {
    MMC_THROW();
  }
  res = omc_alloc_interface.malloc_strdup(html);
  omc_result_free_string(html);
  return res;
}

int SimulationResults_filterSimulationResults(const char *inFile, const char *outFile, void *vars, int numberOfIntervals, int removeDescription, int readAllVars)
{
  size_t n;
  const char **names = to_strings(vars, &n);
  return omc_result_script_filter(&messages, inFile, outFile, names, n, numberOfIntervals, removeDescription);
}
