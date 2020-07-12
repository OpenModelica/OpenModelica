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
#include "meta/meta_modelica.h"

#define ADD_METARECORD_DEFINITIONS static
#if defined(OMC_BOOTSTRAPPING)
  #include "../boot/tarball-include/OpenModelicaBootstrappingHeader.h"
#else
  #include "../OpenModelicaBootstrappingHeader.h"
#endif
}

#define UNBOX_OFFSET 1
#if !defined(_MSC_VER)
#include "GraphStreamExt_impl.cpp"
#else
#include "errorext.h"
#define GRAPHSTREAM_MSVS() c_add_message(NULL, -1, ErrorType_scripting, ErrorLevel_error, "Graphstream not supported on Visual Studio.", NULL, 0);MMC_THROW();
#endif

extern "C" {

extern void GraphStreamExt_newStream(threadData_t *threadData, const char* streamName, const char* host, int port, int debug)
{
#if defined(_MSC_VER)
  GRAPHSTREAM_MSVS();
#else
  GraphStreamExtImpl_newStream(
      streamName,
      host,
      port,
      debug);
#endif
}

extern void GraphStreamExt_addNode(threadData_t *threadData, const char* streamName, const char* sourceId, int timeId, const char* nodeId)
{
#if defined(_MSC_VER)
  GRAPHSTREAM_MSVS();
#else
  GraphStreamExtImpl_addNode(
      streamName,
      sourceId,
      timeId,
      nodeId);
#endif
}

extern void GraphStreamExt_addEdge(threadData_t *threadData, const char* streamName, const char* sourceId, int timeId, const char* nodeIdSource, const char* nodeIdTarget, int directed)
{
#if defined(_MSC_VER)
  GRAPHSTREAM_MSVS();
#else
  GraphStreamExtImpl_addEdge(
      streamName,
      sourceId,
      timeId,
      nodeIdSource,
      nodeIdTarget,
      directed);
#endif
}

extern void GraphStreamExt_addNodeAttribute(threadData_t *threadData, const char* streamName, const char* sourceId, int timeId, const char* nodeId, const char* attribute, void* value)
{
#if defined(_MSC_VER)
  GRAPHSTREAM_MSVS();
#else
  GraphStreamExtImpl_addNodeAttribute(
      streamName,
      sourceId,
      timeId,
      nodeId,
      attribute,
      value);
#endif
}

extern void GraphStreamExt_addEdgeAttribute(threadData_t *threadData, const char* streamName, const char* sourceId, int timeId, const char* nodeIdSource, const char* nodeIdTarget, const char* attribute, void* value)
{
#if defined(_MSC_VER)
  GRAPHSTREAM_MSVS();
#else
  GraphStreamExtImpl_addEdgeAttribute(
      streamName,
      sourceId,
      timeId,
      nodeIdSource,
      nodeIdTarget,
      attribute,
      value);
#endif
}

extern void GraphStreamExt_addGraphAttribute(threadData_t *threadData, const char* streamName, const char* sourceId, int timeId, const char* attribute, void* value)
{
#if defined(_MSC_VER)
  GRAPHSTREAM_MSVS();
#else
  GraphStreamExtImpl_addGraphAttribute(
      streamName,
      sourceId,
      timeId,
      attribute,
      value);
#endif
}

extern void GraphStreamExt_changeNodeAttribute(threadData_t *threadData, const char* streamName, const char* sourceId, int timeId, const char* nodeId, const char* attribute, void* oldvalue, void* newvalue)
{
#if defined(_MSC_VER)
  GRAPHSTREAM_MSVS();
#else
  GraphStreamExtImpl_changeNodeAttribute(
      streamName,
      sourceId,
      timeId,
      nodeId,
      attribute,
      oldvalue,
      newvalue);
#endif
}

extern void GraphStreamExt_changeEdgeAttribute(threadData_t *threadData, const char* streamName, const char* sourceId, int timeId, const char* nodeIdSource, const char* nodeIdTarget, const char* attribute, void* oldvalue, void* newvalue)
{
#if defined(_MSC_VER)
  GRAPHSTREAM_MSVS();
#else
  GraphStreamExtImpl_changeEdgeAttribute(
    streamName,
    sourceId,
    timeId,
    nodeIdSource,
    nodeIdTarget,
    attribute,
    oldvalue,
    newvalue);
#endif
}

extern void GraphStreamExt_changeGraphAttribute(threadData_t *threadData, const char* streamName, const char* sourceId, int timeId, const char* attribute, void* oldvalue, void* newvalue)
{
#if defined(_MSC_VER)
  GRAPHSTREAM_MSVS();
#else
  GraphStreamExtImpl_changeGraphAttribute(
    streamName,
    sourceId,
    timeId,
    attribute,
    oldvalue,
    newvalue);
#endif
}

extern void GraphStreamExt_cleanup(threadData_t *threadData)
{
#if defined(_MSC_VER)
  GRAPHSTREAM_MSVS();
#else
  GraphStreamExtImpl_cleanup();
#endif
}

}
