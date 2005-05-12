#include "MergeAllParents.hpp"
#include <time.h>

MergeAllParents::MergeAllParents(TaskGraph *tg,TaskGraph *orig_tg,
				 ContainSetMap *cmap, 
				 VertexID inv, VertexID outv,
				 double l,double B, int nproc,map<VertexID,bool>* removed)
 : MergeRule(tg,orig_tg,cmap,inv,outv,l,B,nproc,removed)
{
}

bool MergeAllParents::apply(VertexID v)
{
  bool change = false;
  if (v != m_invartask && v != m_outvartask) { 
    set<VertexID> A, B;
    if (in_degree(v,*m_taskgraph) > 1 && 

	    tlevel(v) > maxTlevel(parents(v,*m_taskgraph))  
				       + totalExecCost(parents(v,*m_taskgraph),v) 
	    /* &&
	       calculateAB(parents(v,*m_taskgraph),v,A,B) > 0  */
	    ) {
	  calculateAB(parents(v,*m_taskgraph),v,A,B);
	  // Do the merge
	  //cerr << "MergeAllParents, child: "<< getTaskID(v,m_taskgraph) << " (";
	  //printContainTasks(v,cerr);
	  //cerr << ")" << endl;
	  //cerr << "parents :" ;
	  //ParentsIterator p,p_end;	    
	  //for (tie(p,p_end)=parents(v,*m_taskgraph); p != p_end; p++) {
	  // cerr << getTaskID(*p,m_taskgraph) << "(" ;
	  // printContainTasks(*p,cerr);
	  // cerr << ")  " ;
	  //  }
	  //cerr << endl;
	  // cerr << "siblings (A: " ;
	  //printVertexSet(A,cerr);
	  //cerr << endl << "A complement: " ;
	  //printVertexSet(B,cerr);
	  //cerr << endl;

	  mergeAll(parents(v,*m_taskgraph),v,A,B);
	  //cerr << "parent now contains: " ;
	  //printContainTasks(v,cerr); 
	  //cerr << endl;
	  change=true;
	}
  }
  return change;
}

/* Calculate  the set A: The set of siblings to head
   that is not delayed by merging head with its predecessors.
   Returned by reference, also returning size as return value.
*/
int MergeAllParents::calculateAB(std::pair<ParentsIterator, ParentsIterator> pair,
				 VertexID head,
				 set<VertexID> &A,
				 set<VertexID> &B)

{
  int size=0;
  double tlevel_newc = maxTlevel(parents(head,*m_taskgraph))
    + totalExecCost(pair,head); //This calcuation is not correct. It should be even lower.

  ParentsIterator p,p_end;
  ChildrenIterator c, c_end;
  for (tie(p,p_end)=pair; p != p_end; p++) {
    if (*p != m_invartask) {
      for (tie(c,c_end) = children(*p,*m_taskgraph); c != c_end; c++) {
	if (*c != head) {
	  EdgeID e; bool tmp;
	  tie(e,tmp) = edge(*p,*c,*m_taskgraph);
	  assert(tmp);
	  if (tlevel(*p) > tlevel_newc + 
	      getCommCost(e)/m_bandwidth + m_latency ) {
	  A.insert(*c); // A - set of siblings not affecting merge.
	  size++;
	  } else {
	      B.insert(*p); // B - set of parents to be kept.
	  }
	}
      }
    } else { // invartask should not be merged.
      B.insert(*p);
    }
  }
  //cerr << "calculateAB, size =" << size << endl;
  return size;
}


bool MergeAllParents::containTask(VertexID task, 
				  std::pair<ParentsIterator, ParentsIterator> pair)
{
  ParentsIterator p,p_end;
  for (tie(p,p_end)=pair; p != p_end; p++) {
    if (task ==*p) {
      return true;
    }
  }
  return false;
}

