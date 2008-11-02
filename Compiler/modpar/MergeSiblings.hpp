#ifndef _MERGESIBLINGS_HPP
#define _MERGESIBLINGS_HPP
#include <queue>
#include "MergeRule.hpp"

/* Merges siblings (a1, a2) given a source and sink node(m_invartask, m_outvartask)

      (S)
      / \
 (c1)/   \ (c2)
    /     \
  (a1)   (a2)
    \     /
(c1')\   / (c2')
      \ /
      (T)

  Condition: tau(a1)+ tau(a2) < 2*l + max(tau(a1),tau(a2)
*/
// Helper class for execcost sorted priority queue
class TauCmp
{
public:
  TauCmp(MergeRule *rule)
    : m_rule(rule) {};
  bool operator()(VertexID &v1,VertexID &v2)
  {
    return m_rule->getExecCost(v1) > m_rule->getExecCost(v2);
  };
private:
  MergeRule *m_rule;
};

typedef priority_queue<VertexID,vector<VertexID>,TauCmp> ExecCostQueue;

// The main class
class MergeSiblings : MergeRule
{
public:
  MergeSiblings(TaskGraph *, TaskGraph*, ContainSetMap*, VertexID, VertexID,
		double, double,int,map<VertexID,bool>*);
  bool apply(VertexID);
private:
  bool exist_edge(VertexID parent, VertexID child, TaskGraph *tg);
  bool try_merge(ExecCostQueue & queue);
};

#endif
