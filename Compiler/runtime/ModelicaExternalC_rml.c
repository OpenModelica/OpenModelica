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

#include "rml.h"
#include "memory_pool.h"

void ModelicaInternal_print(const char*,const char*);
const char* ModelicaInternal_readLine(const char*,int,int*);
int ModelicaInternal_countLines(const char*);
void ModelicaStreams_closeFile(const char*);

void ModelicaExternalC_5finit(void)
{
}

RML_BEGIN_LABEL(ModelicaExternalC__Streams_5fprint)
{
  char* str = RML_STRINGDATA(rmlA0);
  char* fileName = RML_STRINGDATA(rmlA1);
  ModelicaInternal_print(str,fileName);
  RML_TAILCALLK(rmlSC);
}
RML_END_LABEL

RML_BEGIN_LABEL(ModelicaExternalC__Streams_5freadLine)
{
  state mem_state;
  
  mem_state = get_memory_state();
  char* fileName = RML_STRINGDATA(rmlA0);
  long line = RML_UNTAGFIXNUM(rmlA1);
  int endOfFile = 0;
  char* res = ModelicaInternal_readLine(fileName,line,&endOfFile);
  rmlA0 = mk_scon(res);
  rmlA1 = mk_icon(endOfFile);
  restore_memory_state(mem_state);
  RML_TAILCALLK(rmlSC);
}
RML_END_LABEL

RML_BEGIN_LABEL(ModelicaExternalC__Streams_5fcountLines)
{
  char* fileName = RML_STRINGDATA(rmlA0);
  rmlA0 = mk_icon(ModelicaInternal_countLines(fileName));
  RML_TAILCALLK(rmlSC);
}
RML_END_LABEL

RML_BEGIN_LABEL(ModelicaExternalC__Streams_5fclose)
{
  char* fileName = RML_STRINGDATA(rmlA0);
  ModelicaStreams_closeFile(fileName);
  RML_TAILCALLK(rmlSC);
}
RML_END_LABEL

