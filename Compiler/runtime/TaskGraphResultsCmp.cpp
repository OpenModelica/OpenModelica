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

#include <list>
#include <string>
#include <sstream>
#include <map>
#include <fstream>
#include <vector>
#include <iostream>
#include <set>
#include <cstring>
#include "expat.h"

class GraphComparator;

//--------------------------
//Graph structure definition
//--------------------------

struct Node
{
	std::string id;
	std::string name;

	Node() : id(""), name("")
	{}

	~Node()
	{

	}
};

struct Edge
{
	std::string id;
	std::string sourceId;
	std::string sourceName;
	std::string targetId;
	std::string targetName;

	Edge() : id(""), sourceId(""), sourceName(""), targetId(""), targetName("")
	{

	}

	~Edge()
	{

	}
};

class Graph
{
	friend class GraphComparator;
	public:
		Graph(void) : nodes(), edges()
		{
		}

		~Graph(void)
		{
			for( std::list<Node*>::iterator i = nodes.begin(); i != nodes.end(); ++i )
			{
				Node *nodePtr = *i;
			    delete nodePtr;
			}
			nodes.clear();

			for( std::list<Edge*>::iterator i = edges.begin(); i != edges.end(); ++i )
			{
				Edge *edgePtr = *i;
			    delete edgePtr;
			}
			edges.clear();
		}

		void AddNode( Node *node )
		{
			nodes.push_back(node);
		}

		void RemoveNode( Node *node )
		{
			nodes.remove(node);
		}

		int NodeCount()
		{
			return nodes.size();
		}

		Node* GetNode( int index )
		{
			if(NodeCount() <= index)
				return 0;

			std::list<Node*>::iterator iter = nodes.begin();
			std::advance(iter,index);
			return *iter;
		}

		void AddEdge( Edge *edge )
		{
			edges.push_back(edge);
		}

		void RemoveEdge( Edge *edge )
		{
			edges.remove(edge);
		}

		int EdgeCount()
		{
			return edges.size();
		}

		Edge* GetEdge( int index )
		{
			if(EdgeCount() <= index)
				return 0;

			std::list<Edge*>::iterator iter = edges.begin();
			std::advance(iter,index);
			return *iter;
		}

	private:
		std::list<Node*> nodes;
		std::list<Edge*> edges;
};

class GraphMLParser
{
private:
	struct ParserUserData
	{
		Graph* currentGraph;
		Node* currentNode;
		bool readNodeName;
		std::string* errorMsg;
		int level;
		std::set<Node*,bool(*)(Node*,Node*)> *nodeSet;
	};

protected:
	//Handler for the expat-startElement-event.
	static void StartElement( void *data, const XML_Char *name, const XML_Char **attribute )
	{
		ParserUserData *userData = (ParserUserData *)data;

		//get rid of the xml-namespace
		std::string name_wo_ns = RemoveNamespace(name);
		userData->level++;

		//check if the element is a node-element
		if((userData->level == 3) && (name_wo_ns.compare("node") == 0))
		{
			//find id-attribute
			for(int i = 0; attribute[i]; i+=2)
			{
				if(strcmp("id", attribute[i]) == 0)
				{
					userData->currentNode = new Node();
					userData->currentNode->id = attribute[i+1];
				}
			}

			//don't add the node to the node-set, because the DataElement-method has to fill the node-name first
		}

		//check if the element is the NodeLabel of the node element
		if((userData->level == 6) && (name_wo_ns.compare("NodeLabel") == 0))
			userData->readNodeName = true;

		//check if the element is an edge
		if((userData->level == 3) && (name_wo_ns.compare("edge") == 0))
		{
			//Parse the edge-object
			Edge* edge = new Edge();
			std::string id = "";
			std::string target = "";
			std::string source = "";

			for(int i = 0; attribute[i]; i+=2)
			{
				if(strcmp("id", attribute[i]) == 0)
					id = std::string(attribute[i+1]);
				else if(strcmp("source", attribute[i]) == 0)
					source = std::string(attribute[i+1]);
				else if(strcmp("target", attribute[i]) == 0)
					target = std::string(attribute[i+1]);
			}
			if(id.length() == 0)
				*(userData->errorMsg) += "Warning: edge without id defined\n";
			else
			{
				edge->id = id;
			}

			if(source.length() == 0)
				*(userData->errorMsg) += "Warning: edge without source defined\n";
			else
			{
				edge->sourceId = source;
			}

			if(target.length() == 0)
				*(userData->errorMsg) += "Warning: edge without target defined\n";
			else
			{
				edge->targetId = target;
			}
			userData->currentGraph->AddEdge(edge);
		}
	}

	//Handler for the expat-endElement-event. This method just decreases the level.
	static void EndElement( void *data, const char *el )
	{
		ParserUserData *userData = (ParserUserData *)data;
		userData->level--;
	}

