#ifndef _DUPLICATEPARENTMERGE_HPP
#define _DUPLICATEPARENTMERGE_HPP

#include "MergeRule.hpp"




class DuplicateParentMerge : MergeRule
{
public:

  DuplicateParentMerge(TaskGraph *,TaskGraph *,ContainSetMap *, VertexID, VertexID,
		       double,double,int,map<VertexID,bool>*);
  bool apply(VertexID);
  

private:
  bool containTask(VertexID task, 
		   std::pair<ChildrenIterator, ChildrenIterator> pair);
  void printVertexList(const list<VertexID> &lst, ostream &);
  list<VertexID>*
  duplicateParentSelectFulfill(pair<ChildrenIterator,ChildrenIterator> pair,
			       vector<bool>* cond1,
			       vector<bool>* cond2);

  list<VertexID>*
  duplicateParentSelectNotFulfill(pair<ChildrenIterator,ChildrenIterator> pair,
				  vector<bool>* cond1,
				  vector<bool>* cond2);

  vector<bool> *
  newTlevelLower(pair<ChildrenIterator ,ChildrenIterator> pair,
		 VertexID parent);
  vector<bool> *
  siblingCondition(pair<ChildrenIterator,ChildrenIterator> pair,
		   VertexID parent);
  bool 
  allSiblingsCondition(std::pair<ParentsIterator,ParentsIterator> pair,
		       VertexID child,
		       VertexID parent);
  // Deletes the vector when finished.
  int numberOfTrues(vector<bool> *v);

  void duplicateParent(VertexID parent,
		       list<VertexID>*,
		       list<VertexID>*);
};



#endif
