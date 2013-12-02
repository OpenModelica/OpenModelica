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

RML_BEGIN_LABEL(HpcOmSchedulerExt__scheduleAdjList)
{
  int nelts = (int)RML_HDRSLOTS(RML_GETHDR(rmlA0)); //number of elements in array
  std::list<std::list<long int> > adjLsts = std::list<std::list<long int> >();

  std::cerr << "element count: " << nelts << std::endl;

  for(int i=0; i<nelts; i++) {
  std::cerr << "bla" << std::endl;
    void* adjLstE = RML_STRUCTDATA(rmlA0)[i]; //adjacence list entry
    std::list<long int> adjLst;

    while(RML_GETHDR(adjLstE) == RML_CONSHDR)
    {
      long int i1 = RML_UNTAGFIXNUM(RML_CAR(adjLstE));
      adjLst.push_back(i1);
      std::cerr << "elem: " << i1 << std::endl;
      adjLstE = RML_CDR(adjLstE);
    }

    adjLsts.push_back(adjLst);
  }

  rmlA0 = HpcOmSchedulerExtImpl__scheduleAdjList(adjLsts);
  RML_TAILCALLK(rmlSC);
}
RML_END_LABEL
}
