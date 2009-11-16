/*
 * This file is part of OpenModelica.
 *
 * Copyright (c) 1998-2008, Linköpings University,
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

#include <stdlib.h>
#include "rml.h"
#include "Values.h"
#include "ValuesUtil.h"

void* read_ptolemy_dataset(char*filename, int size,char**vars,int);
void* read_ptolemy_variables(char* filename, char* visvars);
int read_ptolemy_dataset_size(char*filename);

void SimulationResults_5finit(void)
{
}

RML_BEGIN_LABEL(SimulationResults__readPtolemyplotVariables)
{
  rml_sint_t i,size;
  char* filename = RML_STRINGDATA(rmlA0);
  char* visvars = RML_STRINGDATA(rmlA1);
  void* p;

  rmlA0 = (void*)read_ptolemy_variables(filename, visvars);
  if (rmlA0 == NULL) {
    RML_TAILCALLK(rmlFC);
  }
  RML_TAILCALLK(rmlSC);
}
RML_END_LABEL

RML_BEGIN_LABEL(SimulationResults__readPtolemyplotDataset)
{
  rml_sint_t i,size;
  char **vars;
  char* filename = RML_STRINGDATA(rmlA0);
  void *lst = rmlA1;
  rml_sint_t datasize = RML_UNTAGFIXNUM(rmlA2);
  void* p;
  rmlA0 = lst;
  rml_prim_once(RML__list_5flength);
  size = RML_UNTAGFIXNUM(rmlA0);

  vars = (char**)malloc(sizeof(char*)*size);
  for (i=0,p=lst;i<size;i++) {
    vars[i]=RML_STRINGDATA(RML_CAR(p));
    p=RML_CDR(p);
  }
  rmlA0 = (void*)read_ptolemy_dataset(filename,size,vars,datasize);
  if (rmlA0 == NULL) {
    RML_TAILCALLK(rmlFC);
  }

  rml_prim_once(ValuesUtil__reverseMatrix);

  RML_TAILCALLK(rmlSC);
}
RML_END_LABEL

RML_BEGIN_LABEL(SimulationResults__readPtolemyplotDatasetSize)
{
  int size;
  char* filename = RML_STRINGDATA(rmlA0);
  void* p;

  size=read_ptolemy_dataset_size(filename);

  rmlA0 = (void*)Values__INTEGER(mk_icon(size));
  if (rmlA0 == NULL) {
    RML_TAILCALLK(rmlFC);
  }
  RML_TAILCALLK(rmlSC);
}
RML_END_LABEL
