#include "TaskMerging.hpp" 
#include "ParallelOptions.hpp"
#include "SingleChildMerge.hpp"
#include "DuplicateParentMerge.hpp"
#include "MergeAllParents.hpp"
#include "MergeSiblings.hpp"
#include <iostream>
#include <time.h>

extern VertexID merged_start_task;
extern VertexID merged_stop_task;

//Return the tlevel of a task, stored in a map, reused from Schedule
double get_tlevel(VertexID u, const TaskGraph &g,map<VertexID,double>*level) {
  map<VertexID,double>::iterator elt;
  elt = level->find(u);
  if (elt == level->end()) { 
    cerr << "Error finding level value for node " 
	 << getTaskID(u,&g) << endl;
    exit(-1);
  }
  return elt->second;
};


TaskMerging::TaskMerging() : m_latency(0.001), 
			     m_bandwidth(500.0), 
			     m_change(true),
			     m_taskgraph(0),
			     m_containTasks(0),
			     m_num_rules(4)
{
  m_rules = new MergeRule*[m_num_rules];
}

void TaskMerging::initializeRules()
{
  if (!m_taskgraph) {
    cerr << "initializeRules must be called after taskgraph has been initialized.\n" << endl;
    exit(-1);
  }

  VertexIterator v,v_end;
  // Each task contains itself.
  for(tie(v,v_end) = vertices(*m_taskgraph); v != v_end; v++) {
    ContainSet *s = new ContainSet();
    s->insert(getTaskID(*v,m_taskgraph));
    (*m_containTasks)[*v] = s;
    m_taskRemoved[*v]=false;
  }
    
  m_rules[0] = (MergeRule*)new SingleChildMerge(m_taskgraph,m_orig_taskgraph,
						m_containTasks,m_invartask,
						m_outvartask,m_latency,
						m_bandwidth,m_nproc,
						&m_taskRemoved);
  m_rules[1] = (MergeRule*)new DuplicateParentMerge(m_taskgraph,m_orig_taskgraph,
						    m_containTasks,m_invartask,
						    m_outvartask,m_latency,
						    m_bandwidth,m_nproc,
						    &m_taskRemoved);
  m_rules[2] = (MergeRule*)new MergeAllParents(m_taskgraph,m_orig_taskgraph,
					       m_containTasks,m_invartask,
					       m_outvartask,m_latency,
					       m_bandwidth,m_nproc,
					       &m_taskRemoved);

  m_rules[3] = (MergeRule*)new MergeSiblings(m_taskgraph,m_orig_taskgraph,
					     m_containTasks,m_invartask,
					     m_outvartask,m_latency,
					     m_bandwidth,m_nproc,
					     &m_taskRemoved);
  
  // Add more rules here and change number of rules in constructor.
}

TaskMerging::~TaskMerging()
{
  delete [] m_rules;
}

void TaskMerging::merge(TaskGraph *taskgraph, TaskGraph* orig_tg,
			ParallelOptions *options,
			VertexID invartask, VertexID outvartask,
			ContainSetMap *cmap)
{
  if (!options) { cerr << "No paralleloptions set." << endl; exit(-1); }
  if (!taskgraph) { cerr << "No taskgraph built, merging impossible." 
			 << endl; exit(-1); }

  m_latency=options->get_latency();
  m_bandwidth = options->get_bandwidth();
  m_nproc = options->get_nproc();
  m_taskgraph = taskgraph;
  m_orig_taskgraph = orig_tg;
  m_containTasks = cmap;
  m_invartask = invartask;
  m_outvartask = outvartask;
  
  int new_size,orig_size=num_vertices(*m_taskgraph);
  initializeRules();

  //printTaskInfo();

  while (m_change) {
    m_change=false;
   mergeRules();
  }
  new_size = num_vertices(*m_taskgraph);

  cout << "Merged task graph from " << orig_size << " to " << new_size << endl;
}

void TaskMerging::printTaskInfo()
{
  VertexIterator v,v_end;
  cout << "bandwidth = " << m_bandwidth << endl;
  cout << "latency = " << m_latency << endl;
  
  for(tie(v,v_end) = vertices(*m_taskgraph); v!=v_end; ++v) {
    cout << "task: " <<(int) *v << " tlevel = " << m_rules[0]->tlevel(*v) 
	 << " execcost= " << m_rules[0]->getExecCost(*v) << endl;
  }
}


// Reinsert the source and sink nodes after merging has been preformed.
void::TaskMerging::reinsertSourceAndSink()
{
  
  
  list<EdgeInfo>::iterator e;
  
  m_taskRemoved[m_invartask]=false;
  m_taskRemoved[m_outvartask]=false;
  
  m_invartask = boost::add_vertex(*m_taskgraph);
  m_outvartask = boost::add_vertex(*m_taskgraph);
  
  (*m_containTasks)[m_invartask] = new ContainSet();
  (*m_containTasks)[m_outvartask] = new ContainSet();
  nameVertex(m_invartask,m_taskgraph,"invar");
  nameVertex(m_invartask,m_taskgraph,"outvar"); 
  setExecCost(m_invartask,1.0,m_taskgraph);
  setExecCost(m_outvartask,1.0,m_taskgraph);
  put(VertexUniqueIDProperty(m_taskgraph),
      m_invartask,
      m_invarID); 
  put(VertexUniqueIDProperty(m_taskgraph),
      m_outvartask,
      m_outvarID); 
  // Set global vars for start and end task
  merged_start_task=m_invartask;
  merged_stop_task=m_outvartask;

  for(e=m_source_sink_edges.begin(); e != m_source_sink_edges.end(); e++) {
    add_edge_containing(*e);
  }
}

