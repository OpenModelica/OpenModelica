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

#include "BackendDAEEXT.cpp"
#include <stdlib.h>

extern "C" {

extern int BackendDAEEXT_getVMark(int _inInteger)
{
  fprintf(stderr, "BackendDAEEXT NYI\n");
  exit(1);
}
extern void* BackendDAEEXT_getMarkedEqns()
{
  fprintf(stderr, "BackendDAEEXT NYI\n");
  exit(1);
}
extern void BackendDAEEXT_eMark(int _inInteger)
{
  fprintf(stderr, "BackendDAEEXT NYI\n");
  exit(1);
}
extern void BackendDAEEXT_clearDifferentiated()
{
  fprintf(stderr, "BackendDAEEXT NYI\n");
  exit(1);
}
extern void* BackendDAEEXT_getDifferentiatedEqns()
{
  fprintf(stderr, "BackendDAEEXT NYI\n");
  exit(1);
}
extern int BackendDAEEXT_getLowLink(int _inInteger)
{
  fprintf(stderr, "BackendDAEEXT NYI\n");
  exit(1);
}
extern void* BackendDAEEXT_getMarkedVariables()
{
  fprintf(stderr, "BackendDAEEXT NYI\n");
  exit(1);
}
extern int BackendDAEEXT_getNumber(int _inInteger)
{
  fprintf(stderr, "BackendDAEEXT NYI\n");
  exit(1);
}
extern void BackendDAEEXT_setNumber(int _inInteger1, int _inInteger2)
{
  fprintf(stderr, "BackendDAEEXT NYI\n");
  exit(1);
}
extern void BackendDAEEXT_initMarks(int _inInteger1, int _inInteger2)
{
  fprintf(stderr, "BackendDAEEXT NYI\n");
  exit(1);
}
extern void BackendDAEEXT_initLowLink(int _inInteger)
{
  fprintf(stderr, "BackendDAEEXT NYI\n");
  exit(1);
}
extern void BackendDAEEXT_markDifferentiated(int _inInteger)
{
  fprintf(stderr, "BackendDAEEXT NYI\n");
  exit(1);
}
extern void BackendDAEEXT_initNumber(int _inInteger)
{
  fprintf(stderr, "BackendDAEEXT NYI\n");
  exit(1);
}
extern void BackendDAEEXT_setLowLink(int _inInteger1, int _inInteger2)
{
  fprintf(stderr, "BackendDAEEXT NYI\n");
  exit(1);
}
extern void BackendDAEEXT_vMark(int _inInteger)
{
  fprintf(stderr, "BackendDAEEXT NYI\n");
  exit(1);
}

}
