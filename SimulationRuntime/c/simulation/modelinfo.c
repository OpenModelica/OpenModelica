/*
 * This file is part of OpenModelica.
 *
 * Copyright (c) 1998-2014, Open Source Modelica Consortium (OSMC),
 * c/o Linköpings universitet, Department of Computer and Information Science,
 * SE-58183 Linköping, Sweden.
 *
 * All rights reserved.
 *
 * THIS PROGRAM IS PROVIDED UNDER THE TERMS OF THE BSD NEW LICENSE OR THE
 * GPL VERSION 3 LICENSE OR THE OSMC PUBLIC LICENSE (OSMC-PL) VERSION 1.2.
 * ANY USE, REPRODUCTION OR DISTRIBUTION OF THIS PROGRAM CONSTITUTES
 * RECIPIENT'S ACCEPTANCE OF THE OSMC PUBLIC LICENSE OR THE GPL VERSION 3,
 * ACCORDING TO RECIPIENTS CHOICE.
 *
 * The OpenModelica software and the OSMC (Open Source Modelica Consortium)
 * Public License (OSMC-PL) are obtained from OSMC, either from the above
 * address, from the URLs: http://www.openmodelica.org or
 * http://www.ida.liu.se/projects/OpenModelica, and in the OpenModelica
 * distribution. GNU version 3 is obtained from:
 * http://www.gnu.org/copyleft/gpl.html. The New BSD License is obtained from:
 * http://www.opensource.org/licenses/BSD-3-Clause.
 *
 * This program is distributed WITHOUT ANY WARRANTY; without even the implied
 * warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE, EXCEPT AS
 * EXPRESSLY SET FORTH IN THE BY RECIPIENT SELECTED SUBSIDIARY LICENSE
 * CONDITIONS OF OSMC-PL.
 *
 */

#include "../util/omc_error.h"
#include "../simulation_data.h"
#include "../util/rtclock.h"
#include "modelinfo.h"
#include "simulation_info_json.h"
#include "simulation_runtime.h"
#include "../util/omc_mmap.h"
#include "solver/model_help.h"


#include <errno.h>
#include <stdio.h>
#include <string.h>
#include <time.h>
#include <assert.h>
#include <stdint.h>
#include "../util/read_matlab4.h"

/* UNDEF to debug the gnuplot file */
#define NO_PIPE

/* Returns -1 if the file was not found */
static size_t fileSize(const char *filename) {
  size_t sz = -1;
  FILE *f = fopen(filename, "rb");
  if(f) {
    fseek(f, 0, SEEK_END);
    sz = ftell(f);
    fclose(f);
  }
  return sz;
}

static void indent(FILE *fout, int n) {
  while(n--) fputc(' ', fout);
}

static void convertProfileData(const char *outputPath, const char *prefix, int numFnsAndBlocks)
{
  const char* fullFileName;
  if (0 > GC_asprintf(&fullFileName, "%s%s", outputPath, prefix)) {
    throwStreamPrint(NULL, "modelinfo.c: Error: can not allocate memory.");
  }
  size_t len = strlen(fullFileName);
  char *inBinaryInt = (char*)malloc(sizeof(char)*(len + 14));
  char *inBinaryReal = (char*)malloc(sizeof(char)*(len + 15));
  FILE *finInt, *finReal, *fout;
  int fail = 0;
  size_t intRowSize = sizeof(uint32_t)*(1+numFnsAndBlocks);
  size_t realRowSize = sizeof(double)*(2+numFnsAndBlocks);
  uint32_t *intData;
  double *realData;
  /* There seems to be a very small performance gain from using mmap here.
   * But it is not worse than in-memory and may be paged out on low memory. */
  omc_mmap_write intMap,realMap;

  memcpy(inBinaryInt,fullFileName,len);
  memcpy(inBinaryReal,fullFileName,len);
  strcpy(inBinaryInt + len, "_prof.intdata");
  strcpy(inBinaryReal + len, "_prof.realdata");

  intMap = omc_mmap_open_write(inBinaryInt,0);
  intData = (uint32_t*)intMap.data;
  assert(0 == intMap.size % intRowSize);
  matrix_transpose_uint32(intData, 1+numFnsAndBlocks, intMap.size / intRowSize);
  omc_mmap_close_write(intMap);

  realMap = omc_mmap_open_write(inBinaryReal,0);
  realData = (double*)realMap.data;
  assert(0 == realMap.size % realRowSize);
  matrix_transpose(realData, 2+numFnsAndBlocks, realMap.size / realRowSize);
  omc_mmap_close_write(realMap);

  free(inBinaryInt);
  free(inBinaryReal);
}

