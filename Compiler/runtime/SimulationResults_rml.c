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

#include <stdlib.h>
#include "rml.h"
#include "Values.h"
#include "ValuesUtil.h"

#include "SimulationResults.c"
#include "SimulationResultsCmp.c"

void SimulationResults_5finit(void)
{
}

RML_BEGIN_LABEL(SimulationResults__readVariables)
{
  rml_sint_t i,size;
  char* filename = RML_STRINGDATA(rmlA0);

  rmlA0 = SimulationResultsImpl__readVars(filename,&simresglob);
  RML_TAILCALLK(rmlSC);
}
RML_END_LABEL

RML_BEGIN_LABEL(SimulationResults__readDataset)
{
  rmlA0 = (void*)SimulationResultsImpl__readDataset(RML_STRINGDATA(rmlA0),rmlA1,RML_UNTAGFIXNUM(rmlA2),0,&simresglob);

  if (rmlA0 == NULL) {
    RML_TAILCALLK(rmlFC);
  }

  RML_TAILCALLK(rmlSC);
}
RML_END_LABEL

RML_BEGIN_LABEL(SimulationResults__readSimulationResultSize)
{
  char* filename = RML_STRINGDATA(rmlA0);
  rmlA0 = mk_icon(SimulationResultsImpl__readSimulationResultSize(filename,&simresglob));
  RML_TAILCALLK(rmlSC);
}
RML_END_LABEL

RML_BEGIN_LABEL(SimulationResults__val)
{
  rmlA0 = mk_rcon(SimulationResultsImpl__val(RML_STRINGDATA(rmlA0),RML_STRINGDATA(rmlA1),rml_prim_get_real(rmlA2),&simresglob));
  RML_TAILCALLK(rmlSC);
}
RML_END_LABEL

RML_BEGIN_LABEL(SimulationResults__close)
{
  SimulationResultsImpl__close(&simresglob);
  RML_TAILCALLK(rmlSC);
}
RML_END_LABEL

RML_BEGIN_LABEL(SimulationResults__cmpSimulationResults)
{
  rmlA0 = SimulationResultsCmp_compareResults(1,RML_UNTAGFIXNUM(rmlA0),RML_STRINGDATA(rmlA1),RML_STRINGDATA(rmlA2),RML_STRINGDATA(rmlA3),rml_prim_get_real(rmlA4),rml_prim_get_real(rmlA5),0 /*rangeDelta*/,0 /*reltolDiff*/,rmlA6,0,NULL,0,NULL);
  RML_TAILCALLK(rmlSC);
}
RML_END_LABEL


RML_BEGIN_LABEL(SimulationResults__diffSimulationResults)
{
  int res;
  rmlA1 = SimulationResultsCmp_compareResults(0,RML_UNTAGFIXNUM(rmlA0),RML_STRINGDATA(rmlA1),RML_STRINGDATA(rmlA2),RML_STRINGDATA(rmlA3),rml_prim_get_real(rmlA4),0.0/*abstol*/,rml_prim_get_real(rmlA5),rml_prim_get_real(rmlA6),rmlA7,RML_UNTAGFIXNUM(rmlA8),&res,0,NULL);
  rmlA0 = mk_icon(res);
  RML_TAILCALLK(rmlSC);
}
RML_END_LABEL

RML_BEGIN_LABEL(SimulationResults__diffSimulationResultsHtml)
{
  char *res = "";
  SimulationResultsCmp_compareResults(0,RML_UNTAGFIXNUM(rmlA0),RML_STRINGDATA(rmlA1),RML_STRINGDATA(rmlA2),"",rml_prim_get_real(rmlA3),0.0/*abstol*/,rml_prim_get_real(rmlA4),rml_prim_get_real(rmlA5),mk_cons(rmlA6,mk_nil()),0,NULL,1,&res);
  rmlA0 = mk_scon(res);
  RML_TAILCALLK(rmlSC);
}
RML_END_LABEL
