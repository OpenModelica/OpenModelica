#ifndef _MERGEALLPARENTS_HPP
#define _MERGEALLPARENTS_HPP

#include "TaskGraph.hpp"
#include "MergeRule.hpp"

class MergeAllParents : MergeRule
{

public:
  MergeAllParents(TaskGraph *,TaskGraph*,ContainSetMap *, VertexID, VertexID,
		  double,double,int,map<VertexID,bool>*);
  
  bool apply(VertexID);
private:
  int calculateAB(std::pair<ParentsIterator, ParentsIterator> pair,
		  VertexID head,
		  set<VertexID> &A,
		  set<VertexID> &B);
  bool onlyOneChild(std::pair<ParentsIterator, ParentsIterator>);
  bool containTask(VertexID task, std::pair<ParentsIterator, ParentsIterator> pair);
  double maxTlevel(std::pair<ParentsIterator, ParentsIterator>);
  double totalExecCost(std::pair<ParentsIterator,ParentsIterator> pair,
		       VertexID parent);
  void mergeAll(std::pair<ParentsIterator,ParentsIterator> pair,
		VertexID parent, set<VertexID> &A,
		set<VertexID> &B);
};

#endif