	//Handler for the expat-dataElement-event
	static void DataElement(void* data, const XML_Char* text, int textLength)
	{
		ParserUserData *userData = (ParserUserData *)data;
		//Should we read the data-element and is there a node-instance in the currentNode-container?
		if(userData->readNodeName && userData->currentNode != 0)
		{
			userData->currentNode->name = std::string((const char*)text, textLength);

			//Now the node-object should have all important informations, so add it to the node-set
			std::pair<std::set<Node*>::iterator,bool> insertReturn = userData->nodeSet->insert(userData->currentNode);

			if(!insertReturn.second)
			{
				std::stringstream ss;
				ss << "Warning: a node with the name '" << userData->currentNode->name << "' was added multiple times to graph." << std::endl;
				(*(userData->errorMsg)) += ss.str().c_str();
			}

			userData->currentNode = 0;
		}
		userData->readNodeName = false;
	}

	//Removes the namespace of the given name
	static std::string RemoveNamespace( const char* name )
	{
		std::string sName = std::string(name);
		size_t sepPosition = sName.rfind(':');

		// did we find a seperator
		if((sepPosition > 0) && (sepPosition < sName.length()))
		{
			const std::string shortName = sName.substr(sepPosition+1);
			return shortName;
		}

		return name;
	}

private:
	GraphMLParser(void)
	{
	}


	~GraphMLParser(void)
	{
	}

public:
	static void ParseGraph(Graph *currentGraph, const char* fileName, bool(*nodeComparator)(Node*,Node*), std::string *_errorMsg)
	{
		//We have to use expat which makes simple parsing really complicated :)
		std::FILE *graphFile;
		const int bufferSize = 10000;
		char buffer[bufferSize];
		XML_Parser parser;
		int len;   /* len is the number of bytes in the current buffer of data */
		int done = 0;

		ParserUserData userData = ParserUserData();

		//Create a new graph first
		userData.currentGraph = currentGraph;
		//Stores the level of the current xml-element
		userData.level = 0;
		userData.currentNode = 0;
		userData.readNodeName = false;
		userData.nodeSet = new std::set<Node*,bool(*)(Node*,Node*)>(nodeComparator);
		userData.errorMsg = _errorMsg;
		graphFile = fopen(fileName, "r");
		parser = XML_ParserCreate(NULL);
		XML_SetUserData(parser, &userData);
		XML_SetElementHandler(parser, StartElement, EndElement);
		XML_SetCharacterDataHandler(parser, DataElement);

		do
		{
			//Read the graphml-file piece by piece
			len = std::fread(buffer, sizeof(char), bufferSize, graphFile);

			if(len < bufferSize)
				done = true;

			if (XML_Parse(parser, buffer, len, done) == XML_STATUS_ERROR)
			{
				*(userData.errorMsg) += "Error during xml-parsing\n";
				break;
			}
		}
		while (!done);

		XML_ParserFree(parser);

		//Add all elements of the node-set to the graph
		for(std::set<Node*,bool(*)(Node*,Node*)>::iterator iter = userData.nodeSet->begin(); iter != userData.nodeSet->end(); iter++)
		{
			Node *node = *iter;
			userData.currentGraph->AddNode(node);
		}


		delete userData.nodeSet;
		userData.currentNode = 0;
	}

};

class GraphComparator
{
private:
	GraphComparator(void);
public:
	//Compares the two given graphs and adds every error-message to the given string.
	static bool CompareGraphs(Graph *g1, Graph *g2, std::string *errorMsg)
	{
		std::stringstream ss;

		//Compare Nodes
		//-------------

		if(g1->NodeCount() != g2->NodeCount())
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


		std::list<Node*> sortedNodeListG1 = std::list<Node*>(g1->nodes.begin(),g1->nodes.end());
		std::list<Node*> sortedNodeListG2 = std::list<Node*>(g2->nodes.begin(),g2->nodes.end());
		sortedNodeListG1.sort(CompareNodesBool);
		sortedNodeListG2.sort(CompareNodesBool);

		std::list<Node*>::iterator nodeIterG2 = sortedNodeListG2.begin();
		for (std::list<Node*>::iterator nodeIterG1 = sortedNodeListG1.begin(); nodeIterG1 != sortedNodeListG1.end(); nodeIterG1++)
		{
			if(((*nodeIterG1)->name).compare((*nodeIterG2)->name) != 0)
			{
				if(!IsNodePartOfGraph(*nodeIterG1, g2))
					ss << "Node '" << (*nodeIterG1)->name << "' is not part of the second graph.";
				else
					ss << "Node '" << (*nodeIterG2)->name << "' is not part of the first graph.";

				(*errorMsg) += ss.str().c_str();
				return false;
			}

			nodeIterG2++;
		}

		//Compare Edges
		//-------------
		if(g1->EdgeCount() != g2->EdgeCount())
		{
			ss << "The first graph has " << g1->EdgeCount() << " edges, but the second graph has " << g2->EdgeCount() << " edges.";
			(*errorMsg) += ss.str().c_str();
			return false;
		}

		//fill nodeName-information of edge-objects
		if(!FillEdgesWithNodeNames(g1->edges, &nodeMapG1))
			return false;

		if(!FillEdgesWithNodeNames(g2->edges, &nodeMapG2))
			return false;

		//sort edge list
		std::list<Edge*> sortedEdgeListG1 = std::list<Edge*>(g1->edges.begin(),g1->edges.end());
		std::list<Edge*> sortedEdgeListG2 = std::list<Edge*>(g2->edges.begin(),g2->edges.end());
		sortedEdgeListG1.sort(CompareEdgesBool);
		sortedEdgeListG2.sort(CompareEdgesBool);

		std::list<Edge*>::iterator edgeIterG2 = sortedEdgeListG2.begin();
		for (std::list<Edge*>::iterator edgeIterG1 = sortedEdgeListG1.begin(); edgeIterG1 != sortedEdgeListG1.end(); edgeIterG1++)
		{
			if(CompareEdgesInt(*edgeIterG1, *edgeIterG2) != 0)
			{
				if(!IsEdgePartOfGraph(*edgeIterG1, g2))
					ss << "Edge '" << (*edgeIterG1)->sourceName << " --> " << (*edgeIterG1)->targetName << "' is not part of the second graph.";
				else
					ss << "Edge '" << (*edgeIterG2)->sourceName << " --> " << (*edgeIterG2)->targetName << "' is not part of the first graph.";

				(*errorMsg) += ss.str().c_str();
				return false;
			}

			edgeIterG2++;
		}
		return true;
	}

