#include "TaskGraph.hpp"
#include <sstream>

const int max_nodes=1000;

int tempNo=0;

VertexNameMap::type VertexNameProperty(TaskGraph* tg)
{
  boost::vertex_name_t pname;
  VertexNameMap::type pmap = get(pname, *tg);
  return pmap;
};

VertexUniqueIDMap::type VertexUniqueIDProperty(const TaskGraph* tg)
{
  vertex_unique_id_t pname;
  VertexUniqueIDMap::type pmap = get(pname, *(TaskGraph*)tg);
  return pmap;
};

VertexExecCostMap::type VertexExecCostProperty(TaskGraph* tg)
{
  vertex_execcost_t pname;
  VertexExecCostMap::type pmap = get(pname, *tg);
  return pmap;
}

VertexIndexMap::type VertexIndexProperty(TaskGraph* tg)
{
  boost::vertex_index_t pname;
  VertexIndexMap::type pmap = get(pname, *tg);
  return pmap;
}


VertexResultNameMap::type VertexResultNameProperty(TaskGraph *tg)
{
  vertex_resultname_t pname;
  VertexResultNameMap::type pmap = get(pname, *tg);
  return pmap;
}

VertexOrigNameMap::type VertexOrigNameProperty(TaskGraph *tg)
{
  vertex_origname_t pname;
  VertexOrigNameMap::type pmap = get(pname, *tg);
  return pmap;
}

VertexTaskTypeMap::type VertexTaskTypeProperty(TaskGraph *tg)
{
  vertex_tasktype_t pname;
  VertexTaskTypeMap::type pmap = get(pname, *tg);
  return pmap;
}

VertexColorMap::type VertexColorProperty(TaskGraph *tg)
{
  boost::vertex_color_t pname;
  VertexColorMap::type pmap = get(pname, *tg);
  return pmap;
}

EdgeCommCostMap::type EdgeCommCostProperty(TaskGraph* tg)
{
  boost::edge_weight_t pname;
  EdgeCommCostMap::type pmap= get(pname, *tg);
  return pmap;
};

EdgeResultSetMap::type EdgeResultSetProperty(TaskGraph* tg)
{
  edge_result_set_t pname;
  EdgeResultSetMap::type pmap = get(pname, *tg);
  return pmap;
};

EdgePriorityMap::type EdgePriorityProperty(TaskGraph* tg)
{
  edge_priority_t pname;
  EdgePriorityMap::type pmap = get(pname, *tg);
  return pmap;
};


void setPriority(EdgeID edge, int p, TaskGraph *tg)
{
  put(EdgePriorityProperty(tg),edge,p);
}

int getPriority(EdgeID edge, TaskGraph *tg)
{
  return get(EdgePriorityProperty(tg),edge);
}

void setResultSet(EdgeID edge, ResultSet &set, TaskGraph *tg)
{
  put(EdgeResultSetProperty(tg),edge,set);
}

ResultSet& getResultSet(EdgeID edge, TaskGraph *tg)
{
  return get(EdgeResultSetProperty(tg),edge);
}

void setTaskType(VertexID task, TaskType t, TaskGraph *tg)
{
  put(VertexTaskTypeProperty(tg),task,t);
}

TaskType getTaskType(VertexID task, TaskGraph *tg)
{
  return get(VertexTaskTypeProperty(tg),task);
}

boost::default_color_type getVertexColor(VertexID v, TaskGraph *tg)
{
  return get(VertexColorProperty(tg),v);
}

void setVertexColor(VertexID v, boost::default_color_type  color, TaskGraph *tg)
{
  put(VertexColorProperty(tg),v,color);
}

int getCommCost(EdgeID edge,TaskGraph * tg)
{
  return get(EdgeCommCostProperty(tg),edge);;
}


void setCommCost(EdgeID edge, int weight,TaskGraph * tg)
{
  put(EdgeCommCostProperty(tg),edge, weight);
}

int getTaskID(VertexID v,const TaskGraph * tg)
{
  return get(VertexUniqueIDProperty((TaskGraph*)tg),v);
}

double getExecCost(VertexID v, const TaskGraph * tg)
{
  return get(VertexExecCostProperty((TaskGraph*)tg),v);
}


void setExecCost(VertexID v, double weight,TaskGraph * tg)
{
  put(VertexExecCostProperty(tg),v,weight);
}

void nameVertex(VertexID task,TaskGraph *tg, const string *s)
{
  put(VertexNameProperty(tg),
      task,
      *s);
}

void nameVertex(VertexID task, TaskGraph *tg,const char *s)
{
 put(VertexNameProperty(tg),
     task,
     s);
}

string & getVertexName(VertexID task,TaskGraph *tg)
{
  return get(VertexNameProperty(tg),task);
}

void setResultName(VertexID task, string &s, TaskGraph *tg)
{
 put(VertexResultNameProperty(tg),
     task,
     s);
}
string & getResultName(VertexID task, TaskGraph *tg)
{
  return get(VertexResultNameProperty(tg),task);
}

void setOrigName(VertexID task, string &s, TaskGraph *tg)
{
 put(VertexOrigNameProperty(tg),
     task,
     s);
}
string & getOrigName(VertexID task, TaskGraph *tg)
{
  return get(VertexOrigNameProperty(tg),task);
}


