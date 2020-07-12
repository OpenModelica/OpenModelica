#include "openmodelica.h"
#include "meta/meta_modelica.h"
#define ADD_METARECORD_DEFINITIONS static
#include "OpenModelicaBootstrappingHeader.h"

#if !defined(_MSC_VER)
#include "HpcOmSchedulerExt.cpp"
#else
#include "errorext.h"
#define HPC_OM_VS() c_add_message(NULL, -1, ErrorType_scripting, ErrorLevel_error, "HpcOmScheduler not supported on Visual Studio.", NULL, 0);MMC_THROW();
#endif

extern "C" {

extern void* HpcOmSchedulerExt_readScheduleFromGraphMl(const char *filename)
{
#if defined(_MSC_VER)
  HPC_OM_VS();
#else
  return HpcOmSchedulerExtImpl__readScheduleFromGraphMl(filename);
#endif
}

extern void* HpcOmSchedulerExt_scheduleMetis(modelica_metatype xadjIn, modelica_metatype adjncyIn, modelica_metatype vwgtIn, modelica_metatype adjwgtIn, int npartsIn)
{
#if defined(_MSC_VER)
  HPC_OM_VS();
#else
  int xadjNelts = (int)MMC_HDRSLOTS(MMC_GETHDR(xadjIn)); //number of elements in xadj-array
  int adjncyNelts = (int)MMC_HDRSLOTS(MMC_GETHDR(adjncyIn)); //number of elements in adjncy-array
  int vwgtNelts = (int)MMC_HDRSLOTS(MMC_GETHDR(vwgtIn)); //number of elements in vwgt-array
  int adjwgtNelts = (int)MMC_HDRSLOTS(MMC_GETHDR(adjwgtIn)); //number of elements in adjwgt-array
  int nparts = npartsIn;

  int* xadj = (int *) malloc(xadjNelts*sizeof(int));
  int* adjncy = (int *) malloc(adjncyNelts*sizeof(int));
  int* vwgt = (int *) malloc(vwgtNelts*sizeof(int));
  int* adjwgt = (int *) malloc(adjwgtNelts*sizeof(int));

  //setup xadj
  for(int i=0; i<xadjNelts; i++) {
    int xadjElem = MMC_UNTAGFIXNUM(MMC_STRUCTDATA(xadjIn)[i]);
    //std::cerr << "xadjElem: " << xadjElem << std::endl;
    xadj[i] = xadjElem;
  }
  //setup adjncy
  for(int i=0; i<adjncyNelts; i++) {
    int adjncyElem = MMC_UNTAGFIXNUM(MMC_STRUCTDATA(adjncyIn)[i]);
    //std::cerr << "adjncyElem: " << adjncyElem << std::endl;
    adjncy[i] = adjncyElem;
  }
  //setup vwgt
  for(int i=0; i<vwgtNelts; i++) {
    int vwgtElem = MMC_UNTAGFIXNUM(MMC_STRUCTDATA(vwgtIn)[i]);
    //std::cerr << "vwgtElem: " << vwgtElem << std::endl;
    vwgt[i] = vwgtElem;
  }
  //setup adjwgt
  for(int i=0; i<adjwgtNelts; i++) {
    int adjwgtElem = MMC_UNTAGFIXNUM(MMC_STRUCTDATA(adjwgtIn)[i]);
    //std::cerr << "adjwgtElem: " << adjwgtElem << std::endl;
    adjwgt[i] = adjwgtElem;
  }

  return HpcOmSchedulerExtImpl__scheduleMetis(xadj, adjncy, vwgt, adjwgt, xadjNelts, adjncyNelts, nparts);
}

extern void* HpcOmSchedulerExt_schedulehMetis(modelica_metatype xadjIn, modelica_metatype adjncyIn, modelica_metatype vwgtIn, modelica_metatype adjwgtIn, int npartsIn)
{

  int vwgtsNelts = (int)MMC_HDRSLOTS(MMC_GETHDR(xadjIn)); //number of elements in xadj-array
  int eptrNelts = (int)MMC_HDRSLOTS(MMC_GETHDR(adjncyIn)); //number of elements in adjncy-array
  int eintNelts = (int)MMC_HDRSLOTS(MMC_GETHDR(vwgtIn)); //number of elements in vwgt-array
  int hewgtsNelts = (int)MMC_HDRSLOTS(MMC_GETHDR(adjwgtIn)); //number of elements in adjwgt-array
  int nparts = npartsIn;

  int* vwgts = (int *) malloc(vwgtsNelts*sizeof(int));
  int* eptr = (int *) malloc(eptrNelts*sizeof(int));
  int* eint = (int *) malloc(eintNelts*sizeof(int));
  int* hewgts = (int *) malloc(hewgtsNelts*sizeof(int));

  //setup xadj
  for(int i=0; i<vwgtsNelts; i++) {
    int xadjElem = MMC_UNTAGFIXNUM(MMC_STRUCTDATA(xadjIn)[i]);
    std::cerr << "vwgtsElem: " << xadjElem << std::endl;
    vwgts[i] = xadjElem;
  }
  //setup adjncy
  for(int i=0; i<eptrNelts; i++) {
    int adjncyElem = MMC_UNTAGFIXNUM(MMC_STRUCTDATA(adjncyIn)[i]);
    std::cerr << "eptrElem: " << adjncyElem << std::endl;
    eptr[i] = adjncyElem;
  }
  //setup vwgt
  for(int i=0; i<eintNelts; i++) {
    int vwgtElem = MMC_UNTAGFIXNUM(MMC_STRUCTDATA(vwgtIn)[i]);
    std::cerr << "eintElem: " << vwgtElem << std::endl;
    eint[i] = vwgtElem;
  }
  //setup adjwgt
  for(int i=0; i<hewgtsNelts; i++) {
    int adjwgtElem = MMC_UNTAGFIXNUM(MMC_STRUCTDATA(adjwgtIn)[i]);
    std::cerr << "adjwgtElem: " << adjwgtElem << std::endl;
    hewgts[i] = adjwgtElem;
  }
  return HpcOmSchedulerExtImpl__scheduleMetis(vwgts, eptr, eint, hewgts, vwgtsNelts, eptrNelts, nparts);
#endif
}

}
