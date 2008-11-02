
#include "Schedule.hpp"
#include "TaskGraph.hpp"
#include <boost/graph/properties.hpp>

VertexID get_fpred(VertexID u, const TaskGraph &g,map<VertexID,VertexID>*fpred)
 {
  map<VertexID,VertexID>::iterator elt;
  elt = fpred->find(u);
  if (elt == fpred->end()) {
    cerr << "Error finding fpred value for node "
	 << getTaskID(u,&g) << endl;
    exit(-1);
  }
  return elt->second;
};
double get_est(VertexID u, const TaskGraph &g,map<VertexID,double>* est) {
  map<VertexID,double>::iterator elt;
  elt = est->find(u);
  if (elt == est->end()) {
    cerr << "Error finding est value for node "
	 << getTaskID(u,&g) << endl;
    exit(-1);
  }
  return elt->second;
};

//Return earliest completion value of a task
double get_ect(VertexID u, const TaskGraph &g,map<VertexID,double>*ect) {
  map<VertexID,double>::iterator elt;
  elt = ect->find(u);
  if (elt == ect->end()) {
    cerr << "Error finding est value for node "
	 << getTaskID(u,&g) << endl;
    exit(-1);
  }
  return elt->second;
};

//Return the level of a task, stored in a map
double get_level(VertexID u, const TaskGraph &g,map<VertexID,double>*level) {
  map<VertexID,double>::iterator elt;
  elt = level->find(u);
  if (elt == level->end()) {
    cerr << "Error finding level value for node "
	 << getTaskID(u,&g) << endl;
    exit(-1);
  }
  return elt->second;
};

double get_lst(VertexID u, const TaskGraph &g,map<VertexID,double> *lst) {
  map<VertexID,double>::iterator elt;
  elt=lst->find(u);
  if (elt == lst->end()) {
    cerr << "Error finding lst value for node "
	 << getTaskID(u,&g) << endl;
    exit(-1);
  }
  return elt->second;
};
//Return lct
double get_lct(VertexID u, const TaskGraph &g, map<VertexID,double>*lct) {
  map<VertexID,double>::iterator elt;
  elt=lct->find(u);
  if (elt == lct->end()) {
    cerr << "Error finding lct value for node "
	 << getTaskID(u,&g) << endl;
    exit(-1);
  }
  return elt->second;
};

Schedule::Schedule(TaskGraph *tg,VertexID start, VertexID end, int nproc)
  :  m_allmerged(true), m_nproc(nproc), m_taskgraph(tg), m_start(start), m_end(end)
{
  //cerr << "m_start = " << getTaskID(m_start,m_taskgraph) << " m_end = " << getTaskID(m_end,m_taskgraph) << endl;

  initialize_index(m_taskgraph);

  // TDS uses level without counting communication cost, thus
  // execcost for start and end node can not be zero because they must be
  // sorted before and after the other nodes.
  setExecCost(m_start,1.0,m_taskgraph);
  setExecCost(m_end,1.0,m_taskgraph);

  scheduleTDS();
}


void Schedule::scheduleTDS()
{
  if (m_nproc < 1) {
    cerr << "Error number of processors < 1" << endl;
    exit(-1);
  }
  //  cerr << "starting tdsPass1" << endl;
  tdsPass1();
  //  cerr << "tdsPass1 done." << endl;
  tdsPass2();
  //  cerr << "tdsPass2 done." << endl;
  tdsPass3();
  //  cerr << "tdsPass3 done." << endl;

  tdsPass4();
  //  cerr << "tdsPass4 done." << endl;

}


void Schedule::tdsPass1()
{
  pass1_visitor vis(&m_ect,&m_est,&m_fpred);
  //  cerr << "Created visitor." << endl;

  reverse_depth_first_search(*m_taskgraph,
			     vis,
			     get(vertex_color, *m_taskgraph),
			     m_end);
}

