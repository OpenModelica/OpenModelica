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
#include <simulation_runtime.h>

void indent(FILE *fout, int n) {
  while (n--) fputc(' ', fout);
}

void printVars(FILE *fout, int n, struct omc_varInfo *vars) {
  int i;
  for (i=0; i<n; i++) {
    indent(fout,4);
    fprintf(fout, "<variable name=\"%s\" comment=\"%s\" info=\"", vars[i].name, vars[i].comment);
    printInfo(fout, vars[i].info);
    fprintf(fout, "\"/>\n");
  }
}

void printFunctions(FILE *fout, int n, struct omc_functionInfo *funcs) {
  int i;
  for (i=0; i<n; i++) {
    indent(fout,4);
    fprintf(fout, "<function name=\"%s\" info=\"", funcs[i].name);
    printInfo(fout, funcs[i].info);
    fprintf(fout, "\"/>\n");
  }
}

int printModelInfo(DATA *data, const char *filename) {
  FILE *fout = fopen(filename, "w");
  if (!fout) {
    fprintf(stderr, "Failed to open %s: %s\n", filename, strerror(errno));
    return 1;
  }
  fprintf(fout, "<modelinfo name=\"%s\">\n", data->modelName);

  indent(fout,2);fprintf(fout, "<variables>\n");
  printVars(fout, data->nStates, data->statesNames);
  printVars(fout, data->nStates, data->stateDerivativesNames);
  printVars(fout, data->nAlgebraic, data->algebraicsNames);
  printVars(fout, data->nParameters, data->parametersNames);
  printVars(fout, data->intVariables.nAlgebraic, data->int_alg_names);
  printVars(fout, data->intVariables.nParameters, data->int_param_names);
  printVars(fout, data->boolVariables.nAlgebraic, data->bool_alg_names);
  printVars(fout, data->boolVariables.nParameters, data->bool_param_names);
  printVars(fout, data->stringVariables.nAlgebraic, data->string_alg_names);
  printVars(fout, data->stringVariables.nParameters, data->string_param_names);
  indent(fout,2);fprintf(fout, "</variables>\n");

  indent(fout,2);fprintf(fout, "<functions>\n");
  printFunctions(fout, data->nFunctions, data->functionNames);
  indent(fout,2);fprintf(fout, "</functions>\n");
  /*
  const struct omc_equationInfo* equationInfo;
  */

  fprintf(fout, "</modelinfo>\n");
  fclose(fout);
  return 0;
}
