/*
 * This file is part of OpenModelica.
 *
 * Copyright (c) 1998-2010, Linköpings University,
 * Department of Computer and Information Science,
 * SE-58183 Linköping, Sweden.
 *
 * All rights reserved.
 *
 * THIS PROGRAM IS PROVIDED UNDER THE TERMS OF THIS OSMC PUBLIC
 * LICENSE (OSMC-PL). ANY USE, REPRODUCTION OR DISTRIBUTION OF
 * THIS PROGRAM CONSTITUTES RECIPIENT'S ACCEPTANCE OF THE OSMC
 * PUBLIC LICENSE.
 *
 * The OpenModelica software and the Open Source Modelica
 * Consortium (OSMC) Public License (OSMC-PL) are obtained
 * from Linköpings University, either from the above address,
 * from the URL: http://www.ida.liu.se/projects/OpenModelica
 * and in the OpenModelica distribution.
 *
 * This program is distributed  WITHOUT ANY WARRANTY; without
 * even the implied warranty of  MERCHANTABILITY or FITNESS
 * FOR A PARTICULAR PURPOSE, EXCEPT AS EXPRESSLY SET FORTH
 * IN THE BY RECIPIENT SELECTED SUBSIDIARY LICENSE CONDITIONS
 * OF OSMC-PL.
 *
 * See the full OSMC Public License conditions for more details.
 *
 */

extern "C" {
#include "rml.h"
}
#include "HpcOmSchedulerExt.cpp"
#include <iostream>
extern "C" {
void HpcOmSchedulerExt_5finit(void)
{
}

RML_BEGIN_LABEL(HpcOmSchedulerExt__readScheduleFromGraphMl)
{
  rmlA0 = HpcOmSchedulerExtImpl__readScheduleFromGraphMl(RML_STRINGDATA(rmlA0));
  RML_TAILCALLK(rmlSC);
}
RML_END_LABEL

RML_BEGIN_LABEL(HpcOmSchedulerExt__scheduleMetis)
{
  int xadjNelts = (int)RML_HDRSLOTS(RML_GETHDR(rmlA0)); //number of elements in xadj-array
  int adjncyNelts = (int)RML_HDRSLOTS(RML_GETHDR(rmlA1)); //number of elements in adjncy-array
  int vwgtNelts = (int)RML_HDRSLOTS(RML_GETHDR(rmlA2)); //number of elements in vwgt-array
  int adjwgtNelts = (int)RML_HDRSLOTS(RML_GETHDR(rmlA3)); //number of elements in adjwgt-array
  int nparts = RML_UNTAGFIXNUM(rmlA4); //number of threads

  int* xadj = (int *) malloc(xadjNelts*sizeof(int));
  int* adjncy = (int *) malloc(adjncyNelts*sizeof(int));
  int* vwgt = (int *) malloc(vwgtNelts*sizeof(int));
  int* adjwgt = (int *) malloc(adjwgtNelts*sizeof(int));

  std::cerr << "xadj element count: " << xadjNelts << std::endl;
  std::cerr << "adjncy element count: " << adjncyNelts << std::endl;
  std::cerr << "vwgt element count: " << vwgtNelts << std::endl;
  std::cerr << "adjwgt element count: " << adjwgtNelts << std::endl;

  //setup xadj
  for(int i=0; i<xadjNelts; i++) {
    int xadjElem = RML_UNTAGFIXNUM(RML_STRUCTDATA(rmlA0)[i]);
    std::cerr << "xadjElem: " << xadjElem << std::endl;
    xadj[i] = xadjElem;
  }
  //setup adjncy
  for(int i=0; i<adjncyNelts; i++) {
    int adjncyElem = RML_UNTAGFIXNUM(RML_STRUCTDATA(rmlA1)[i]);
    std::cerr << "adjncyElem: " << adjncyElem << std::endl;
    adjncy[i] = adjncyElem;
  }
  //setup vwgt
  for(int i=0; i<vwgtNelts; i++) {
    int vwgtElem = RML_UNTAGFIXNUM(RML_STRUCTDATA(rmlA2)[i]);
    std::cerr << "vwgtElem: " << vwgtElem << std::endl;
    vwgt[i] = vwgtElem;
  }
  //setup adjwgt
  for(int i=0; i<adjwgtNelts; i++) {
    int adjwgtElem = RML_UNTAGFIXNUM(RML_STRUCTDATA(rmlA3)[i]);
    std::cerr << "adjwgtElem: " << adjwgtElem << std::endl;
    adjwgt[i] = adjwgtElem;
  }

  rmlA0 = HpcOmSchedulerExtImpl__scheduleMetis(xadj, adjncy, vwgt, adjwgt, xadjNelts, adjncyNelts, nparts);
  RML_TAILCALLK(rmlSC);
}
RML_END_LABEL

RML_BEGIN_LABEL(HpcOmSchedulerExt__schedulehMetis)
{
  int vwgtsNelts = (int)RML_HDRSLOTS(RML_GETHDR(rmlA0)); //number of elements in xadj-array
  int eptrNelts = (int)RML_HDRSLOTS(RML_GETHDR(rmlA1)); //number of elements in adjncy-array
  int eintNelts = (int)RML_HDRSLOTS(RML_GETHDR(rmlA2)); //number of elements in vwgt-array
  int hewgtsNelts = (int)RML_HDRSLOTS(RML_GETHDR(rmlA3)); //number of elements in adjwgt-array
  int nparts = RML_UNTAGFIXNUM(rmlA4); //number of threads

  int* vwgts = (int *) malloc(vwgtsNelts*sizeof(int));
  int* eptr = (int *) malloc(eptrNelts*sizeof(int));
  int* eint = (int *) malloc(eintNelts*sizeof(int));
  int* hewgts = (int *) malloc(hewgtsNelts*sizeof(int));

  std::cerr << "vwgts element count: " << vwgtsNelts << std::endl;
  std::cerr << "eptr element count: " << eptrNelts << std::endl;
  std::cerr << "eint element count: " << eintNelts << std::endl;
  std::cerr << "hewgts element count: " << hewgtsNelts << std::endl;

  //setup xadj
  for(int i=0; i<vwgtsNelts; i++) {
    int xadjElem = RML_UNTAGFIXNUM(RML_STRUCTDATA(rmlA0)[i]);
    std::cerr << "vwgtsElem: " << xadjElem << std::endl;
    vwgts[i] = xadjElem;
  }
  //setup adjncy
  for(int i=0; i<eptrNelts; i++) {
    int adjncyElem = RML_UNTAGFIXNUM(RML_STRUCTDATA(rmlA1)[i]);
    std::cerr << "eptrElem: " << adjncyElem << std::endl;
    eptr[i] = adjncyElem;
  }
  //setup vwgt
  for(int i=0; i<eintNelts; i++) {
    int vwgtElem = RML_UNTAGFIXNUM(RML_STRUCTDATA(rmlA2)[i]);
    std::cerr << "eintElem: " << vwgtElem << std::endl;
    eint[i] = vwgtElem;
  }
  //setup adjwgt
  for(int i=0; i<hewgtsNelts; i++) {
    int adjwgtElem = RML_UNTAGFIXNUM(RML_STRUCTDATA(rmlA3)[i]);
    std::cerr << "hewgtsElem: " << adjwgtElem << std::endl;
    hewgts[i] = adjwgtElem;
  }

  rmlA0 = HpcOmSchedulerExtImpl__scheduleMetis(vwgts, eptr, eint, hewgts, vwgtsNelts, eptrNelts, nparts);
  RML_TAILCALLK(rmlSC);
}
RML_END_LABEL
}

