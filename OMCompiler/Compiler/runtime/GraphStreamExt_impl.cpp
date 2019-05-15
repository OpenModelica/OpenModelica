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
#include <iostream>
#include <sstream>

/* include unistd on *nix systems for sleep */
#if !defined(__MINGW32__) && !defined(_MSC_VER)
#include <unistd.h>
#endif

#include "netstream-sender.h"

using namespace std;
using namespace netstream;

static map<string, NetStreamSender *> streams;
static map<string, GS_LONG> streamsTime;

int isInt(void* value) { return (MMC_HDRCTOR(MMC_GETHDR(value)) == Values__INTEGER_3dBOX1); }
GS_LONG getInt(void* value) { return (GS_LONG)(MMC_UNTAGFIXNUM(MMC_STRUCTDATA(value)[UNBOX_OFFSET])); }

int isDouble(void* value) { return (MMC_HDRCTOR(MMC_GETHDR(value)) == Values__REAL_3dBOX1); }
GS_DOUBLE getDouble(void* value) { return (GS_DOUBLE)mmc_prim_get_real(MMC_STRUCTDATA(value)[UNBOX_OFFSET]); }

int isBool(void* value) { return (MMC_HDRCTOR(MMC_GETHDR(value)) == Values__BOOL_3dBOX1); }
GS_BOOL getBool(void* value) { return (GS_BOOL)(MMC_UNTAGFIXNUM(MMC_STRUCTDATA(value)[UNBOX_OFFSET])); }

int isString(void* value) { return (MMC_HDRCTOR(MMC_GETHDR(value)) == Values__STRING_3dBOX1); }
GS_STRING getString(void* value) { return (GS_STRING)(MMC_STRINGDATA(MMC_STRUCTDATA(value)[UNBOX_OFFSET])); }

void GraphStreamExtImpl_newStream(const char* streamName, const char* host, int port, int debug)
{
  NetStreamSender* ns = new NetStreamSender(string(streamName),string(host),port,debug?true:false);
  streams.insert(std::pair<string,NetStreamSender*>(string(streamName),ns));
  streamsTime.insert(std::pair<string,GS_LONG>(string(streamName),(GS_LONG)0L));
}

GS_LONG getTimeId(const char* streamName, int timeId)
{
  GS_LONG timeID = (GS_LONG)timeId;
  if (timeID < 0)
  { /* automatic time id */
    std::map<string,GS_LONG>::iterator it;
    it = streamsTime.find(streamName);
    timeID = it->second;
    it->second = ++timeID;
  }
  return timeID;
}

void GraphStreamExtImpl_addNode(const char* streamName, const char* sourceId, int timeId, const char* nodeId)
{
  NetStreamSender* ns = streams.find(streamName)->second;
  ns->addNode(sourceId,getTimeId(streamName, timeId),nodeId);
}

void GraphStreamExtImpl_addEdge(const char* streamName, const char* sourceId, int timeId, const char* nodeIdSource, const char* nodeIdTarget, int directed)
{
  NetStreamSender* ns = streams.find(streamName)->second;
  stringstream e;
  e << nodeIdSource <<"-"<< nodeIdTarget;
  ns->addEdge(sourceId,getTimeId(streamName, timeId),e.str(),nodeIdSource,nodeIdTarget,directed?true:false);
}

void GraphStreamExtImpl_addNodeAttribute(const char* streamName, const char* sourceId, int timeId, const char* nodeId, const char* attribute, void* value)
{
  NetStreamSender* ns = streams.find(streamName)->second;
  if (isInt(value))    ns->addNodeAttribute(sourceId, getTimeId(streamName, timeId), nodeId, attribute, getInt(value));
  else if (isBool(value))   ns->addNodeAttribute(sourceId, getTimeId(streamName, timeId), nodeId, attribute, getBool(value));
  else if (isDouble(value)) ns->addNodeAttribute(sourceId, getTimeId(streamName, timeId), nodeId, attribute, getDouble(value));
  else if (isString(value)) ns->addNodeAttribute(sourceId, getTimeId(streamName, timeId), nodeId, attribute, getString(value));
  else { fprintf(stderr, "GraphStreamExtImpl: unsupported attribute value [int, bool, real, string]!\n"); fflush(stderr); }
}