static void printPlotCommand(FILE *plt, const char *plotFormat, const char *title, const char *outputPath, const char *prefix, int numFnsAndBlocks, int i, int id, const char *idPrefix) {
  const char *format = "plot \"%s%s_prof.realdata\" binary format=\"%%%ddouble\" using 1:($%d>1e-9 ? $%d : 1e-30) w l lw %d\n";
  const char *formatCount = "plot \"%s%s_prof.intdata\" binary format=\"%%%duint32\" using %d w l lw %d\n";
  unsigned long nmin = 0, nmax = 0;
  double ymin = 0.0, ymax = 0.0;
  double ygraphmin = 1e-30, ygraphmax = 0.0;
  if(!plt) return;
  if(i >= 0) {
    /*
     * Note: We set the yrange here because otherwise we get warnings if the
     * number of calls are the same in every time step (i.e. autoscale thinks
     * the range is [3:3])
     */
    nmin = rt_ncall_min(SIM_TIMER_FIRST_FUNCTION + i);
    nmax = rt_ncall_max(SIM_TIMER_FIRST_FUNCTION + i);
    ymin = nmin==0 ? -0.01 : nmin*0.95;
    ymax = nmax==0 ?  0.01 : nmax*1.05;
    ygraphmax = rt_max_accumulated(SIM_TIMER_FIRST_FUNCTION + i) * 1.01 + 1e-30;
  }
  /* SVG thumbnail */
  fputs("set terminal svg\n", plt);
  fprintf(plt, "unset xtics\n");
  fprintf(plt, "unset ytics\n");
  fprintf(plt, "unset border\n");
  fprintf(plt, "set output \"%s%s_prof.%s%d.thumb.svg\"\n", outputPath, prefix, idPrefix, id);
  fprintf(plt, "set title\n");
  fprintf(plt, "set xlabel\n");
  fprintf(plt, "set ylabel\n");
  fprintf(plt, "set log y\n");

  if(i>=0)
  {
    fprintf(plt, "set yrange [*:%g]\n", ygraphmax);
  }
  else
  {
    fprintf(plt, "set yrange [*:*]\n");
  }
  /* time */
  fprintf(plt, format, outputPath, prefix, 2+numFnsAndBlocks, 3+i, 3+i, 4);
  fprintf(plt, "set nolog xy\n");
  /* count */
  if(i >= 0) {
    fprintf(plt, "unset ytics\n");
    if(nmin == nmax)
    {
      fprintf(plt, "set yrange [%g:%g]\n", ymin, ymax);
    }
    else
    {
      fprintf(plt, "set yrange [*:*]\n");
    }
    fprintf(plt, "set output \"%s%s_prof.%s%d_count.thumb.svg\"\n", outputPath, prefix, idPrefix, id);
    fprintf(plt, formatCount, outputPath, prefix, 1+numFnsAndBlocks, 2+i, 4);
    fprintf(plt, "set ytics\n");
  }

  /* SVG */
  fprintf(plt, "set xtics\n");
  fprintf(plt, "set ytics\n");
  fprintf(plt, "set border\n");
  fprintf(plt, "set terminal %s\n", plotFormat);
  fprintf(plt, "set title \"%s\"\n", title);
  fprintf(plt, "set xlabel \"Global step at time\"\n");
  fprintf(plt, "set ylabel \"Execution time [s]\"\n");
  fprintf(plt, "set output \"%s%s_prof.%s%d.%s\"\n", outputPath, prefix, idPrefix, id, plotFormat);
  fprintf(plt, "set log y\n");
  if(i>=0)
  {
    fprintf(plt, "set yrange [*:%g]\n", ygraphmax);
  }
  else
  {
    fprintf(plt, "set yrange [*:*]\n");
  }
  fprintf(plt, format, outputPath, prefix, 2+numFnsAndBlocks, 3+i, 3+i, 2);
  /* count */
  fprintf(plt, "set nolog xy\n");
  if(i >= 0)
  {
    if(nmin == nmax)
    {
      fprintf(plt, "set yrange [%g:%g]\n", ymin, ymax);
    }
    else
    {
      fprintf(plt, "set yrange [*:*]\n");
    }
    fprintf(plt, "set xlabel \"Global step number\"\n");
    fprintf(plt, "set ylabel \"Execution count\"\n");
    fprintf(plt, "set output \"%s_prof.%s%d_count.%s\"\n", prefix, idPrefix, id, plotFormat);
    fprintf(plt, formatCount, outputPath, prefix, 1+numFnsAndBlocks, 2+i, 2);
  }
}

