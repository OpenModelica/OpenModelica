#ifndef _MERGERULE_HPP
#define _MERGERULE_HPP


#include "TaskGraph.hpp"
#include <boost/graph/breadth_first_search.hpp>

class MergeRule 
{  
  
public:
  
  virtual bool apply(VertexID id) = 0;
  VertexID find_task(int taskID, TaskGraph *tg);
  double getExecCost(VertexID v); // Execcost in merged tg.
  int  getCommCost(EdgeID e); // Commcost in merged tg.
  double tlevel(VertexID node); // The tlevel for node in merged tg.

protected:
  void addContainsTask(VertexID mainTask, VertexID subTask);
  void printContainTasks(VertexID task, ostream &os);
  void printVertexSet(set<VertexID> list, ostream &os);  

  MergeRule(TaskGraph *,TaskGraph *,ContainSetMap *, VertexID, VertexID,double,double,int,
	    map<VertexID,bool> *removed);
  virtual ~MergeRule() {};
  double m_latency;
  double m_bandwidth;
  int m_nproc;
  TaskGraph *m_taskgraph;
  TaskGraph *m_orig_taskgraph;
  ContainSetMap * m_containTasks;
  VertexID m_invartask;
  VertexID m_outvartask;
  map<int,VertexID> m_VertexIDMap;
  map<int,VertexID> m_orig_VertexIDMap;

  map<VertexID,bool>* m_taskRemoved;
};





#endif
