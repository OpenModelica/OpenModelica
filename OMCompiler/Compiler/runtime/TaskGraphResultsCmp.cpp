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

#if !defined(_MSC_VER)

#include "TaskGraphResultsCmp.h"
#include <sys/stat.h>
#include "util/omc_file.h"

Node::Node() : id(""), name(""), calcTime(-1), threadId(""), taskNumber(-1), taskId(-1), simCodeEqs()
{
}

Node::Node(std::string id, std::string name, double calcTime, std::string threadId, int taskNumber, int taskId, std::list<int> simCodeEqs)
  : id(id), name(name), calcTime(calcTime), threadId(threadId), taskNumber(taskNumber), taskId(taskId), simCodeEqs(simCodeEqs)
{

}

Node::~Node()
{

}

Edge::Edge() : id(""), sourceId(""), sourceName(""), targetId(""), targetName(""), commTime(-1)
{

}

Edge::Edge(std::string id, std::string sourceId, std::string sourceName, std::string targetId, std::string targetName, double commTime)
  : id(id), sourceId(sourceId), sourceName(sourceName), targetId(targetId), targetName(targetName), commTime(commTime)
{

}

Edge::~Edge()
{

}

Graph::Graph(void) :
    nodes(), edges(), criticalPathInfo("")
{
}

Graph::~Graph(void)
{
  for (std::list<Node*>::iterator i = nodes.begin(); i != nodes.end(); ++i)
  {
    Node *nodePtr = *i;
    delete nodePtr;
  }
  nodes.clear();

  for (std::list<Edge*>::iterator i = edges.begin(); i != edges.end(); ++i)
  {
    Edge *edgePtr = *i;
    delete edgePtr;
  }
  edges.clear();
}

void Graph::AddNode(Node *node)
{
  nodes.push_back(node);
}

void Graph::RemoveNode(Node *node)
{
  nodes.remove(node);
}

int Graph::NodeCount()
{
  return nodes.size();
}

Node* Graph::GetNode(int index)
{
  if (NodeCount() <= index)
    return 0;

  std::list<Node*>::iterator iter = nodes.begin();
  std::advance(iter, index);
  return *iter;
}

void Graph::AddEdge(Edge *edge)
{
  edges.push_back(edge);
}

void Graph::RemoveEdge(Edge *edge)
{
  edges.remove(edge);
}

int Graph::EdgeCount()
{
  return edges.size();
}

Edge* Graph::GetEdge(int index)
{
  if (EdgeCount() <= index)
    return 0;

  std::list<Edge*>::iterator iter = edges.begin();
  std::advance(iter, index);
  return *iter;
}

GraphParser::GraphParser()
{

}

GraphParser::~GraphParser()
{

}

bool GraphParser::CheckIfFileExists(const char* fileName)
{
  return omc_file_exists(fileName);
}

GraphMLParser::GraphMLParser() : GraphParser()
{
}

GraphMLParser::~GraphMLParser()
{
}

