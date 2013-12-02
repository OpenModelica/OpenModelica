#include "openmodelica.h"
#include "meta_modelica.h"
#include "rml_compatibility.h"
#define ADD_METARECORD_DEFINITIONS static
#include "OpenModelicaBootstrappingHeader.h"
#include "HpcOmSchedulerExt.cpp"

extern "C" {

extern void* HpcOmSchedulerExt_readScheduleFromGraphMl(const char *filename)
{
  return HpcOmSchedulerExtImpl__readScheduleFromGraphMl(filename);
}

extern void* HpcOmSchedulerExt_scheduleAdjList(modelica_metatype adjList)
{
	int nelts = (int)MMC_HDRSLOTS(MMC_GETHDR(adjList));
	std::list<long int> adjLsts[nelts];

	for(int i=0; i<nelts; ++i)
	{
		modelica_metatype adjLstE = MMC_STRUCTDATA(adjList)[i];
		std::list<long int> adjLst;

	    while(MMC_GETHDR(adjLstE) == MMC_CONSHDR) {
	      long int i1 = MMC_UNTAGFIXNUM(MMC_CAR(adjLstE));
	      adjLst.push_back(i1);
	      adjLstE = MMC_CDR(adjLstE);
	    }

	    adjLsts[i] = adjLst;
	}

	return HpcOmSchedulerExtImpl__scheduleAdjList(adjLsts);
}

}