void TaskMerging::add_edge_containing(const EdgeInfo &info)
{
  if (info.source == m_invarID) {
    //cerr << "Source edge" << endl;
    VertexIterator v,v_end;
    // This is really expensive, fortunately there are no longer so many tasks
    for (tie(v,v_end) = vertices(*m_taskgraph); v != v_end; v++) {
      if (*v != m_invartask && *v != m_outvartask) {
	ContainSet *cset = m_containTasks->find(*v)->second;
	if (cset && cset->find(info.target) != cset->end()) {
	  add_edge(m_invartask,*v,m_taskgraph,info.result);
	}
      }
    }
  } else if (info.target == m_outvarID) {
    VertexIterator v,v_end;
    // This is really expensive, fortunately there are no longer so many tasks
    for (tie(v,v_end) = vertices(*m_taskgraph); v != v_end; v++) { 
      if (*v != m_invartask && *v != m_outvartask) {
	ContainSet *cset = m_containTasks->find(*v)->second;
	if (cset && cset->find(info.source) != cset->end()) {
	  add_edge(*v,m_outvartask,m_taskgraph,info.result);
	}
      }
    }
  }  
}


// Remove source and sink nodes to speedup and simplify task merging
// ExecCost(src)= ExecCost(sink) = 0  
void TaskMerging::removeSourceAndSink()
{
  ChildrenIterator c,c_end;
  ParentsIterator p,p_end;
  m_invarID = getTaskID(m_invartask,m_taskgraph);
  m_outvarID = getTaskID(m_outvartask,m_taskgraph);

  for(tie(c,c_end) = children(m_invartask,*m_taskgraph); c != c_end; c++) {
    bool tmp; EdgeID e;
    tie(e,tmp) = edge(m_invartask,*c,*m_taskgraph);
    if (!tmp) { cerr << "Error, edge does not exist." << endl; exit(-1); }
    m_source_sink_edges.push_back(EdgeInfo(m_invarID,
					   getTaskID(*c,m_taskgraph),
					   copy_resultset(getResultSet(e,m_taskgraph))));
  }

  for(tie(p,p_end) = parents(m_outvartask,*m_taskgraph); p != p_end; p++) {
    bool tmp; EdgeID e;
    tie(e,tmp) = edge(*p,m_outvartask,*m_taskgraph);
    if (!tmp) { cerr << "Error, edge does not exist." << endl; exit(-1); }
    m_source_sink_edges.push_back(EdgeInfo(getTaskID(*p,m_taskgraph),
					   m_outvarID,
					   copy_resultset(getResultSet(e,m_taskgraph))));
  }
  
  clear_vertex(m_invartask,*m_taskgraph);
  clear_vertex(m_outvartask,*m_taskgraph);
  remove_vertex(m_invartask,*m_taskgraph);
  remove_vertex(m_outvartask,*m_taskgraph);
  m_taskRemoved[m_invartask]=true;
  m_taskRemoved[m_outvartask]=true;

  
  m_containTasks->erase(m_containTasks->find(m_invartask));
  m_containTasks->erase(m_containTasks->find(m_outvartask));

  ofstream file("removed.viz");
  my_write_graphviz(file,
		    *m_taskgraph,
		    make_label_writer(VertexUniqueIDProperty(m_taskgraph)),
		    make_label_writer(EdgeCommCostProperty(m_taskgraph))
		    );
  file.close();
}

void TaskMerging::mergeRules()
{
  
  //call each rule in order
  
  bool change=true;

  removeSourceAndSink();
  
  // calculate tlevel for each node
  map<VertexID,double> tlevel;
  VertexIterator v,v_end;
  for(tie(v,v_end) = vertices(*m_taskgraph); v != v_end; v++) {
    tlevel[*v] = m_rules[0]->tlevel(*v);
  }

  // a queue sorted on tlevel.
  TQueue *queue= new TQueue(TLevelCmp(m_taskgraph,&tlevel));
  
  clock_t t1,t2,t3;
  t1=clock();
  for(tie(v,v_end) = vertices(*m_taskgraph); v != v_end; v++) {
    queue->push(*v);
  }
  t2 = clock();
  //cerr << "Sorting took " << (double)(t2-t1)/(double)CLOCKS_PER_SEC << " seconds." << endl;

  while(change) {
    change = false;
    for (tie(v,v_end) = vertices(*m_taskgraph); v != v_end; v++) {
      change =  change || m_rules[0]->apply(*v)  ||
      	m_rules[1]->apply(*v) ||
	m_rules[2]->apply(*v);
      if (change) break;
    }
  }
  
  while(m_rules[3]->apply(NULL));

  ofstream file("merged_nosourcesink.viz");
  my_write_graphviz(file,*m_taskgraph,
		    make_label_writer(VertexUniqueIDProperty(m_taskgraph)),
		    make_label_writer(EdgeCommCostProperty(m_taskgraph))
		    );
  file.close();

  //  cerr << "Reinserting source and sink" << endl;

  // put back source and sink nodes.
  reinsertSourceAndSink();
  //  cerr << "Updating execution costs" << endl;
  updateExecCosts(); // When finished mergin, execcost should be calculated for each task 
		     // from containSet.
  //  cerr << "Leaving task merging.." << endl;
}

//write the correct exec cost to each task, by investigating m_containTasks
void TaskMerging::updateExecCosts()
{

  VertexIterator v,v_end;
  
  for(tie(v,v_end) = vertices(*m_taskgraph); v != v_end; v++) {
    double cost = m_rules[0]->getExecCost(*v);
    put(VertexExecCostProperty(m_taskgraph),*v,cost);
  }
}


