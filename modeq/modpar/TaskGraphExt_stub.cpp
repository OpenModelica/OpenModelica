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
#include "../absyn_builder/yacclib.h"

  void errormsg()
  {
  cerr << "MODPAR disabled. Configure with --with-BOOST=boostdir and --with-MODPAR and recompile for enabling." << endl;
  }

  void TaskGraphExt_5finit(void)
  {
  }
  
  RML_BEGIN_LABEL(TaskGraphExt__new_5ftask)
  {
    errormsg();
    RML_TAILCALLK(rmlFC);
  } 
  RML_END_LABEL

  RML_BEGIN_LABEL(TaskGraphExt__add_5fedge)
  {
    errormsg();
    RML_TAILCALLK(rmlFC);
  } 
  RML_END_LABEL

  RML_BEGIN_LABEL(TaskGraphExt__get_5ftask)
  {
    errormsg();
    RML_TAILCALLK(rmlFC);
  } 
  RML_END_LABEL

  RML_BEGIN_LABEL(TaskGraphExt__store_5fresult)
  {
    errormsg();
    RML_TAILCALLK(rmlFC);
  } 
  RML_END_LABEL

  RML_BEGIN_LABEL(TaskGraphExt__dump_5fgraph)
  {
    errormsg();
    RML_TAILCALLK(rmlFC);
  } 
  RML_END_LABEL

  RML_BEGIN_LABEL(TaskGraphExt__dump_5fmerged_5fgraph)
  {
    errormsg();
    RML_TAILCALLK(rmlFC);
  } 
  RML_END_LABEL

  RML_BEGIN_LABEL(TaskGraphExt__register_5fstartstop)
  {
    errormsg();
    RML_TAILCALLK(rmlFC);
  } 
  RML_END_LABEL

  RML_BEGIN_LABEL(TaskGraphExt__get_5fstarttask)
  {
    errormsg();
    RML_TAILCALLK(rmlFC);

  } 
  RML_END_LABEL

  RML_BEGIN_LABEL(TaskGraphExt__get_5fstoptask)
  {
    errormsg();
    RML_TAILCALLK(rmlFC);
  } 
  RML_END_LABEL


  RML_BEGIN_LABEL(TaskGraphExt__merge_5ftasks)
  {
    errormsg();
    RML_TAILCALLK(rmlFC);
  } 
  RML_END_LABEL  

  RML_BEGIN_LABEL(TaskGraphExt__set_5fexeccost)
  {
    errormsg();
    RML_TAILCALLK(rmlFC);
  } 
  RML_END_LABEL  

  RML_BEGIN_LABEL(TaskGraphExt__set_5fcommcost)
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

  RML_BEGIN_LABEL(TaskGraphExt__generate_5fcode)
  {
    errormsg();
    RML_TAILCALLK(rmlFC);			  
  } 
  RML_END_LABEL  

  RML_BEGIN_LABEL(TaskGraphExt__add_5finitstate)
  {
    errormsg();
    RML_TAILCALLK(rmlFC);			  
  } 
  RML_END_LABEL  

  RML_BEGIN_LABEL(TaskGraphExt__add_5finitparam)
  {
    errormsg();
    RML_TAILCALLK(rmlFC);			  
  } 
  RML_END_LABEL  

  RML_BEGIN_LABEL(TaskGraphExt__add_5finitvar)
  {
    errormsg();
    RML_TAILCALLK(rmlFC);			  
  } 
  RML_END_LABEL  

} // extern "C"
