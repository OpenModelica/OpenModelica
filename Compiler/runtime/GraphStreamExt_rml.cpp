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

/*
 * RCS: $Id: GraphStreamExt_rml.cpp 2014-02-04 mwalther $
 */

#include <stdlib.h>

extern "C" {
#include "rml.h"
#include "Values.h"
}

#define UNBOX_OFFSET 0
#include "GraphStreamExt_impl.cpp"

extern "C" {


void GraphStreamExt_5finit(void)
{

}

RML_BEGIN_LABEL(GraphStreamExt__newStream)
{
  GraphStreamExtImpl_newStream(
    RML_STRINGDATA(rmlA0),
    RML_STRINGDATA(rmlA1),
    RML_UNTAGFIXNUM(rmlA2),
    RML_UNTAGFIXNUM(rmlA3));
  RML_TAILCALLK(rmlSC);
}
RML_END_LABEL

RML_BEGIN_LABEL(GraphStreamExt__addNode)
{
  GraphStreamExtImpl_addNode(
    RML_STRINGDATA(rmlA0),
    RML_STRINGDATA(rmlA1),
    RML_UNTAGFIXNUM(rmlA2),
    RML_STRINGDATA(rmlA3));
  RML_TAILCALLK(rmlSC);
}
RML_END_LABEL

RML_BEGIN_LABEL(GraphStreamExt__addEdge)
{
  GraphStreamExtImpl_addEdge(
    RML_STRINGDATA(rmlA0),
    RML_STRINGDATA(rmlA1),
    RML_UNTAGFIXNUM(rmlA2),
    RML_STRINGDATA(rmlA3),
    RML_STRINGDATA(rmlA4),
    RML_UNTAGFIXNUM(rmlA5));
  RML_TAILCALLK(rmlSC);
}
RML_END_LABEL

RML_BEGIN_LABEL(GraphStreamExt__addNodeAttribute)
{
  GraphStreamExtImpl_addNodeAttribute(
    RML_STRINGDATA(rmlA0),
    RML_STRINGDATA(rmlA1),
    RML_UNTAGFIXNUM(rmlA2),
    RML_STRINGDATA(rmlA3),
    RML_STRINGDATA(rmlA4),
    rmlA5);
  sleep(2);
  RML_TAILCALLK(rmlSC);
}
RML_END_LABEL

RML_BEGIN_LABEL(GraphStreamExt__addEdgeAttribute)
{
  GraphStreamExtImpl_addEdgeAttribute(
    RML_STRINGDATA(rmlA0),
    RML_STRINGDATA(rmlA1),
    RML_UNTAGFIXNUM(rmlA2),
    RML_STRINGDATA(rmlA3),
    RML_STRINGDATA(rmlA4),
    RML_STRINGDATA(rmlA5),
    rmlA6);
  RML_TAILCALLK(rmlSC);
}
RML_END_LABEL

RML_BEGIN_LABEL(GraphStreamExt__addGraphAttribute)
{
  GraphStreamExtImpl_addGraphAttribute(
    RML_STRINGDATA(rmlA0),
    RML_STRINGDATA(rmlA1),
    RML_UNTAGFIXNUM(rmlA2),
    RML_STRINGDATA(rmlA3),
    rmlA4);
  RML_TAILCALLK(rmlSC);
}
RML_END_LABEL

RML_BEGIN_LABEL(GraphStreamExt__changeNodeAttribute)
{
  GraphStreamExtImpl_changeNodeAttribute(
    RML_STRINGDATA(rmlA0),
    RML_STRINGDATA(rmlA1),
    RML_UNTAGFIXNUM(rmlA2),
    RML_STRINGDATA(rmlA3),
    RML_STRINGDATA(rmlA4),
    rmlA5,
    rmlA6);
  RML_TAILCALLK(rmlSC);
}
RML_END_LABEL

RML_BEGIN_LABEL(GraphStreamExt__changeEdgeAttribute)
{
  GraphStreamExtImpl_changeEdgeAttribute(
      RML_STRINGDATA(rmlA0),
      RML_STRINGDATA(rmlA1),
      RML_UNTAGFIXNUM(rmlA2),
      RML_STRINGDATA(rmlA3),
      RML_STRINGDATA(rmlA4),
      RML_STRINGDATA(rmlA5),
      rmlA6,
      rmlA7);
  RML_TAILCALLK(rmlSC);
}
RML_END_LABEL

RML_BEGIN_LABEL(GraphStreamExt__changeGraphAttribute)
{
  GraphStreamExtImpl_changeGraphAttribute(
    RML_STRINGDATA(rmlA0),
    RML_STRINGDATA(rmlA1),
    RML_UNTAGFIXNUM(rmlA2),
    RML_STRINGDATA(rmlA3),
    rmlA4,
    rmlA5);
  RML_TAILCALLK(rmlSC);
}
RML_END_LABEL


RML_BEGIN_LABEL(GraphStreamExt__cleanup)
{
  GraphStreamExtImpl_cleanup();
  RML_TAILCALLK(rmlSC);
}
RML_END_LABEL

}
