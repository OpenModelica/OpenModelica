#include "DuplicateParentMerge.hpp"


DuplicateParentMerge::DuplicateParentMerge(TaskGraph *tg,TaskGraph * orig_tg,
					   ContainSetMap *cmap, 
					   VertexID inv, VertexID outv,
					   double l,double B)
 : MergeRule(tg,orig_tg,cmap,inv,outv,l,B)
{
}

bool DuplicateParentMerge::apply()
{ 
  VertexIterator v,v_end;
  bool change = true;
  vector<bool>* cond1,*cond2;
  while(change) {
    change = false;
    for(tie(v,v_end) = vertices(*m_taskgraph); v!=v_end; ++v) {
      if (*v != m_invartask && *v != m_outvartask) {
	if (out_degree(*v,*m_taskgraph) > 1 &&
	    !containTask(m_outvartask,children(*v,*m_taskgraph)) &&
	    numberOfTrues(cond1=newTlevelLower(children(*v,*m_taskgraph),
					       *v)) > 0 &&
	    numberOfTrues(cond2=siblingCondition(children(*v,*m_taskgraph),
						 *v)) > 0)
	  {
	    // do the merge, split children in two groups, one fulfilling
	    // the merge, the other not fulfilling the merge...
	    duplicateParent(*v,
			    duplicateParentSelectFulfill(
							 children(*v,*m_taskgraph),
							 cond1,cond2),
			    duplicateParentSelectNotFulfill(
							    children(*v,*m_taskgraph),
							    cond1,cond2)
			    );
	    delete cond1; delete cond2;
	    // Do the merge
	    change=true;
	    break;
	  }
      }
    }
  } 
  return change;
}

bool DuplicateParentMerge::containTask(VertexID task, 
				  std::pair<ChildrenIterator, ChildrenIterator> pair)
{
  ChildrenIterator c,c_end;
  for (tie(c,c_end)=pair; c != c_end; c++) {
    if (task ==*c) {
      return true;
    }
  }
  return false;
}

// Returns a list of the children that fullfill both conditions.
list<VertexID>*
DuplicateParentMerge::duplicateParentSelectFulfill(pair<ChildrenIterator,ChildrenIterator> pair,
						   vector<bool>* cond1,
						   vector<bool>* cond2)
{
  list<VertexID> * lst = new list<VertexID>();
  ChildrenIterator c,c_end;
  vector<bool>::iterator c1,c2;
  assert(cond1->size() == cond2->size()); // sizes should agree
  tie(c,c_end) = pair;
  for (c1=cond1->begin(),c2=cond2->begin(); c1 != cond1->end(); c1++,c2++,c++) {
    if (*c1 && *c2) {
      lst->insert(lst->begin(),*c);
    }
  }
  return lst;
}
list<VertexID>*
DuplicateParentMerge::duplicateParentSelectNotFulfill(pair<ChildrenIterator,ChildrenIterator> pair,
						      vector<bool>* cond1,
						      vector<bool>* cond2)
{
  list<VertexID> * lst = new list<VertexID>();
  ChildrenIterator c,c_end;
  vector<bool>::iterator c1,c2;
  assert(cond1->size() == cond2->size()); // sizes should agree
  tie(c,c_end) = pair;
  for (c1=cond1->begin(),c2=cond2->begin(); c1 != cond1->end(); c1++,c2++,c++) {
    if (!(*c1 && *c2)) {
      lst->insert(lst->begin(),*c);
    }
  }
  return lst;
}

// For use in duplicateParentMerge. True means that parent can be merged into 
// child without affecting overall cost.
vector<bool> *
DuplicateParentMerge::newTlevelLower(pair<ChildrenIterator ,ChildrenIterator> pair,
				     VertexID parent)
{
  ChildrenIterator v,v_end;
  tie(v,v_end) = pair;
  vector<bool> *res=new vector<bool>(out_degree(parent,*m_taskgraph));
  
  for (int i=0; v != v_end; v++,i++) {
    EdgeID e; bool tmp;
    tie(e,tmp)=edge(parent,*v,*m_taskgraph);
    assert(tmp);
    
    if (*v == m_invartask) {  // Ugly: invar shoudl not be duplicated.
      (*res)[i]=false;
    }
    if (getExecCost(*v) <= m_latency 
	+ getCommCost(e)/m_bandwidth) {
      (*res)[i]=true;
    } else {
      (*res)[i]=false;
    }
  } 
  return res;
}