string * genTemp()
{
  ostringstream str;

  str << "tmp" << tempNo++;
  return new string(str.str());
}

string & insert_strings(string &s, vector<string> &v)
{
  unsigned int i;
  for(i=0; i<v.size(); i++) {
    string::size_type pos=s.find("%s");
    if (pos == s.npos) {
      // If replicated node is generated code for, the string insertion
      // has already taken place. just return.
      // Not nice because can't perform check of format string against vector.
      // Redesign requires unique tasks replicated in rewrite rules.
      return s;
    }
    s.replace(pos,2,v[i]);
  }
  return s;
}


std::pair<ChildrenIterator, ChildrenIterator>
children(VertexID v, const TaskGraph &tg)
{
  boost::graph_traits<TaskGraph>::out_edge_iterator e,e_end;
  // OutEdgeIterator e,e_end;
  tie(e,e_end) = out_edges(v,tg);
  ChildrenIterator c(e,&tg),c_end(e_end,&tg);
  return make_pair(c,c_end);
}

 std::pair<ParentsIterator, ParentsIterator>
 parents(VertexID v, const TaskGraph &tg)
{
  InEdgeIterator e,e_end;
  tie(e,e_end) = in_edges(v,tg);
  ParentsIterator c(e,&tg),c_end(e_end,&tg);
  return make_pair(c,c_end);
}

// Return iterators to the siblings of a node, i.e the parents of the nodes children (excluding the node itself)

std::list<VertexID>*
siblings( VertexID, const TaskGraph &tg)
{
  std::list<VertexID> *res=new std::list<VertexID>();

  return res;
}

EdgeID add_edge(VertexID parent, VertexID child, TaskGraph *tg,
	      ResultSet &rset)
{
  EdgeID e;
  bool edge_exist;
  tie(e,edge_exist)= edge(parent,child,*tg);

  if (edge_exist) {
    setCommCost(e,getCommCost(e,tg)+1,tg);
    ResultSet & s=getResultSet(e,tg);
    s.make_union(&rset);
  }
  else {
    bool succeed;
    tie(e,succeed) = boost::add_edge(parent,child,*tg);
    setCommCost(e,1,tg);
    setResultSet(e,rset,tg);
  }
  return e;
}

EdgeID add_edge(VertexID parent, VertexID child, TaskGraph *tg,
	      string * result,int prio)
{
  EdgeID e;
  bool edge_exist;
  tie(e,edge_exist)= edge(parent,child,*tg);

  if (edge_exist) {
    setCommCost(e,getCommCost(e,tg)+1,tg);
    if (result) {
      ResultSet & s=getResultSet(e,tg);
      s.insert(pair<string,int>(*result,prio));
    }
  }
  else {
    bool succeed;
    tie(e,succeed) = boost::add_edge(parent,child,*tg);
    setCommCost(e,1,tg);
    setResultSet(e,make_resultset(result,prio),tg);
  }
  return e;
}

const int max_result_sets=max_nodes;
static int curNo=0;
const int maxNo=200000;
static ResultSet sets[maxNo];
// Create a result_set given a first result entry.
ResultSet& make_resultset(string *firstelt, int prio)
{
  ResultSet & set=sets[curNo++];
  if (curNo == maxNo) {
    cerr << "Error, ResultSet allocator reached maximum no :" << maxNo << endl;
    exit(-1);
  }
  if (firstelt) {
    set.insert(pair<string,int>(*firstelt,prio));
    //cerr << "Creating resultset with elt: " << *firstelt << endl;
  }
  return set;
}

ResultSet& copy_resultset(ResultSet &s)
{
  ResultSet & set=sets[curNo++];
  if (curNo == maxNo) {
    cerr << "Error, ResultSet allocator reached maximum no :" << maxNo << endl;
    exit(-1);
  }
  std::set<string>::iterator vname;
  for( vname= s.m_set.begin(); vname != s.m_set.end(); vname++) {
    map<string,int>::iterator pit;
    pit = s.m_map.find(*vname);
    if (pit != s.m_map.end()) {
      set.insert(pair<string,int>(*vname,pit->second));
    } else {
      assert(0);
    }
  }
  return set;
}

//Find a task in a taskgraph that has the unique id taskID
// TODO: Fix this lousy performace problem. Not ok to traverse all tasks!!!
VertexID find_task(int taskID, TaskGraph *tg)
{

  VertexIterator v,v_end;
  //cerr << "Warning, calling slow find_task function." << endl;
  for (tie(v,v_end) = vertices(*tg);v != v_end; v++) {
    if (getTaskID(*v,tg) == taskID)
      return *v;
  }
  cerr << "Error. Could not find task with ID: " << taskID << "in taskgraph."
       << endl;
  exit(-1);
}

/* Set index property for the complete task graph*/
void initialize_index(TaskGraph *tg)
{
  VertexIterator v,v_end;
  int i;

  for ( i=0,tie(v,v_end) = vertices(*tg); v != v_end; v++,i++) {
    put(VertexIndexProperty(tg),*v,i);
  }
}
