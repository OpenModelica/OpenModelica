#ifndef _MERGERULE_HPP
#define _MERGERULE_HPP


#include "TaskGraph.hpp"

class MergeRule
{  
  
public:
  
  virtual bool apply() = 0;
  VertexID find_task(int taskID, TaskGraph *tg);
  double getExecCost(VertexID v); // Execcost in merged tg.
  int  getCommCost(EdgeID e); // Commcost in merged tg.
  double tlevel(VertexID node); // The tlevel for node in merged tg.
protected:
  void addContainsTask(VertexID mainTask, VertexID subTask);
  void printContainTasks(VertexID task, ostream &os);
  void printVertexSet(set<VertexID> list, ostream &os);  

  MergeRule(TaskGraph *,TaskGraph *,ContainSetMap *, VertexID, VertexID,double,double);
  virtual ~MergeRule() {};
  double m_latency;
  double m_bandwidth;
  TaskGraph *m_taskgraph;
  TaskGraph *m_orig_taskgraph;
  ContainSetMap * m_containTasks;
  VertexID m_invartask;
  VertexID m_outvartask;
  map<int,VertexID> m_VertexIDMap;
  map<int,VertexID> m_orig_VertexIDMap;
};





#endif
