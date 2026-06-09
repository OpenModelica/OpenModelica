/*
* This file is part of OpenModelica.
*
* Copyright (c) 1998-CurrentYear, Open Source Modelica Consortium (OSMC),
* c/o Linköpings universitet, Department of Computer and Information Science,
* SE-58183 Linköping, Sweden.
*
* All rights reserved.
*
* THIS PROGRAM IS PROVIDED UNDER THE TERMS OF GPL VERSION 3 LICENSE OR
* THIS OSMC PUBLIC LICENSE (OSMC-PL) VERSION 1.2.
* ANY USE, REPRODUCTION OR DISTRIBUTION OF THIS PROGRAM CONSTITUTES
* RECIPIENT'S ACCEPTANCE OF THE OSMC PUBLIC LICENSE OR THE GPL VERSION 3,
* ACCORDING TO RECIPIENTS CHOICE.
*
* The OpenModelica software and the Open Source Modelica
* Consortium (OSMC) Public License (OSMC-PL) are obtained
* from OSMC, either from the above address,
* from the URLs: http://www.ida.liu.se/projects/OpenModelica or
* http://www.openmodelica.org, and in the OpenModelica distribution.
* GNU version 3 is obtained from: http://www.gnu.org/copyleft/gpl.html.
*
* This program is distributed WITHOUT ANY WARRANTY; without
* even the implied warranty of  MERCHANTABILITY or FITNESS
* FOR A PARTICULAR PURPOSE, EXCEPT AS EXPRESSLY SET FORTH
* IN THE BY RECIPIENT SELECTED SUBSIDIARY LICENSE CONDITIONS OF OSMC-PL.
*
* See the full OSMC Public License conditions for more details.
*
*/

#include <iostream>
#include <fstream>
#include <map>
#include <set>
#include <string>
#include <vector>
#include <cassert>
#include "../../SimulationRuntime/c/util/list.h"

#ifdef __cplusplus
extern "C" {
#endif

LIST** ASSC_fromDense(int* dense, int nv_, int ne_, int* nnz = nullptr);
void* allocAsscElement(const void* data);
bool isEqualAsscMatrixDebug(LIST **mref, int *mappingref, int ne);
void ASSC_setMatrixDebug(int* dense, int nv_, int ne_);
void bareiss();
int getNumberOfOperations();
LIST* getOperations();
void ASSC_printMatrix();

typedef struct{
  int index;
  int value;
} ASSC_ELEMENT;

typedef struct {
  // mode 0: pivot-update operation (normal step of Bareiss algorithm)
  // mode 1: swap-rows operation
  // mode 2: gcd operation
  int mode;
  union {
    struct { int pivot_index, pivot_value, update_index, update_value; } m0;
    struct { int index1, index2; } m1;
    struct { int index, gcd_value; } m2;
  } u;
} ASSC_OPERATION;


#ifdef __cplusplus
}
#endif
