/*
 * This file is part of OpenModelica.
 *
 * Copyright (c) 1998-CurrentYear, Open Source Modelica Consortium (OSMC),
 * c/o Linköpings universitet, Department of Computer and Information Science,
 * SE-58183 Linköping, Sweden.
 *
 * All rights reserved.
 *
 * THIS PROGRAM IS PROVIDED UNDER THE TERMS OF THE BSD NEW LICENSE OR THE
 * GPL VERSION 3 LICENSE OR THE OSMC PUBLIC LICENSE (OSMC-PL) VERSION 1.2.
 * ANY USE, REPRODUCTION OR DISTRIBUTION OF THIS PROGRAM CONSTITUTES
 * RECIPIENT'S ACCEPTANCE OF THE OSMC PUBLIC LICENSE OR THE GPL VERSION 3,
 * ACCORDING TO RECIPIENTS CHOICE.
 *
 * The OpenModelica software and the OSMC (Open Source Modelica Consortium)
 * Public License (OSMC-PL) are obtained from OSMC, either from the above
 * address, from the URLs: http://www.openmodelica.org or
 * http://www.ida.liu.se/projects/OpenModelica, and in the OpenModelica
 * distribution. GNU version 3 is obtained from:
 * http://www.gnu.org/copyleft/gpl.html. The New BSD License is obtained from:
 * http://www.opensource.org/licenses/BSD-3-Clause.
 *
 * This program is distributed WITHOUT ANY WARRANTY; without even the implied
 * warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE, EXCEPT AS
 * EXPRESSLY SET FORTH IN THE BY RECIPIENT SELECTED SUBSIDIARY LICENSE
 * CONDITIONS OF OSMC-PL.
 *
 */

#ifndef _EVAL_DEP_H_
#define _EVAL_DEP_H_

#ifdef __cplusplus
extern "C" {
#endif

#include <stddef.h>
#include "../openmodelica_types.h"


/**
 * @brief DAG of evaluation dependency
 *
 * map from vars to eqns
 * directed acyclic graph between eqns
 */
typedef struct EVAL_DAG
{
  size_t nVars;                         /* number of (scalar) vars */
  size_t nEqns;                         /* number of (array) equation super nodes */
  size_t* mapVarToEqNode;               /* map from (scalar) var index to super node index */
  size_t* nEqDep;                       /* number of dependencies for each superNode */
  size_t** eqDep;                       /* index of dependent eqFunctions (edges of DAG) */
  modelica_boolean* select;             /* work array to mark selection */
} EVAL_DAG;

/**
 * @brief List of indices selected for evaluation
 */
typedef struct EVAL_SELECTION
{
  size_t n;                             /* number of selected equations */
  size_t* idx;                          /* selected equations */
  EVAL_DAG* dag;                        /* DAG to select from */
} EVAL_SELECTION;


EVAL_DAG* allocEvalDAG(size_t nVars, size_t nEqns);
EVAL_SELECTION* allocEvalSelection(EVAL_DAG* dag);
void freeEvalDAG(EVAL_DAG* dag);
void freeEvalSelection(EVAL_SELECTION* selection);

void clearEvalSelection(EVAL_SELECTION* selection);
void activateEvalDependencies(EVAL_SELECTION* selection);

#ifdef __cplusplus
}
#endif

#endif /* _EVAL_DEP_H_ */
