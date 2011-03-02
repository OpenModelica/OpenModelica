/*
 * This file is part of OpenModelica.
 *
 * Copyright (c) 1998-2010, Link�pings University,
 * Department of Computer and Information Science,
 * SE-58183 Link�ping, Sweden.
 *
 * All rights reserved.
 *
 * THIS PROGRAM IS PROVIDED UNDER THE TERMS OF THIS OSMC PUBLIC
 * LICENSE (OSMC-PL). ANY USE, REPRODUCTION OR DISTRIBUTION OF
 * THIS PROGRAM CONSTITUTES RECIPIENT'S ACCEPTANCE OF THE OSMC
 * PUBLIC LICENSE.
 *
 * The OpenModelica software and the Open Source Modelica
 * Consortium (OSMC) Public License (OSMC-PL) are obtained
 * from Link�pings University, either from the above address,
 * from the URL: http://www.ida.liu.se/projects/OpenModelica
 * and in the OpenModelica distribution.
 *
 * This program is distributed  WITHOUT ANY WARRANTY; without
 * even the implied warranty of  MERCHANTABILITY or FITNESS
 * FOR A PARTICULAR PURPOSE, EXCEPT AS EXPRESSLY SET FORTH
 * IN THE BY RECIPIENT SELECTED SUBSIDIARY LICENSE CONDITIONS
 * OF OSMC-PL.
 *
 * See the full OSMC Public License conditions for more details.
 *
 */

#include <errno.h>
#include <stdio.h>
#include <string.h>
#include <time.h>
#include "assert.h"
#include <simulation_runtime.h>

static void indent(FILE *fout, int n) {
  while (n--) fputc(' ', fout);
}

static void printPlotCommand(FILE *plt, const char *prefix, int i, int id) {
  if (!plt) return;
  fputs("set terminal png size 32,32\n", plt);
  fprintf(plt, "set output \"%s_prof.%d.thumb.png\"\n", prefix, id);
  fprintf(plt, "plot \"%s_prof.csv\" using 2:%d w l lw 1\n", prefix, 2*i+5);
  fputs("set terminal svg\n", plt);
  fprintf(plt, "set output \"%s_prof.%d.svg\"\n", prefix, id);
  fprintf(plt, "plot \"%s_prof.csv\" using 2:%d\n", prefix, 2*i+5);
}

static void printInfoTag(FILE *fout, int level, const omc_fileInfo info) {
  indent(fout,level);
  fprintf(fout, "<info filename=\"%s\" startline=\"%d\" startcol=\"%d\" endline=\"%d\" endcol=\"%d\" readonly=\"%s\" />\n", info.filename, info.lineStart, info.colStart, info.lineEnd, info.colEnd, info.readonly ? "readonly" : "writable");
}

static void printVars(FILE *fout, int level, int n, const struct omc_varInfo *vars) {
  int i;
  for (i=0; i<n; i++) {
    indent(fout,level);
    fprintf(fout, "<variable id=\"%d\" name=\"%s\" comment=\"%s\">\n", vars[i].id, vars[i].name, vars[i].comment);
    printInfoTag(fout, level+2, vars[i].info);
    indent(fout,level);
    fprintf(fout, "</variable>\n");
  }
}

static void printFunctions(FILE *fout, FILE *plt, const char *modelFilePrefix, int n, const struct omc_functionInfo *funcs) {
  int i;
  for (i=0; i<n; i++) {
    printPlotCommand(plt, modelFilePrefix, i, funcs[i].id);
    rt_clear(i + SIM_TIMER_FIRST_FUNCTION);
    indent(fout,2);
    fprintf(fout, "<function id=\"%d\">\n", funcs[i].id);
    indent(fout,4);fprintf(fout, "<name>%s</name>\n", funcs[i].name);
    indent(fout,4);fprintf(fout, "<ncall>%d</ncall>\n", (int) rt_ncall_total(i + SIM_TIMER_FIRST_FUNCTION));
    indent(fout,4);fprintf(fout, "<time>%.9f</time>\n",rt_total(i + SIM_TIMER_FIRST_FUNCTION));
    indent(fout,4);fprintf(fout, "<maxTime>%.9f</maxTime>\n",rt_max_accumulated(i + SIM_TIMER_FIRST_FUNCTION));
    printInfoTag(fout, 6, funcs[i].info);
    indent(fout,2);
    fprintf(fout, "</function>\n");
  }
}

