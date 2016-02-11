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
 */

#include <stdio.h>
#include <stdlib.h>
#include <stdlib.h>

extern "C" {
#include "meta_modelica.h"
#define ADD_METARECORD_DEFINITIONS static
#include "OpenModelicaBootstrappingHeader.h"
}

#define UNBOX_OFFSET 1
#include "GraphStreamExt_impl.cpp"

extern "C" {

extern void GraphStreamExt_newStream(threadData_t *threadData, const char* streamName, const char* host, int port, int debug)
{
  GraphStreamExtImpl_newStream(
      streamName,
      host,
      port,
      debug);
}

extern void GraphStreamExt_addNode(threadData_t *threadData, const char* streamName, const char* sourceId, int timeId, const char* nodeId)
{
  GraphStreamExtImpl_addNode(
      streamName,
      sourceId,
      timeId,
      nodeId);
}

extern void GraphStreamExt_addEdge(threadData_t *threadData, const char* streamName, const char* sourceId, int timeId, const char* nodeIdSource, const char* nodeIdTarget, int directed)
{
  GraphStreamExtImpl_addEdge(
      streamName,
      sourceId,
      timeId,
      nodeIdSource,
      nodeIdTarget,
      directed);
}

extern void GraphStreamExt_addNodeAttribute(threadData_t *threadData, const char* streamName, const char* sourceId, int timeId, const char* nodeId, const char* attribute, void* value)
{
  GraphStreamExtImpl_addNodeAttribute(
      streamName,
      sourceId,
      timeId,
      nodeId,
      attribute,
      value);
}

extern void GraphStreamExt_addEdgeAttribute(threadData_t *threadData, const char* streamName, const char* sourceId, int timeId, const char* nodeIdSource, const char* nodeIdTarget, const char* attribute, void* value)
{
  GraphStreamExtImpl_addEdgeAttribute(
      streamName,
      sourceId,
      timeId,
      nodeIdSource,
      nodeIdTarget,
      attribute,
      value);
}

extern void GraphStreamExt_addGraphAttribute(threadData_t *threadData, const char* streamName, const char* sourceId, int timeId, const char* attribute, void* value)
{
  GraphStreamExtImpl_addGraphAttribute(
      streamName,
      sourceId,
      timeId,
      attribute,
      value);
}

extern void GraphStreamExt_changeNodeAttribute(threadData_t *threadData, const char* streamName, const char* sourceId, int timeId, const char* nodeId, const char* attribute, void* oldvalue, void* newvalue)
{
  GraphStreamExtImpl_changeNodeAttribute(
      streamName,
      sourceId,
      timeId,
      nodeId,
      attribute,
      oldvalue,
      newvalue);
}

extern void GraphStreamExt_changeEdgeAttribute(threadData_t *threadData, const char* streamName, const char* sourceId, int timeId, const char* nodeIdSource, const char* nodeIdTarget, const char* attribute, void* oldvalue, void* newvalue)
{
  GraphStreamExtImpl_changeEdgeAttribute(
    streamName,
    sourceId,
    timeId,
    nodeIdSource,
    nodeIdTarget,
    attribute,
    oldvalue,
    newvalue);
}

extern void GraphStreamExt_changeGraphAttribute(threadData_t *threadData, const char* streamName, const char* sourceId, int timeId, const char* attribute, void* oldvalue, void* newvalue)
{
  GraphStreamExtImpl_changeGraphAttribute(
    streamName,
    sourceId,
    timeId,
    attribute,
    oldvalue,
    newvalue);
}

extern void GraphStreamExt_cleanup(threadData_t *threadData)
{
  GraphStreamExtImpl_cleanup();
}

}
