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

/*
 * file:        ASSCEXT.cpp
 * description: The ASSCEXT.cpp file is the external implementation of
 *              MetaModelica package: Compiler/ASSC.mo.
 *              This is used for the analytical to structural singularity conversion
 *              (ASSC) algorithm which is used for alias elimination and before index
 *              reduction.
 */

#include <iostream>
#include <fstream>
#include <map>
#include <set>
#include <string>
#include <vector>
#include <cassert>
#include "../../SimulationRuntime/c/util/list.h"

using namespace std;

#ifdef __cplusplus
extern "C" {
#endif

static int nv;
static int ne;
static int nnz;
static int* col_ptrs=NULL;
static int* col_ids=NULL;
static int* col_val=NULL;

LIST** rows = NULL;

typedef struct{
  int index;
  int value;
} ASSC_ELEMENT;

void* allocAsscElement(const void* data)
{
  void* new_element = malloc(sizeof(ASSC_ELEMENT));
  assertStreamPrint(NULL, new_element != NULL, "ASSC_ELEMENT out of memory.");
  return new_element;
};

void copyAsscElement(void* dest, const void* src)
{
  memcpy(dest, src, sizeof(ASSC_ELEMENT));
};

void printAsscElement(void* data)
{
  ASSC_ELEMENT* elem = (ASSC_ELEMENT*) data;
  printf("(%d: %d) ", (int) elem->index, (int) elem->value);
}

#ifdef __cplusplus
}
#endif