void GraphStreamExtImpl_addEdgeAttribute(const char* streamName, const char* sourceId, int timeId, const char* nodeIdSource, const char* nodeIdTarget, const char* attribute, void* value)
{
  NetStreamSender* ns = streams.find(streamName)->second;
  stringstream e;
  e << nodeIdSource <<"-"<< nodeIdTarget;
  if (isInt(value))    ns->addEdgeAttribute(sourceId, getTimeId(streamName, timeId), e.str(), attribute, getInt(value));
  else if (isBool(value))   ns->addEdgeAttribute(sourceId, getTimeId(streamName, timeId), e.str(), attribute, getBool(value));
  else if (isDouble(value)) ns->addEdgeAttribute(sourceId, getTimeId(streamName, timeId), e.str(), attribute, getDouble(value));
  else if (isString(value)) ns->addEdgeAttribute(sourceId, getTimeId(streamName, timeId), e.str(), attribute, getString(value));
  else { fprintf(stderr, "GraphStreamExtImpl: unsupported attribute value [int, bool, real, string]!\n"); fflush(stderr); }
}

void GraphStreamExtImpl_addGraphAttribute(const char* streamName, const char* sourceId, int timeId, const char* attribute, void* value)
{
  NetStreamSender* ns = streams.find(streamName)->second;
  if (isInt(value))    ns->addGraphAttribute(sourceId, getTimeId(streamName, timeId), attribute, getInt(value));
  else if (isBool(value))   ns->addGraphAttribute(sourceId, getTimeId(streamName, timeId), attribute, getBool(value));
  else if (isDouble(value)) ns->addGraphAttribute(sourceId, getTimeId(streamName, timeId), attribute, getDouble(value));
  else if (isString(value)) ns->addGraphAttribute(sourceId, getTimeId(streamName, timeId), attribute, getString(value));
  else { fprintf(stderr, "GraphStreamExtImpl: unsupported attribute value [int, bool, real, string]!\n"); fflush(stderr); }
}

void GraphStreamExtImpl_changeNodeAttribute(const char* streamName, const char* sourceId, int timeId, const char* nodeId, const char* attribute, void* oldvalue, void* newvalue)
{
  NetStreamSender* ns = streams.find(streamName)->second;
  if (isInt(oldvalue) && isInt(newvalue))       ns->changeNodeAttribute(sourceId,getTimeId(streamName, timeId),nodeId,attribute,getInt(oldvalue),getInt(newvalue));
  else if (isInt(oldvalue) && isBool(newvalue))      ns->changeNodeAttribute(sourceId,getTimeId(streamName, timeId),nodeId,attribute,getInt(oldvalue),getBool(newvalue));
  else if (isInt(oldvalue) && isDouble(newvalue))    ns->changeNodeAttribute(sourceId,getTimeId(streamName, timeId),nodeId,attribute,getInt(oldvalue),getDouble(newvalue));
  else if (isInt(oldvalue) && isString(newvalue))    ns->changeNodeAttribute(sourceId,getTimeId(streamName, timeId),nodeId,attribute,getInt(oldvalue),getString(newvalue));

  else if (isBool(oldvalue) && isInt(newvalue))      ns->changeNodeAttribute(sourceId,getTimeId(streamName, timeId),nodeId,attribute,getBool(oldvalue),getInt(newvalue));
  else if (isBool(oldvalue) && isBool(newvalue))     ns->changeNodeAttribute(sourceId,getTimeId(streamName, timeId),nodeId,attribute,getBool(oldvalue),getBool(newvalue));
  else if (isBool(oldvalue) && isDouble(newvalue))   ns->changeNodeAttribute(sourceId,getTimeId(streamName, timeId),nodeId,attribute,getBool(oldvalue),getDouble(newvalue));
  else if (isBool(oldvalue) && isString(newvalue))   ns->changeNodeAttribute(sourceId,getTimeId(streamName, timeId),nodeId,attribute,getBool(oldvalue),getString(newvalue));

  else if (isDouble(oldvalue) && isInt(newvalue))    ns->changeNodeAttribute(sourceId,getTimeId(streamName, timeId),nodeId,attribute,getDouble(oldvalue),getInt(newvalue));
  else if (isDouble(oldvalue) && isBool(newvalue))   ns->changeNodeAttribute(sourceId,getTimeId(streamName, timeId),nodeId,attribute,getDouble(oldvalue),getBool(newvalue));
  else if (isDouble(oldvalue) && isDouble(newvalue)) ns->changeNodeAttribute(sourceId,getTimeId(streamName, timeId),nodeId,attribute,getDouble(oldvalue),getDouble(newvalue));
  else if (isDouble(oldvalue) && isString(newvalue)) ns->changeNodeAttribute(sourceId,getTimeId(streamName, timeId),nodeId,attribute,getDouble(oldvalue),getString(newvalue));

  else if (isString(oldvalue) && isInt(newvalue))    ns->changeNodeAttribute(sourceId,getTimeId(streamName, timeId),nodeId,attribute,getString(oldvalue),getInt(newvalue));
  else if (isString(oldvalue) && isBool(newvalue))   ns->changeNodeAttribute(sourceId,getTimeId(streamName, timeId),nodeId,attribute,getString(oldvalue),getBool(newvalue));
  else if (isString(oldvalue) && isDouble(newvalue)) ns->changeNodeAttribute(sourceId,getTimeId(streamName, timeId),nodeId,attribute,getString(oldvalue),getDouble(newvalue));
  else if (isString(oldvalue) && isString(newvalue)) ns->changeNodeAttribute(sourceId,getTimeId(streamName, timeId),nodeId,attribute,getString(oldvalue),getString(newvalue));
  else { fprintf(stderr, "GraphStreamExtImpl: unsupported attribute value [int, bool, real, string]!\n"); fflush(stderr); }
}