static void printStrXML(FILE *fout, const char *str)
{
  while(*str) {
  switch (*str) {
  case '<': fputs("&lt;",fout);break;
  case '>': fputs("&gt;",fout);break;
  case '\'': fputs("&apos;",fout);break;
  case '"': fputs("&quot;",fout);break;
  /* case '\\': fputs("\\\\",fout);break; */
  default: fputc(*str,fout); break;
  }
  str++;
  }
}

static void printInfoTag(FILE *fout, int level, const FILE_INFO info) {
  indent(fout,level);
  fprintf(fout, "<info filename=\"");
  printStrXML(fout, info.filename);
  fprintf(fout, "\" startline=\"%d\" startcol=\"%d\" endline=\"%d\" endcol=\"%d\" readonly=\"%s\" />\n", info.lineStart, info.colStart, info.lineEnd, info.colEnd, info.readonly ? "readonly" : "writable");
}

static void printVar(FILE *fout, int level, VAR_INFO* info) {

  indent(fout,level);
  fprintf(fout, "<variable id=\"var%d\" name=\"", info->id);
  printStrXML(fout, info->name);
  fprintf(fout, "\" comment=\"");
  printStrXML(fout, info->comment);
  fprintf(fout, "\">\n");
  printInfoTag(fout, level+2, info->info);
  indent(fout,level);
  fprintf(fout, "</variable>\n");
}

static void printFunctions(FILE *fout, FILE *plt, const char *plotFormat, const char *outputPath, const char *modelFilePrefix, DATA *data) {
  int i;
  for(i=0; i<data->modelData->modelDataXml.nFunctions; i++) {
    const struct FUNCTION_INFO func = modelInfoGetFunction(&data->modelData->modelDataXml, i);
    printPlotCommand(plt, plotFormat, func.name, outputPath, modelFilePrefix, data->modelData->modelDataXml.nFunctions+data->modelData->modelDataXml.nProfileBlocks, i, func.id, "fun");
    rt_clear(i + SIM_TIMER_FIRST_FUNCTION);
    indent(fout,2);
    fprintf(fout, "<function id=\"fun%d\">\n", func.id);
    indent(fout,4);fprintf(fout, "<name>");printStrXML(fout, func.name);fprintf(fout,"</name>\n");
    indent(fout,4);fprintf(fout, "<ncall>%d</ncall>\n", (int) rt_ncall_total(i + SIM_TIMER_FIRST_FUNCTION));
    indent(fout,4);fprintf(fout, "<time>%.9f</time>\n",rt_total(i + SIM_TIMER_FIRST_FUNCTION));
    indent(fout,4);fprintf(fout, "<maxTime>%.9f</maxTime>\n",rt_max_accumulated(i + SIM_TIMER_FIRST_FUNCTION));
    printInfoTag(fout, 6, func.info);
    indent(fout,2);
    fprintf(fout, "</function>\n");
  }
}

static void printProfileBlocks(FILE *fout, FILE *plt, const char *plotFormat, const char *outputPath, DATA *data) {
  int i;
  for(i = data->modelData->modelDataXml.nFunctions; i < data->modelData->modelDataXml.nFunctions + data->modelData->modelDataXml.nProfileBlocks; i++) {
    const struct EQUATION_INFO eq = modelInfoGetEquationIndexByProfileBlock(&data->modelData->modelDataXml, i-data->modelData->modelDataXml.nFunctions);
    printPlotCommand(plt, plotFormat, "equation", outputPath, data->modelData->modelFilePrefix, data->modelData->modelDataXml.nFunctions+data->modelData->modelDataXml.nProfileBlocks, i, eq.id, "eq");
    rt_clear(i + SIM_TIMER_FIRST_FUNCTION);
    indent(fout,2);fprintf(fout, "<profileblock>\n");
    indent(fout,4);fprintf(fout, "<ref refid=\"eq%d\"/>\n", (int) eq.id);
    indent(fout,4);fprintf(fout, "<ncall>%d</ncall>\n", (int) rt_ncall_total(i + SIM_TIMER_FIRST_FUNCTION));
    indent(fout,4);fprintf(fout, "<time>%.9f</time>\n", rt_total(i + SIM_TIMER_FIRST_FUNCTION));
    indent(fout,4);fprintf(fout, "<maxTime>%.9f</maxTime>\n",rt_max_accumulated(i + SIM_TIMER_FIRST_FUNCTION));
    indent(fout,2);fprintf(fout, "</profileblock>\n");
  }
}


