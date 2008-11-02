#include "MergeRule.hpp"
#include "TaskGraph.hpp"

MergeRule::MergeRule(TaskGraph *tg, TaskGraph *orig_tg,
		     ContainSetMap *cmap, VertexID invar,
		     VertexID outvar, double l, double B,
		     int nproc,
		     map<VertexID,bool>*removed)
  : m_latency(l), m_bandwidth(B),m_nproc(nproc),
    m_taskgraph(tg), m_orig_taskgraph(orig_tg),
    m_containTasks(cmap), m_invartask(invar),
    m_outvartask(outvar), m_taskRemoved(removed)
{
  VertexIterator v,v_end;

  //Maps for fast access to unique ID given VertexID
  for (tie(v,v_end) = vertices(*tg);v != v_end; v++) {
    int id =getTaskID(*v,tg);
    m_VertexIDMap[id]=*v;
  }
  for (tie(v,v_end) = vertices(*orig_tg);v != v_end; v++) {
    int id =getTaskID(*v,tg);
    m_orig_VertexIDMap[id]=*v;
  }
}

// Return the communication cost in the merged task graph.
int MergeRule::getCommCost(EdgeID e)
{
  return ::getCommCost(e,m_taskgraph);
}

// Return the execution cost in the merged task graph.
// VertexID should belong to the merged task graph. (m_taskgraph)
double MergeRule::getExecCost(VertexID v)
{
  double cost =0.0;
  map<int,double>::iterator c;
  ContainSet *cset= m_containTasks->find(v)->second;
  if (cset) {
    ContainSet::iterator i;
    for(i=cset->begin(); i != cset->end() ; i++) {
      cost+= ::getExecCost(find_task(*i,(TaskGraph*)m_orig_taskgraph),
			   m_orig_taskgraph);
    }
    return cost;
  }
  return ::getExecCost(find_task(getTaskID(v,m_taskgraph),m_orig_taskgraph),
		       m_orig_taskgraph);
}

VertexID MergeRule::find_task(int taskID, TaskGraph *tg)
{
  if (tg == m_taskgraph) {
    return m_VertexIDMap[taskID];
  } else if (tg == m_orig_taskgraph) {
    return m_orig_VertexIDMap[taskID];
  } else {
    // Call global taskgraph.
    cerr << "Warning, calling slower find_task function" << endl;
    return ::find_task(taskID,tg);
  }
}

void MergeRule::addContainsTask(VertexID mainTask, VertexID subTask)
{
  ContainSetMap::iterator set1,set2;
  set1=m_containTasks->find(mainTask);
  set2=m_containTasks->find(subTask);

  if (set1 == m_containTasks->end()) { // new set needed
    ContainSet *s = new ContainSet();
    (*m_containTasks)[mainTask] = s;
  }
  if (set2 == m_containTasks->end()) { // new set needed
    ContainSet *s = new ContainSet();
    (*m_containTasks)[subTask] = s;
  }

  set1->second->make_union(set2->second);
}


void MergeRule::printContainTasks(VertexID task, ostream &os)
{
  ContainSet *s=(*m_containTasks)[task];
  set<int>::iterator i;
  for (i=s->begin(); i != s->end(); i++) {
    os << *i << " ";
  }
}

void MergeRule::printVertexSet(set<VertexID> list, ostream &os)
{
  set<VertexID>::iterator i;
  for (i = list.begin(); i != list.end(); i++) {
    os << getTaskID(*i,m_taskgraph) << endl;
  }
}

// Tlevel version for tasks that contain other tasks, i.e. merged tasks
double MergeRule::tlevel(VertexID node)
{
  int i;
  if (in_degree(node,*m_taskgraph) == 0)
    return 0.0;
  else {
    vector<double> tlevels(in_degree(node,*m_taskgraph));
    InEdgeIterator e,e_end;
    tie(e,e_end) = in_edges(node,*m_taskgraph);
    for (i=0; e != e_end; ++e, i++) {
      VertexID p=source(*e,*m_taskgraph);
      // tlevel = max (tlevel(p) + tau(p) + L + c(p,node)/B) forall parents p
      double execsum = 0.0;
      ContainSet::iterator it;
      ContainSet *s =m_containTasks->find(p)->second;
      for (it = s->begin(); it != s->end(); it++) {
	execsum+=getExecCost(find_task(*it,m_taskgraph));
      }
      tlevels[i] = tlevel(p)+ execsum + m_latency
	+ getCommCost(*e)/m_bandwidth;
    }
    return max(tlevels);
  }
}
