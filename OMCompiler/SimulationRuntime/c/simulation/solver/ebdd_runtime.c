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

/*! \file ebdd_runtime.c
 *
 *  Runtime side of the Equation-Based Declarative Debugger (EBDD) bridge.
 *  See ebdd_runtime.h for the overall idea and the file format.
 */

#include "ebdd_runtime.h"

#include <math.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#include "../../util/omc_error.h"
#include "../simulation_info_json.h"

/* For a model without nonlinear systems NONLINEAR_SYSTEM_DATA is an opaque
 * void* (see simulation_data.h), so the logger's body cannot be compiled. Guard
 * it with the same macro the typedef uses and fall back to a no-op stub. */
#if !defined(OMC_NUM_NONLINEAR_SYSTEMS) || OMC_NUM_NONLINEAR_SYSTEMS>0

/* Single output file for the whole process. A model simulation executable runs
 * as its own process, so a static handle plus atexit() is enough and avoids
 * wiring an explicit lifecycle into the runtime. */
static FILE *ebddFile = NULL;
static int ebddOpenAttempted = 0;

static void ebddRuntimeClose(void)
{
  if (ebddFile != NULL) {
    fclose(ebddFile);
    ebddFile = NULL;
  }
}

/* Write a JSON-escaped string (without surrounding quotes) to the file. */
static void ebddWriteEscaped(FILE *f, const char *s)
{
  if (s == NULL) {
    return;
  }
  for (; *s != '\0'; ++s) {
    unsigned char c = (unsigned char) *s;
    switch (c) {
    case '\"': fputs("\\\"", f); break;
    case '\\': fputs("\\\\", f); break;
    case '\b': fputs("\\b", f); break;
    case '\f': fputs("\\f", f); break;
    case '\n': fputs("\\n", f); break;
    case '\r': fputs("\\r", f); break;
    case '\t': fputs("\\t", f); break;
    default:
      if (c < 0x20) {
        fprintf(f, "\\u%04x", c);
      } else {
        fputc(c, f);
      }
    }
  }
}

/* Write a double as a JSON number, or null for non-finite values (JSON has no
 * representation for nan/inf). */
static void ebddWriteDouble(FILE *f, double v)
{
  if (isfinite(v)) {
    fprintf(f, "%.17g", v);
  } else {
    fputs("null", f);
  }
}

/* Lazily open "<modelFilePrefix>_dbg.json" and emit the meta header line.
 * Returns the file handle or NULL on failure (failure is only reported once). */
static FILE *ebddRuntimeEnsureOpen(DATA *data)
{
  const char *prefix;
  char *fileName;
  size_t len;

  if (ebddFile != NULL) {
    return ebddFile;
  }
  if (ebddOpenAttempted) {
    return NULL;   /* already failed once, do not spam warnings */
  }
  ebddOpenAttempted = 1;

  prefix = data->modelData->modelFilePrefix;
  if (prefix == NULL) {
    prefix = "model";
  }

  len = strlen(prefix) + strlen("_dbg.json") + 1;
  fileName = (char*) malloc(len);
  if (fileName == NULL) {
    return NULL;
  }
  snprintf(fileName, len, "%s_dbg.json", prefix);

  ebddFile = fopen(fileName, "w");
  if (ebddFile == NULL) {
    warningStreamPrint(OMC_LOG_STDOUT, 0, "LOG_EBDD: could not open '%s' for writing.", fileName);
    free(fileName);
    return NULL;
  }
  free(fileName);

  atexit(ebddRuntimeClose);

  /* meta header (first JSONL line) */
  fputs("{\"format\":\"EBDD runtime info\",\"version\":1,\"model\":\"", ebddFile);
  ebddWriteEscaped(ebddFile, data->modelData->modelName);
  fputs("\"}\n", ebddFile);

  return ebddFile;
}

static const char *ebddNlsStatusString(NLS_SOLVER_STATUS status)
{
  switch (status) {
  case NLS_SOLVED:               return "solved";
  case NLS_SOLVED_LESS_ACCURACY: return "solved_less_accuracy";
  case NLS_FAILED:               return "failed";
  default:                       return "unknown";
  }
}

void ebddRuntimeLogNonlinearSystem(DATA *data, NONLINEAR_SYSTEM_DATA *nonlinsys)
{
  FILE *f;
  EQUATION_INFO eqInfo;
  long i;

  if (!OMC_ACTIVE_STREAM(OMC_LOG_EBDD)) {
    return;
  }

  f = ebddRuntimeEnsureOpen(data);
  if (f == NULL) {
    return;
  }

  eqInfo = modelInfoGetEquation(&data->modelData->modelDataXml, nonlinsys->equationIndex);

  fprintf(f, "{\"kind\":\"nonlinear\",\"eqIndex\":%ld,\"section\":\"%s\",\"time\":",
          (long) nonlinsys->equationIndex,
          eqInfo.section == EQUATION_SECTION_INITIAL ? "initial" : "regular");
  ebddWriteDouble(f, data->localData[0]->timeValue);
  fprintf(f, ",\"status\":\"%s\",\"iterations\":%lu,\"size\":%ld,\"vars\":[",
          ebddNlsStatusString(nonlinsys->solved),
          nonlinsys->numberOfIterations,
          (long) nonlinsys->size);

  for (i = 0; i < nonlinsys->size; ++i) {
    /* vars[i] (the variable defined by row i) aligns with nlsx[i]/resValues[i]
     * by construction, the same mapping printNonLinearFinishInfo() relies on. */
    if (i > 0) {
      fputc(',', f);
    }
    fputs("{\"name\":\"", f);
    if (i < eqInfo.numVar) {
      ebddWriteEscaped(f, eqInfo.vars[i]);
    }
    fputs("\",\"value\":", f);
    ebddWriteDouble(f, nonlinsys->nlsx[i]);
    fputs(",\"residual\":", f);
    ebddWriteDouble(f, nonlinsys->resValues[i]);
    fputs(",\"nominal\":", f);
    ebddWriteDouble(f, nonlinsys->nominal[i]);
    fputc('}', f);
  }

  fputs("]}\n", f);
  fflush(f);
}

#else /* OMC_NUM_NONLINEAR_SYSTEMS == 0: NONLINEAR_SYSTEM_DATA is opaque */

void ebddRuntimeLogNonlinearSystem(DATA *data, NONLINEAR_SYSTEM_DATA *nonlinsys)
{
  (void)data;
  (void)nonlinsys;
}

#endif /* OMC_NUM_NONLINEAR_SYSTEMS */