void GraphMLParser::StartElement(void *data, const XML_Char *name, const XML_Char **attribute)
{
  ParserUserData *userData = (ParserUserData *) data;

  //get rid of the xml-namespace
  std::string name_wo_ns = RemoveNamespace(name);
  userData->level++;

  //check if the element is a key-element
  if ((userData->level == 2) && (name_wo_ns.compare("key") == 0))
  {
    for (int i = 0; attribute[i]; i += 2)
    {
      if(strcmp("attr.name", attribute[i]) != 0)
        continue;

      if (strcmp("CommCost", attribute[i + 1]) == 0)
      {
        for (int j = 0; attribute[j]; j += 2)
        {
          if (strcmp("id", attribute[j]) == 0)
            userData->commCostAttributeId = attribute[j + 1];
        }
      }
      else if (strcmp("CalcTime", attribute[i + 1]) == 0)
      {
        for (int j = 0; attribute[j]; j += 2)
        {
          if (strcmp("id", attribute[j]) == 0)
            userData->calcTimeAttributeId = attribute[j + 1];
        }
      }
      else if (strcmp("CriticalPath", attribute[i + 1]) == 0)
      {
        for (int j = 0; attribute[j]; j += 2)
        {
          if (strcmp("id", attribute[j]) == 0)
            userData->criticalPathAttributeId = attribute[j + 1];
        }
      }
      else if (strcmp("Name", attribute[i + 1]) == 0)
      {
        for (int j = 0; attribute[j]; j += 2)
        {
          if (strcmp("id", attribute[j]) == 0)
            userData->nameAttributeId = attribute[j + 1];
        }
      }
      else if (strcmp("ThreadId", attribute[i + 1]) == 0)
      {
        for (int j = 0; attribute[j]; j += 2)
        {
          if (strcmp("id", attribute[j]) == 0)
            userData->threadIdAttributeId = attribute[j + 1];
        }
      }
      else if (strcmp("TaskNumber", attribute[i + 1]) == 0)
      {
        for (int j = 0; attribute[j]; j += 2)
        {
          if (strcmp("id", attribute[j]) == 0)
            userData->taskNumberAttributeId = attribute[j + 1];
        }
      }
      else if (strcmp("TaskID", attribute[i + 1]) == 0)
      {
        for (int j = 0; attribute[j]; j += 2)
        {
          if (strcmp("id", attribute[j]) == 0)
            userData->taskIdAttributeId = attribute[j + 1];
        }
      }
    }
  }

  //check if the element is a node-element
  if ((userData->level == 3) && (name_wo_ns.compare("node") == 0))
  {
    //find id-attribute
    for (int i = 0; attribute[i]; i += 2)
    {
      if (strcmp("id", attribute[i]) == 0)
      {
        userData->currentNode = new Node();
        userData->currentNode->id = attribute[i + 1];
      }
    }
    //don't add the node to the node-set, because the DataElement-method has to fill the node-name first
  }

  //check if the element is a data element of node or edge
  if ((userData->level == 4) && (name_wo_ns.compare("data") == 0))
  {
    for (int i = 0; attribute[i]; i += 2)
    {
      if(strcmp("key", attribute[i]) != 0)
        continue;

      if (strcmp(userData->commCostAttributeId.c_str(), attribute[i + 1]) == 0 && userData->currentEdge != 0)
      {
        userData->readDoubleValue = true;
        userData->doubleValue = &userData->currentEdge->commTime;
      }
      else if (strcmp(userData->calcTimeAttributeId.c_str(), attribute[i + 1]) == 0 && userData->currentNode != 0)
      {
        userData->readDoubleValue = true;
        userData->doubleValue = &userData->currentNode->calcTime;
      }
      else if (strcmp(userData->nameAttributeId.c_str(), attribute[i + 1]) == 0 && userData->currentNode != 0)
      {
        userData->readStringValue = true;
        userData->stringValue = &userData->currentNode->name;
      }
      else if (strcmp(userData->threadIdAttributeId.c_str(), attribute[i + 1]) == 0 && userData->currentNode != 0)
      {
        userData->readStringValue = true;
        userData->stringValue = &userData->currentNode->threadId;
      }
      else if (strcmp(userData->taskNumberAttributeId.c_str(), attribute[i + 1]) == 0 && userData->currentNode != 0)
      {
        userData->readIntValue = true;
        userData->intValue = &userData->currentNode->taskNumber;
      }
      else if (strcmp(userData->taskIdAttributeId.c_str(), attribute[i + 1]) == 0 && userData->currentNode != 0)
      {
        userData->readIntValue = true;
        userData->intValue = &userData->currentNode->taskId;
      }
    }
  }

  //check if the element is a data element of graph
  if ((userData->level == 3) && (name_wo_ns.compare("data") == 0))
  {
    for (int i = 0; attribute[i]; i += 2)
    {
      if (strcmp("key", attribute[i]) == 0 && strcmp(userData->criticalPathAttributeId.c_str(), attribute[i + 1]) == 0 && userData->currentGraph != 0)
      {
        userData->readStringValue = true;
        userData->stringValue = &userData->currentGraph->criticalPathInfo;
      }
    }
  }

  //check if the element is the NodeLabel of the node element
  //if ((userData->level == 6) && (name_wo_ns.compare("NodeLabel") == 0) && (userData->currentNode != 0))
  //{
  //  userData->readStringValue = true;
  //  userData->stringValue = &userData->currentNode->name;
  //}

  //check if the element is an edge
  if ((userData->level == 3) && (name_wo_ns.compare("edge") == 0))
  {
    //Parse the edge-object
    Edge* edge = new Edge();
    std::string id = "";
    std::string target = "";
    std::string source = "";

    for (int i = 0; attribute[i]; i += 2)
    {
      if (strcmp("id", attribute[i]) == 0)
        id = std::string(attribute[i + 1]);
      else if (strcmp("source", attribute[i]) == 0)
        source = std::string(attribute[i + 1]);
      else if (strcmp("target", attribute[i]) == 0)
        target = std::string(attribute[i + 1]);
    }
    if (id.length() == 0)
      *(userData->errorMsg) += "Warning: edge without id defined\n";
    else
    {
      edge->id = id;
    }

    if (source.length() == 0)
      *(userData->errorMsg) += "Warning: edge without source defined\n";
    else
    {
      edge->sourceId = source;
    }

    if (target.length() == 0)
      *(userData->errorMsg) += "Warning: edge without target defined\n";
    else
    {
      edge->targetId = target;
    }
    //userData->currentGraph->AddEdge(edge);
    userData->currentEdge = edge;
  }
}

