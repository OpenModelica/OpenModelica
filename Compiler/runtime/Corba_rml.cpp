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

// includes for both linux and windows
extern "C" {
#include "../Values.h"
#include "rml.h"
}
#include "corbaimpl.cpp"
extern "C" {

void Corba_5finit(void)
{

}

RML_BEGIN_LABEL(Corba__haveCorba)
{
  rmlA0 = mk_icon(1);
  RML_TAILCALLK(rmlSC);
}
RML_END_LABEL

RML_BEGIN_LABEL(Corba__setObjectReferenceFilePath)
{
  const char *path = RML_STRINGDATA(rmlA0);
  CorbaImpl__setObjectReferenceFilePath(path);
  RML_TAILCALLK(rmlSC);
}
RML_END_LABEL

RML_BEGIN_LABEL(Corba__setSessionName)
{
  const char *name = RML_STRINGDATA(rmlA0);
  CorbaImpl__setSessionName(name);
  RML_TAILCALLK(rmlSC);
}
RML_END_LABEL

RML_BEGIN_LABEL(Corba__initialize)
{
  if (CorbaImpl__initialize()) RML_TAILCALLK(rmlFC);
  RML_TAILCALLK(rmlSC);
}
RML_END_LABEL

RML_BEGIN_LABEL(Corba__waitForCommand)
{
  rmlA0=mk_scon(CorbaImpl__waitForCommand());
  RML_TAILCALLK(rmlSC);
}
RML_END_LABEL

RML_BEGIN_LABEL(Corba__sendreply)
{
  const char *msg=RML_STRINGDATA(rmlA0);
  CorbaImpl__sendreply(msg);
  RML_TAILCALLK(rmlSC);
}
RML_END_LABEL

RML_BEGIN_LABEL(Corba__close)
{
  CorbaImpl__close();
  RML_TAILCALLK(rmlSC);
}
RML_END_LABEL

}
