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
#include "meta_modelica.h"

void (*omc_assert)(FILE_INFO info,const char *msg,...) = omc_assert_function;
void (*omc_terminate)(FILE_INFO info,const char *msg,...) = omc_terminate_function;
void (*omc_throw)() = omc_throw_function;

void ModelicaInternal_print(const char*,const char*);
const char* ModelicaInternal_readLine(const char*,int,int*);
int ModelicaInternal_countLines(const char*);
const char* ModelicaInternal_fullPathName(const char*);
int ModelicaInternal_stat(const char*);
void ModelicaStreams_closeFile(const char*);
void ModelicaStrings_scanReal(const char*,int,int,int*,double*);
int ModelicaStrings_skipWhiteSpace(const char*,int);

void ModelicaExternalC_5finit(void)
{
}

RML_BEGIN_LABEL(ModelicaExternalC__Streams_5fprint)
{
  int fail=0;
  char* str = RML_STRINGDATA(rmlA0);
  char* fileName = RML_STRINGDATA(rmlA1);
  MMC_TRY();
    ModelicaInternal_print(str,fileName);
  MMC_ELSE();
    fail = 1;
  MMC_CATCH();
  if (fail) RML_TAILCALLK(rmlFC);
  RML_TAILCALLK(rmlSC);
}
RML_END_LABEL

RML_BEGIN_LABEL(ModelicaExternalC__Streams_5freadLine)
{
  state mem_state;

  mem_state = get_memory_state();
  char* fileName = RML_STRINGDATA(rmlA0), *res = 0;
  long line = RML_UNTAGFIXNUM(rmlA1);
  int endOfFile = 0, fail = 0;
  MMC_TRY();
    res = (char*)ModelicaInternal_readLine(fileName,line,&endOfFile);
  MMC_ELSE();
    fail = 1;
  MMC_CATCH();
  if (fail) RML_TAILCALLK(rmlFC);
  rmlA0 = mk_scon(res);
  rmlA1 = mk_icon(endOfFile);
  restore_memory_state(mem_state);
  RML_TAILCALLK(rmlSC);
}
RML_END_LABEL

RML_BEGIN_LABEL(ModelicaExternalC__Streams_5fcountLines)
{
  int fail = 0;
  char* fileName = RML_STRINGDATA(rmlA0);
  MMC_TRY();
    rmlA0 = mk_icon(ModelicaInternal_countLines(fileName));
  MMC_ELSE();
    fail = 1;
  MMC_CATCH();
  if (fail) RML_TAILCALLK(rmlFC);
  RML_TAILCALLK(rmlSC);
}
RML_END_LABEL

RML_BEGIN_LABEL(ModelicaExternalC__File_5ffullPathName)
{
  state mem_state;

  mem_state = get_memory_state();
  char* fileName = RML_STRINGDATA(rmlA0), *res = 0;
  int fail = 0;
  MMC_TRY();
    res = (char*)ModelicaInternal_fullPathName(fileName);
  MMC_ELSE();
    fail = 1;
  MMC_CATCH();
  if (fail) RML_TAILCALLK(rmlFC);
  rmlA0 = mk_scon(res);
  restore_memory_state(mem_state);
  RML_TAILCALLK(rmlSC);
}
RML_END_LABEL

RML_BEGIN_LABEL(ModelicaExternalC__File_5fstat)
{
  char* name = RML_STRINGDATA(rmlA0);
  int res = 0, fail = 0;
  MMC_TRY();
    res = ModelicaInternal_stat(name);
  MMC_ELSE();
    fail = 1;
  MMC_CATCH();
  if (fail) RML_TAILCALLK(rmlFC);
  rmlA0 = mk_icon(res);
  RML_TAILCALLK(rmlSC);
}
RML_END_LABEL

RML_BEGIN_LABEL(ModelicaExternalC__Streams_5fclose)
{
  char* fileName = RML_STRINGDATA(rmlA0);
  int fail = 0;
  MMC_TRY();
    ModelicaStreams_closeFile(fileName);
  MMC_ELSE();
    fail = 1;
  MMC_CATCH();
  if (fail) RML_TAILCALLK(rmlFC);
  RML_TAILCALLK(rmlSC);
}
RML_END_LABEL

RML_BEGIN_LABEL(ModelicaExternalC__Strings_5fadvanced_5fscanReal)
{
  char* str = RML_STRINGDATA(rmlA0);
  int i = RML_UNTAGFIXNUM(rmlA1);
  int unsign = RML_UNTAGFIXNUM(rmlA2);
  int next_ix=0, fail=0;
  double val=0;
  MMC_TRY();
    ModelicaStrings_scanReal(str,i,unsign,&next_ix,&val);
  MMC_ELSE();
    fail = 1;
  MMC_CATCH();
  if (fail) RML_TAILCALLK(rmlFC);
  rmlA0 = mk_icon(next_ix);
  rmlA1 = mk_rcon(val);
  RML_TAILCALLK(rmlSC);
}
RML_END_LABEL

RML_BEGIN_LABEL(ModelicaExternalC__Strings_5fadvanced_5fskipWhiteSpace)
{
  char* str = RML_STRINGDATA(rmlA0);
  int i = RML_UNTAGFIXNUM(rmlA1), fail = 0;
  MMC_TRY();
    rmlA0 = mk_icon(ModelicaStrings_skipWhiteSpace(str,i));
  MMC_ELSE();
    fail = 1;
  MMC_CATCH();
  if (fail) RML_TAILCALLK(rmlFC);
  RML_TAILCALLK(rmlSC);
}
RML_END_LABEL