void GraphMLParser::EndElement(void *data, const XML_Char *name)
{
  ParserUserData *userData = (ParserUserData *) data;
  std::string name_wo_ns = RemoveNamespace(name);

  if ((userData->level == 3) && (name_wo_ns.compare("node") == 0))
  {
    //Now the node-object should have all important informations, so add it to the node-set
    std::pair<std::set<Node*>::iterator, bool> insertReturn = userData->nodeSet->insert(userData->currentNode);

    if (!insertReturn.second)
    {
      std::stringstream ss;
      ss << "Warning: a node with the name '" << userData->currentNode->name << "' was added multiple times to graph." << std::endl;
      (*(userData->errorMsg)) += ss.str().c_str();
    }

    userData->currentNode = 0;
  }

  if ((userData->level == 3) && (name_wo_ns.compare("edge") == 0))
  {
    userData->currentGraph->AddEdge(userData->currentEdge);
    userData->currentEdge = 0;
  }
  userData->level--;
}

void GraphMLParser::DataElement(void* data, const XML_Char* text, int textLength)
{
  ParserUserData *userData = (ParserUserData *) data;

  if (userData->readStringValue && userData->stringValue != 0)
  {
    *userData->stringValue = std::string((const char*) text, textLength);
    //userData->currentNode->name = std::string((const char*)text, textLength);
    userData->readStringValue = false;
    userData->stringValue = 0;
  }

  if (userData->readDoubleValue && userData->doubleValue != 0)
  {
    *userData->doubleValue = atof(text);
    userData->readDoubleValue = false;
    userData->doubleValue = 0;
  }

  if (userData->readIntValue && userData->intValue != 0)
  {
    *userData->intValue = atoi(text);
    userData->readIntValue = false;
    userData->intValue = 0;
  }
}

std::string GraphMLParser::RemoveNamespace(const char* name)
{
  std::string sName = std::string(name);
  size_t sepPosition = sName.rfind(':');

  // did we find a seperator
  if ((sepPosition > 0) && (sepPosition < sName.length()))
  {
    const std::string shortName = sName.substr(sepPosition + 1);
    return shortName;
  }

  return name;
}

void GraphMLParser::ParseGraph(Graph *currentGraph, const char* fileName, NodeComparator nodeComparator, std::string *_errorMsg)
{
  //We have to use expat which makes simple parsing really complicated :)
  std::FILE *graphFile;

  XML_Parser parser;
  int len; /* len is the number of bytes in the current buffer of data */
  int done = 0;

  ParserUserData userData = ParserUserData();

  //Create a new graph first
  userData.currentGraph = currentGraph;
  //Stores the level of the current xml-element
  userData.level = 0;
  userData.currentNode = 0;
  userData.readStringValue = false;
  userData.stringValue = 0;
  userData.readDoubleValue = false;
  userData.doubleValue = 0;
  userData.readIntValue = false;
  userData.intValue = 0;
  userData.nodeSet = new std::set<Node*, NodeComparator>(nodeComparator);
  userData.errorMsg = _errorMsg;
  graphFile = omc_fopen(fileName, "rb");
  parser = XML_ParserCreate(NULL);
  XML_SetUserData(parser, &userData);
  XML_SetElementHandler(parser, StartElement, EndElement);
  XML_SetCharacterDataHandler(parser, DataElement);

  //Get file length
  fseek(graphFile, 0, SEEK_END);
  const int bufferSize = ftell(graphFile);
  char* buffer = (char *) malloc(bufferSize + 1);
  fseek(graphFile, 0, SEEK_SET);

  do
  {
    //Read the graphml-file piece by piece
    len = std::fread(buffer, sizeof(char), bufferSize, graphFile);
    //std::cout << buffer;
    if (len < bufferSize)
      done = true;

    if (XML_Parse(parser, buffer, len, done) == XML_STATUS_ERROR)
    {
      *(userData.errorMsg) += "Error during xml-parsing\n";
      break;
    }
  } while (!done);
  XML_ParserFree(parser);
  fclose(graphFile);

  //Add all elements of the node-set to the graph
  for (std::set<Node*, bool (*)(Node*, Node*)>::iterator iter = userData.nodeSet->begin(); iter != userData.nodeSet->end(); iter++)
  {
    Node *node = *iter;
    userData.currentGraph->AddNode(node);
  }

  delete userData.nodeSet;
  userData.currentNode = 0;
}

