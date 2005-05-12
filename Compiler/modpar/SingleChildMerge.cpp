#include "SingleChildMerge.hpp"

SingleChildMerge::SingleChildMerge(TaskGraph *tg,TaskGraph * orig_tg,
				   ContainSetMap *cmap, 
				   VertexID inv, VertexID outb, 
				   double l, double B,int nproc,map<VertexID,bool> *removed) 
  : MergeRule(tg,orig_tg,cmap,inv,outb,l,B,nproc,removed) 
{

}

bool SingleChildMerge::apply(VertexID v)
{
  ChildrenIterator c,c_end;
  bool change = false;
  if (out_degree(v,*m_taskgraph) == 1) {
    // tie(e,e_end) = out_edges(v,*m_taskgraph);
    tie(c,c_end) = children(v,*m_taskgraph);
    if (in_degree(*c,*m_taskgraph) == 1) {
      //cerr << "SingleChildMerge, parent: " << getTaskID(v,m_taskgraph)
      //   << " child: " << getTaskID(*c,m_taskgraph) << endl;
      mergeTasks(v,*c);
      //cerr << "parent now contains: " ;
      //printContainTasks(v,cerr); 
      //cerr << endl; 
      change=true;
    } 
  }
  return change;
}

void SingleChildMerge::mergeTasks(VertexID n1, VertexID n2)
{
  VertexID p,c;
  OutEdgeIterator oute,oute_end;
  InEdgeIterator ine,ine_end;
  tie(p,c)=determineParent(n1,n2);

  set<VertexID> parents,children;
  set<VertexID>::iterator child;

  for (tie(ine,ine_end)=in_edges(p,*m_taskgraph); ine != ine_end; ++ine) {
    assert(p != source(*ine,*m_taskgraph));
    parents.insert(source(*ine,*m_taskgraph));
  }
  for (tie(oute,oute_end)= out_edges(c,*m_taskgraph); oute != oute_end; ++oute) {
    assert(c != target(*oute,*m_taskgraph));
    children.insert(target(*oute,*m_taskgraph)); 
  }
  // Add edges from newtask = p to children and update costs.
  for(child = children.begin(); child != children.end(); ++child) {
    EdgeID newEdge,oldEdge;
    bool tmp;
    tie(newEdge,tmp)= add_edge(p,*child,*m_taskgraph);
    tie(oldEdge,tmp) = edge(c,*child,*m_taskgraph);

    //cerr << "old cost: " << getCommCost(oldEdge) << endl;
    setCommCost(newEdge,
		getCommCost(oldEdge),m_taskgraph);
  }


  addContainsTask(p,c); // Need to store that c is in p to be able to
			// go back to orig task graph when generating code.

  // Remove task and edges to the task
  (*m_taskRemoved)[c]=true;
  clear_vertex(c,*m_taskgraph);
  

  remove_vertex(c,*m_taskgraph);
}

pair<VertexID,VertexID> 
SingleChildMerge::determineParent(VertexID n1, VertexID n2)
{
  EdgeID e;
  bool found;
  tie(e,found) = edge(n1,n2,*m_taskgraph);

  if (found) return pair<VertexID,VertexID>(n1,n2);
  
  tie(e,found) = edge(n2,n1,*m_taskgraph);
  assert(found);
  return pair<VertexID,VertexID>(n2,n1);
}
