#ifndef _SCHEDULE_HPP
#define _SCHEDULE_HPP

#include "TaskGraph.hpp"
#include "reverse_depth_first_search.hpp"

#include <boost/graph/breadth_first_search.hpp>
#include <boost/graph/depth_first_search.hpp>
#include <queue>
using namespace std;
using namespace boost;
//Typedefs



// Return the favourite predecessor of a task 
VertexID get_fpred(VertexID u, const TaskGraph &g,map<VertexID,VertexID>*fpred);
// Return earliest start value of a task
double get_est(VertexID u, const TaskGraph &g,map<VertexID,double>* est);
//Return earliest completion value of a task
double get_ect(VertexID u, const TaskGraph &g,map<VertexID,double>*ect);
//Return the level of a task, stored in a map
double get_level(VertexID u, const TaskGraph &g,map<VertexID,double>*level);
double get_lst(VertexID u, const TaskGraph &g,map<VertexID,double> *lst);
//Return lct 
double get_lct(VertexID u, const TaskGraph &g, map<VertexID,double>*lct);
// Class for visiting each node in bfs manner, used for pass1 of tds algorithm

class pass1_visitor : public boost::default_reverse_dfs_visitor {
public:
  pass1_visitor(map<VertexID,double>*ect,
		map<VertexID,double>*est,
		map<VertexID,VertexID>*fpred) : m_ect(ect),
						m_est(est),
						m_fpred(fpred) { };
  void finish_vertex(VertexID u, const TaskGraph & g)
  {
    calc_est(u,g);
    calc_ect(u,g);
    calc_fpred(u,g);
  };
  void calc_ect(VertexID u, const TaskGraph & g) {
    double est = get_est(u,g,m_est);
    (*m_ect)[u] = est + getExecCost(u,&g);
  };
  void calc_est(VertexID u, const TaskGraph & g) {
    ParentsIterator p,p_end,p2,p2_end;
    double minVal=1.0e99,maxVal;
    if (in_degree(u,g) == 0) {
          (*m_est)[u] = minVal;
    } else {
      tie(p,p_end) = parents(u,g);
      maxVal = get_ect(*p,g,m_ect);
      for (; p != p_end; p++) {
	for (tie(p2,p2_end) = parents(u,g); p2 != p2_end; p2++) {
	  if (*p2 != *p) {
	    maxVal = max(maxVal,get_ect(*p2,g,m_ect)+getExecCost(*p2,&g));
	  }
	}
	minVal = min(minVal,maxVal);
      }
      (*m_est)[u] = minVal;
    }
  };
    
  void calc_fpred(VertexID u, const TaskGraph &g) {
    double maxVal=-1;
    ParentsIterator p,p_end;
    for(tie(p,p_end) = parents(u,g); p != p_end; p++) {
      if (get_ect(u,g,m_ect) + getExecCost(u,&g) > maxVal) {
	maxVal = get_ect(u,g,m_ect) + getExecCost(u,&g);
	(*m_fpred)[u] = *p;
      }
    }
  };
  map<VertexID,double> *m_ect;
  map<VertexID,double> *m_est;
  map<VertexID,VertexID> *m_fpred;
 
};

class level_visitor: public default_dfs_visitor {
public:
  level_visitor(map<VertexID,double>*level) : m_level(level) { }
  void finish_vertex(VertexID u, const TaskGraph & g) 
  {
    calc_level(u,g);
  };

  void calc_level(VertexID u, const TaskGraph & g)
  {
    ChildrenIterator c,c_end;
    double maxVal=0;
    for (tie(c,c_end)=children(u,g); c != c_end; c++) {
      maxVal = max(maxVal,get_level(*c,g,m_level)+getExecCost(*c,&g));
    }
    (*m_level)[u] = maxVal;
    //cerr << "level for task "<< u << " = " << maxVal<< endl;
  };
protected:
  
  map<VertexID,double> *m_level;
};

class pass2_visitor : public default_dfs_visitor {
public:
  pass2_visitor(map<VertexID,double>*lst,
		map<VertexID,double>*lct,
		map<VertexID,double>*ect,
		map<VertexID,double>*level,
		map<VertexID,VertexID>*fpred) : m_lst(lst),
						m_lct(lct),
						m_ect(ect),
						m_level(level),
						m_fpred(fpred) { };
  void finish_vertex(VertexID u, const TaskGraph & g) 
  {
    calc_lct(u,g);
    calc_lst(u,g);
    calc_level(u,g);
  };
  