void MergeAllParents::mergeAll(std::pair<ParentsIterator,ParentsIterator> pair,
			       VertexID child,
			       set<VertexID> &A,
			       set<VertexID> &B)
{
  set<VertexID> parents2;
  set<VertexID> parents1;
  set<VertexID>::iterator pit,Aelt,Belt;	
  ParentsIterator p,p_end,p2,p2_end;
  InEdgeIterator e,e_end;
  
  for (tie(p,p_end) = pair; p != p_end; p++) {
    if (*p != m_invartask) {
      parents1.insert(*p);
    }
  }

  for (pit=parents1.begin(); pit != parents1.end(); pit++) {
    addContainsTask(child,*pit);
    
    for (tie(p2,p2_end) = parents(*pit,*m_taskgraph); p2 != p2_end; p2++) {
      if (parents1.find(*pit) == parents1.end() && *p2 != m_invartask)
	parents2.insert(*p2);
    }
    // Add edge from parents^2 to child
    for(tie(e,e_end) = in_edges(*pit,*m_taskgraph); e != e_end; e++) {
      // Adding edge here invalidates pair iterators
      if (parents1.find(source(*e,*m_taskgraph)) == parents1.end()) {
	EdgeID newEdge = add_edge(source(*e,*m_taskgraph),child,m_taskgraph);
	ResultSet &set = getResultSet(newEdge,m_taskgraph);
	ResultSet &oldSet = getResultSet(*e,m_taskgraph);
	set.make_union(&oldSet);
      }
    }
  }

  // Add edge from new node to all in A
  for (Aelt=A.begin(); Aelt != A.end(); Aelt++) {
    add_edge(child,*Aelt,m_taskgraph);    
  }

  // Can not iterate through pair since add_edge above invalidates that 
  // iterator.	
  for (pit=parents1.begin(); pit != parents1.end(); pit++) {
    if (B.find(*pit) == B.end() && *pit != m_invartask) {
      (*m_taskRemoved)[*pit] = true;
      clear_vertex(*pit,*m_taskgraph);
      remove_vertex(*pit,*m_taskgraph);
    }
  }
  
  // Remove edges from elts in B to child, the elts are already dupl. into child.
  for (Belt = B.begin(); Belt != B.end(); Belt++) {
    remove_edge(*Belt,child,*m_taskgraph);
  }
}

double MergeAllParents::maxTlevel(std::pair<ParentsIterator, ParentsIterator> pair)
{
  ParentsIterator p,p_end;
  double maxVal;
  tie(p,p_end) = pair;
  if (p == p_end) return 0.0;
  maxVal = tlevel(*p++);
  for(; p!= p_end ; p++) {
    double t = tlevel(*p);
    if (t > maxVal) maxVal = t;
  }
  return maxVal;
}

bool MergeAllParents::onlyOneChild(std::pair<ParentsIterator, ParentsIterator> pair)
{
  ParentsIterator c,c_end;
  tie(c,c_end) = pair;
  if (c == c_end) return false; // No children
  bool res=true;
  for (  ; c != c_end; c++) {
    res = res && out_degree(*c,*m_taskgraph) == 1;
  }
  return res;
}

double MergeAllParents::totalExecCost(std::pair<ParentsIterator,ParentsIterator> pair,
				      VertexID parent)
{
  double cost=0.0;
  ContainSet allNodes;
  ParentsIterator p,p_end;
  
  for(tie(p,p_end) = pair; p != p_end; p++) {
    ContainSetMap::iterator set;
    if (*p != m_invartask && *p != m_outvartask) {
      set = m_containTasks->find(*p);
      if (set != m_containTasks->end()) {
	allNodes.make_union((*set).second);
      }
      allNodes.insert(getTaskID(*p,m_taskgraph));    
    }
  }
  
  ContainSet::iterator it;
  for (it = allNodes.begin(); it !=allNodes.end(); it++) {
    cost +=getExecCost(find_task(*it,(TaskGraph*)m_taskgraph));
  }
  cost+= getExecCost(parent);
  return cost;
}

