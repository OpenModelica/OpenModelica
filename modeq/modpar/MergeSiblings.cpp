#include "MergeSiblings.hpp"

MergeSiblings::MergeSiblings(TaskGraph *tg,TaskGraph * orig_tg,
			     ContainSetMap *cmap, 
			     VertexID inv, VertexID outv,
			     double l,double B, int nproc,
			     map<VertexID,bool>*removed) 
  : MergeRule(tg,orig_tg,cmap,inv,outv,l,B,nproc,removed)
{
}

bool MergeSiblings::apply(VertexID dummy)
{
  bool change = true;
  VertexIterator v,v_end;
  ExecCostQueue exec_queue(TauCmp((MergeRule*)this));
  change = false;    
  for(tie(v,v_end) = vertices(*m_taskgraph); v != v_end; v++) {    
    if (out_degree(*v,*m_taskgraph) == 0 &&
	in_degree(*v,*m_taskgraph) == 0 ) {	  
      exec_queue.push(*v);
      // Do the merge
    }    
  }
  if (exec_queue.size() > 1) {
    change = try_merge(exec_queue);
  } 
 
  return change;
}

bool MergeSiblings::exist_edge(VertexID parent, VertexID child, TaskGraph *tg)
{
  //Perhaps there exist a more efficient way of doing this?
  // If so, we can move the code to TaskGraph.hpp and use it more often.
  // This usage will only have one child, i.e. not so unefficient.
  ChildrenIterator c,c_end;
  for ( tie(c,c_end) = children(parent,*tg); c != c_end; c++) {
    if (*c == child) {
      return true;
    }
  }
  return false;
}


bool MergeSiblings::try_merge(ExecCostQueue & queue) 
{
  VertexID a,b;
  a = queue.top(); queue.pop();
  b = queue.top(); queue.pop();
  double tau_a,tau_b; 
  tau_a = getExecCost(a);
  tau_b = getExecCost(b);
  
  if ( tau_a + tau_b < (2*m_latency + max(tau_a,tau_b))) {
    //cerr << "queue size =" << queue.size() << endl;
    //cerr << "tau_a =" << tau_a << endl;
    //cerr << "tau_b =" << tau_b << endl;
    //cerr << "tau_a + tau_b =" << tau_a + tau_b <<
    //  endl;
    //cerr << "(2*m_latency + max(tau_a,tau_b) =" << (2*m_latency + max(tau_a,tau_b)) << endl;
    //cerr << "MergeSiblings, merging " << getTaskID(a,m_taskgraph) << 
    //  "with execcost =" << tau_a << "    and " <<
    //  getTaskID(b,m_taskgraph) << " with execcost =" << tau_b << endl;
    EdgeID a1,a2,b1,b2; bool tmp;

    addContainsTask(a,b);

    (*m_taskRemoved)[b]=true;
    clear_vertex(b,*m_taskgraph);
    remove_vertex(b,*m_taskgraph);
    queue.push(a);  // The new task is added with new execcost, 
		    // it might be merged again...
    return true;
  } else {
    queue.push(a); //put back if no merge.
    queue.push(b);
    return false;
  }
  return false; // never reached.
}

bool MergeSiblings::try_merge2(ExecCostQueue & queue) 
{
  VertexID a,b;
  a = queue.top(); queue.pop();
  b = queue.top(); queue.pop();
  double tau_a,tau_b; 
  tau_a = getExecCost(a);
  tau_b = getExecCost(b);
  if ( tau_a + tau_b < (m_latency + max(tau_a,tau_b)) && queue.size()>m_nproc) {
    EdgeID a1,a2,b1,b2; bool tmp;
    tie(b2,tmp) = edge(b,m_outvartask,*m_taskgraph);
    tie(a2,tmp) = edge(a,m_outvartask,*m_taskgraph);

    ResultSet &b2_set = getResultSet(b2,m_taskgraph);
    ResultSet &new2_set = getResultSet(a2,m_taskgraph);

    new2_set.make_union(&b2_set);
    setCommCost(a2,new2_set.size(),m_taskgraph);
    
    addContainsTask(a,b);

    (*m_taskRemoved)[b]=true;
    clear_vertex(b,*m_taskgraph);
    remove_vertex(b,*m_taskgraph);
    queue.push(a);  // The new task is added with new execcost, 
		    // it might be merged again...
    return true;
  } else {
    queue.push(a); //put back if no merge.
    queue.push(b);
    return false;
  }
  return false; // never reached.
}
