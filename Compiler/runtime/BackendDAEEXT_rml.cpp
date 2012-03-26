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

/*
 * file:        BackendDAEEXT.cpp
 * description: The BackendDAEEXT.cpp file is the external implementation of
 *              MetaModelica package: Compiler/BackendDAEEXT.mo.
 *              This is used for the BLT and index reduction algorithms in BackendDAE.
 *              The implementation mainly consists of several bitvectors implemented
 *              using std::vector<bool> since such functionality is not available in
 *              MetaModelica Compiler (MMC).
 *
 * RCS: $Id$
 *
 */

extern "C" {
#include "rml.h"
}

#include "BackendDAEEXT.cpp"

extern "C" {

void BackendDAEEXT_5finit(void)
{
}

RML_BEGIN_LABEL(BackendDAEEXT__initMarks)
{
  int nvars = RML_UNTAGFIXNUM(rmlA0);
  int neqns = RML_UNTAGFIXNUM(rmlA1);
  BackendDAEEXTImpl__initMarks(nvars,neqns);
  RML_TAILCALLK(rmlSC);
} 
RML_END_LABEL

RML_BEGIN_LABEL(BackendDAEEXT__eMark)
{
  int i = RML_UNTAGFIXNUM(rmlA0);
  BackendDAEEXTImpl__eMark(i);
  RML_TAILCALLK(rmlSC);
}
RML_END_LABEL

RML_BEGIN_LABEL(BackendDAEEXT__vMark)
{
  int i = RML_UNTAGFIXNUM(rmlA0);
  BackendDAEEXTImpl__vMark(i);
  RML_TAILCALLK(rmlSC);
}
RML_END_LABEL

RML_BEGIN_LABEL(BackendDAEEXT__getVMark)
{
  int i = RML_UNTAGFIXNUM(rmlA0);
  rmlA0 = mk_bcon(BackendDAEEXTImpl__getVMark(i));
  RML_TAILCALLK(rmlSC);
}
RML_END_LABEL

RML_BEGIN_LABEL(BackendDAEEXT__getEMark)
{
  int i = RML_UNTAGFIXNUM(rmlA0);
  rmlA0 = mk_bcon(BackendDAEEXTImpl__getEMark(i));
  RML_TAILCALLK(rmlSC);
}
RML_END_LABEL

RML_BEGIN_LABEL(BackendDAEEXT__getMarkedEqns)
{
  rmlA0 = BackendDAEEXTImpl__getMarkedEqns();
  RML_TAILCALLK(rmlSC);
}
RML_END_LABEL

RML_BEGIN_LABEL(BackendDAEEXT__markDifferentiated)
{
  int i = RML_UNTAGFIXNUM(rmlA0);
  BackendDAEEXTImpl__markDifferentiated(i);
  RML_TAILCALLK(rmlSC);
}
RML_END_LABEL

RML_BEGIN_LABEL(BackendDAEEXT__clearDifferentiated)
{
  BackendDAEEXTImpl__clearDifferentiated();
  RML_TAILCALLK(rmlSC);
}
RML_END_LABEL

RML_BEGIN_LABEL(BackendDAEEXT__getDifferentiatedEqns)
{
  rmlA0 = BackendDAEEXTImpl__getDifferentiatedEqns();
  RML_TAILCALLK(rmlSC);
}
RML_END_LABEL

RML_BEGIN_LABEL(BackendDAEEXT__getMarkedVariables)
{
  rmlA0 = BackendDAEEXTImpl__getMarkedVariables();
  RML_TAILCALLK(rmlSC);
}
RML_END_LABEL

RML_BEGIN_LABEL(BackendDAEEXT__initLowLink)
{
  int nvars = RML_UNTAGFIXNUM(rmlA0);
  BackendDAEEXTImpl__initLowLink(nvars);
  RML_TAILCALLK(rmlSC);
} 
RML_END_LABEL

RML_BEGIN_LABEL(BackendDAEEXT__initNumber)
{
  int nvars = RML_UNTAGFIXNUM(rmlA0);
  BackendDAEEXTImpl__initNumber(nvars);
  RML_TAILCALLK(rmlSC);
} 
RML_END_LABEL

RML_BEGIN_LABEL(BackendDAEEXT__setLowLink)
{
  int i = RML_UNTAGFIXNUM(rmlA0);
  int val = RML_UNTAGFIXNUM(rmlA1);
  BackendDAEEXTImpl__setLowLink(i,val);
  RML_TAILCALLK(rmlSC);
}
RML_END_LABEL

RML_BEGIN_LABEL(BackendDAEEXT__setNumber)
{
  int i = RML_UNTAGFIXNUM(rmlA0);
  int val = RML_UNTAGFIXNUM(rmlA1);
  BackendDAEEXTImpl__setNumber(i,val);
  RML_TAILCALLK(rmlSC);
}
RML_END_LABEL

RML_BEGIN_LABEL(BackendDAEEXT__getNumber)
{
  int i = RML_UNTAGFIXNUM(rmlA0);
  rmlA0 = mk_icon(BackendDAEEXTImpl__getNumber(i));
  RML_TAILCALLK(rmlSC);
}
RML_END_LABEL

RML_BEGIN_LABEL(BackendDAEEXT__getLowLink)
{
  int i = RML_UNTAGFIXNUM(rmlA0);
  rmlA0 = mk_icon(BackendDAEEXTImpl__getLowLink(i));
  RML_TAILCALLK(rmlSC);
}
RML_END_LABEL


RML_BEGIN_LABEL(BackendDAEEXT__dumpMarkedEquations)
{
  int nvars = RML_UNTAGFIXNUM(rmlA0);
  BackendDAEEXTImpl__dumpMarkedEquations(nvars);
  RML_TAILCALLK(rmlSC);
}
RML_END_LABEL

RML_BEGIN_LABEL(BackendDAEEXT__dumpMarkedVariables)
{
  int nvars = RML_UNTAGFIXNUM(rmlA0);
  BackendDAEEXTImpl__dumpMarkedVariables(nvars);
  RML_TAILCALLK(rmlSC);
}
RML_END_LABEL

RML_BEGIN_LABEL(BackendDAEEXT__initV)
{
  int size = RML_UNTAGFIXNUM(rmlA0);
  BackendDAEEXTImpl__initV(size);
  RML_TAILCALLK(rmlSC);
}
RML_END_LABEL

RML_BEGIN_LABEL(BackendDAEEXT__initF)
{
  int size = RML_UNTAGFIXNUM(rmlA0);
  BackendDAEEXTImpl__initF(size);
  RML_TAILCALLK(rmlSC);
}
RML_END_LABEL

RML_BEGIN_LABEL(BackendDAEEXT__setF)
{
  int i = RML_UNTAGFIXNUM(rmlA0);
  int val = RML_UNTAGFIXNUM(rmlA1);
  BackendDAEEXTImpl__setF(i,val);
  RML_TAILCALLK(rmlSC);
}
RML_END_LABEL

RML_BEGIN_LABEL(BackendDAEEXT__getF)
{
  int i = RML_UNTAGFIXNUM(rmlA0);
  rmlA0 = mk_icon(BackendDAEEXTImpl__getF(i));
  RML_TAILCALLK(rmlSC);
}
RML_END_LABEL

RML_BEGIN_LABEL(BackendDAEEXT__setV)
{
  int i = RML_UNTAGFIXNUM(rmlA0);
  int val = RML_UNTAGFIXNUM(rmlA1);
  BackendDAEEXTImpl__setV(i,val);
  RML_TAILCALLK(rmlSC);
}
RML_END_LABEL

RML_BEGIN_LABEL(BackendDAEEXT__getV)
{
  int i = RML_UNTAGFIXNUM(rmlA0);
  rmlA0 = mk_icon(BackendDAEEXTImpl__getV(i));
  RML_TAILCALLK(rmlSC);
}
RML_END_LABEL

} // extern "C"
