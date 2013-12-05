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

extern void* HpcOmSchedulerExt_scheduleMetis(modelica_metatype xadjIn, modelica_metatype adjncyIn, modelica_metatype vwgtIn, modelica_metatype adjwgtIn)
{
  int xadjNelts = (int)MMC_HDRSLOTS(MMC_GETHDR(xadjIn)); //number of elements in xadj-array
  int adjncyNelts = (int)MMC_HDRSLOTS(MMC_GETHDR(adjncyIn)); //number of elements in adjncy-array
  int vwgtNelts = (int)MMC_HDRSLOTS(MMC_GETHDR(vwgtIn)); //number of elements in vwgt-array
  int adjwgtNelts = (int)MMC_HDRSLOTS(MMC_GETHDR(adjwgtIn)); //number of elements in adjwgt-array

  int* xadj = (int *) malloc(xadjNelts*sizeof(int));
  int* adjncy = (int *) malloc(adjncyNelts*sizeof(int));
  int* vwgt = (int *) malloc(vwgtNelts*sizeof(int));
  int* adjwgt = (int *) malloc(adjwgtNelts*sizeof(int));

  //setup xadj
  for(int i=0; i<xadjNelts; i++) {
    int xadjElem = MMC_UNTAGFIXNUM(MMC_STRUCTDATA(xadjIn)[i]);
    std::cerr << "xadjElem: " << xadjElem << std::endl;
    xadj[i] = xadjElem;
  }
  //setup adjncy
  for(int i=0; i<adjncyNelts; i++) {
    int adjncyElem = MMC_UNTAGFIXNUM(MMC_STRUCTDATA(adjncyIn)[i]);
    std::cerr << "adjncyElem: " << adjncyElem << std::endl;
    xadj[i] = adjncyElem;
  }
  //setup vwgt
  for(int i=0; i<vwgtNelts; i++) {
    int vwgtElem = MMC_UNTAGFIXNUM(MMC_STRUCTDATA(vwgtIn)[i]);
    std::cerr << "vwgtElem: " << vwgtElem << std::endl;
    xadj[i] = vwgtElem;
  }
  //setup adjwgt
  for(int i=0; i<adjwgtNelts; i++) {
    int adjwgtElem = MMC_UNTAGFIXNUM(MMC_STRUCTDATA(adjwgtIn)[i]);
    std::cerr << "adjwgtElem: " << adjwgtElem << std::endl;
    xadj[i] = adjwgtElem;
  }

  return HpcOmSchedulerExtImpl__scheduleMetis(xadj, adjncy, vwgt, adjwgt, xadjNelts, adjncyNelts);
}

}
