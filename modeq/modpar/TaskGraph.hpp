#ifndef _TASKGRAPH_H
#define _TASKGRAPH_H

#include <boost/config.hpp>
#include <iostream>                      // for std::cout
#include <utility>                       // for std::pair
#include <algorithm>                     // for std::for_each
#include <boost/utility.hpp>             // for boost::tie
#include <boost/graph/graph_traits.hpp>  // for boost::graph_traits
#include <boost/graph/adjacency_list.hpp>
#include <boost/graph/adjacency_iterator.hpp> 
#include <boost/graph/graphviz.hpp>
#include <boost/graph/properties.hpp>

//Task graph types
using namespace std;

using boost::tie;

struct vertex_execcost_t {
  typedef boost::vertex_property_tag kind;
};

struct vertex_unique_id_t {
  typedef boost::vertex_property_tag kind;
};

struct edge_result_set_t {
  typedef boost::edge_property_tag kind;
};

struct vertex_resultname_t {
  typedef boost::vertex_property_tag kind;
};

struct vertex_origname_t {
  typedef boost::vertex_property_tag kind;
};

struct vertex_tasktype_t {
  typedef boost::vertex_property_tag kind;
};

enum TaskType {Assignment=0, TempVar=1, LinSys=2, NonLinSys=3, Begin=4, End=5, Copy=6};

typedef boost::property<boost::vertex_name_t,string,
	 boost::property<vertex_execcost_t,float,
	  boost::property<vertex_unique_id_t, int,
	   boost::property<boost::vertex_index_t,int,
	    boost::property<boost::vertex_color_t, boost::default_color_type,
	     boost::property<vertex_resultname_t, string,
	      boost::property<vertex_tasktype_t, TaskType,
       	       boost::property<vertex_origname_t, string>
	      >
	     >
	    >
           >
	  >
         > 
        > VertexProperty;


// A small extension of set to allow union of two sets.
template <class T>
class UnionSet : public std::set<T> {
public:
  inline  void make_union (const set<T> *s) {
    typename set<T>::iterator it;
    if (s == this) { return; }
    for (it=s->begin(); it != s->end(); it++) 
      insert(*it);
  };
};  

// The differet variables communicated over an edge
typedef UnionSet<string> ResultSet;
  
typedef boost::property<boost::edge_weight_t, int,
	 boost::property<edge_result_set_t, ResultSet > > EdgeProperty;
  
typedef boost::adjacency_list<boost::listS, boost::listS, 
			      boost::bidirectionalS,
		       VertexProperty, EdgeProperty> TaskGraph;
  
typedef  boost::property_map<TaskGraph,boost::vertex_name_t> VertexNameMap;
typedef  boost::property_map<TaskGraph,vertex_execcost_t> VertexExecCostMap;
typedef  boost::property_map<TaskGraph,vertex_unique_id_t> VertexUniqueIDMap;
typedef  boost::property_map<TaskGraph,boost::vertex_index_t> VertexIndexMap;
typedef  boost::property_map<TaskGraph,vertex_resultname_t> VertexResultNameMap;
typedef  boost::property_map<TaskGraph,vertex_origname_t> VertexOrigNameMap;
typedef  boost::property_map<TaskGraph,vertex_tasktype_t> VertexTaskTypeMap;
typedef  boost::property_map<TaskGraph,boost::vertex_color_t> VertexColorMap;

typedef  boost::property_map<TaskGraph,boost::edge_weight_t> EdgeCommCostMap;
typedef  boost::property_map<TaskGraph,edge_result_set_t> EdgeResultSetMap;
  
  
typedef boost::graph_traits<TaskGraph>::vertex_descriptor VertexID;
typedef boost::graph_traits<TaskGraph>::vertex_iterator VertexIterator;
typedef boost::graph_traits<TaskGraph>::edge_descriptor EdgeID;
typedef boost::graph_traits<TaskGraph>::edge_iterator EdgeIterator;
  
typedef boost::graph_traits<TaskGraph>::out_edge_iterator OutEdgeIterator;
typedef boost::graph_traits<TaskGraph>::in_edge_iterator InEdgeIterator;

typedef boost::adjacency_iterator_generator<TaskGraph, VertexID, OutEdgeIterator>::type ChildrenIterator;
  
typedef boost::inv_adjacency_iterator_generator<TaskGraph, VertexID, InEdgeIterator>::type ParentsIterator;
  
typedef UnionSet<int> ContainSet;

typedef map<VertexID,ContainSet* > ContainSetMap;
  
  
VertexNameMap::type VertexNameProperty(TaskGraph* tg);
  
VertexUniqueIDMap::type VertexUniqueIDProperty(const TaskGraph* tg);
  
VertexExecCostMap::type VertexExecCostProperty(TaskGraph* tg);
  
VertexIndexMap::type VertexIndexProperty(TaskGraph* tg);

VertexOrigNameMap::type VertexOrigNameProperty(TaskGraph *tg);

