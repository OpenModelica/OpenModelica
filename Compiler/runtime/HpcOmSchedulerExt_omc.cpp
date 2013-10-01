#include "openmodelica.h"
#include "meta_modelica.h"
#include "rml_compatibility.h"
#include "OpenModelicaBootstrappingHeader.h"
#include "HpcOmSchedulerExt.cpp"

extern "C" {

extern void* HpcOmSchedulerExt_readScheduleFromGraphMl(const char *filename)
{
	return HpcOmSchedulerExtImpl__readScheduleFromGraphMl(filename);
}
}
