/*
 * This file is part of OpenModelica.
 *
 * Copyright (c) 1998-2010, Linköpings University,
 * Department of Computer and Information Science,
 * SE-58183 Linköping, Sweden.
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
 * from Linköpings University, either from the above address,
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

#include <stdio.h>
#include <stdlib.h>

#include "meta_modelica.h"
#include "OpenModelicaBootstrappingHeader.h"

extern "C" {

#include "SimulationResults.c"

void* read_ptolemy_dataset(const char*filename, int size,const char**vars,int);
void* read_ptolemy_variables(const char* filename, const char* visvars);
int read_ptolemy_dataset_size(const char*filename);

void* SimulationResults_readPtolemyplotVariables(const char *filename, const char *visvars)
{
  void* res = read_ptolemy_variables(filename, visvars);
  if (res == NULL) MMC_THROW();
  return res;
}

extern void* _ValuesUtil_reverseMatrix(void*);
void* SimulationResults_readPtolemyplotDataset(const char *filename, void *lst, int datasize)
{
  int i, size = listLength(lst);
  void *p,*res;
  const char** vars = (const char**) malloc(sizeof(const char*)*size);
  for (i=0, p=lst; i<size; i++) {
    vars[i] = MMC_STRINGDATA(MMC_CAR(p));
    p = MMC_CDR(p);
  }
  res = read_ptolemy_dataset(filename,size,vars,datasize);
  if (res == NULL) MMC_THROW();
  return res;
}

void* SimulationResults_readPtolemyplotDatasetSize(const char *filename)
{
  return Values__INTEGER(mmc_mk_icon(read_ptolemy_dataset_size(filename)));
}

double SimulationResults_val(const char *filename, const char *varname, double timeStamp)
{
  return SimulationResultsImpl__val(filename,varname,timeStamp);
}

}
