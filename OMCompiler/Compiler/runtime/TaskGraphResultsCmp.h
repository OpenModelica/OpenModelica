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

#include <list>
#include <string>
#include <sstream>
#include <map>
#include <fstream>
#include <vector>
#include <iostream>
#include <set>
#include <string.h>
#include <sys/types.h>
#include "regex.h"
#include "expat.h"

//--------------------------
//Graph structure definition
//--------------------------
#ifndef TGRC_NODE
#define TGRC_NODE
struct Node
{
  std::string id;
  std::string name;
  double calcTime;
  std::string threadId;
  int taskNumber;
  int taskId;
  std::list<int> simCodeEqs;

  Node();
  Node(std::string id, std::string name, double calcTime, std::string threadId, int taskNumber, int taskId, std::list<int> simCodeEqs);
  ~Node();
};
#endif //TGRC_NODE

#ifndef TGRC_EDGE
#define TGRC_EDGE
struct Edge
{
  std::string id;
  std::string sourceId;
  std::string sourceName;
  std::string targetId;
  std::string targetName;
  double commTime;

  Edge();
  Edge(std::string id, std::string sourceId, std::string sourceName, std::string targetId, std::string targetName, double commTime);
  ~Edge();
};
#endif //TGRC_EDGE

#ifndef TGRC_GRAPH
#define TGRC_GRAPH
class Graph
{
public:
  std::list<Node*> nodes;
  std::list<Edge*> edges;

  std::string criticalPathInfo;

  Graph(void);
  ~Graph(void);

  void AddNode(Node *node);
  void RemoveNode(Node *node);
  int NodeCount();
  Node* GetNode(int index);

  void AddEdge(Edge *edge);
  void RemoveEdge(Edge *edge);
  int EdgeCount();
  Edge* GetEdge(int index);
};
#endif //TGRC_GRAPH

#ifndef TGRC_NODECOMPARATOR
#define TGRC_NODECOMPARATOR
class NodeComparator
{
public:
  int (*comparator)(Node *n1, Node* n2);

  NodeComparator(int (*comparator)(Node *n1, Node* n2));
  ~NodeComparator();

    bool operator()(Node *node1, Node *node2) const {
          return (comparator(node1,node2) > 0);
    }

  static int CompareNodeNamesInt(Node *n1, Node *n2);
  static int CompareNodeIdsInt(Node *n1, Node *n2);
  static int CompareNodeTaskIdsInt(Node *n1, Node *n2);
};
#endif //TGRC_NODECOMPARATOR

#ifndef TGRC_EDGECOMPARATOR
#define TGRC_EDGECOMPARATOR
class EdgeComparator
{
public:
  int (*comparator)(Edge *n1, Edge* n2);

  EdgeComparator(int (*comparator)(Edge *n1, Edge* n2));
  ~EdgeComparator();

    bool operator()(Edge *node1, Edge *node2) const {
          return (comparator(node1,node2) > 0);
    }

    static int CompareEdgesByNodeIdsInt(Edge *e1, Edge *e2);
    static int CompareEdgesByNodeNamesInt(Edge *e1, Edge *e2);

};
#endif //TGRC_EDGECOMPARATOR

#ifndef TGRC_GRAPHPARSER
#define TGRC_GRAPHPARSER
class GraphParser
{
public:
  GraphParser();
  virtual ~GraphParser();

  static bool CheckIfFileExists(const char* fileName);

  virtual void ParseGraph(Graph *currentGraph, const char* fileName, NodeComparator nodeComparator, std::string *_errorMsg) = 0;
};
#endif //TGRC_GRAPHPARSER

#ifndef TGRC_GRAPHMLPARSER
#define TGRC_GRAPHMLPARSER
class GraphMLParser : public GraphParser
{
private:
  struct ParserUserData
  {
    Graph* currentGraph;
    Node* currentNode;
    Edge* currentEdge;

    bool readStringValue;
    bool readDoubleValue;
    bool readIntValue;
    double* doubleValue;
    std::string* stringValue;
    int* intValue;

    std::string* errorMsg;
    int level;
    std::set<Node*, NodeComparator> *nodeSet;
    std::string calcTimeAttributeId;
    std::string commCostAttributeId;
    std::string criticalPathAttributeId;
    std::string nameAttributeId;
    std::string threadIdAttributeId;
    std::string taskNumberAttributeId;
    std::string taskIdAttributeId;
  };

protected:
  //Handler for the expat-startElement-event.
  static void StartElement(void *data, const XML_Char *name, const XML_Char **attribute);

  //Handler for the expat-endElement-event. This method just decreases the level.
  static void EndElement(void *data, const XML_Char *name);

  //Handler for the expat-dataElement-event
  static void DataElement(void* data, const XML_Char* text, int textLength);

  //Removes the namespace of the given name
  static std::string RemoveNamespace(const char* name);

public:
  GraphMLParser(void);
  virtual ~GraphMLParser(void);

  virtual void ParseGraph(Graph *currentGraph, const char* fileName, NodeComparator nodeComparator, std::string *_errorMsg);
};
#endif //TGRC_GRAPHMLPARSER

#ifndef TGRC_CODEPARSER
#define TGRC_CODEPARSER
class GraphCodeParser : public GraphParser
{
protected:
  std::string Trim(const std::string& str);
public:
  GraphCodeParser();
  virtual ~GraphCodeParser();

  virtual void ParseGraph(Graph *currentGraph, const char* fileName, NodeComparator nodeComparator, std::string *_errorMsg);
};
#endif //TGRC_CODEPARSER

#ifndef TGRC_GRAPHCOMPARATOR
#define TGRC_GRAPHCOMPARATOR

enum CompareMode { FULL, LEVEL };

class GraphComparator
{
private:
  GraphComparator(void);
public:
  //Compares the two given graphs and adds every error-message to the given string.
  static bool CompareGraphs(Graph *g1, Graph *g2, CompareMode mode, std::string *errorMsg);
  static bool CompareGraphs(Graph *g1, Graph *g2, NodeComparator nodeComparator, EdgeComparator edgeComparator, bool checkCalcTime, bool checkCommTime, CompareMode mode, std::string *errorMsg);

  ~GraphComparator(void);


  static bool IsNodePartOfGraph(Node *node, Graph *graph, NodeComparator nodeComparator);
  static bool IsEdgePartOfGraph(Edge *edge, Graph *graph, EdgeComparator edgeComparator);
protected:
  static bool FillEdgesWithNodeNames(std::list<Edge*> edges, std::map<std::string, Node*> *nodeIdNodeMap);

  /**
   * Checks if all nodes of g2 and the connected equations are valid regarding the level-structure of the reference graph.
   * Attention: The reference graph must contain the original ode-structure without summarized nodes.
   */
  static bool CompareGraphsLevel(Graph *referenceGraph, Graph *g2, NodeComparator nodeComparator, bool checkCalcTime, std::string *errorMsg);
};
#endif //TGRC_GRAPHCOMPARATOR

#endif