static int getVarIdByName(DATA *data, const char* varName)
{
  int i;
  for(i=0;i<data->modelData->nVariablesReal;++i)
    if (strcmp(varName, data->modelData->realVarsData[i].info.name) == 0)
      return data->modelData->realVarsData[i].info.id;

  for(i=0;i<data->modelData->nParametersReal;++i)
    if (strcmp(varName, data->modelData->realParameterData[i].info.name) == 0)
      return data->modelData->realParameterData[i].info.id;

  for(i=0;i<data->modelData->nVariablesInteger;++i)
    if (strcmp(varName, data->modelData->integerVarsData[i].info.name) == 0)
      return data->modelData->integerVarsData[i].info.id;

  for(i=0;i<data->modelData->nParametersInteger;++i)
    if (strcmp(varName, data->modelData->integerParameterData[i].info.name) == 0)
      return data->modelData->integerParameterData[i].info.id;

  for(i=0;i<data->modelData->nVariablesBoolean;++i)
    if (strcmp(varName, data->modelData->booleanVarsData[i].info.name) == 0)
      return data->modelData->booleanVarsData[i].info.id;

  for(i=0;i<data->modelData->nParametersBoolean;++i)
    if (strcmp(varName, data->modelData->booleanParameterData[i].info.name) == 0)
      return data->modelData->booleanParameterData[i].info.id;

  for(i=0;i<data->modelData->nVariablesString;++i)
    if (strcmp(varName, data->modelData->stringVarsData[i].info.name) == 0)
      return data->modelData->stringVarsData[i].info.id;

  for(i=0;i<data->modelData->nParametersString;++i)
    if (strcmp(varName, data->modelData->stringParameterData[i].info.name) == 0)
      return data->modelData->stringParameterData[i].info.id;

  return 0;
}

static void printEquations(FILE *fout, int n, MODEL_DATA_XML *xml, DATA *data) {
  int i,j;
  for(i=0; i<n; i++) {
    indent(fout,2);fprintf(fout, "<equation id=\"eq%d\">\n", modelInfoGetEquation(xml,i).id);
    indent(fout,4);fprintf(fout, "<refs>\n");
    for(j=0; j<modelInfoGetEquation(xml,i).numVar; j++) {
      indent(fout,6);fprintf(fout, "<ref refid=\"var%d\" />\n", getVarIdByName(data, modelInfoGetEquation(xml,i).vars[j]));
    }
    indent(fout,4);fprintf(fout, "</refs>\n");
    indent(fout,4);fprintf(fout, "<calcinfo time=\"%f\" count=\"%lu\"/>\n", rt_accumulated(SIM_TIMER_FIRST_FUNCTION + xml->nFunctions + xml->nProfileBlocks + modelInfoGetEquation(xml,i).id), (long) rt_ncall(SIM_TIMER_FIRST_FUNCTION + xml->nFunctions + xml->nProfileBlocks + modelInfoGetEquation(xml,i).id));
    indent(fout,2);fprintf(fout, "</equation>\n");
  }
}

static void printProfilingDataHeader(FILE *fout, DATA *data) {
  char *filename;
  int i;

  filename = malloc(strlen(data->modelData->modelFilePrefix) + 15);
  sprintf(filename, "%s_prof.data", data->modelData->modelFilePrefix);
  indent(fout, 2); fprintf(fout, "<filename>");printStrXML(fout,filename);fprintf(fout,"</filename>\n");
  indent(fout, 2); fprintf(fout, "<filesize>%ld</filesize>\n", (long) fileSize(filename));
  free(filename);

  indent(fout, 2); fprintf(fout, "<format>\n");
  indent(fout, 4); fprintf(fout, "<uint32>step</uint32>\n");
  indent(fout, 4); fprintf(fout, "<double>time</double>\n");
  indent(fout, 4); fprintf(fout, "<double>cpu time</double>\n");
  for(i = 0; i < data->modelData->modelDataXml.nFunctions; i++) {
    const char *name = modelInfoGetFunction(&data->modelData->modelDataXml,i).name;
    indent(fout, 4); fprintf(fout, "<uint32>");printStrXML(fout,name);fprintf(fout, " (calls)</uint32>\n");
  }
  for(i = 0; i < data->modelData->modelDataXml.nProfileBlocks; i++) {
    int id = modelInfoGetEquationIndexByProfileBlock(&data->modelData->modelDataXml,i).id;
    indent(fout, 4); fprintf(fout, "<uint32>Equation %d (calls)</uint32>\n", id);
  }
  for(i = 0; i < data->modelData->modelDataXml.nFunctions; i++) {
    const char *name = modelInfoGetFunction(&data->modelData->modelDataXml,i).name;
    indent(fout, 4); fprintf(fout, "<double>");printStrXML(fout,name);fprintf(fout, " (cpu time)</double>\n");
  }
  for(i = 0; i < data->modelData->modelDataXml.nProfileBlocks; i++) {
    int id = modelInfoGetEquationIndexByProfileBlock(&data->modelData->modelDataXml,i).id;
    indent(fout, 4); fprintf(fout, "<double>Equation %d (cpu time)</double>\n", id);
  }
  indent(fout, 2); fprintf(fout, "</format>\n");
}