void GraphStreamExtImpl_changeEdgeAttribute(const char* streamName, const char* sourceId, int timeId, const char* nodeIdSource, const char* nodeIdTarget, const char* attribute, void* oldvalue, void* newvalue)
{
  NetStreamSender* ns = streams.find(streamName)->second;
  stringstream e;
  e << nodeIdSource <<"-"<< nodeIdTarget;
  if (isInt(oldvalue) && isInt(newvalue))       ns->changeEdgeAttribute(sourceId,getTimeId(streamName, timeId),e.str(),attribute,getInt(oldvalue),getInt(newvalue));
  else if (isInt(oldvalue) && isBool(newvalue))      ns->changeEdgeAttribute(sourceId,getTimeId(streamName, timeId),e.str(),attribute,getInt(oldvalue),getBool(newvalue));
  else if (isInt(oldvalue) && isDouble(newvalue))    ns->changeEdgeAttribute(sourceId,getTimeId(streamName, timeId),e.str(),attribute,getInt(oldvalue),getDouble(newvalue));
  else if (isInt(oldvalue) && isString(newvalue))    ns->changeEdgeAttribute(sourceId,getTimeId(streamName, timeId),e.str(),attribute,getInt(oldvalue),getString(newvalue));

  else if (isBool(oldvalue) && isInt(newvalue))      ns->changeEdgeAttribute(sourceId,getTimeId(streamName, timeId),e.str(),attribute,getBool(oldvalue),getInt(newvalue));
  else if (isBool(oldvalue) && isBool(newvalue))     ns->changeEdgeAttribute(sourceId,getTimeId(streamName, timeId),e.str(),attribute,getBool(oldvalue),getBool(newvalue));
  else if (isBool(oldvalue) && isDouble(newvalue))   ns->changeEdgeAttribute(sourceId,getTimeId(streamName, timeId),e.str(),attribute,getBool(oldvalue),getDouble(newvalue));
  else if (isBool(oldvalue) && isString(newvalue))   ns->changeEdgeAttribute(sourceId,getTimeId(streamName, timeId),e.str(),attribute,getBool(oldvalue),getString(newvalue));

  else if (isDouble(oldvalue) && isInt(newvalue))    ns->changeEdgeAttribute(sourceId,getTimeId(streamName, timeId),e.str(),attribute,getDouble(oldvalue),getInt(newvalue));
  else if (isDouble(oldvalue) && isBool(newvalue))   ns->changeEdgeAttribute(sourceId,getTimeId(streamName, timeId),e.str(),attribute,getDouble(oldvalue),getBool(newvalue));
  else if (isDouble(oldvalue) && isDouble(newvalue)) ns->changeEdgeAttribute(sourceId,getTimeId(streamName, timeId),e.str(),attribute,getDouble(oldvalue),getDouble(newvalue));
  else if (isDouble(oldvalue) && isString(newvalue)) ns->changeEdgeAttribute(sourceId,getTimeId(streamName, timeId),e.str(),attribute,getDouble(oldvalue),getString(newvalue));

  else if (isString(oldvalue) && isInt(newvalue))    ns->changeEdgeAttribute(sourceId,getTimeId(streamName, timeId),e.str(),attribute,getString(oldvalue),getInt(newvalue));
  else if (isString(oldvalue) && isBool(newvalue))   ns->changeEdgeAttribute(sourceId,getTimeId(streamName, timeId),e.str(),attribute,getString(oldvalue),getBool(newvalue));
  else if (isString(oldvalue) && isDouble(newvalue)) ns->changeEdgeAttribute(sourceId,getTimeId(streamName, timeId),e.str(),attribute,getString(oldvalue),getDouble(newvalue));
  else if (isString(oldvalue) && isString(newvalue)) ns->changeEdgeAttribute(sourceId,getTimeId(streamName, timeId),e.str(),attribute,getString(oldvalue),getString(newvalue));
  else { fprintf(stderr, "GraphStreamExtImpl: unsupported attribute value [int, bool, real, string]!\n"); fflush(stderr); }
}