	~GraphComparator(void)
	{
	}

	static bool CompareNodesBool( Node *n1, Node *n2 )
	{
		return CompareNodesInt(n1,n2) > 0;
	}

	static int CompareNodesInt( Node *n1, Node *n2 )
	{
		return  n1->name.compare(n2->name);
	}

	static bool CompareEdgesBool( Edge *e1, Edge *e2 )
	{
		return CompareEdgesInt(e1,e2) > 0;
	}

	static int CompareEdgesInt( Edge *e1, Edge *e2 )
	{
		std::string s1 = e1->sourceName + e1->targetName;
		std::string s2 = e2->sourceName + e2->targetName;

		return s1.compare(s2);
	}

	static bool IsNodePartOfGraph( Node *node, Graph *graph )
	{
		for (std::list<Node*>::iterator iterG = graph->nodes.begin(); iterG != graph->nodes.end(); iterG++)
		{
			if(CompareNodesInt(node,*iterG) == 0)
				return true;
		}

		return false;
	}

	static bool IsEdgePartOfGraph( Edge *edge, Graph *graph )
	{
		for (std::list<Edge*>::iterator iterG = graph->edges.begin(); iterG != graph->edges.end(); iterG++)
		{
			if(CompareEdgesInt(edge,*iterG) == 0)
				return true;
		}

		return false;
	}

protected:
	static bool FillEdgesWithNodeNames( std::list<Edge*> edges, std::map<std::string, Node*> *nodeIdNodeMap )
	{
		for (std::list<Edge*>::iterator edgeIter = edges.begin(); edgeIter != edges.end(); edgeIter++)
		{
			std::map<std::string, Node*>::iterator sourceNodeObject = nodeIdNodeMap->find((*edgeIter)->sourceId);
			std::map<std::string, Node*>::iterator targetNodeObject = nodeIdNodeMap->find((*edgeIter)->targetId);
			if(sourceNodeObject == nodeIdNodeMap->end())
				return false;

			if(targetNodeObject == nodeIdNodeMap->end())
				return false;
			Edge* currentEdge = *edgeIter;
			currentEdge->sourceName = sourceNodeObject->second->name;
			currentEdge->targetName = targetNodeObject->second->name;
		}

		return true;
	}

};

bool checkIfFileExists(const char* fileName)
{
  std::ifstream ifile(fileName);
  return ifile;
}

void* TaskGraphResultsCmp_cmpTaskGraphs(const char *filename, const char *reffilename)
{
	void *res = mk_nil();
	Graph g1;
	Graph g2;
	std::string errorMsg = std::string("");

	if(!checkIfFileExists(filename))
	{
		errorMsg = "File '";
		errorMsg += std::string(filename);
		errorMsg += "' does not exist";
		res = mk_cons(mk_scon(errorMsg.c_str()),mk_nil());
		return res;
	}

	if(!checkIfFileExists(reffilename))
	{
		errorMsg = "File '";
		errorMsg += std::string(reffilename);
		errorMsg += "' does not exist";
		res = mk_cons(mk_scon(errorMsg.c_str()),mk_nil());
		return res;
	}

	GraphMLParser::ParseGraph(&g1, filename, GraphComparator::CompareNodesBool, &errorMsg);
	GraphMLParser::ParseGraph(&g2, reffilename, GraphComparator::CompareNodesBool, &errorMsg);

	if(GraphComparator::CompareGraphs(&g1,&g2,&errorMsg))
		res = mk_cons(mk_scon("Graphs equal"),mk_nil());
	else
		res = mk_cons(mk_scon("Graphs not equal"),mk_nil());

	if(errorMsg.length() != 0)
		res = mk_cons(mk_scon(errorMsg.c_str()),res);

	return res;
}
