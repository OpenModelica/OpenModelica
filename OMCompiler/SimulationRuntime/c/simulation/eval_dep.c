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

#include "eval_dep.h"


/**
 * @brief allocate new empty DAG with no edges
 *
 * @param nVars   number of variables in the system
 * @param nEqns   number of equations in the system
 * @return EVAL_DAG*
 */
EVAL_DAG* allocEvalDAG(size_t nVars, size_t nEqns)
{
  EVAL_DAG* dag = (EVAL_DAG*) malloc(sizeof(EVAL_DAG));
  dag->nVars = nVars;
  dag->nEqns = nEqns;
  if (nVars != 0) {
    dag->mapVarToEqNode = (size_t*) malloc(nVars*sizeof(size_t));
  } else {
    dag->mapVarToEqNode = NULL;
  }
  if (nEqns != 0 ) {
    dag->nEqDep = (size_t*) calloc(nEqns, sizeof(size_t));
    dag->eqDep = (size_t**) calloc(nEqns, sizeof(size_t*));
    dag->select = (modelica_boolean*) calloc(nEqns, sizeof(modelica_boolean));
  } else {
    dag->nEqDep = NULL;
    dag->eqDep = NULL;
    dag->select = NULL;
  }

  /*
  workaround, some JACOBIAN_TMP_VAR variables seem to miss an equation in which
  they are solved. This is probably because the derivative is zero and the
  corresponding equation was removed from the system.

  So we use the default -1 to mean there is no equation to evaluate.

  A better solution would be to remove the variable as well and propagate the
  zero symbolically.
  */
  for (size_t i = 0; i < nVars; i++)
    dag->mapVarToEqNode[i] = (size_t)(-1);

  return dag;
}

/**
 * @brief Free DAG
 *
 * @param dag
 */
void freeEvalDAG(EVAL_DAG* dag)
{
  free(dag->select);
  for (size_t i = 0; i < dag->nEqns; i++)
    free(dag->eqDep[i]);
  free(dag->eqDep);
  free(dag->nEqDep);
  free(dag->mapVarToEqNode);
  free(dag);
}

/**
 * @brief Create empty selection
 *
 * @param dag
 * @return EVAL_SELECTION*
 */
EVAL_SELECTION* allocEvalSelection(EVAL_DAG* dag)
{
  EVAL_SELECTION* selection = (EVAL_SELECTION*) malloc(sizeof(EVAL_SELECTION));
  selection->n = 0;
  selection->idx = (size_t*) malloc(dag->nEqns * sizeof(size_t));
  selection->dag = dag;

  return selection;
}

/**
 * @brief Free selection
 *
 * except the DAG, it may be used by other selections.
 *
 * @param selection
 */
void freeEvalSelection(EVAL_SELECTION* selection)
{
  free(selection->idx);
  free(selection);
}

/**
 * @brief clear selection
 *
 * call this first, then select manually, then activateEvalDependencies
 *
 * @param selection
 */
void clearEvalSelection(EVAL_SELECTION* selection)
{
  /* clear work array */
  for (size_t k = 0; k < selection->dag->nEqns; k++)
    selection->dag->select[k] = FALSE;

  /* set selected equations to zero just to be safe */
  selection->n = 0;
  // don't clear idx as that would be O(n) work,
  // it will be owerwritten by activateEvalDependencies
}

/**
 * @brief Set dependencies based on already selected subset.
 *
 * Since we have a DAG we can just go backwards and look at direct dependency
 * only, because indirect dependencies will be handled when we get to the direct
 * dependency node which sets its direct dependency and so on...
 */
void activateEvalDependencies(EVAL_SELECTION* selection)
{
  EVAL_DAG* dag = selection->dag;
  /* select dependencies backwards */
  for (size_t i = dag->nEqns-1; i+1 > 0 /* careful: count down with unsigned */; i--) {
    if (dag->select[i]) {
      for (size_t j = 0; j < dag->nEqDep[i]; j ++) {
        size_t dep = dag->eqDep[i][j];

        /*
        workaround, some JACOBIAN_TMP_VAR variables seem to miss an equation in which
        they are solved. This is probably because the derivative is zero and the
        corresponding equation was removed from the system.

        So we use the default -1 to mean there is no equation to evaluate.

        A better solution would be to remove the variable as well and propagate the
        zero symbolically.
        */
        if (dep == (size_t)(-1))
          continue;

        dag->select[dep] = TRUE;
      }
    }
  }

  /* get the indices in correct order */
  selection->n = 0;
  for (size_t i = 0; i < dag->nEqns; i++)
    if (dag->select[i])
      selection->idx[selection->n++] = i;
}