GraphCodeParser::GraphCodeParser() : GraphParser()
{
}

GraphCodeParser::~GraphCodeParser()
{
}

std::string GraphCodeParser::Trim(const std::string& str)
{
  const std::string& whitespace = " \t";
    const size_t strBegin = str.find_first_not_of(whitespace);
    if (strBegin == std::string::npos)
        return ""; // no content

    const size_t strEnd = str.find_last_not_of(whitespace);
    const size_t strRange = strEnd - strBegin + 1;

    return str.substr(strBegin, strRange);
}

void GraphCodeParser::ParseGraph(Graph *currentGraph, const char* fileName,NodeComparator nodeComparator, std::string *_errorMsg)
{
  std::string line;
  const int MAX_MATCHES=1;
  regmatch_t matches[MAX_MATCHES];
  regex_t nodeRegex, nodeParentRegex, nodeDependencyRegex;

  std::ifstream infile(fileName);

  if(regcomp(&nodeRegex, "^[ \t]*//[ \t]*TG_NODE: [0-9]*$", REG_EXTENDED) != 0)
  {
    *_errorMsg = _errorMsg->append("Failed to compile node regex!\n");
    return;
  }

  if(regcomp(&nodeParentRegex, "^[ \t]*//[ \t]*TG_NODE: [0-9]* TG_PARENTS: (()|(([0-9]*)(,[0-9]*)*))$", REG_EXTENDED) != 0)
  {
    *_errorMsg = _errorMsg->append("Failed to compile node parent regex!\n");
    return;
  }

  if(regcomp(&nodeDependencyRegex, "^[ \t]*//[ \t]*TG_DEPENDENCY: [0-9]* -> ([0-9]*)$", REG_EXTENDED) != 0)
  {
    *_errorMsg = _errorMsg->append("Failed to compile node dependency regex!\n");
    return;
  }

  while (std::getline(infile, line))
  {
    std::istringstream iss(line);

    if (regexec(&nodeRegex, line.c_str(), MAX_MATCHES, matches, 0) == 0)
    {
      std::string trimmedLine = Trim(Trim(line).substr(2));
      trimmedLine = trimmedLine.substr(9);
      std::string nodeIdx = trimmedLine;
      //std::cout << "Found node with index " << nodeIdx << std::endl;
      std::string nodeId = "Node" + nodeIdx;
      currentGraph->AddNode(new Node(nodeId,nodeId,0,"",0,0,std::list<int>()));
    }
    else if(regexec(&nodeParentRegex, line.c_str(), MAX_MATCHES, matches, 0) == 0)
    {
      std::string trimmedLine = Trim(Trim(line).substr(2));
      trimmedLine = trimmedLine.substr(9);
      unsigned int spaceIdx = trimmedLine.find(' ');
      std::string nodeIdx = trimmedLine.substr(0, spaceIdx);
      std::string nodeId = "Node" + nodeIdx;
      currentGraph->AddNode(new Node(nodeId,nodeId,0,"",0,0,std::list<int>()));
      //std::cout << "Found node with index " << nodeIdx;

      if(trimmedLine.size() < spaceIdx + 13)
      {
        //std::cout << std::endl;
        continue;
      }

      std::string parents = trimmedLine.substr(spaceIdx + 13);
      //std::cout << " and parents: ";

      char* ptr = strtok((char*)parents.c_str(), ",");

      while(ptr != NULL) {
        //std::cout << ptr << " ";
        std::string parentIdx(ptr);
        currentGraph->AddEdge(new Edge("Edge" + parentIdx + nodeIdx, "Node" + parentIdx, "Node" + parentIdx, nodeId, nodeId, 0));
         ptr = strtok(NULL, ",");
      }

      //std::cout << std::endl;
    }
    else if(regexec(&nodeDependencyRegex, line.c_str(), MAX_MATCHES, matches, 0) == 0)
    {
      std::string trimmedLine = Trim(Trim(line).substr(2));
      trimmedLine = trimmedLine.substr(15);
      int spaceIdx = trimmedLine.find(' ');
      std::string parentIdx = trimmedLine.substr(0, spaceIdx);
      std::string nodeIdx = trimmedLine.substr(spaceIdx + 4);
      //std::cout << "Found dependency from " << parentIdx << " to " << nodeIdx << std::endl;
      currentGraph->AddEdge(new Edge("Edge" + parentIdx + nodeIdx, "Node" + parentIdx, "Node" + parentIdx, "Node" + nodeIdx, "Node" + nodeIdx, 0));
    }
  }
}