void Schedule::tdsPass2()
{
  pass2_visitor vis(&m_lst,&m_lct,&m_ect,&m_level,&m_fpred);


  depth_first_search(*m_taskgraph,visitor(vis));


  VertexIterator v,v_end;
  m_queue = new Queue(LevelCmp(m_taskgraph,&m_level));
  for (tie(v,v_end) = vertices(*m_taskgraph); v != v_end; v++) {
    if (*v != m_start && *v != m_end)
      m_queue->push(*v);
  }
}

void Schedule::setAssigned(VertexID v,int proc)
{
  m_latest_assigned[v]= proc;
}

int Schedule::isAssigned(VertexID v)
{
  if (m_latest_assigned.find(v) == m_latest_assigned.end())
    return -1;
  else
    return m_latest_assigned.find(v)->second;
}

bool Schedule::isAssignedTo(VertexID v, int proc)
{
  if (proc < 0 || proc > (int)m_proclists.size()) {
    cerr << "processor out of bounds in isAssignedTo, proc=" << proc << endl;
    return false;
  }
  if (m_assigned.find(v) == m_assigned.end()) {
    return false;
  }
  set<int> *s=m_assigned.find(v)->second;
  if (s->find(proc) == s->end()) {
    return false;
  } else {
    return true;
  }
}

double Schedule::lst(VertexID v)
{
  return get_lst(v,*m_taskgraph,&m_lst);
}

double Schedule::lct(VertexID v)
{
 return get_lct(v,*m_taskgraph,&m_lct);
}

double Schedule::est(VertexID v)
{
  return get_est(v,*m_taskgraph,&m_est);
}

double Schedule::ect(VertexID v)
{
 return get_ect(v,*m_taskgraph,&m_ect);
}

double Schedule::level(VertexID v)
{
  return get_level(v,*m_taskgraph,&m_level);
}
void Schedule::tdsPass3()
{

  VertexID x,y,z;
  ParentsIterator p,p_end;
  int i;
  double cost;
  // Start and end node on processor 0 (Where solver is running)
  i = newProcessor();
  assignProcessor(m_start,i);
  assignProcessor(m_end,i);

  if (m_queue->empty() ) { return; }
  x = m_queue->top(); m_queue->pop();

  if (isAssigned(x)==-1) { // x can be (and should be) m_start
    assignProcessor(x,0);
  }

  while( !m_queue->empty()) {
    //    cerr << " schedule loop. x= " << getTaskID(x,m_taskgraph) << " queue length =" << m_queue->size() << endl ;
    if (in_degree(x,*m_taskgraph) > 0) {
      y = get_fpred(x,*m_taskgraph,&m_fpred);
      //      cerr << "Scheduling. x= " << getTaskID(x,m_taskgraph) << " y= " << getTaskID(y,m_taskgraph) << endl;
      cost = getExecCost(y,m_taskgraph);
      if (isAssigned(y)!= -1) {
	if (lst(x) - lct(y) >= cost) {
	  for (tie(p,p_end) = parents(x,*m_taskgraph); p != p_end; p++) {
	    if (isAssigned(*p)==-1) {
	      y = *p;
	      break;
	    }
	  }
	} else {
	  for (tie(p,p_end) = parents(x,*m_taskgraph); p != p_end; p++) {
	    if (*p != y) {
	      z = *p;
	      if (ect(y) + cost == ect(z)+getExecCost(*p,m_taskgraph) && isAssigned(z)==-1) {
		y = z;
		break;
	      }
	    }
	  }
	}
      }
      if (y != m_start && y != m_end)
	assignProcessor(y,i);
      x=y;
    }
    if (in_degree(x,*m_taskgraph) == 0) {
      //      cerr << "Entry node" << endl;
      //assignProcessor(x,i);
      x = m_queue->top(); m_queue->pop();
      //      cerr << " x=" << getTaskID(x,m_taskgraph) << endl;
      while(isAssigned(x)!=-1) {
	if (m_queue->empty()) break;
	//	cerr << getTaskID(x,m_taskgraph) << " assigned, skipping" <<  endl;
	x = m_queue->top(); m_queue->pop();
      }
      i = newProcessor();
      //      cerr << getTaskID(x,m_taskgraph) << " assigned: " << isAssigned(x) <<  endl;
      if (isAssigned(x)==-1)
	assignProcessor(x,i);
    }
  }
}

