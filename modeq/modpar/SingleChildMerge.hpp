#ifndef _SINGLECHILDMERGE_HPP
#define _SINGLECHILDMERGE_HPP

#include "MergeRule.hpp"

class SingleChildMerge : MergeRule 
{

public:
  SingleChildMerge(TaskGraph *,TaskGraph *,ContainSetMap *, VertexID, VertexID,
		   double,double);
  bool apply();

private:
  void mergeTasks(VertexID n1, VertexID n2);
  
  pair<VertexID,VertexID> determineParent(VertexID n1, VertexID n2);
};

#endif