NodeComparator::NodeComparator(int (*comparator)(Node* n1, Node* n2)) : comparator(comparator) {
}

NodeComparator::~NodeComparator() {
}

int NodeComparator::CompareNodeNamesInt(Node *n1, Node *n2)
{
  return n1->name.compare(n2->name);
}

int NodeComparator::CompareNodeIdsInt(Node *n1, Node *n2)
{
  return n1->id.compare(n2->id);
}

int NodeComparator::CompareNodeTaskIdsInt(Node *n1, Node *n2)
{
  if(n1->taskId > n2->taskId)
    return 1;
  else if(n1->taskId == n2->taskId)
    return 0;
  else return -1;
}

EdgeComparator::EdgeComparator(int (*comparator)(Edge *n1, Edge* n2)) : comparator(comparator)
{

}

EdgeComparator::~EdgeComparator()
{

}

int EdgeComparator::CompareEdgesByNodeIdsInt(Edge *e1, Edge *e2)
{
  std::string s1 = e1->sourceId + e1->targetId;
  std::string s2 = e2->sourceId + e2->targetId;

  return s1.compare(s2);
}

int EdgeComparator::CompareEdgesByNodeNamesInt(Edge *e1, Edge *e2)
{
  std::string s1 = e1->sourceName + e1->targetName;
  std::string s2 = e2->sourceName + e2->targetName;

  return s1.compare(s2);
}

GraphComparator::GraphComparator()
{
}

GraphComparator::~GraphComparator()
{
}

bool GraphComparator::CompareGraphsLevel(Graph *referenceGraph, Graph *g2, NodeComparator nodeComparator, bool checkCalcTime, std::string *errorMsg)
{
//  std::stringstream ss;
//
//  //Create mapping simCodeEq -> node (refernceGraph)
//  std::map<int,Node*> simCodeEqNodeMapping = std::map<int,Node*>();
//  for(std::list<Node*>::iterator iter = referenceGraph->nodes.begin(); iter != referenceGraph->nodes.end(); iter++)
//  {
//    if((*iter)->simCodeEqs.size() == 0 || (*iter)->simCodeEqs.size() > 1)
//    {
//      ss << "Node " << (*iter)->id << " of reference graph has " << (*iter)->simCodeEqs.size() << " equations. One was expected, because summarized nodes are not allowed!" << std::endl;
//      (*errorMsg) += ss.str().c_str();
//      return false;
//    }
//
//    for(std::list<int>::iterator eqIter = (*iter)->simCodeEqs.begin(); eqIter != (*iter)->simCodeEqs.end(); eqIter++)
//    {
//      std::map<int,Node*>::iterator it = simCodeEqNodeMapping.find(*eqIter);
//      if(it != simCodeEqNodeMapping.end())
//      {
//        ss << "SimCode-equation with index " << *eqIter << " was added to node "<< (*it).second->id << " and to node " << (*iter)->id << ". This is not allowed!" << std::endl;
//        (*errorMsg) += ss.str().c_str();
//        return false;
//      }
//      simCodeEqNodeMapping.insert(std::pair<int, Node*>(*eqIter, *iter));
//    }
//  }
//
//  //Create mapping node -> list of edges
//  std::map<std::string, std::list<Edge*>> edgeMapping = std::map<std::string, std::list<Edge*>>();
//  for(std::list<Edge*>::iterator iter = referenceGraph->edges.begin(); iter != referenceGraph->edges.end(); iter++)
//  {
//    std::list<Edge*> edgeListSource, edgeListTarget;
//    std::map<std::string*, std::list<Edge*>>::iterator sourceNodeEdgeIter = edgeMapping.find((*iter)->sourceId);
//    std::map<std::string*, std::list<Edge*>>::iterator targetNodeEdgeIter = edgeMapping.find((*iter)->targetId);
//
//    //if(sourceNodeEdgeIter == edgeMapping.end())
//    //  edgeListSource = std::list<Edge*>();
//    //else
//    //  edgeListSource = sourceNodeEdgeIter->second;
//
//    //if(targetNodeEdgeIter == edgeMapping.end())
//    //  edgeListTarget = std::list<Edge*>();
//    //else
//    //  edgeListTarget = targetNodeEdgeIter->second;
//
//    edgeListSource.push_back(*iter);
//    edgeListTarget.push_back(*iter);
//
//    //edgeMapping.
//  }
//
//  //iterate over all nodes in g2
//  for(std::list<Node*>::iterator iter = g2->nodes.begin(); iter != g2->nodes.end(); iter++)
//  {
//    for(std::list<int>::iterator eqIter = (*iter)->simCodeEqs.begin(); eqIter != (*iter)->simCodeEqs.end(); eqIter++)
//    {
//      std::map<int,Node*>::iterator it = simCodeEqNodeMapping.find(*eqIter);
//      if(it == simCodeEqNodeMapping.end())
//      {
//        ss << "SimCode-equation with index " << *eqIter << " solved in node " << (*iter)->id << " was not part of the reference graph" << std::endl;
//        (*errorMsg) += ss.str().c_str();
//        return false;
//      }
//      //find connected edges
//
//    }
//  }

  return false;
}

