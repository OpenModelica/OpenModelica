extern "C" {
#include "openmodelica.h"
#include "meta_modelica.h"
#include "rml_compatibility.h"
#define ADD_METARECORD_DEFINTIONS static
#include "OpenModelicaBootstrappingHeader.h"
}

#include "TaskGraphResultsCmp.cpp"

extern "C" {
void* TaskGraphResults_checkTaskGraph(const char *filename,const char *reffilename)
{
  return TaskGraphResultsCmp_checkTaskGraph(filename,reffilename);
}

}