void GraphStreamExtImpl_changeGraphAttribute(const char* streamName, const char* sourceId, int timeId, const char* attribute, void* oldvalue, void* newvalue)
{
  NetStreamSender* ns = streams.find(streamName)->second;
  if (isInt(oldvalue) && isInt(newvalue))       ns->changeGraphAttribute(sourceId,getTimeId(streamName, timeId),attribute,getInt(oldvalue),getInt(newvalue));
  else if (isInt(oldvalue) && isBool(newvalue))      ns->changeGraphAttribute(sourceId,getTimeId(streamName, timeId),attribute,getInt(oldvalue),getBool(newvalue));
  else if (isInt(oldvalue) && isDouble(newvalue))    ns->changeGraphAttribute(sourceId,getTimeId(streamName, timeId),attribute,getInt(oldvalue),getDouble(newvalue));
  else if (isInt(oldvalue) && isString(newvalue))    ns->changeGraphAttribute(sourceId,getTimeId(streamName, timeId),attribute,getInt(oldvalue),getString(newvalue));

  else if (isBool(oldvalue) && isInt(newvalue))      ns->changeGraphAttribute(sourceId,getTimeId(streamName, timeId),attribute,getBool(oldvalue),getInt(newvalue));
  else if (isBool(oldvalue) && isBool(newvalue))     ns->changeGraphAttribute(sourceId,getTimeId(streamName, timeId),attribute,getBool(oldvalue),getBool(newvalue));
  else if (isBool(oldvalue) && isDouble(newvalue))   ns->changeGraphAttribute(sourceId,getTimeId(streamName, timeId),attribute,getBool(oldvalue),getDouble(newvalue));
  else if (isBool(oldvalue) && isString(newvalue))   ns->changeGraphAttribute(sourceId,getTimeId(streamName, timeId),attribute,getBool(oldvalue),getString(newvalue));

  else if (isDouble(oldvalue) && isInt(newvalue))    ns->changeGraphAttribute(sourceId,getTimeId(streamName, timeId),attribute,getDouble(oldvalue),getInt(newvalue));
  else if (isDouble(oldvalue) && isBool(newvalue))   ns->changeGraphAttribute(sourceId,getTimeId(streamName, timeId),attribute,getDouble(oldvalue),getBool(newvalue));
  else if (isDouble(oldvalue) && isDouble(newvalue)) ns->changeGraphAttribute(sourceId,getTimeId(streamName, timeId),attribute,getDouble(oldvalue),getDouble(newvalue));
  else if (isDouble(oldvalue) && isString(newvalue)) ns->changeGraphAttribute(sourceId,getTimeId(streamName, timeId),attribute,getDouble(oldvalue),getString(newvalue));

  else if (isString(oldvalue) && isInt(newvalue))    ns->changeGraphAttribute(sourceId,getTimeId(streamName, timeId),attribute,getString(oldvalue),getInt(newvalue));
  else if (isString(oldvalue) && isBool(newvalue))   ns->changeGraphAttribute(sourceId,getTimeId(streamName, timeId),attribute,getString(oldvalue),getBool(newvalue));
  else if (isString(oldvalue) && isDouble(newvalue)) ns->changeGraphAttribute(sourceId,getTimeId(streamName, timeId),attribute,getString(oldvalue),getDouble(newvalue));
  else if (isString(oldvalue) && isString(newvalue)) ns->changeGraphAttribute(sourceId,getTimeId(streamName, timeId),attribute,getString(oldvalue),getString(newvalue));
  else { fprintf(stderr, "GraphStreamExtImpl: unsupported attribute value [int, bool, real, string]!\n"); fflush(stderr); }
}

void GraphStreamExtImpl_cleanup()
{
  std::map<string,NetStreamSender*>::iterator it;
  for(it = streams.begin(); it != streams.end(); it++)
  {
    delete it->second;
    it->second = NULL;
  }
}