bool GraphComparator::CompareGraphs(Graph *g1, Graph *g2, CompareMode mode, std::string *errorMsg)
{
  return GraphComparator::CompareGraphs(g1, g2, NodeComparator(&NodeComparator::CompareNodeNamesInt), EdgeComparator(&EdgeComparator::CompareEdgesByNodeNamesInt), true, true, mode, errorMsg);
}

bool GraphComparator::CompareGraphs(Graph *g1, Graph *g2, NodeComparator nodeComparator, EdgeComparator edgeComparator, bool checkCalcTime, bool checkCommTime, CompareMode mode, std::string *errorMsg)
{
  std::stringstream ss;

  //Compare Critical path
  //---------------------
  if (g2->criticalPathInfo.erase(g2->criticalPathInfo.find_last_not_of(" \n\r\t") + 1).length() > 0)
  {
    if (g1->criticalPathInfo.compare(g2->criticalPathInfo) != 0)
    {
      ss << "The first graph has the critical path '" << g1->criticalPathInfo << "', but the second graph has '" << g2->criticalPathInfo << "' as critical path";
      (*errorMsg) += ss.str().c_str();
      return false;
    }
  }

  //Compare Nodes
  //-------------
  if (g1->NodeCount() != g2->NodeCount())
  {
    ss << "The first graph has " << g1->NodeCount() << " nodes, but the second graph has " << g2->NodeCount() << " nodes.";
    (*errorMsg) += ss.str().c_str();
    return false;
  }

  //map node-id to node-object
  std::map<std::string, Node*> nodeMapG1 = std::map<std::string, Node*>();
  std::map<std::string, Node*> nodeMapG2 = std::map<std::string, Node*>();

  for (std::list<Node*>::iterator nodeIterG1 = g1->nodes.begin(); nodeIterG1 != g1->nodes.end(); nodeIterG1++)
    nodeMapG1.insert(std::pair<std::string, Node*>((*nodeIterG1)->id, *nodeIterG1));

  for (std::list<Node*>::iterator nodeIterG2 = g2->nodes.begin(); nodeIterG2 != g2->nodes.end(); nodeIterG2++)
    nodeMapG2.insert(std::pair<std::string, Node*>((*nodeIterG2)->id, *nodeIterG2));

  std::list<Node*> sortedNodeListG1 = std::list<Node*>(g1->nodes.begin(), g1->nodes.end());
  std::list<Node*> sortedNodeListG2 = std::list<Node*>(g2->nodes.begin(), g2->nodes.end());
  sortedNodeListG1.sort(nodeComparator);
  sortedNodeListG2.sort(nodeComparator);

  std::list<Node*>::iterator nodeIterG2 = sortedNodeListG2.begin();
  for (std::list<Node*>::iterator nodeIterG1 = sortedNodeListG1.begin(); nodeIterG1 != sortedNodeListG1.end(); nodeIterG1++)
  {
    if (nodeComparator.comparator(*nodeIterG1, *nodeIterG2) != 0)
    {
      if (!IsNodePartOfGraph(*nodeIterG1, g2, nodeComparator))
        ss << "Node '" << (*nodeIterG1)->name << "(id: " << (*nodeIterG1)->id << ")' is not part of the second graph.";
      else
        ss << "Node '" << (*nodeIterG2)->name << "(id: " << (*nodeIterG2)->id << ")' is not part of the first graph.";

      (*errorMsg) += ss.str().c_str();
      return false;
    }

    if (checkCalcTime && ((*nodeIterG1)->calcTime < 0))
    {
      ss << "Node '" << (*nodeIterG1)->name << "' has no calculation time.";
      (*errorMsg) += ss.str().c_str();
      return false;
    }

    nodeIterG2++;
  }

  //Compare Edges
  //-------------
  if (g1->EdgeCount() != g2->EdgeCount())
  {
    ss << "The first graph has " << g1->EdgeCount() << " edges, but the second graph has " << g2->EdgeCount() << " edges.";
    (*errorMsg) += ss.str().c_str();
    return false;
  }

  //fill nodeName-information of edge-objects
  if (!FillEdgesWithNodeNames(g1->edges, &nodeMapG1))
    return false;

  if (!FillEdgesWithNodeNames(g2->edges, &nodeMapG2))
    return false;

  //sort edge list
  std::list<Edge*> sortedEdgeListG1 = std::list<Edge*>(g1->edges.begin(), g1->edges.end());
  std::list<Edge*> sortedEdgeListG2 = std::list<Edge*>(g2->edges.begin(), g2->edges.end());
  sortedEdgeListG1.sort(edgeComparator);
  sortedEdgeListG2.sort(edgeComparator);

  std::list<Edge*>::iterator edgeIterG2 = sortedEdgeListG2.begin();
  for (std::list<Edge*>::iterator edgeIterG1 = sortedEdgeListG1.begin(); edgeIterG1 != sortedEdgeListG1.end(); edgeIterG1++)
  {
    if (edgeComparator.comparator(*edgeIterG1, *edgeIterG2) != 0)
    {
      if (!IsEdgePartOfGraph(*edgeIterG1, g2, edgeComparator))
          ss << "Edge '" << (*edgeIterG1)->sourceName << "(id: " << (*edgeIterG1)->sourceId << ") --> " << (*edgeIterG1)->targetName << "(id: " << (*edgeIterG1)->targetId << ")' is not part of the second graph.";
      else
        ss << "Edge '" << (*edgeIterG2)->sourceName << "(id: " << (*edgeIterG2)->sourceId << ") --> " << (*edgeIterG2)->targetName << "(id: " << (*edgeIterG2)->targetId << ")' is not part of the first graph.";

      (*errorMsg) += ss.str().c_str();
      return false;
    }

    if (checkCommTime && ((*edgeIterG1)->commTime < 0))
    {
      ss << "Edge '" << (*edgeIterG1)->sourceName << " --> " << (*edgeIterG1)->targetName << "' has no communication time.";
      (*errorMsg) += ss.str().c_str();
      return false;
    }

    edgeIterG2++;
  }
  return true;
}

