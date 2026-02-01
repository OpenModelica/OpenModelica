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
#include "../util/omc_error.h"
#include "../util/uthash.h"
#include "../simulation_data.h"
#include "simulation_info_json.h"


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
  for (size_t i = 0; i < nVars; ++i) {
    dag->mapVarToEqNode[i] = (size_t)(-1);
  }

  return dag;
}

/**
 * @brief Free DAG
 *
 * @param dag
 */
void freeEvalDAG(EVAL_DAG* dag)
{
  if (dag) {
    free(dag->select);
    /* only free once since eqDep was allocated in one chunk */
    if (dag->eqDep) free(dag->eqDep[0]);
    free(dag->eqDep);
    free(dag->nEqDep);
    free(dag->mapVarToEqNode);
    free(dag);
  }
}

/**
 * @brief Create empty selection
 *
 * @param dag
 * @return EVAL_SELECTION*
 */
EVAL_SELECTION* allocEvalSelection(EVAL_DAG* dag)
{
  assertStreamPrint(NULL, dag, "No DAG was given.");

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
  if (selection) {
    free(selection->idx);
    free(selection);
  }
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
  assertStreamPrint(NULL, selection, "selection is NULL.");

  /* clear work array */
  for (size_t i = 0; i < selection->dag->nEqns; ++i) {
    selection->dag->select[i] = FALSE;
  }

  /* set selected equations to zero just to be safe */
  selection->n = 0;
  // don't clear idx as that would be O(n) work,
  // it will be overwritten by activateEvalDependencies
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
  assertStreamPrint(NULL, selection, "selection is NULL.");

  EVAL_DAG* dag = selection->dag;
  /* select dependencies backwards */
  for (size_t i = dag->nEqns-1; i+1 > 0 /* careful: count down with unsigned */; --i) {
    if (dag->select[i]) {
      for (size_t j = 0; j < dag->nEqDep[i]; ++j) {
        size_t dep = dag->eqDep[i][j];

        /*
        workaround, some JACOBIAN_TMP_VAR variables seem to miss an equation in
        which they are solved. This is probably because the derivative is zero
        and the corresponding equation was removed from the system.

        So we use the default -1 to mean there is no equation to evaluate.

        A better solution would be to remove the variable as well and propagate
        the zero symbolically.
        */
        if (dep == (size_t)(-1)) continue;

        dag->select[dep] = TRUE;
      }
    }
  }

  /* get the indices in correct order */
  selection->n = 0;
  for (size_t i = 0; i < dag->nEqns; ++i) {
    if (dag->select[i]) selection->idx[selection->n++] = i;
  }
}

/* * * * * * * * * * * * * * *
 * OpenModelica specific stuff
 * * * * * * * * * * * * * * */

typedef struct hash_varName_eqIndex
{
  const char *id;     // variable name
  size_t val;         // equation index
  UT_hash_handle hh;
} hash_varName_eqIndex;

static hash_varName_eqIndex *varIndex_ht = NULL;

static void addVarToHashTable(const char *name, size_t index)
{
  hash_varName_eqIndex *s;
  HASH_FIND_STR(varIndex_ht, name, s);
  if (s) {
    errorStreamPrint(OMC_LOG_STDOUT, 1, "Variable %s is solved in more than one equation.", name);
    errorStreamPrint(OMC_LOG_STDOUT, 0, "originally solved in %zu, now in %zu", s->val, index);
    messageClose(OMC_LOG_STDOUT);
  } else {
    s = (hash_varName_eqIndex *)malloc(sizeof *s);
    s->id = name;
    s->val = index;
    HASH_ADD_KEYPTR(hh, varIndex_ht, s->id, strlen(s->id), s);
  }
}

static void clearHashTable()
{
  hash_varName_eqIndex *s, *tmp;

  HASH_ITER(hh, varIndex_ht, s, tmp) {
    HASH_DEL(varIndex_ht, s);
    free(s);
  }
  varIndex_ht = NULL;
}

/**
 * @brief Get variable index from name
 *
 * @param modelData   Pointer to model data structure
 * @param name        Name of variable
 * @return size_t     Index of variable if it exists else -1
 */
static size_t varIndexFromName(MODEL_DATA *modelData, const char *name)
{
  /* for now only look at real vars */
  for (int i = 0; i < modelData->nVariablesReal; i++) {
    if (strcmp(modelData->realVarsData[i].info.name, name)==0) {
      if (modelData->realVarsData[i].info.id >= 1000) {
        return (size_t)(modelData->realVarsData[i].info.id - 1000);
      } else {
        return (size_t)(-1);
      }
    }
  }
  return (size_t)(-1);
}

/**
 * @brief Set up DAG based on modelInfo
 *
 * Reads system info from modelData and sets all edges and var->eqn map in DAG.
 *
 * @param modelData   Pointer to model data structure
 * @param nEqns       Number of equations in this DAG
 * @param ixs         Map from local eqIndices in this DAG to global eqIndices
 */
void buildEvalDAG(MODEL_DATA *modelData, size_t nEqns, const size_t* ixs)
{
  size_t nEdges = 0;
  EVAL_DAG *dag = allocEvalDAG(modelData->nVariablesReal, nEqns);
  modelData->dag = dag;

  for (size_t i = 0; i < dag->nEqns; ++i) {
    EQUATION_INFO eqInfo = modelInfoGetEquation(&modelData->modelDataXml, ixs[i]);

    /* see what variables it defines */
    for (size_t j = 0; j < eqInfo.numVar; ++j) {
      size_t varIndex = varIndexFromName(modelData, eqInfo.vars[j]);
      if (varIndex != (size_t)(-1)) {
        /* store (varName -> eqIndex) in hash table */
        addVarToHashTable(eqInfo.vars[j], i);

        /* set var -> eqn map */
        dag->mapVarToEqNode[varIndex] = i;
      }
    }

    /* count how many edges will be in the DAG */
    // TODO remove duplicates if two vars are solved in the same eqn
    nEdges += eqInfo.numVarUsed;
    dag->nEqDep[i] = eqInfo.numVarUsed;
  }

  /* allocate space for all edges in one go */
  dag->eqDep[0] = (size_t*) malloc(nEdges * sizeof(size_t));
  for (size_t i = 1; i < dag->nEqns; ++i) {
    dag->eqDep[i] = dag->eqDep[i-1] + dag->nEqDep[i-1];
  }

  for (size_t i = 0; i < dag->nEqns; ++i) {
    EQUATION_INFO eqInfo = modelInfoGetEquation(&modelData->modelDataXml, ixs[i]);

    for (size_t j = 0; j < eqInfo.numVarUsed; ++j) {
      /* look up variable in hash table */
      hash_varName_eqIndex *s;
      HASH_FIND_STR(varIndex_ht, eqInfo.varsUsed[j], s);
      /* if it exists, add the corresponding equation to the dependency */
      // TODO reduce size of eqDep if used variables are not solved in the
      // system corresponding to this DAG
      dag->eqDep[i][j] = s ? s->val : (size_t)(-1);
    }
  }

  clearHashTable();
}