int printModelInfo(DATA *data, threadData_t *threadData, const char *outputPath, const char *filename, const char *plotfile, const char *plotFormat, const char *method, const char *outputFormat, const char *outputFilename)
{
  static char buf[256];
  const char* fullFileName;
  if (0 > GC_asprintf(&fullFileName, "%s%s", outputPath, filename)) {
    throwStreamPrint(NULL, "modelinfo.c: Error: can not allocate memory.");
  }
  FILE *fout = fopen(fullFileName, "w");
  FILE *plotCommands;
  time_t t;
  int i;
#if defined(__MINGW32__) || defined(_MSC_VER) || defined(NO_PIPE)
  const char* fullPlotFile;
  if (0 > GC_asprintf(&fullPlotFile, "%s%s", outputPath, plotfile)) {
    throwStreamPrint(NULL, "modelinfo.c: Error: can not allocate memory.");
  }
  plotCommands = fopen(fullPlotFile, "w");
#else
  plotCommands = popen("gnuplot", "w");
#endif
  if (!plotCommands) {
    warningStreamPrint(LOG_UTIL, 0, "Plots of profiling data were disabled: %s\n", strerror(errno));
  }

  assertStreamPrint(threadData, 0 != fout, "Failed to open %s%s: %s\n", outputPath, filename, strerror(errno));

  if(plotCommands) {
    fputs("set terminal svg\n", plotCommands);
    fputs("set nokey\n", plotCommands);
    fputs("set format y \"%g\"\n", plotCommands);
    /* The column containing the time spent to calculate each step */
    printPlotCommand(plotCommands, plotFormat, "Execution time of global steps", outputPath, data->modelData->modelFilePrefix, data->modelData->modelDataXml.nFunctions+data->modelData->modelDataXml.nProfileBlocks, -1, 999, "");
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
  if(time(&t) < 0)
  {
    warningStreamPrint(LOG_UTIL, 0, "time() failed: %s", strerror(errno));
    fclose(fout);
#if defined(__MINGW32__) || defined(_MSC_VER) || defined(NO_PIPE)
      fclose(plotCommands);
#else
      pclose(plotCommands);
#endif
    return 1;
  }
  if(!strftime(buf, 250, "%Y-%m-%d %H:%M:%S", localtime(&t)))
  {
    warningStreamPrint(LOG_UTIL, 0, "strftime() failed");
    fclose(fout);
    return 1;
  }
  fprintf(fout, "<simulation>\n");
  fprintf(fout, "<modelinfo>\n");
  indent(fout, 2); fprintf(fout, "<name>");printStrXML(fout,data->modelData->modelName);fprintf(fout,"</name>\n");
  indent(fout, 2); fprintf(fout, "<prefix>");printStrXML(fout,data->modelData->modelFilePrefix);fprintf(fout,"</prefix>\n");
  indent(fout, 2); fprintf(fout, "<date>");printStrXML(fout,buf);fprintf(fout,"</date>\n");
  indent(fout, 2); fprintf(fout, "<method>");printStrXML(fout,data->simulationInfo->solverMethod);fprintf(fout,"</method>\n");
  indent(fout, 2); fprintf(fout, "<outputFormat>");printStrXML(fout,data->simulationInfo->outputFormat);fprintf(fout,"</outputFormat>\n");
  indent(fout, 2); fprintf(fout, "<outputFilename>");printStrXML(fout,outputFilename);fprintf(fout,"</outputFilename>\n");
  indent(fout, 2); fprintf(fout, "<outputFilesize>%ld</outputFilesize>\n", (long) fileSize(outputFilename));
  indent(fout, 2); fprintf(fout, "<overheadTime>%f</overheadTime>\n", rt_accumulated(SIM_TIMER_OVERHEAD));
  indent(fout, 2); fprintf(fout, "<preinitTime>%f</preinitTime>\n", rt_accumulated(SIM_TIMER_PREINIT));
  indent(fout, 2); fprintf(fout, "<initTime>%f</initTime>\n", rt_accumulated(SIM_TIMER_INIT));
  indent(fout, 2); fprintf(fout, "<eventTime>%f</eventTime>\n", rt_accumulated(SIM_TIMER_EVENT));
  indent(fout, 2); fprintf(fout, "<outputTime>%f</outputTime>\n", rt_accumulated(SIM_TIMER_OUTPUT));
  indent(fout, 2); fprintf(fout, "<jacobianTime>%f</jacobianTime>\n", rt_accumulated(SIM_TIMER_JACOBIAN));
  indent(fout, 2); fprintf(fout, "<totalTime>%f</totalTime>\n", rt_accumulated(SIM_TIMER_TOTAL));
  indent(fout, 2); fprintf(fout, "<totalStepsTime>%f</totalStepsTime>\n", rt_total(SIM_TIMER_STEP));
  indent(fout, 2); fprintf(fout, "<numStep>%d</numStep>\n", (int) rt_ncall_total(SIM_TIMER_STEP));
  indent(fout, 2); fprintf(fout, "<maxTime>%.9f</maxTime>\n", rt_max_accumulated(SIM_TIMER_STEP));
  fprintf(fout, "</modelinfo>\n");

  fprintf(fout, "<modelinfo_ext>\n");
  indent(fout, 2); fprintf(fout, "<odeTime>%f</odeTime>\n", rt_accumulated(SIM_TIMER_FUNCTION_ODE));
  indent(fout, 2); fprintf(fout, "<odeTimeTicks>%lu</odeTimeTicks>\n", (long) rt_ncall(SIM_TIMER_FUNCTION_ODE));
  fprintf(fout, "</modelinfo_ext>\n");

  fprintf(fout, "<profilingdataheader>\n");
  printProfilingDataHeader(fout, data);
  fprintf(fout, "</profilingdataheader>\n");

  fprintf(fout, "<variables>\n");
  for(i=0;i<data->modelData->nVariablesReal;++i){
    printVar(fout, 2, &(data->modelData->realVarsData[i].info));
  }
  for(i=0;i<data->modelData->nParametersReal;++i){
    printVar(fout, 2, &data->modelData->realParameterData[i].info);
  }
  for(i=0;i<data->modelData->nVariablesInteger;++i){
    printVar(fout, 2, &data->modelData->integerVarsData[i].info);
  }
  for(i=0;i<data->modelData->nParametersInteger;++i){
    printVar(fout, 2, &data->modelData->integerParameterData[i].info);
  }
  for(i=0;i<data->modelData->nVariablesBoolean;++i){
    printVar(fout, 2, &data->modelData->booleanVarsData[i].info);
  }
  for(i=0;i<data->modelData->nParametersBoolean;++i){
    printVar(fout, 2, &data->modelData->booleanParameterData[i].info);
  }
  for(i=0;i<data->modelData->nVariablesString;++i){
    printVar(fout, 2, &data->modelData->stringVarsData[i].info);
  }
  for(i=0;i<data->modelData->nParametersString;++i){
    printVar(fout, 2, &data->modelData->stringParameterData[i].info);
  }
  fprintf(fout, "</variables>\n");

  fprintf(fout, "<functions>\n");
  printFunctions(fout, plotCommands, plotFormat, outputPath, data->modelData->modelFilePrefix, data);
  fprintf(fout, "</functions>\n");

  fprintf(fout, "<equations>\n");
  printEquations(fout, data->modelData->modelDataXml.nEquations, &data->modelData->modelDataXml, data);
  fprintf(fout, "</equations>\n");

  fprintf(fout, "<profileblocks>\n");
  printProfileBlocks(fout, plotCommands, plotFormat, outputPath, data);
  fprintf(fout, "</profileblocks>\n");

  fprintf(fout, "</simulation>\n");

  fclose(fout);
  if(plotCommands) {
    const char *omhome = data->simulationInfo->OPENMODELICAHOME;
    char *buf = NULL;
    int genHtmlRes;
    buf = (char*)malloc(230 + 2*strlen(plotfile) + 2*(omhome ? strlen(omhome) : 0));
    assert(buf);
#if defined(__MINGW32__) || defined(_MSC_VER) || defined(NO_PIPE)
    if(omhome) {
#if defined(__MINGW32__) || defined(_MSC_VER)
      sprintf(buf, "%s/lib/omc/libexec/gnuplot/binary/gnuplot.exe %s%s", omhome, outputPath, plotfile);
#else
      sprintf(buf, "gnuplot %s", plotfile);
#endif
      fclose(plotCommands);
      if (measure_time_flag & 4 && 0 != system(buf)) {
        warningStreamPrint(LOG_UTIL, 0, "Plot command failed: %s\n", buf);
      }
    }
#else
    if(0 != pclose(plotCommands)) {
      warningStreamPrint(LOG_UTIL, 0, "Warning: Plot command failed\n");
    }
#endif
    if(omhome)
    {
#if defined(__MINGW32__) || defined(_MSC_VER)
      char *xsltproc;
      sprintf(buf, "%s/lib/omc/libexec/xsltproc/xsltproc.exe", omhome);
      xsltproc = strdup(buf);
#else
      const char *xsltproc = "xsltproc";
#endif
      sprintf(buf, "%s -o %s%s_prof.html %s/share/omc/scripts/default_profiling.xsl %s%s_prof.xml", xsltproc, outputPath, data->modelData->modelFilePrefix, omhome, outputPath, data->modelData->modelFilePrefix);
#if defined(__MINGW32__) || defined(_MSC_VER)
      free(xsltproc);
#endif
      genHtmlRes = measure_time_flag & 4 && system(buf);
    }
    else
    {
      strcpy(buf, "OPENMODELICAHOME missing");
      genHtmlRes = 1;
    }
    if(genHtmlRes)
    {
      warningStreamPrint(LOG_STDOUT, 0, "Failed to generate html version of profiling results: %s\n", buf);
    }
    if (measure_time_flag & 4) {
      infoStreamPrint(LOG_STDOUT, 0, "Time measurements are stored in %s%s_prof.html (human-readable) and %s%s_prof.xml (for XSL transforms or more details)", outputPath, data->modelData->modelFilePrefix, outputPath, data->modelData->modelFilePrefix);
    } else {
      infoStreamPrint(LOG_STDOUT, 0, "Time measurements are stored in %s%s_prof.json", outputPath, data->modelData->modelFilePrefix);
    }
    free(buf);
  }
  return 0;
}

#define ERROR_WRITE() throwStreamPrint(NULL, "Failed to write to opened file")

void escapeJSON(FILE *file, const char *data)
{
  while (*data) {
    switch (*data) {
    case '\"': if (fputs("\\\"",file)<0) ERROR_WRITE();break;
    case '\\': if (fputs("\\\\",file)<0) ERROR_WRITE();break;
    case '\n': if (fputs("\\n",file)<0) ERROR_WRITE();break;
    case '\b': if (fputs("\\b",file)<0) ERROR_WRITE();break;
    case '\f': if (fputs("\\f",file)<0) ERROR_WRITE();break;
    case '\r': if (fputs("\\r",file)<0) ERROR_WRITE();break;
    case '\t': if (fputs("\\t",file)<0) ERROR_WRITE();break;
    default:
      if (*data < ' ') { /* Escape other control characters */
        if (fprintf(file, "\\u%04x",*data)<0) ERROR_WRITE();
      } else {
        if (putc(*data,file)<0) ERROR_WRITE();
      }
    }
    data++;
  }
}

static void printJSONFunctions(FILE *fout, DATA *data) {
  int i;
  for(i = 0; i < data->modelData->modelDataXml.nFunctions; i++) {
    const struct FUNCTION_INFO func = modelInfoGetFunction(&data->modelData->modelDataXml, i);
    rt_clear(i + SIM_TIMER_FIRST_FUNCTION);
    fputs(i == 0 ? "\n" : ",\n", fout);
    fprintf(fout, "{\"name\":\"");
    escapeJSON(fout, func.name);
    fprintf(fout, "\",\"ncall\":%d,\"time\":%.9f,\"maxTime\":%.9f}",
      (int) rt_ncall_total(i + SIM_TIMER_FIRST_FUNCTION),
      rt_total(i + SIM_TIMER_FIRST_FUNCTION),
      rt_max_accumulated(i + SIM_TIMER_FIRST_FUNCTION));
  }
}

static void printJSONProfileBlocks(FILE *fout, DATA *data) {
  int i;
  for(i = data->modelData->modelDataXml.nFunctions; i < data->modelData->modelDataXml.nFunctions + data->modelData->modelDataXml.nProfileBlocks; i++) {
    const struct EQUATION_INFO eq = modelInfoGetEquationIndexByProfileBlock(&data->modelData->modelDataXml, i-data->modelData->modelDataXml.nFunctions);
    rt_clear(i + SIM_TIMER_FIRST_FUNCTION);
    fputs(i == data->modelData->modelDataXml.nFunctions ? "\n" : ",\n", fout);
    fprintf(fout, "{\"id\":%d,\"ncall\":%d,\"time\":%.9f,\"maxTime\":%.9f}",
      (int) eq.id,
      (int) rt_ncall_total(i + SIM_TIMER_FIRST_FUNCTION),
      rt_total(i + SIM_TIMER_FIRST_FUNCTION),
      rt_max_accumulated(i + SIM_TIMER_FIRST_FUNCTION));
  }
}

int printModelInfoJSON(DATA *data, threadData_t *threadData, const char *outputPath, const char *filename, const char *outputFilename)
{
  char buf[256];
  const char* fullFileName;
  if (0 > GC_asprintf(&fullFileName, "%s%s", outputPath, filename)) {
    throwStreamPrint(NULL, "modelinfo.c: Error: can not allocate memory.");
  }
  FILE *fout = fopen(fullFileName, "wb");
  time_t t;
  long i;
  double totalTimeEqs = 0;
  if (!fout) {
    throwStreamPrint(NULL, "Failed to open file %s%s for writing", outputPath, filename);
  }
  convertProfileData(outputPath, data->modelData->modelFilePrefix, data->modelData->modelDataXml.nFunctions+data->modelData->modelDataXml.nProfileBlocks);
  if(time(&t) < 0)
  {
    fclose(fout);
    throwStreamPrint(0, "time() failed: %s", strerror(errno));
  }
  if(!strftime(buf, 250, "%Y-%m-%d %H:%M:%S", localtime(&t)))
  {
    fclose(fout);
    throwStreamPrint(0, "strftime() failed");
  }
  for (i=data->modelData->modelDataXml.nFunctions; i<data->modelData->modelDataXml.nFunctions + data->modelData->modelDataXml.nProfileBlocks; i++) {
    if (modelInfoGetEquation(&data->modelData->modelDataXml,i).parent == 0) {
      /* The equation has no parent. The sum of all such equations is
       * the total time of the profiled blocks including the children. */
      totalTimeEqs += rt_total(i + SIM_TIMER_FIRST_FUNCTION);
    }
  }
  fprintf(fout, "{\n\"name\":\"");
  escapeJSON(fout, data->modelData->modelName);
  fprintf(fout, "\",\n\"prefix\":\"");
  escapeJSON(fout, data->modelData->modelFilePrefix);
  fprintf(fout, "\",\n\"date\":\"");
  escapeJSON(fout, buf);
  fprintf(fout, "\",\n\"method\":\"");
  escapeJSON(fout, data->simulationInfo->solverMethod);
  fprintf(fout, "\",\n\"outputFormat\":\"");
  escapeJSON(fout, data->simulationInfo->outputFormat);
  fprintf(fout, "\",\n\"outputFilename\":\"");
  escapeJSON(fout, outputFilename);
  fprintf(fout, "\",\n\"outputFilesize\":%ld",(long) fileSize(outputFilename));
  fprintf(fout, ",\n\"overheadTime\":%g",rt_accumulated(SIM_TIMER_OVERHEAD));
  fprintf(fout, ",\n\"preinitTime\":%g",rt_accumulated(SIM_TIMER_PREINIT));
  fprintf(fout, ",\n\"initTime\":%g",rt_accumulated(SIM_TIMER_INIT));
  fprintf(fout, ",\n\"eventTime\":%g",rt_accumulated(SIM_TIMER_EVENT));
  fprintf(fout, ",\n\"outputTime\":%g",rt_accumulated(SIM_TIMER_OUTPUT));
  fprintf(fout, ",\n\"jacobianTime\":%g",rt_accumulated(SIM_TIMER_JACOBIAN));
  fprintf(fout, ",\n\"totalTime\":%g",rt_accumulated(SIM_TIMER_TOTAL));
  fprintf(fout, ",\n\"totalStepsTime\":%g",rt_accumulated(SIM_TIMER_STEP));
  fprintf(fout, ",\n\"totalTimeProfileBlocks\":%g",totalTimeEqs); /* The overhead the profiling is huge if small equations are profiled */
  fprintf(fout, ",\n\"numStep\":%d", (int) rt_ncall_total(SIM_TIMER_STEP));
  fprintf(fout, ",\n\"maxTime\":%.9g", rt_max_accumulated(SIM_TIMER_STEP));
  fprintf(fout, ",\n\"functions\":[");
  printJSONFunctions(fout,data);
  fprintf(fout, "\n],\n\"profileBlocks\":[");
  printJSONProfileBlocks(fout,data);
  fprintf(fout, "\n]\n");
  fprintf(fout, "}");
  return 0;
}
