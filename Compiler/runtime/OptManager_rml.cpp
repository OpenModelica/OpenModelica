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

#include "optmanager.cpp"

#include "rml.h"

extern "C" {

// For all options to be used, add an initial value here.
void OptManager_5finit(void)
{
}

RML_BEGIN_LABEL(OptManager__dumpOptions)
{
  OptManagerImpl__dumpOptions();
  RML_TAILCALLK(rmlSC);
}
RML_END_LABEL

RML_BEGIN_LABEL(OptManager__setOption)
{
  char *strEntry = RML_STRINGDATA(rmlA0);
  bool strValue = RML_PRIM_MKBOOL(rmlA1);
  if (OptManagerImpl__setOption(strEntry,strValue))
    RML_TAILCALLK(rmlFC);
  else
    RML_TAILCALLK(rmlSC);
}
RML_END_LABEL

RML_BEGIN_LABEL(OptManager__getOption)
{
  char *strEntry = RML_STRINGDATA(rmlA0);
  int res = OptManagerImpl__getOption(strEntry);
  if (res == -1)
    RML_TAILCALLK(rmlFC);
  rmlA0 = mk_bcon(res);
  RML_TAILCALLK(rmlSC);
}
RML_END_LABEL

}