static void printProfileBlocks(FILE *fout, FILE *plt, DATA *data) {
  int i;
  for (i = data->nFunctions; i < data->nFunctions + data->nProfileBlocks; i++) {
    const struct omc_equationInfo *eq = &data->equationInfo[data->equationInfo_reverse_prof_index[i-data->nFunctions]];
    printPlotCommand(plt, data->modelFilePrefix, i, eq->id);
    rt_clear(i + SIM_TIMER_FIRST_FUNCTION);
    indent(fout,2);fprintf(fout, "<profileblock>\n");
    indent(fout,4);fprintf(fout, "<ref refid=\"%d\"/>\n", (int) eq->id);
    indent(fout,4);fprintf(fout, "<ncall>%d</ncall>\n", (int) rt_ncall_total(i + SIM_TIMER_FIRST_FUNCTION));
    indent(fout,4);fprintf(fout, "<time>%.9f</time>\n", rt_total(i + SIM_TIMER_FIRST_FUNCTION));
    indent(fout,4);fprintf(fout, "<maxTime>%.9f</maxTime>\n",rt_max_accumulated(i + SIM_TIMER_FIRST_FUNCTION));
    indent(fout,2);fprintf(fout, "</profileblock>\n");
  }
}

static void printEquations(FILE *fout, int n, const struct omc_equationInfo *eqns) {
  int i,j;
  for (i=0; i<n; i++) {
    indent(fout,2);fprintf(fout, "<equation id=\"%d\" name=\"%s\">\n", eqns[i].id, eqns[i].name);
    indent(fout,4);fprintf(fout, "<refs>\n");
    for (j=0; j<eqns[i].numVar; j++) {
      indent(fout,6);fprintf(fout, "<ref refid=\"%d\" />\n", eqns[i].vars[j].id);
    }
    indent(fout,4);fprintf(fout, "</refs>\n");
    indent(fout,2);fprintf(fout, "</equation>\n");
  }
}

