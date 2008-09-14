#include <iostream>
#include <fstream>
#include <map>
#include <set>
#include <string>
#include <vector>


using namespace std;


extern "C"
{
#include <assert.h>
#include "rml.h"

  void errormsg()
  {
  cerr << "MODPAR disabled. Configure with --with-BOOST=boostdir and --with-MODPAR and recompile for enabling." << endl;
  }

  void TaskGraphExt_5finit(void)
  {
  }
  
  RML_BEGIN_LABEL(TaskGraphExt__newTask)
  {
    errormsg();
    RML_TAILCALLK(rmlFC);
  } 
  RML_END_LABEL

  RML_BEGIN_LABEL(TaskGraphExt__addEdge)
  {
    errormsg();
    RML_TAILCALLK(rmlFC);
  } 
  RML_END_LABEL

  RML_BEGIN_LABEL(TaskGraphExt__getTask)
  {
    errormsg();
    RML_TAILCALLK(rmlFC);
  } 
  RML_END_LABEL

  RML_BEGIN_LABEL(TaskGraphExt__storeResult)
  {
    errormsg();
    RML_TAILCALLK(rmlFC);
  } 
  RML_END_LABEL

  RML_BEGIN_LABEL(TaskGraphExt__dumpGraph)
  {
    errormsg();
    RML_TAILCALLK(rmlFC);
  } 
  RML_END_LABEL

  RML_BEGIN_LABEL(TaskGraphExt__dumpMergedGraph)
  {
    errormsg();
    RML_TAILCALLK(rmlFC);
  } 
  RML_END_LABEL

  RML_BEGIN_LABEL(TaskGraphExt__registerStartStop)
  {
    errormsg();
    RML_TAILCALLK(rmlFC);
  } 
  RML_END_LABEL

  RML_BEGIN_LABEL(TaskGraphExt__getStartTask)
  {
    errormsg();
    RML_TAILCALLK(rmlFC);

  } 
  RML_END_LABEL

  RML_BEGIN_LABEL(TaskGraphExt__getStopTask)
  {
    errormsg();
    RML_TAILCALLK(rmlFC);
  } 
  RML_END_LABEL


  RML_BEGIN_LABEL(TaskGraphExt__mergeTasks)
  {
    errormsg();
    RML_TAILCALLK(rmlFC);
  } 
  RML_END_LABEL  

  RML_BEGIN_LABEL(TaskGraphExt__setExecCost)
  {
    errormsg();
    RML_TAILCALLK(rmlFC);
  } 
  RML_END_LABEL  

  RML_BEGIN_LABEL(TaskGraphExt__setCommCost)
  {
    errormsg();
    RML_TAILCALLK(rmlFC);
  } 
  RML_END_LABEL  

  RML_BEGIN_LABEL(TaskGraphExt__schedule)
  {
    errormsg();
    RML_TAILCALLK(rmlFC);
  } 
  RML_END_LABEL  

  RML_BEGIN_LABEL(TaskGraphExt__generateCode)
  {
    errormsg();
    RML_TAILCALLK(rmlFC);			  
  } 
  RML_END_LABEL  

  RML_BEGIN_LABEL(TaskGraphExt__addInitState)
  {
    errormsg();
    RML_TAILCALLK(rmlFC);			  
  } 
  RML_END_LABEL  

  RML_BEGIN_LABEL(TaskGraphExt__addInitParam)
  {
    errormsg();
    RML_TAILCALLK(rmlFC);			  
  } 
  RML_END_LABEL  

  RML_BEGIN_LABEL(TaskGraphExt__addInitVar)
  {
    errormsg();
    RML_TAILCALLK(rmlFC);			  
  } 
  RML_END_LABEL  

  RML_BEGIN_LABEL(TaskGraphExt__setTaskType)
  {
    errormsg();
    RML_TAILCALLK(rmlFC);			  
  } 
  RML_END_LABEL  

} // extern "C"