  void calc_lst(VertexID u, const TaskGraph & g)
  {
    (*m_lst)[u] = get_lct(u,g,m_lct) - getExecCost(u,&g);
  };
  void calc_lct(VertexID u, const TaskGraph & g)
  {
    ChildrenIterator c,c_end;
    double min1=1e99,min2=1e99;
    if (out_degree(u,g) == 0) {
      (*m_lct)[u] = get_ect(u,g,m_ect);
      (*m_level)[u] = getExecCost(u,&g);
    } else {
      for (tie(c,c_end)=children(u,g); c != c_end; c++) {
	if (get_fpred(*c,g,m_fpred) == u) {
	  min1 = min(min1,get_lst(*c,g,m_lst) - getExecCost(*c,&g));
	} else {
	  min2 = min(min2, get_lst(*c,g,m_lst));
	}
      }
      (*m_lct)[u] = min(min1,min2);
    }
  };
  void calc_level(VertexID u, const TaskGraph & g)
  {
    ChildrenIterator c,c_end;
    double maxVal=0;
    for (tie(c,c_end)=children(u,g); c != c_end; c++) {
      //cerr << "Child execcost="<< getExecCost(*c,&g) << endl;
      maxVal = max(maxVal,get_level(*c,g,m_level)+getExecCost(*c,&g));
    }
    (*m_level)[u] = maxVal;
    //    cerr << "level for task "<< u << " = " << maxVal<< endl;
  };
protected:
  
  map<VertexID,double>*m_lst;
  map<VertexID,double>*m_lct;
  map<VertexID,double>*m_ect;
  map<VertexID,double>*m_level;
  map<VertexID,VertexID>*m_fpred;
};


// Comparison class for sorting vertices in levelorder.
class LevelCmp 
{
public:
  LevelCmp(TaskGraph*tg, map<VertexID,double>*level) : m_level(level),
						       m_taskgraph(tg) {};
  bool operator()(VertexID &v1,VertexID &v2)  
  {
    return get_level(v1,*m_taskgraph,m_level) > get_level(v2,*m_taskgraph,m_level);
  };
private:
  map<VertexID,double> *m_level;
  TaskGraph * m_taskgraph;
};

// The inverse order for level comparisons
class InvLevelCmp 
{
public:
  InvLevelCmp(TaskGraph*tg, map<VertexID,double>*level) : m_level(level),
						       m_taskgraph(tg) {};
  bool operator()(VertexID &v1,VertexID &v2)  
  {
    return get_level(v1,*m_taskgraph,m_level) < get_level(v2,*m_taskgraph,m_level);
  };
private:
  map<VertexID,double> *m_level;
  TaskGraph * m_taskgraph;
};

typedef priority_queue<VertexID,vector<VertexID>,LevelCmp> Queue;
typedef priority_queue<VertexID,vector<VertexID>,InvLevelCmp> InvQueue;
typedef InvQueue TaskList; //Resuse inv levelsorted queue as tasklist

class Schedule 
{
public:
  Schedule(TaskGraph*,VertexID start, VertexID end,int nproc);  
  TaskList * get_tasklist(int proc);
    map<VertexID,double>& levelMap() { return m_level; };
  void printSchedule(ostream &os);
  set<int>* getAssignedProcessors(VertexID v);
  bool isAssignedTo(VertexID v, int proc);

private:
  //Methods
  void scheduleTDS();
  void tdsPass1();
  void tdsPass2();
  void tdsPass3();
  void tdsPass4();
  int mergeTasks();
  void mergeTaskLists(TaskList *t1, TaskList *t2);
  int getTaskListIndex(TaskList *t);
  void reorderTaskLists();

  void assignProcessor(VertexID,int);
  int  newProcessor();
  void setAssigned(VertexID,int);
  int isAssigned(VertexID);
  double level(VertexID v);
  double lst(VertexID v);
  double lct(VertexID v);
  double est(VertexID v);
  double ect(VertexID v);

  double calcTaskListCost(TaskList *t);

  
  // Data
  map<int,TaskList*> m_proclists;

  bool m_allmerged;
  
  int m_nproc;
  TaskGraph *m_taskgraph;
  
  VertexID m_start;
  VertexID m_end;
  map<VertexID, int> m_latest_assigned;
  map<VertexID, set<int>* > m_assigned;
  
  // TDS attributes
  map<VertexID, double> m_ect;
  map<VertexID, double> m_est;
  map<VertexID, VertexID> m_fpred;
  map<VertexID, double> m_level;
  map<VertexID, double> m_lst;
  map<VertexID, double> m_lct;
  
  
  Queue* m_queue; // Priority queue for vertices (levelorder)
};

#endif //_SCHEDULER_HPP