bool GraphComparator::IsNodePartOfGraph(Node *node, Graph *graph, NodeComparator nodeComparator)
{
  for (std::list<Node*>::iterator iterG = graph->nodes.begin(); iterG != graph->nodes.end(); iterG++)
  {
    if (nodeComparator.comparator(node, *iterG) == 0)
      return true;
  }

  return false;
}

bool GraphComparator::IsEdgePartOfGraph(Edge *edge, Graph *graph, EdgeComparator edgeComparator)
{
  for (std::list<Edge*>::iterator iterG = graph->edges.begin(); iterG != graph->edges.end(); iterG++)
  {
    if (edgeComparator.comparator(edge, *iterG) == 0)
      return true;
  }

  return false;
}

bool GraphComparator::FillEdgesWithNodeNames(std::list<Edge*> edges, std::map<std::string, Node*> *nodeIdNodeMap)
{
  for (std::list<Edge*>::iterator edgeIter = edges.begin(); edgeIter != edges.end(); edgeIter++)
  {
    std::map<std::string, Node*>::iterator sourceNodeObject = nodeIdNodeMap->find((*edgeIter)->sourceId);
    std::map<std::string, Node*>::iterator targetNodeObject = nodeIdNodeMap->find((*edgeIter)->targetId);
    if (sourceNodeObject == nodeIdNodeMap->end())
      return false;

    if (targetNodeObject == nodeIdNodeMap->end())
      return false;
    Edge* currentEdge = *edgeIter;
    currentEdge->sourceName = sourceNodeObject->second->name;
    currentEdge->targetName = targetNodeObject->second->name;
  }

  return true;
}

