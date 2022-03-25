#if !defined(_MSC_VER)
extern "C" {
#include "openmodelica.h"
#include "meta/meta_modelica.h"

#define ADD_METARECORD_DEFINITIONS static
#if defined(OMC_BOOTSTRAPPING)
  #include "../boot/tarball-include/OpenModelicaBootstrappingHeader.h"
#else
  #include "../OpenModelicaBootstrappingHeader.h"
#endif
}

#include "TaskGraphResultsCmp.cpp"
#else
#include "meta/meta_modelica.h"
#include "errorext.h"
#define TASKGRAPH_VS() c_add_message(NULL, -1, ErrorType_scripting, ErrorLevel_error, "TaskGraphResults not supported on Visual Studio.", NULL, 0);MMC_THROW();
#endif

extern "C" {
void* TaskGraphResults_checkTaskGraph(const char *filename,const char *reffilename)
{
#if defined(_MSC_VER)
  TASKGRAPH_VS();
#else
  return TaskGraphResultsCmp_checkTaskGraph(filename,reffilename);
#endif
}

void* TaskGraphResults_checkCodeGraph(const char *filename,const char *reffilename)
{
#if defined(_MSC_VER)
  TASKGRAPH_VS();
#else
  return TaskGraphResultsCmp_checkCodeGraph(filename,reffilename);
#endif
}

}

