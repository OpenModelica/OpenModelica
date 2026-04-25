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

#if defined(_MSC_VER) || defined(__MINGW32__)
 #include <windows.h>
#endif

#include <stdio.h>
#include <stdlib.h>


#include "meta/meta_modelica.h"

#define ADD_METARECORD_DEFINITIONS static
#if defined(OMC_BOOTSTRAPPING)
  #include "../boot/tarball-include/OpenModelicaBootstrappingHeader.h"
#else
  #include "../OpenModelicaBootstrappingHeader.h"
#endif

#include "SimulationResults.c"
#include "SimulationResultsCmp.c"

void* SimulationResults_readVariables(const char *filename, int readParameters, int omcStyle)
{
  return SimulationResultsImpl__readVars(filename, readParameters, omcStyle, &simresglob);
}

extern void* _ValuesUtil_reverseMatrix(void*);
void* SimulationResults_readDataset(const char *filename, void *vars, int datasize)
{
  void *res = SimulationResultsImpl__readDataset(filename,vars,datasize,0,&simresglob,0);
  if (res == NULL) MMC_THROW();
  return res;
}

int SimulationResults_readSimulationResultSize(const char *filename)
{
  return SimulationResultsImpl__readSimulationResultSize(filename,&simresglob);
}

double SimulationResults_val(const char *filename, const char *varname, double timeStamp)
{
  return SimulationResultsImpl__val(filename,varname,timeStamp,&simresglob);
}

void* SimulationResults_cmpSimulationResults(int runningTestsuite, const char *filename,const char *reffilename,const char *logfilename, double refTol, double absTol, void *vars)
{
  return SimulationResultsCmp_compareResults(1,runningTestsuite,filename,reffilename,logfilename,refTol,absTol,0,0,vars,0,NULL,0,NULL);
}

double SimulationResults_deltaSimulationResults(const char *filename,const char *reffilename, const char *methodname, void *vars)
{
  double res = SimulationResultsCmp_deltaResults(filename,reffilename,methodname,vars);
  return res;
}

void* SimulationResults_diffSimulationResults(int runningTestsuite, const char *filename,const char *reffilename,const char *logfilename, double refTol, double reltolDiffMaxMin, double rangeDelta, void *vars, int keepEqualResults, int *success)
{
  return SimulationResultsCmp_compareResults(0,runningTestsuite,filename,reffilename,logfilename,refTol,0,reltolDiffMaxMin,rangeDelta,vars,keepEqualResults,success,0,NULL);
}

const char* SimulationResults_diffSimulationResultsHtml(int runningTestsuite, const char *var, const char *filename,const char *reffilename, double refTol, double reltolDiffMaxMin, double rangeDelta)
{
  char *res = "";
  SimulationResultsCmp_compareResults(0,runningTestsuite,filename,reffilename,"",0,refTol,reltolDiffMaxMin,rangeDelta,mmc_mk_cons(mmc_mk_scon(var),mmc_mk_nil()),0,NULL,1,&res);
  return res;
}

void SimulationResults_close()
{
  SimulationResultsImpl__close(&simresglob);
}
