#include <iostream>
#include <fstream>
#include <map>
#include <set>
#include <string>
#include <vector>
#include "TaskGraph.hpp"
#include "ParallelOptions.hpp"
#include "TaskMerging.hpp"
#include "Schedule.hpp"
#include "Codegen.hpp"

using namespace std;


// Global variables
//-----------------

// The taskgraph (using boost graph library)
TaskGraph taskgraph;

// The merged taskgraph
TaskGraph merged_taskgraph;

// Symboltable, giving task for a given variable name
map<string,int> symboltable;

// Mapping from unique id to VertexID
map<int,VertexID> id_map;

// Map for containsets (which tasks are contained inside other tasks )
ContainSetMap contain_set;

// Start and stop task.
VertexID start_task;
VertexID stop_task;

// Task Merging object
TaskMerging taskmerging;

// Schedule object
Schedule *schedule;

// Codegen object
Codegen *codegen;

extern "C"
{
#include <assert.h>
#include "rml.h"
#include "../absyn_builder/yacclib.h"

// Number of processors, defined in rtopts.c
extern int nproc;


  void TaskGraphExt_5finit(void)
  {
  }
  
  RML_BEGIN_LABEL(TaskGraphExt__new_5ftask)
  {
    char *str = RML_STRINGDATA(rmlA0); 
    static int nextID=0; // Give unique id to each task.
    VertexID newID=boost::add_vertex(taskgraph); 
    nameVertex(newID,&taskgraph,str);
    put(VertexUniqueIDProperty(&taskgraph),
	newID,
	nextID); 
    setTaskType(newID,TempVar,&taskgraph);
    id_map[nextID]=newID;
    setExecCost(newID,1.0,&taskgraph);
    rmlA0 = (void*)mk_icon(nextID++);
    RML_TAILCALLK(rmlSC);
  } 
  RML_END_LABEL

  RML_BEGIN_LABEL(TaskGraphExt__add_5fedge)
  {
    int parent = RML_UNTAGFIXNUM(rmlA0);
    int child = RML_UNTAGFIXNUM(rmlA1);
    map<int,VertexID>::iterator i;
    VertexID p,c;
    i = id_map.find(parent);
    if (i == id_map.end()) { RML_TAILCALLK(rmlFC);};
    p = i->second;
    
    i = id_map.find(child);
    if (i == id_map.end()) { RML_TAILCALLK(rmlFC);};
    c = i->second;
    
    char * resVar = RML_STRINGDATA(rmlA2);
    if (strcmp(resVar,"")==0) {
      add_edge(p,c,&taskgraph);
    } else {
      add_edge(p,c,&taskgraph,new string(resVar));
    }
    RML_TAILCALLK(rmlSC);
  } 
  RML_END_LABEL

  RML_BEGIN_LABEL(TaskGraphExt__get_5ftask)
  {
    char *str = RML_STRINGDATA(rmlA0); 
    
    map<string,int>::iterator i;
    i = symboltable.find(string(str));
    
    if (i == symboltable.end()) {
      RML_TAILCALLK(rmlFC);
    } else {
      rmlA0 = (void*)mk_icon(i->second);
      RML_TAILCALLK(rmlSC);
    }
  } 
  RML_END_LABEL

  RML_BEGIN_LABEL(TaskGraphExt__store_5fresult)
  {
    char *str = RML_STRINGDATA(rmlA0); 
    int task = RML_UNTAGFIXNUM(rmlA1);
    int send_to_end = (rml_sint_t)(rmlA2);
    VertexID taskID;
    map<int,VertexID>::iterator i;

    symboltable[string(str)]=task;

    i = id_map.find(task);
    if (i == id_map.end()) { RML_TAILCALLK(rmlFC);};
    taskID = i->second;
 
    if (send_to_end) {
      add_edge(taskID,stop_task,&taskgraph,new string(str));
    }

    RML_TAILCALLK(rmlSC);
  } 
  RML_END_LABEL

  RML_BEGIN_LABEL(TaskGraphExt__dump_5fgraph)
  {
    char *filename = RML_STRINGDATA(rmlA0); 
    ofstream file(filename);
    my_write_graphviz(file,taskgraph,
		      make_label_writer(VertexUniqueIDProperty(&taskgraph)),
		      make_label_writer(EdgeCommCostProperty(&taskgraph))
		      );
    file.close();
    RML_TAILCALLK(rmlSC);
  } 
  RML_END_LABEL

  RML_BEGIN_LABEL(TaskGraphExt__dump_5fmerged_5fgraph)
  {
    char *filename = RML_STRINGDATA(rmlA0); 
    ofstream file(filename);
    my_write_graphviz(file,merged_taskgraph,
		      make_label_writer(VertexUniqueIDProperty(&merged_taskgraph)),
		      make_label_writer(EdgeCommCostProperty(&merged_taskgraph))
		      );
    file.close();
    RML_TAILCALLK(rmlSC);
  } 
  RML_END_LABEL

  RML_BEGIN_LABEL(TaskGraphExt__register_5fstartstop)
  {
    int start = RML_UNTAGFIXNUM(rmlA0);
    int stop = RML_UNTAGFIXNUM(rmlA1);

    map<int,VertexID>::iterator i;
    i = id_map.find(start);
    if (i == id_map.end()) { RML_TAILCALLK(rmlFC);};
    start_task = i->second;

    i = id_map.find(stop);
    if (i == id_map.end()) { RML_TAILCALLK(rmlFC);};
    stop_task = i->second;

    setExecCost(start_task,0.0,&taskgraph);
    setExecCost(stop_task,0.0,&taskgraph);
    RML_TAILCALLK(rmlSC);
  } 
  RML_END_LABEL

  RML_BEGIN_LABEL(TaskGraphExt__get_5fstarttask)
  {
    rmlA0 = (void*)mk_icon(getTaskID(start_task,&taskgraph));
    RML_TAILCALLK(rmlSC);
  } 
  RML_END_LABEL

  RML_BEGIN_LABEL(TaskGraphExt__get_5fstoptask)
  {
    rmlA0 = (void*)mk_icon(getTaskID(stop_task,&taskgraph));
    RML_TAILCALLK(rmlSC);
  } 
  RML_END_LABEL


  RML_BEGIN_LABEL(TaskGraphExt__merge_5ftasks)
  {
    double l = rml_prim_get_real(rmlA0); 
    double b = rml_prim_get_real(rmlA1); 
    
    cerr << "latency =" << l 
	 << " bandwidth ="  << b << endl;
      
    
    ParallelOptions options(nproc,l,b);
    merged_taskgraph = taskgraph;
    taskmerging.merge(&merged_taskgraph,&taskgraph,&options,
		      find_task(getTaskID(start_task,&taskgraph),&merged_taskgraph),
		      find_task(getTaskID(stop_task,&taskgraph),&merged_taskgraph),
		      &contain_set);
      
    RML_TAILCALLK(rmlSC);
  } 
  RML_END_LABEL

  RML_BEGIN_LABEL(TaskGraphExt__set_5fexeccost)
  {
    int taskID = RML_UNTAGFIXNUM(rmlA0);
    double cost = rml_prim_get_real(rmlA1); 
    VertexID task = find_task(taskID,&taskgraph);
    setExecCost(task,cost,&taskgraph);      
    RML_TAILCALLK(rmlSC);
  } 
  RML_END_LABEL  

  RML_BEGIN_LABEL(TaskGraphExt__set_5fcommcost)
  {
    int p = RML_UNTAGFIXNUM(rmlA0);
    int c = RML_UNTAGFIXNUM(rmlA1);
    VertexID parent,child;
    int cost = RML_UNTAGFIXNUM(rmlA2);
    EdgeID e; bool tmp;
    parent = find_task(p,&taskgraph);
    child = find_task(c,&taskgraph);    
    tie(e,tmp) = edge(parent,child,taskgraph);
    if (!tmp) {
      cerr << "edge (" << p << ", " << c << " does not exist\n" << endl;
      RML_TAILCALLK(rmlFC);
    }
    setCommCost(e,cost,&taskgraph);      
    RML_TAILCALLK(rmlSC);
  } 
  RML_END_LABEL  

  RML_BEGIN_LABEL(TaskGraphExt__schedule)
  {
    int n = RML_UNTAGFIXNUM(rmlA0);
    cerr << "Schedule with " << n << " processors." << endl;

    schedule = new Schedule(&merged_taskgraph,
			    taskmerging.get_starttask(),
			    taskmerging.get_endtask(),
			    n);

    schedule->printSchedule(cerr);    
    
    RML_TAILCALLK(rmlSC);
  } 
  RML_END_LABEL  

  RML_BEGIN_LABEL(TaskGraphExt__generate_5fcode)
  {
    int nx = RML_UNTAGFIXNUM(rmlA0);
    int ny = RML_UNTAGFIXNUM(rmlA1);
    int np = RML_UNTAGFIXNUM(rmlA2);
    codegen = new Codegen("model.cpp","model.hpp");
    
    codegen->initialize(&taskgraph,&merged_taskgraph,schedule,&contain_set,nproc,nx,ny,np);

    codegen->generateCode();
    			  
    RML_TAILCALLK(rmlSC);
  } 
  RML_END_LABEL  

  
} // extern "C"
