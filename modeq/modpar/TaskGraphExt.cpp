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

// Start and stop task in merged task graph
VertexID merged_start_task;
VertexID merged_stop_task;

// Task Merging object
TaskMerging taskmerging;

// Schedule object
Schedule *schedule;

// Codegen object
Codegen *codegen;

// Initialization vectors
vector<double> initvars;
vector<double> initstates;
vector<double> initparams;

// Variable names
vector<string> varnames;
vector<string> statenames;
vector<string> paramnames;

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
    int prio = RML_UNTAGFIXNUM(rmlA3);
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
      add_edge(p,c,&taskgraph,new string(resVar),prio);
    }
    
    EdgeID edgeID; bool tmp;
    tie(edgeID,tmp) = edge(p,c,taskgraph);

    setPriority(edgeID,prio,&taskgraph);

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
    char *orig_name = RML_STRINGDATA(rmlA3);
    VertexID taskID;
    map<int,VertexID>::iterator i;
    string str2=string(str);
    string str3=string(orig_name);

    symboltable[str2]=task;

    i = id_map.find(task);
    if (i == id_map.end()) { RML_TAILCALLK(rmlFC);};
    taskID = i->second;

    setResultName(taskID,str2,&taskgraph);
    setOrigName(taskID,str3,&taskgraph);
 
    if (send_to_end) {
      add_edge(taskID,stop_task,&taskgraph,new string(str),0);
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
    codegen = new Codegen("model.cpp","model.hpp","modelinit.txt");
    
    codegen->initialize(&taskgraph,&merged_taskgraph,schedule,&contain_set,nproc,nx,ny,np,
			merged_start_task,merged_stop_task,initvars,initstates,initparams,
			varnames,statenames,paramnames);

    codegen->generateCode();
    			  
    RML_TAILCALLK(rmlSC);
  } 
  RML_END_LABEL  


  RML_BEGIN_LABEL(TaskGraphExt__add_5finitvar)
  {
    int indx = RML_UNTAGFIXNUM(rmlA0);
    char *value = RML_STRINGDATA(rmlA1); 
    char *origname = RML_STRINGDATA(rmlA2);
    double val = atof(value);
    cerr << "initvars[" << indx << "] =" << val << endl;
    initvars.insert(initvars.begin()+indx,val);
    varnames.insert(varnames.begin()+indx,string(origname));
    RML_TAILCALLK(rmlSC);
  } 
  RML_END_LABEL  

  RML_BEGIN_LABEL(TaskGraphExt__add_5finitstate)
  {
    int indx = RML_UNTAGFIXNUM(rmlA0);
    char *value = RML_STRINGDATA(rmlA1); 
    char *origname = RML_STRINGDATA(rmlA2);
    double val = atof(value);
    cerr << "initstates[" << indx << "] =" << val << endl;
    initstates.insert(initstates.begin()+indx,val);
    statenames.insert(statenames.begin()+indx,string(origname));
    RML_TAILCALLK(rmlSC);
  } 
  RML_END_LABEL  

  RML_BEGIN_LABEL(TaskGraphExt__add_5finitparam)
  {
    int indx = RML_UNTAGFIXNUM(rmlA0);
    char *value = RML_STRINGDATA(rmlA1);
    char *origname = RML_STRINGDATA(rmlA2);
    double val = atof(value);
    cerr << "initparams[" << indx << "] =" << val << endl;
    initparams.insert(initparams.begin()+indx,val);
    paramnames.insert(paramnames.begin()+indx,string(origname));
    RML_TAILCALLK(rmlSC);
  } 
  RML_END_LABEL  

  RML_BEGIN_LABEL(TaskGraphExt__set_5ftasktype)
  {
    int taskID = RML_UNTAGFIXNUM(rmlA0);
    int type = RML_UNTAGFIXNUM(rmlA1); 
    VertexID task = find_task(taskID,&taskgraph);
    setTaskType(task,(TaskType)type,&taskgraph);      
    RML_TAILCALLK(rmlSC);
  } 
  RML_END_LABEL  


} // extern "C"