#ifndef TGRC_CHECKTG
#define TGRC_CHECKTG
void* TaskGraphResultsCmp_checkTaskGraph(const char *filename, const char *reffilename)
{
  void *res = mmc_mk_nil();
  Graph g1;
  Graph g2;
  GraphMLParser parser;
  std::string errorMsg = std::string("");

  if (!GraphMLParser::CheckIfFileExists(filename))
  {
    errorMsg = "File '";
    errorMsg += std::string(filename);
    errorMsg += "' does not exist";
    res = mmc_mk_cons(mmc_mk_scon(errorMsg.c_str()), mmc_mk_nil());
    return res;
  }

  if (!GraphMLParser::CheckIfFileExists(reffilename))
  {
    errorMsg = "File '";
    errorMsg += std::string(reffilename);
    errorMsg += "' does not exist";
    res = mmc_mk_cons(mmc_mk_scon(errorMsg.c_str()), mmc_mk_nil());
    return res;
  }

  parser.ParseGraph(&g1, filename, NodeComparator(&NodeComparator::CompareNodeNamesInt), &errorMsg);
  parser.ParseGraph(&g2, reffilename, NodeComparator(&NodeComparator::CompareNodeNamesInt), &errorMsg);

  if (GraphComparator::CompareGraphs(&g1, &g2, FULL, &errorMsg))
    res = mmc_mk_cons(mmc_mk_scon("Taskgraph correct"), mmc_mk_nil());
  else
    res = mmc_mk_cons(mmc_mk_scon("Taskgraph not correct"), mmc_mk_nil());

  if (errorMsg.length() != 0)
    res = mmc_mk_cons(mmc_mk_scon(errorMsg.c_str()), res);

  return res;
}

void* TaskGraphResultsCmp_checkCodeGraph(const char *filename, const char *codeFileName)
{
  void *res = mmc_mk_nil();
  Graph g1;
  Graph g2;
  GraphMLParser parser;
  GraphCodeParser codeParser;
  std::string errorMsg = std::string("");

  if (!GraphMLParser::CheckIfFileExists(filename))
  {
    errorMsg = "File '";
    errorMsg += std::string(filename);
    errorMsg += "' does not exist";
    res = mmc_mk_cons(mmc_mk_scon(errorMsg.c_str()), mmc_mk_nil());
    return res;
  }

  if (!GraphMLParser::CheckIfFileExists(codeFileName))
  {
    errorMsg = "File '";
    errorMsg += std::string(codeFileName);
    errorMsg += "' does not exist";
    res = mmc_mk_cons(mmc_mk_scon(errorMsg.c_str()), mmc_mk_nil());
    return res;
  }

  parser.ParseGraph(&g1, filename, NodeComparator(&NodeComparator::CompareNodeNamesInt), &errorMsg);
  codeParser.ParseGraph(&g2, codeFileName, NodeComparator(&NodeComparator::CompareNodeNamesInt), &errorMsg);

  if (GraphComparator::CompareGraphs(&g1, &g2, NodeComparator(&NodeComparator::CompareNodeIdsInt),EdgeComparator(&EdgeComparator::CompareEdgesByNodeIdsInt), false, false, FULL, &errorMsg))
    res = mmc_mk_cons(mmc_mk_scon("Codegraph correct"), mmc_mk_nil());
  else
    res = mmc_mk_cons(mmc_mk_scon("Codegraph not correct"), mmc_mk_nil());

  if (errorMsg.length() != 0)
    res = mmc_mk_cons(mmc_mk_scon(errorMsg.c_str()), res);

  return res;
}
#endif

#endif
