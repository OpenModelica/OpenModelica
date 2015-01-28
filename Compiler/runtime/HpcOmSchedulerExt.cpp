#include "TaskGraphResultsCmp.h"
#include "omc_config.h"
#include <iostream>

#if USE_PATOH
#include "patoh.h"
#endif

#if USE_METIS
#include "metis.h"
#endif

using namespace std;



void* HpcOmSchedulerExtImpl__readScheduleFromGraphMl(const char *filename)
{
  void *res = mmc_mk_nil();
  std::string errorMsg = std::string("");
  Graph g;
  GraphMLParser parser;

  if (!GraphMLParser::CheckIfFileExists(filename))
  {
    std::cerr << "File " << filename << " not found" << std::endl;
    errorMsg = "File '";
    errorMsg += std::string(filename);
    errorMsg += "' does not exist";
    res = mmc_mk_cons(mmc_mk_scon(errorMsg.c_str()), mmc_mk_nil());
    return res;
  }

  parser.ParseGraph(&g, filename,NodeComparator(&NodeComparator::CompareNodeNamesInt), &errorMsg);

  std::list<Node*> sortedNodeList = std::list<Node*>(g.nodes.begin(), g.nodes.end());
  sortedNodeList.sort(NodeComparator(&NodeComparator::CompareNodeTaskIdsInt));

    for (std::list<Node*>::iterator iter = sortedNodeList.begin(); iter != sortedNodeList.end(); iter++) {
      //std::cerr << "Node " << (*iter)->taskId << " th " << atoi((*iter)->threadId.substr(3).c_str()) << std::endl;

      if((*iter)->threadId.size() < 3)
        continue;
      res = mmc_mk_cons(mmc_mk_icon(atoi((*iter)->threadId.substr(3).c_str())), res);
    }
  return res;
}

#if USE_METIS
void* HpcOmSchedulerExtImpl__scheduleMetis(int* xadj, int* adjncy, int* vwgt, int* adjwgt, int xadjCount, int adjncyCount, int nparts)
{
  void *res = mmc_mk_nil();
  int nvert=xadjCount-1;
  idx_t met_nvtxs=xadjCount-1;
  idx_t met_ncon=1;
  //double * part=new double[nvert];
  idx_t * met_xadj=new idx_t[nvert+1]; //={0,2,5,8,11,13,16,20,24,28,31,33,36,39,42,44};
  idx_t * met_adjncy=new idx_t[xadj[nvert]];//={1,5,0,2,6,1,3,7,2,4,8,3,9,0,6,10,1,5,7,11,2,6,8,12,3,7,9,13,4,8,14,5,11,6,10,12,2,7,11,13,8,12,14,9,13};
  idx_t * met_vwgt=new idx_t[nvert]; //={0,2,5,8,11,13,16,20,24,28,31,33,36,39,42,44};
  idx_t * met_adjwgt=new idx_t[xadj[nvert]];
  idx_t met_objval;
  idx_t * met_part=new idx_t[nvert];
  idx_t met_nparts=nparts;
  int returnval;

  for(int i=0; i<nvert; i++) {
      met_xadj[i]=xadj[i];
    met_vwgt[i]=vwgt[i];
//    cout<<met_xadj[i]<<" "<<met_vwgt[i]<<endl;
  }
  met_xadj[nvert]=xadj[nvert];
//        cout<<"test: "<<met_xadj[nvert+4]<<endl;
  for(int i=0; i<xadj[nvert]; i++) {
    met_adjncy[i]=adjncy[i];
    met_adjwgt[i]=adjwgt[i];
//    cout<<met_adjncy[i]<<" "<<met_adjwgt[i]<<endl;
  }
    int * result=new int[nvert];
    returnval=METIS_PartGraphKway(&met_nvtxs,&met_ncon,met_xadj,met_adjncy,met_vwgt,NULL,met_adjwgt,&met_nparts,NULL,NULL,NULL,&met_objval,met_part);
    for(int i=nvert-1; i>=0; i--) {
        result[i]=met_part[i]+1;
        res = mmc_mk_cons(mmc_mk_icon(result[i]),res);
    }
    delete[] met_xadj;
    delete[] met_adjncy;
    delete[] met_vwgt;
    delete[] met_adjwgt;
    delete[] met_part;
    return res;
}
#elif USE_PATOH
void* HpcOmSchedulerExtImpl__scheduleMetis(int* vwgts, int* eptr, int* eint, int* hewgts, int vwgtsNelts, int eptrNelts, int nparts)
{
    void *res = mmc_mk_nil();
    int * result=new int[vwgtsNelts];
    PaToH_Parameters args;
    int c, n, nconst, cut, *partweights;
    PaToH_Initialize_Parameters(&args, PATOH_CONPART, PATOH_SUGPARAM_DEFAULT);
    args._k = nparts;
    partweights = new int[nparts];
    PaToH_Alloc(&args, vwgtsNelts, eptrNelts-1, 1, vwgts, NULL, eptr, eint);
    PaToH_Part(&args, vwgtsNelts, eptrNelts-1, 1, 0, vwgts, NULL,eptr, eint, NULL, result, partweights, &cut);
    PaToH_Free();


    for(int i=vwgtsNelts-1; i>=0; i--) {
        res = mmc_mk_cons(mmc_mk_icon(result[i]+1),res);
    }
    cout<<endl;
    delete [] result;
    delete [] partweights;
    return res;
}
#else
void* HpcOmSchedulerExtImpl__scheduleMetis(int* vwgts, int* eptr, int* eint, int* hewgts, int vwgtsNelts, int eptrNelts, int nparts)
{
    std::cerr<<"OpenModelica was not compiled with PATOH or METIS."<<std::endl;
    return mmc_mk_nil();
}
#endif