double Schedule::calcTaskListCost(TaskList*t)
{
  double cost=0.0;
  TaskList tmp = *t;

  while(!tmp.empty()) {
    VertexID task= tmp.top();
    tmp.pop();
    cost += getExecCost(task,m_taskgraph);
  }
  return cost;
}

int Schedule::mergeTasks(void)
{
  TaskList* lowest;
  TaskList *highest;

  static map<TaskList*,bool> merged;
  double min_cost=1000000;
  double max_cost=-100;
  double procCost;

  /* Find cheapest and the most expensive task lists */
  if (m_allmerged) {
    m_allmerged = false;
    map<int,TaskList*>::iterator i;
    for (i = m_proclists.begin(); i != m_proclists.end(); i++) {
      merged[i->second]=false;
    }
    return -1;
  }
  map<int,TaskList*>::iterator i;
  for(i = m_proclists.begin(); i != m_proclists.end() ; i++ ) {
    procCost = calcTaskListCost(i->second);
    //    cerr << i->second << " :procCost =" << procCost << endl;
    if (!merged[i->second]) {
      if (min_cost > procCost) {
	lowest = i->second;
	min_cost = procCost;
      }
    }
    if (!merged[i->second]) {
      if (max_cost < procCost) {
	highest = i->second;
	max_cost = procCost;
      }
    }
  }
  //  cerr << "highest = " << highest << " lowest = " << lowest << endl;
  //  cerr << "max_cost =" << max_cost << " min_cost =" << min_cost << endl;
  if (highest == lowest) { /* Never merge with itself */
    //    cerr << "Highest == lowest, never merge with itself." << endl;

    map<int,TaskList*>::iterator i; // Take first in queue n
    for( i = m_proclists.begin(); i != m_proclists.end(); i++) {
      if (i->second != lowest && !merged[i->second]) {
	lowest = i->second; break;
      }
    }
    if (highest == lowest) { // Still same, mark as merged and restart
      merged[lowest] = true;
      m_allmerged=true;
      return -1;
    }
  }
  if (max_cost == -100 || min_cost == 1000000 ) {
    m_allmerged = true;
    return 0;
  }
  //  cerr << "About to merge" << endl;
  //  cerr << "chosen :highest = " << highest << " lowest = " << lowest << endl;
  assert(lowest != highest);
  mergeTaskLists(lowest,highest);
  merged[lowest] = true;
  merged[highest] = true;
  return 1;
}

int Schedule::getTaskListIndex(TaskList *t)
{

  map<int,TaskList*>::iterator i;
  for (i = m_proclists.begin(); i != m_proclists.end(); i++) {
    if (i->second == t) return i->first;
  }
  return -1;
}

void Schedule::mergeTaskLists(TaskList *t1, TaskList *t2)
{
  //  cerr << "Merging, t2 =" << t2 << endl;

  int t2indx= getTaskListIndex(t2);
  //  cerr << "t2indx = " << t2indx << endl;
  if (t2indx == 0) { // Proc 0 can not be merged into another processor, swap list
    TaskList *tmp;
    tmp=t1;
    t1=t2;
    t2=tmp;
    t2indx = getTaskListIndex(t2);
  }

  while (!t2->empty()) { // Insert all tasks in t2 into t1
    VertexID task=t2->top();
    map<VertexID,set<int>*>::iterator ma;
    ma = m_assigned.find(task);
    if (ma == m_assigned.end()) {
      cerr << "Error removing m_assigned elt that is not present." << endl;
      exit(-1);
      }
    ma->second->erase(t2indx); // task no longer on processor
    t2->pop();
    t1->push(task);
  }

  //  cerr << "m_proclists.size before :" << m_proclists.size() << endl;
//  cerr << "removing t2:" << t2 << endl;
  m_proclists.erase(t2indx); // .. and remove t2
  // cerr << "m_proclists.size after :" << m_proclists.size() << endl;
}