// For use in duplicateParentMerge. True indicates that a sibling to the
// parent node will not be affected by merging in a duplicated parent into the 
// child.
vector<bool> *
DuplicateParentMerge::siblingCondition(pair<ChildrenIterator,ChildrenIterator> pair,
				       VertexID parent)
{
  ChildrenIterator c,c_end;
  tie(c,c_end) = pair;
  int i;
  vector<bool> *res=new vector<bool>(out_degree(parent,*m_taskgraph)); 
  
  for (i=0; c != c_end; c++,i++) {
    if ( allSiblingsCondition(parents(*c,*m_taskgraph),*c,parent)) {
      (*res)[i]=true;
    } else {
      (*res)[i]=false;
    }
  } 
  return res;
}

bool 
DuplicateParentMerge::allSiblingsCondition(std::pair<ParentsIterator,ParentsIterator> pair,
					   VertexID child,
					   VertexID parent)
{
  bool res=true;
  EdgeID e; bool tmp;
  ParentsIterator sibl,sibl_end;

  for(  tie(sibl,sibl_end) = pair; sibl != sibl_end; sibl++) {
    if (*sibl != parent) {
      tie(e,tmp) = edge(*sibl,child,*m_taskgraph);
      assert(tmp); // Edge must exist
      
      res = res && 
	tlevel(child) >= tlevel(*sibl) + m_latency 
	+ getCommCost(e)/m_bandwidth;
    }
  }
  return res;
}

// Deletes the vector when finished.
int DuplicateParentMerge::numberOfTrues(vector<bool> *v) 
{
  int res=0;
  vector<bool>::iterator it;
  for(it=v->begin(); it != v->end(); it++) {
    if (*it) res++;
  }
  return res;
}

void DuplicateParentMerge::printVertexList(const list<VertexID> &lst,ostream &os)
{
  list<VertexID>::const_iterator e;
  for (e = lst.begin(); e != lst.end(); ) {
    os  << getTaskID(*e,m_taskgraph); 
    e++; 
    if (e != lst.end()) os << ", ";
  }
}

// Duplicate parent into each of the child in the mergeChildren list and keep
// the edges to each child in the nonmergeChildren list.
void DuplicateParentMerge::duplicateParent(VertexID parent,
					   list<VertexID>*mergeChildren,
					   list<VertexID>*nonmergeChildren)
{
  ParentsIterator p2,p2_end;
  list<VertexID>::iterator child;

  //cerr << "DuplicateParent. parent: " << getTaskID(parent,m_taskgraph) 
  //     << " mergeChildren: "; 
  //printVertexList(*mergeChildren,cerr);
  //cerr << " nonMergeChildren: ";
  //printVertexList(*nonmergeChildren,cerr);
  //cerr << endl;
    
    
  if (nonmergeChildren->size() == 0) {// When parent merged into -all- children
				      // delete parent.
    for(child=mergeChildren->begin(); child != mergeChildren->end(); child++) {
      for (tie(p2,p2_end) = parents(parent,*m_taskgraph); p2 != p2_end ;p2++) {
	add_edge(*p2,*child,m_taskgraph);
	ResultSet &s=getResultSet(edge(*p2,parent,*m_taskgraph).first,
				  m_taskgraph);
	ResultSet &newSet = getResultSet(edge(*p2,*child,*m_taskgraph).first,
					 m_taskgraph);
	newSet.make_union(&s);
	
      }
      addContainsTask(*child,parent);
    }
    clear_vertex(parent,*m_taskgraph);
    remove_vertex(parent,*m_taskgraph);
  } else {
    for (tie(p2,p2_end) = parents(parent,*m_taskgraph); p2 != p2_end ;p2++) {
      remove_edge(*p2,parent,*m_taskgraph);
    }
    
    for(child=mergeChildren->begin(); child != mergeChildren->end(); child++) {
      for (tie(p2,p2_end) = parents(parent,*m_taskgraph); p2 != p2_end ;p2++) {
	add_edge(*p2,*child,m_taskgraph);
	ResultSet &s=getResultSet(edge(*p2,parent,*m_taskgraph).first,
				  m_taskgraph);
	ResultSet &newSet = getResultSet(edge(*p2,*child,*m_taskgraph).first,
					 m_taskgraph);
	newSet.make_union(&s);
      }
      addContainsTask(*child,parent);
    }
  }
  //cerr << "parent now contains:" ;
  //printContainTasks(parent,cerr);
  //cerr << endl;
}
					  