int printModelInfo(DATA *data, const char *filename, const char *plotfile) {
  static char buf[256];
  FILE *fout = fopen(filename, "w");
  FILE *plotCommands;
  time_t t;
#if defined(__MINGW32__) || defined(_MSC_VER)
  plotCommands = fopen(plotfile, "w");
#else
  plotCommands = popen("gnuplot", "w");
#endif
  if (!plotCommands) {
    fprintf(stderr, "Warning: Plots of profiling data were disabled: %s\n", strerror(errno));
  }
  if (!fout) {
    fprintf(stderr, "Failed to open %s: %s\n", filename, strerror(errno));
    return 1;
  }
  if (plotCommands) {
    fputs("set terminal svg\n", plotCommands);
    fputs("set datafile separator \",\"\n", plotCommands);
    fputs("set nokey\n", plotCommands);
    /* The column containing the time spent to calculate each step */
    printPlotCommand(plotCommands, data->modelFilePrefix, -1, 999);
  }
  /* The doctype is needed for id() lookup to work properly */
  fprintf(fout, "<!DOCTYPE doc [\
  <!ELEMENT simulation (modelinfo, variables, functions, equations)>\
  <!ATTLIST variable id ID #REQUIRED>\
  <!ELEMENT equation (refs)>\
  <!ATTLIST equation id ID #REQUIRED>\
  <!ELEMENT profileblocks (profileblock*)>\
  <!ELEMENT profileblock (refs, ncall, time, maxTime)>\
  <!ELEMENT refs (ref*)>\
  <!ATTLIST ref refid IDREF #REQUIRED>\
  ]>\n");
  if (time(&t) < 0) {
    fprintf(stderr, "time() failed: %s", strerror(errno));
    fclose(fout);
    return 1;
  }
  if (!strftime(buf, 250, "%Y-%m-%d %H:%M:%S", localtime(&t))) {
    fprintf(stderr, "strftime() failed");
    fclose(fout);
    return 1;
  }

  fprintf(fout, "<simulation>\n");
  fprintf(fout, "<modelinfo>\n");
  indent(fout, 2); fprintf(fout, "<name>%s</name>\n", data->modelName);
  indent(fout, 2); fprintf(fout, "<prefix>%s</prefix>\n", data->modelFilePrefix);
  indent(fout, 2); fprintf(fout, "<date>%s</date>\n", buf);
  indent(fout, 2); fprintf(fout, "<overheadTime>%f</overheadTime>\n", rt_accumulated(SIM_TIMER_OVERHEAD));
  indent(fout, 2); fprintf(fout, "<preinitTime>%f</preinitTime>\n", rt_accumulated(SIM_TIMER_PREINIT));
  indent(fout, 2); fprintf(fout, "<initTime>%f</initTime>\n", rt_accumulated(SIM_TIMER_INIT));
  indent(fout, 2); fprintf(fout, "<eventTime>%f</eventTime>\n", rt_accumulated(SIM_TIMER_EVENT));
  indent(fout, 2); fprintf(fout, "<outputTime>%f</outputTime>\n", rt_accumulated(SIM_TIMER_OUTPUT));
  indent(fout, 2); fprintf(fout, "<linearizeTime>%f</linearizeTime>\n", rt_accumulated(SIM_TIMER_LINEARIZE));
  indent(fout, 2); fprintf(fout, "<totalTime>%f</totalTime>\n", rt_accumulated(SIM_TIMER_TOTAL));
  indent(fout, 2); fprintf(fout, "<totalStepsTime>%f</totalStepsTime>\n", rt_total(SIM_TIMER_STEP));
  indent(fout, 2); fprintf(fout, "<numStep>%d</numStep>\n", rt_ncall_total(SIM_TIMER_STEP));
  indent(fout, 2); fprintf(fout, "<maxTime>%.9f</maxTime>\n", rt_max_accumulated(SIM_TIMER_STEP));
  fprintf(fout, "</modelinfo>\n");

  fprintf(fout, "<variables>\n");
  printVars(fout, 2, data->nStates, data->statesNames);
  printVars(fout, 2, data->nStates, data->stateDerivativesNames);
  printVars(fout, 2, data->nAlgebraic, data->algebraicsNames);
  printVars(fout, 2, data->nParameters, data->parametersNames);
  printVars(fout, 2, data->intVariables.nAlgebraic, data->int_alg_names);
  printVars(fout, 2, data->intVariables.nParameters, data->int_param_names);
  printVars(fout, 2, data->boolVariables.nAlgebraic, data->bool_alg_names);
  printVars(fout, 2, data->boolVariables.nParameters, data->bool_param_names);
  printVars(fout, 2, data->stringVariables.nAlgebraic, data->string_alg_names);
  printVars(fout, 2, data->stringVariables.nParameters, data->string_param_names);
  fprintf(fout, "</variables>\n");

  fprintf(fout, "<functions>\n");
  printFunctions(fout, plotCommands, data->modelFilePrefix, data->nFunctions, data->functionNames);
  fprintf(fout, "</functions>\n");

  fprintf(fout, "<equations>\n");
  printEquations(fout, data->nEquations, data->equationInfo);
  fprintf(fout, "</equations>\n");

  fprintf(fout, "<profileblocks>\n");
  printProfileBlocks(fout, plotCommands, data);
  fprintf(fout, "</profileblocks>\n");

  fprintf(fout, "</simulation>\n");

  fclose(fout);
  if (plotCommands) {
    char *omhome;
    char *buf;
    omhome = getenv("OPENMODELICAHOME");
    buf = malloc(200 + 2*strlen(plotfile) + (omhome ? strlen(omhome) : 0));
#if defined(__MINGW32__) || defined(_MSC_VER)
    assert(buf);
    sprintf(buf, "gnuplot %s", plotfile);
    fclose(plotCommands);
    if (0 != system(buf)) {
      fprintf(stderr, "Warning: Plot command failed: \n", buf);
    }
#else
    if (0 != pclose(plotCommands)) {
      fprintf(stderr, "Warning: Plot command failed\n");
    }
#endif
    if (omhome) {
      sprintf(buf, "xsltproc -o %s_prof.html %s/share/omc/scripts/default_profiling.xsl %s_prof.xml", data->modelFilePrefix, omhome, data->modelFilePrefix);
      if (0 != system(buf)) {
        fprintf(stdout, "Time measurements stored in %s_prof.xml (for XSL transforms) and %s_prof.csv (the raw data)\n", data->modelFilePrefix, data->modelFilePrefix);
      } else {
        fprintf(stdout, "Time measurements stored in %s_prof.html (human-readable), %s_prof.xml (for XSL transforms) and %s_prof.csv (the raw data)\n", data->modelFilePrefix, data->modelFilePrefix, data->modelFilePrefix);
      }
    } else {
      fprintf(stdout, "Time measurements stored in %s_prof.xml (for XSL transforms) and %s_prof.csv (the raw data)\n", data->modelFilePrefix, data->modelFilePrefix);
    }
    free(buf);
  }
  return 0;
}