void Schedule::tdsPass4()
{
  int numProc=m_proclists.size();
  int temp;
  if (m_nproc < numProc) {


      while (m_nproc < numProc) {

	temp = mergeTasks();

	if (temp == -1) {
	  //cerr << "temp == -1, problem?" << endl;

	} else {
	  numProc-= temp;
	  //	  cerr << "reduced by " << temp << " to " << numProc
	  //	       << " (" << m_proclists.size() << ")" << endl;
	}
      }
  }
  if (m_nproc > numProc) {
    cerr << "The number of required processors are smaller than the number of given ones." << endl;
    exit(-1);
  }
  //  cerr << "Reduced no of processors to " << numProc << endl;

  reorderTaskLists();
}

void Schedule::reorderTaskLists()
{

  map<int,TaskList*> newMap;

  map<int,TaskList*>::iterator i;
  int p;
  for( i=m_proclists.begin(),p=0; i != m_proclists.end(); i++,p++) {
    int oldProcNo=i->first;
    TaskList t=*i->second;
    while(!t.empty()) {
      VertexID task = t.top(); t.pop();
      if (m_assigned.find(task) == m_assigned.end()) {
	cerr << "Error can not find m_assigned for task "<< task << endl;
	exit(-1);
      }
      set<int>* s =m_assigned.find(task)->second;
      if (s->erase(oldProcNo)>0) {
	s->insert(p);
      }
    }
    newMap[p]=i->second;
  }
  m_proclists = newMap;
}

void Schedule::assignProcessor(VertexID v, int processor)
{
  if (isAssigned(v) != processor) {
    setAssigned(v,processor);
    //    cerr << "Assign " << getTaskID(v,m_taskgraph) << " to " << processor << endl;

    get_tasklist(processor)->push(v);

    // Since task replication we need set of processors task is assigned to
    if (m_assigned.find(v) == m_assigned.end()) {
      m_assigned[v] = new set<int>;
    }
    m_assigned[v]->insert(processor);
  }
}


TaskList * Schedule::get_tasklist(int processor)
{
  if (processor < 0 || processor > (int)m_proclists.size()) {
    cerr << "Error, processor no. out of bounds. processor =" << processor
	 << " proclist size= " << m_proclists.size() << endl;
    exit(-1);
  }

  map<int,TaskList*>::iterator i=m_proclists.find(processor);
  if (i == m_proclists.end()) {
    cerr<< "get_tasklist: Error no proclist for processor " << processor
	<< " proclist size = " << m_proclists.size() << endl;
    exit(-1);
  }
  return i->second;
}


int Schedule::newProcessor()
{
  static int curProc=-1;

  curProc++;
  m_proclists[curProc]=new TaskList(InvLevelCmp(m_taskgraph,&m_level));

  //  cerr << "newProcessor: " << curProc << endl;
  //  cerr << "size =:" << m_proclists.size() << endl;
  return curProc;
}


void Schedule::printSchedule(ostream &os)
{
  TaskList t(InvLevelCmp(m_taskgraph,&m_level));
  map<int,TaskList*>::iterator i;
  for (i=m_proclists.begin(); i != m_proclists.end(); i++) {
    os << "proc"<< i->first << endl;
    os << "======" << endl;
    t = *(i->second); // Copy so we can pop from it...
    while (!t.empty()) {
      VertexID task=t.top();
      t.pop();
      os << getTaskID(task,m_taskgraph) << ":"<<task<< " (" << m_level[task] << ", "
	 << getExecCost(task,m_taskgraph) << ") ";
    }
    os << endl;
  }
}


set<int> * Schedule::getAssignedProcessors(VertexID v)
{
  if (m_assigned.find(v) == m_assigned.end()) {
    return NULL;
  }
  return m_assigned.find(v)->second;
}