VertexResultNameMap::type VertexResultNameProperty(TaskGraph *tg);

VertexTaskTypeMap::type VertexTaskTypeProperty(TaskGraph *tg);

VertexColorMap::type VertexColorProperty(TaskGraph *tg);

EdgeCommCostMap::type EdgeCommCostProperty(TaskGraph* tg); 

EdgeResultSetMap::type EdgeResultSetProperty(TaskGraph* tg);

boost::default_color_type getVertexColor(VertexID v, TaskGraph *tg);  

void setVertexColor(VertexID v, boost::default_color_type  color, TaskGraph *tg);  

int getCommCost(EdgeID edge,TaskGraph * tg);
  
void setCommCost(EdgeID edge, int weight,TaskGraph * tg);
  
double getExecCost(VertexID v,const TaskGraph * tg);

double getExecCost(int uniqueID,const TaskGraph * tg);
  
void setExecCost(VertexID v, double weight,TaskGraph * tg);
  
int getTaskID(VertexID v,const TaskGraph * tg);

void setResultSet(EdgeID edge, ResultSet &set, TaskGraph *tg);

ResultSet& getResultSet(EdgeID edge, TaskGraph *tg);

void setTaskType(VertexID task, TaskType t, TaskGraph *tg);

TaskType getTaskType(VertexID task, TaskGraph *tg);

void nameVertex(VertexID task,TaskGraph *tg, const string *s);

void nameVertex(VertexID task, TaskGraph *tg,const char *s); 

string & getVertexName(VertexID task,TaskGraph *tg);

void setResultName(VertexID, string&, TaskGraph *tg);
string & getResultName(VertexID task, TaskGraph *tg);

// The original name used in the Modelica model, must be 
// used because var names change to e.g. x[4] and xd[2]
void setOrigName(VertexID, string&, TaskGraph *tg);
string & getOrigName(VertexID task, TaskGraph *tg);

// Provide formatstrings for std::string (as for printf)
string & insert_strings(string &s, vector<string> &v);
  
// the top level of a node.
double tlevel(VertexID node,TaskGraph *tg,double,double);
  
std::pair<ChildrenIterator, ChildrenIterator> 
children(VertexID v, const TaskGraph &tg); 
  
std::pair<ParentsIterator, ParentsIterator> 
parents(VertexID v, const TaskGraph &tg); 
  
std::list<VertexID> *
siblings( VertexID, const TaskGraph &tg);

void initialize_index(TaskGraph *tg);  

string * genTemp();
  
EdgeID add_edge(VertexID parent, VertexID child, TaskGraph *tg, 
	      string *result=0);

EdgeID add_edge(VertexID parent, VertexID child, TaskGraph *tg,
		ResultSet &rset);

VertexID find_task(VertexID alientask,TaskGraph *alientg,TaskGraph *tg);

VertexID find_task(int taskID,TaskGraph *tg);

ResultSet& make_resultset(string *firstelt=0);

ResultSet& copy_resultset(ResultSet &);

extern map<int,double> execcost; // mapping from unique id to exec cost.

extern int tempNo;

// return the maximum value of a vector
template <class T> T max(std::vector<T> v) {
  typename vector<T>::iterator i;
  T maxVal=v[0];
  for (i=v.begin(); i != v.end(); ++i) {
    if (*i > maxVal) maxVal=*i;
  }
  return maxVal;
}


template <typename Graph, typename VertexPropertiesWriter,
	  typename EdgePropertiesWriter, typename GraphPropertiesWriter>
inline void my_write_graphviz(std::ostream& out, const Graph& g,
			      VertexPropertiesWriter vpw,
			      EdgePropertiesWriter epw,
			      GraphPropertiesWriter gpw) {
  
  typedef typename boost::graph_traits<Graph>::directed_category cat_type;
  typedef boost::graphviz_io_traits<cat_type> Traits;
  std::string name = "G";
  out << Traits::name() << " " << name << " {" << std::endl;
  
  gpw(out); //print graph properties
  
  typename boost::graph_traits<Graph>::vertex_iterator i, end;
  
  for(boost::tie(i,end) = boost::vertices(g); i != end; ++i) {
    out << (int)*i;
    vpw(out, *i); //print vertex attributes
    out << ";" << std::endl;
  }
  typename boost::graph_traits<Graph>::edge_iterator ei, edge_end;
    for(boost::tie(ei, edge_end) = boost::edges(g); ei != edge_end; ++ei) {
      out << (int)(source(*ei, g)) << Traits::delimiter() << ((int)target(*ei, g)) << " ";
      epw(out, *ei); //print edge attributes
      out << ";" << std::endl;
    }
    out << "}" << std::endl;
}

template <typename Graph, typename VertexWriter, typename EdgeWriter>
inline void
my_write_graphviz(std::ostream& out, const Graph& g,
		  VertexWriter vw, EdgeWriter ew) {
  boost::default_writer gw;
  my_write_graphviz(out, g, vw, ew, gw);
}


#endif
